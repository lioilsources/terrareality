package listing

// Demo listings ("ukázkové inzeráty") of the closed beta: clearly labelled
// placeholder offers so the map is not empty before real landlords add units
// (terractl demo seed|list|remove, docs/runbooks/seed-praha.md). They are
// created in system context for a company organization without members,
// their photos go through the normal media pipeline (blob store +
// ProcessMedia) and they are published without the moderation queue (the
// operator who seeds them is the reviewer). listings.is_demo keeps them out
// of statistics, SEO pages and digests and makes the API refuse tenant
// actions on them (problem code demo_listing).

import (
	"context"
	"crypto/sha256"
	"encoding/binary"
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"math/rand/v2"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/terrareality/terrareality/services/api/internal/audit"
	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/media"
	"github.com/terrareality/terrareality/services/api/internal/storage"
)

// DefaultDemoOrg is the name of the organization holding the demo listings.
const DefaultDemoOrg = "TerraReality – ukázka"

// DefaultDemoSeed makes the address pick reproducible across runs.
const DefaultDemoSeed = "terrareality-demo"

// demoRooms are the photos every flat directory must contain, in display order.
var demoRooms = []struct {
	File    string
	Caption I18n
}{
	{"living.jpg", I18n{CS: "Obývací pokoj", EN: "Living room"}},
	{"kitchen.jpg", I18n{CS: "Kuchyně", EN: "Kitchen"}},
	{"bedroom.jpg", I18n{CS: "Ložnice", EN: "Bedroom"}},
	{"bathroom.jpg", I18n{CS: "Koupelna", EN: "Bathroom"}},
}

// DemoFlat is one entry of manifest.json in the photos directory:
// [{"flat":"flat-01","type":"panel|brick|new","layout":"2+kk"}].
type DemoFlat struct {
	Flat   string `json:"flat"`
	Type   string `json:"type"`
	Layout string `json:"layout"`
}

var demoFlatRe = regexp.MustCompile(`^flat-[0-9]{2,3}$`)

// demoBaseArea is a typical floor area (m²) per layout.
var demoBaseArea = map[string]float64{"1+kk": 28, "1+1": 36, "2+kk": 50, "2+1": 58, "3+kk": 72, "3+1": 80,
	"4+kk": 95, "4+1": 105, "5+kk": 120, "5+1": 130}

// LoadDemoManifest reads and validates manifest.json of a photos directory:
// every flat has a flat-NN subdirectory with the four room photos.
func LoadDemoManifest(dir string) ([]DemoFlat, error) {
	raw, err := os.ReadFile(filepath.Join(dir, "manifest.json"))
	if err != nil {
		return nil, fmt.Errorf("manifest: %w", err)
	}
	var flats []DemoFlat
	if err := json.Unmarshal(raw, &flats); err != nil {
		return nil, fmt.Errorf("manifest.json: %w", err)
	}
	if len(flats) == 0 {
		return nil, errors.New("manifest.json lists no flats")
	}
	seen := map[string]bool{}
	for i, f := range flats {
		if !demoFlatRe.MatchString(f.Flat) {
			return nil, fmt.Errorf("manifest entry %d: flat %q is not flat-NN", i+1, f.Flat)
		}
		if seen[f.Flat] {
			return nil, fmt.Errorf("manifest entry %d: %s listed twice", i+1, f.Flat)
		}
		seen[f.Flat] = true
		if f.Type != "panel" && f.Type != "brick" && f.Type != "new" {
			return nil, fmt.Errorf("%s: type %q is not panel, brick or new", f.Flat, f.Type)
		}
		if _, ok := demoBaseArea[f.Layout]; !ok {
			return nil, fmt.Errorf("%s: unsupported layout %q", f.Flat, f.Layout)
		}
		for _, r := range demoRooms {
			st, err := os.Stat(filepath.Join(dir, f.Flat, r.File))
			if err != nil {
				return nil, fmt.Errorf("%s: %w", f.Flat, err)
			}
			if st.Size() <= 0 || st.Size() > media.MaxBytes {
				return nil, fmt.Errorf("%s/%s: photos must have 1 byte to 20 MB", f.Flat, r.File)
			}
		}
	}
	return flats, nil
}

// DemoFacts are the generated, plausible attributes of one demo flat.
type DemoFacts struct {
	FloorArea     float64
	Floor         int32
	TotalFloors   int32
	Rent          int64 // minor units (CZK haléře)
	Deposit       int64
	Utilities     int64
	AvailableFrom time.Time
	Attributes    map[string]any
}

// demoRand is a generator seeded from the seed and the flat key, so the same
// flat always gets the same attributes.
func demoRand(seed, key string) *rand.Rand {
	h := sha256.Sum256([]byte(seed + "/" + key))
	return rand.New(rand.NewPCG(binary.BigEndian.Uint64(h[0:8]), binary.BigEndian.Uint64(h[8:16])))
}

// between returns a uniform value in [lo, hi].
func between(r *rand.Rand, lo, hi float64) float64 { return lo + r.Float64()*(hi-lo) }

// GenerateDemoFacts derives area, floor, rent (consistent with layout and
// building type, Praha 2026 asking rents), deposit, utilities and catalog
// attributes for a demo flat. today anchors the availability date.
func GenerateDemoFacts(f DemoFlat, seed string, today time.Time) DemoFacts {
	r := demoRand(seed, f.Flat)
	area := math.Round(demoBaseArea[f.Layout] * between(r, 0.9, 1.15))
	// CZK per m² and month by building type.
	perM2 := map[string]float64{"panel": 340, "brick": 390, "new": 450}[f.Type] * between(r, 0.92, 1.08)
	rentCZK := math.Round(area*perM2/500) * 500
	utilCZK := math.Round(area*between(r, 40, 55)/100) * 100
	rooms := 1
	if _, err := fmt.Sscanf(f.Layout, "%d", &rooms); err != nil {
		rooms = 1
	}
	var floor, total int32
	attrs := map[string]any{"layout": f.Layout, "floor_area": area, "rooms_count": float64(rooms), "bathrooms_count": float64(1),
		"washing_machine": true, "intercom": true, "cellar": true, "internet": "available", "shower": true,
		"transport": []any{"metro", "tram", "bus"}, "suitable_for": []any{"couples", "expats"}}
	switch f.Type {
	case "panel":
		total = []int32{8, 12, 13}[r.IntN(3)]
		floor = int32(1 + r.IntN(int(total-1)))
		attrs["building_type"] = "panel"
		attrs["building_condition"] = "after_renovation"
		attrs["year_built"] = float64(1970 + r.IntN(20))
		attrs["energy_class"] = []string{"C", "D"}[r.IntN(2)]
		attrs["elevator"] = true
		attrs["heating"] = "district"
		attrs["furnished"] = "partly"
		attrs["kitchen_appliances"] = []any{"fridge", "oven", "induction"}
		attrs["loggia"] = r.IntN(2) == 0
	case "brick":
		total = []int32{4, 5, 6}[r.IntN(3)]
		floor = int32(1 + r.IntN(int(total)))
		attrs["building_type"] = "brick"
		attrs["building_condition"] = "very_good"
		attrs["year_built"] = float64(1895 + r.IntN(45))
		attrs["energy_class"] = []string{"D", "E"}[r.IntN(2)]
		attrs["elevator"] = r.IntN(2) == 0
		attrs["heating"] = "gas"
		attrs["ceiling_height"] = float64(290 + 10*r.IntN(6))
		attrs["furnished"] = "full"
		attrs["kitchen_appliances"] = []any{"fridge", "oven", "gas_hob", "dishwasher"}
		attrs["balcony"] = r.IntN(3) == 0
	default: // new
		total = []int32{6, 7, 8}[r.IntN(3)]
		floor = int32(1 + r.IntN(int(total)))
		attrs["building_type"] = "other"
		attrs["building_condition"] = "new"
		attrs["year_built"] = float64(2019 + r.IntN(6))
		attrs["energy_class"] = []string{"A", "B"}[r.IntN(2)]
		attrs["elevator"] = true
		attrs["heating"] = "district"
		attrs["furnished"] = "partly"
		attrs["kitchen_appliances"] = []any{"fridge", "oven", "induction", "dishwasher", "microwave"}
		attrs["balcony"] = true
		attrs["air_conditioning"] = r.IntN(2) == 0
		attrs["floor_heating"] = true
		attrs["bike_storage"] = true
	}
	attrs["floor"] = float64(floor)
	attrs["total_floors"] = float64(total)
	attrs["max_occupants"] = float64(min(rooms+1, 6))
	// The first day of a month two to ten weeks ahead.
	d := today.AddDate(0, 0, 14+r.IntN(56))
	from := time.Date(d.Year(), d.Month(), 1, 0, 0, 0, 0, time.UTC).AddDate(0, 1, 0)
	return DemoFacts{FloorArea: area, Floor: floor, TotalFloors: total, Rent: int64(rentCZK) * 100,
		Deposit: int64(rentCZK) * 2 * 100, Utilities: int64(utilCZK) * 100, AvailableFrom: from, Attributes: attrs}
}

// demoPlace names the location in texts ("Praha 6 – Dejvice").
func demoPlace(place db.GetRuianPlaceRow) string {
	parts := []string{}
	if place.District != nil && *place.District != "" {
		parts = append(parts, *place.District)
	} else {
		parts = append(parts, place.Municipality)
	}
	if place.CityPart != nil && *place.CityPart != "" && (place.District == nil || *place.CityPart != *place.District) {
		parts = append(parts, *place.CityPart)
	}
	return strings.Join(parts, " – ")
}

// DemoDisclaimerCS opens every demo description.
const DemoDisclaimerCS = "Toto je ukázkový inzerát pro uzavřenou betu TerraReality – byt nelze pronajmout a pronajímatele nelze kontaktovat."

// DemoDisclaimerEN opens every English demo description.
const DemoDisclaimerEN = "This is a demo listing for the TerraReality closed beta – the flat cannot be rented and the landlord cannot be contacted."

// DemoTexts returns the title ("Ukázka: …") and the description, both
// starting with the demo disclaimer. No LLM involved.
func DemoTexts(f DemoFlat, facts DemoFacts, place string) (title, desc I18n) {
	area := int(facts.FloorArea)
	title = I18n{CS: fmt.Sprintf("Ukázka: Pronájem bytu %s, %d m², %s", f.Layout, area, place),
		EN: fmt.Sprintf("Demo: %s flat for rent, %d m², %s", f.Layout, area, place)}
	var cs, en string
	switch f.Type {
	case "panel":
		cs = fmt.Sprintf("Zrekonstruovaný byt %s v panelovém domě s výtahem, %d. patro z %d. Nová kuchyňská linka, "+
			"koupelna se sprchovým koutem, sklep. Výborná dostupnost MHD, obchody a škola v docházkové vzdálenosti.",
			f.Layout, facts.Floor, facts.TotalFloors)
		en = fmt.Sprintf("Renovated %s flat in a panel building with a lift, floor %d of %d. New kitchen, bathroom with "+
			"a shower, cellar. Excellent public transport, shops and a school within walking distance.",
			f.Layout, facts.Floor, facts.TotalFloors)
	case "brick":
		cs = fmt.Sprintf("Světlý byt %s v cihlovém činžovním domě, %d. patro z %d, vysoké stropy. Plně zařízený, "+
			"kuchyň s myčkou, sklep. Klidná ulice s kavárnami a parkem nedaleko.", f.Layout, facts.Floor, facts.TotalFloors)
		en = fmt.Sprintf("Bright %s flat in a brick apartment building, floor %d of %d, high ceilings. Fully furnished, "+
			"kitchen with a dishwasher, cellar. Quiet street with cafés and a park nearby.", f.Layout, facts.Floor, facts.TotalFloors)
	default:
		cs = fmt.Sprintf("Byt %s v novostavbě, %d. patro z %d, balkon, podlahové topení, energetická třída %s. "+
			"Kuchyň se spotřebiči, kolárna, výtah.", f.Layout, facts.Floor, facts.TotalFloors, facts.Attributes["energy_class"])
		en = fmt.Sprintf("%s flat in a new building, floor %d of %d, balcony, floor heating, energy class %s. "+
			"Kitchen with appliances, bike storage, lift.", f.Layout, facts.Floor, facts.TotalFloors, facts.Attributes["energy_class"])
	}
	return title, I18n{CS: DemoDisclaimerCS + "\n\n" + cs, EN: DemoDisclaimerEN + "\n\n" + en}
}

// DemoSeed configures SeedDemo.
type DemoSeed struct {
	OrgName string // DefaultDemoOrg when empty
	Dir     string // photos directory with manifest.json and flat-NN subdirectories
	Count   int    // at most this many flats from the manifest (all when <= 0)
	Seed    string // address and attribute seed (DefaultDemoSeed when empty)
	Today   time.Time
}

// DemoSeedResult reports what SeedDemo did.
type DemoSeedResult struct {
	OrgID      uuid.UUID
	OrgCreated bool
	Created    []uuid.UUID
	Skipped    int // flats that already have a live demo listing
}

// SeedDemo creates one published demo listing per manifest flat that does
// not have a live one yet (idempotent). Each flat gets a distinct real Praha
// address from the imported RÚIAN points, picked deterministically.
func (s *Service) SeedDemo(ctx context.Context, in DemoSeed) (DemoSeedResult, error) {
	var res DemoSeedResult
	if s.Blob == nil || s.Scanner == nil {
		return res, errors.New("demo seed needs object storage and the media scanner")
	}
	if in.OrgName == "" {
		in.OrgName = DefaultDemoOrg
	}
	if in.Seed == "" {
		in.Seed = DefaultDemoSeed
	}
	if in.Today.IsZero() {
		in.Today = time.Now()
	}
	flats, err := LoadDemoManifest(in.Dir)
	if err != nil {
		return res, err
	}
	if in.Count > 0 && len(flats) > in.Count {
		flats = flats[:in.Count]
	}
	orgID, created, err := s.EnsureDemoOrg(ctx, in.OrgName)
	if err != nil {
		return res, err
	}
	res.OrgID, res.OrgCreated = orgID, created
	q := db.New(s.Pool)
	places, err := q.DemoRuianPlaces(ctx, db.DemoRuianPlacesParams{Seed: in.Seed, Lim: int32(len(flats))})
	if err != nil {
		return res, err
	}
	if len(places) < len(flats) {
		return res, fmt.Errorf("only %d Praha addresses imported, %d needed: run terractl import-ruian --region praha first",
			len(places), len(flats))
	}
	live, err := q.ListDemoListings(ctx)
	if err != nil {
		return res, err
	}
	have := map[string]bool{}
	for _, l := range live {
		if l.OrgID == orgID && l.Status != "archived" {
			have[l.UnitLabel] = true
		}
	}
	for i, f := range flats {
		if have[f.Flat] {
			res.Skipped++
			continue
		}
		id, err := s.CreateDemoListing(ctx, orgID, f, places[i], in.Dir, in.Seed, in.Today)
		if err != nil {
			return res, fmt.Errorf("%s: %w", f.Flat, err)
		}
		res.Created = append(res.Created, id)
	}
	return res, nil
}

// EnsureDemoOrg returns the memberless company organization of that name,
// creating it when missing.
func (s *Service) EnsureDemoOrg(ctx context.Context, name string) (uuid.UUID, bool, error) {
	var id uuid.UUID
	created := false
	err := s.system(ctx, func(q *db.Queries, _ pgx.Tx) error {
		o, err := q.FindDemoOrganization(ctx, name)
		if err == nil {
			id = o.ID
			return nil
		}
		if !errors.Is(err, pgx.ErrNoRows) {
			return err
		}
		o, err = q.CreateOrganization(ctx, db.CreateOrganizationParams{Kind: "company", Name: name, JurisdictionCode: "CZ"})
		if err != nil {
			return err
		}
		id, created = o.ID, true
		return audit.Record(ctx, q, audit.Event{OrgID: &o.ID, Entity: "organization", EntityID: &o.ID,
			Action: "organization.created", Diff: map[string]any{"name": name, "source": "terractl demo seed"}})
	})
	return id, created, err
}

// CreateDemoListing creates, fills and publishes one demo listing: address,
// property and unit (labelled with the flat key), the generated texts and
// attributes, the four photos through the media pipeline, and an approved
// first version that is indexed for search.
func (s *Service) CreateDemoListing(ctx context.Context, orgID uuid.UUID, f DemoFlat, ruianID int64, dir, seed string, today time.Time) (uuid.UUID, error) {
	q := db.New(s.Pool)
	place, err := q.GetRuianPlace(ctx, ruianID)
	if err != nil {
		return uuid.Nil, fmt.Errorf("address %d: %w", ruianID, err)
	}
	facts := GenerateDemoFacts(f, seed, today)
	title, desc := DemoTexts(f, facts, demoPlace(place))
	type upload struct {
		id   uuid.UUID
		key  string
		data []byte
	}
	var uploads []upload
	var id uuid.UUID
	err = s.system(ctx, func(q *db.Queries, _ pgx.Tx) error {
		prop, err := ensureProperty(ctx, q, orgID, place, "apartment")
		if err != nil {
			return err
		}
		layout, area, floor := f.Layout, facts.FloorArea, facts.Floor
		u, err := q.CreateUnit(ctx, db.CreateUnitParams{OrgID: orgID, PropertyID: prop.ID, Kind: "apartment",
			Label: f.Flat, Floor: &floor, FloorArea: &area, Layout: &layout})
		if err != nil {
			return err
		}
		rent, deposit, util, term := facts.Rent, facts.Deposit, facts.Utilities, int32(12)
		l, err := q.CreateListing(ctx, db.CreateListingParams{OrgID: orgID, UnitID: u.ID, Title: jsonb(title),
			Description: jsonb(desc), RentAmount: &rent, Currency: "CZK", DepositAmount: &deposit, UtilitiesAmount: &util,
			AvailableFrom: pgtype.Date{Time: facts.AvailableFrom, Valid: true}, MinTermMonths: &term,
			Attributes: jsonb(facts.Attributes), LocationPrecision: "approximate"})
		if err != nil {
			return err
		}
		id = l.ID
		if err := q.SetListingDemo(ctx, id); err != nil {
			return err
		}
		for pos, r := range demoRooms {
			data, err := os.ReadFile(filepath.Join(dir, f.Flat, r.File))
			if err != nil {
				return err
			}
			ct := http.DetectContentType(data)
			if !allowedTypes[ct] {
				return fmt.Errorf("%s: %s is not a JPEG, PNG or WebP photo", r.File, ct)
			}
			mid := uuid.Must(uuid.NewV7())
			key := fmt.Sprintf("orgs/%s/media/%s/original", orgID, mid)
			size := int64(len(data))
			if _, err := q.CreateMedia(ctx, db.CreateMediaParams{ID: mid, OrgID: orgID, ListingID: &id, Kind: "photo",
				ObjectKey: key, Filename: r.File, ContentType: ct, SizeBytes: &size}); err != nil {
				return err
			}
			if _, err := q.UpdateMediaMeta(ctx, db.UpdateMediaMetaParams{ID: mid, OrgID: orgID, Position: int32(pos),
				Caption: jsonb(r.Caption)}); err != nil {
				return err
			}
			uploads = append(uploads, upload{id: mid, key: key, data: data})
		}
		return audit.Record(ctx, q, audit.Event{OrgID: &orgID, Entity: "listing", EntityID: &id, Action: "listing.created",
			Diff: map[string]any{"unit_kind": "apartment", "address": place.Label, "demo": true, "flat": f.Flat}})
	})
	if err != nil {
		return uuid.Nil, err
	}
	// The owner upload path: object in the blob store, then the same
	// processing the process_media job runs (sanitize, scan, vision when on),
	// synchronously so the listing can be published right away.
	for _, u := range uploads {
		if err := s.Blob.Put(ctx, u.key, "application/octet-stream", u.data); err != nil {
			return id, err
		}
		if err := q.SetMediaStatus(ctx, db.SetMediaStatusParams{ID: u.id, Status: "processing"}); err != nil {
			return id, err
		}
		if err := s.ProcessMedia(ctx, u.id); err != nil {
			return id, err
		}
		m, err := q.SystemGetMedia(ctx, u.id)
		if err != nil {
			return id, err
		}
		if m.Status != "ready" {
			reason := ""
			if m.RejectionReason != nil {
				reason = *m.RejectionReason
			}
			return id, fmt.Errorf("photo %s was rejected: %s", m.Filename, reason)
		}
	}
	return id, s.publishDemo(ctx, orgID, id)
}

// publishDemo snapshots the working copy as an approved version and indexes
// it. Demo listings skip the moderation queue: the operator seeding them is
// the human who approves them (ADR 0003).
func (s *Service) publishDemo(ctx context.Context, orgID, id uuid.UUID) error {
	return s.system(ctx, func(q *db.Queries, _ pgx.Tx) error {
		if _, err := q.LockListing(ctx, id); err != nil {
			return err
		}
		var v View
		if err := loadView(ctx, q, orgID, id, &v); err != nil {
			return err
		}
		if !v.Listing.IsDemo {
			return errors.New("not a demo listing")
		}
		snap := buildSnapshot(v.Listing, v.Context, v.Media)
		next, err := q.NextListingVersion(ctx, id)
		if err != nil {
			return err
		}
		ver, err := q.CreateListingVersion(ctx, db.CreateListingVersionParams{ListingID: id, OrgID: orgID, Version: next,
			Snapshot: jsonb(snap)})
		if err != nil {
			return err
		}
		note := "terractl demo seed"
		if _, err := q.ReviewListingVersion(ctx, db.ReviewListingVersionParams{ID: ver.ID, Status: "approved", ReviewNote: &note}); err != nil {
			return err
		}
		if err := q.PublishListingVersion(ctx, db.PublishListingVersionParams{ID: id, PublishedVersion: &next}); err != nil {
			return err
		}
		if err := s.index(ctx, q, id); err != nil {
			return err
		}
		return audit.Record(ctx, q, audit.Event{OrgID: &orgID, Entity: "listing", EntityID: &id,
			Action: "listing.review_approved", Diff: map[string]any{"version": next, "note": note, "demo": true}})
	})
}

// DemoListing is one row of terractl demo list.
type DemoListing = db.ListDemoListingsRow

// DemoListings lists the live (not removed) demo listings.
func (s *Service) DemoListings(ctx context.Context) ([]DemoListing, error) {
	return db.New(s.Pool).ListDemoListings(ctx)
}

// RemoveDemoListings archives every live demo listing, takes it out of
// search and deletes its photos (rows and stored objects, as DeleteMedia does
// for photos no version shows any more). Idempotent: a second run finds
// nothing. It returns the numbers of removed listings and photos.
func (s *Service) RemoveDemoListings(ctx context.Context) (listings, photos int, err error) {
	rows, err := s.DemoListings(ctx)
	if err != nil {
		return 0, 0, err
	}
	for _, l := range rows {
		var keys []string
		err := s.system(ctx, func(q *db.Queries, _ pgx.Tx) error {
			if err := q.SoftDeleteListing(ctx, db.SoftDeleteListingParams{ID: l.ID, OrgID: l.OrgID}); err != nil {
				return err
			}
			if err := q.WithdrawPendingVersions(ctx, l.ID); err != nil {
				return err
			}
			if err := q.DeleteListingSearch(ctx, l.ID); err != nil {
				return err
			}
			ms, err := q.ListAllListingMedia(ctx, &l.ID)
			if err != nil {
				return err
			}
			for _, m := range ms {
				key, err := q.DeleteMedia(ctx, db.DeleteMediaParams{ID: m.ID, OrgID: l.OrgID})
				if err != nil {
					return err
				}
				keys = append(keys, key)
			}
			return audit.Record(ctx, q, audit.Event{OrgID: &l.OrgID, Entity: "listing", EntityID: &l.ID, Action: "listing.archived",
				Diff: map[string]any{"status": []string{l.Status, "archived"}, "demo": true, "source": "terractl demo remove",
					"photos": len(keys)}})
		})
		if err != nil {
			return listings, photos, fmt.Errorf("listing %s: %w", l.ID, err)
		}
		listings++
		for _, k := range keys {
			if err := s.Blob.Delete(ctx, k); err != nil && !errors.Is(err, storage.ErrNotFound) {
				return listings, photos, err
			}
			photos++
		}
	}
	return listings, photos, nil
}
