package integration

import (
	"context"
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/listing"
	"github.com/terrareality/terrareality/services/api/internal/media"
	"github.com/terrareality/terrareality/services/api/internal/search"
	"github.com/terrareality/terrareality/services/api/internal/storage"
)

// markDemo turns a published listing into a demo listing (as terractl demo
// seed creates them) and re-indexes it.
func (e *env) markDemo(id uuid.UUID) {
	e.t.Helper()
	ctx := context.Background()
	if _, err := e.pool.Exec(ctx, "UPDATE listings SET is_demo = true WHERE id = $1", id); err != nil {
		e.t.Fatal(err)
	}
	if err := (search.Indexer{}).Index(ctx, db.New(e.svc), id); err != nil {
		e.t.Fatal(err)
	}
}

type demoSearch struct {
	Total int `json:"total"`
	Items []struct {
		ID     uuid.UUID `json:"id"`
		IsDemo bool      `json:"is_demo"`
	} `json:"items"`
	Points []struct {
		ID     uuid.UUID `json:"id"`
		IsDemo bool      `json:"is_demo"`
	} `json:"points"`
}

// Demo listings stay visible in search, on the map and in detail with the
// flag, are left out with exclude_demo and refuse every tenant action.
func TestDemoListingFlagAndRefusals(t *testing.T) {
	e := newEnv(t)
	ownerTok, orgID := e.ownerOrg("demo-owner")
	staff := e.staffToken()
	unique := "Ukazkovy-" + uuid.NewString()[:6]
	real := e.publishFlat(ownerTok, orgID, staff, "Byt "+unique+" skutecny", "approximate")
	demo := e.publishFlat(ownerTok, orgID, staff, "Byt "+unique+" demo", "approximate")

	// An application filed before the listing became a demo one (for the
	// viewing refusal below).
	early := e.register(uniqueEmail("demo-early"))
	var app appDetail
	e.must(201, "POST", "/v1/applications", early, map[string]any{"listing_id": demo, "message": "Mám zájem."}, &app)
	lpath := "/v1/orgs/" + orgID.String() + "/listings/" + demo.String()
	var slot struct {
		ID uuid.UUID `json:"id"`
	}
	e.must(201, "POST", lpath+"/viewing-slots", ownerTok, map[string]any{"starts_at": time.Now().Add(72 * time.Hour).Format(time.RFC3339),
		"capacity": 3}, &slot)
	e.markDemo(demo)

	// Search and map: both listings, the flag only on the demo one.
	var res demoSearch
	e.must(200, "POST", "/v1/search", "", map[string]any{"text": unique}, &res)
	if res.Total != 2 || len(res.Items) != 2 {
		t.Fatalf("search %+v", res)
	}
	for _, it := range res.Items {
		if it.IsDemo != (it.ID == demo) {
			t.Fatalf("card flag %+v", it)
		}
	}
	for _, p := range res.Points {
		if p.IsDemo != (p.ID == demo) {
			t.Fatalf("map point flag %+v", p)
		}
	}
	// exclude_demo (static site) leaves it out.
	e.must(200, "POST", "/v1/search", "", map[string]any{"text": unique, "exclude_demo": true}, &res)
	if res.Total != 1 || res.Items[0].ID != real || res.Items[0].IsDemo {
		t.Fatalf("exclude_demo %+v", res)
	}

	// Detail: public and owner views carry the flag.
	var pub struct {
		IsDemo bool `json:"is_demo"`
	}
	e.must(200, "GET", "/v1/listings/"+demo.String(), "", nil, &pub)
	if !pub.IsDemo {
		t.Fatal("public detail without is_demo")
	}
	e.must(200, "GET", "/v1/listings/"+real.String(), "", nil, &pub)
	if pub.IsDemo {
		t.Fatal("real listing flagged as demo")
	}
	e.must(200, "GET", lpath, ownerTok, nil, &pub)
	if !pub.IsDemo {
		t.Fatal("owner detail without is_demo")
	}
	var summaries []struct {
		ID     uuid.UUID `json:"id"`
		IsDemo bool      `json:"is_demo"`
	}
	e.must(200, "GET", "/v1/orgs/"+orgID.String()+"/listings", ownerTok, nil, &summaries)
	for _, s := range summaries {
		if s.IsDemo != (s.ID == demo) {
			t.Fatalf("summary flag %+v", s)
		}
	}

	// Tenant actions are refused with demo_listing.
	seeker := e.register(uniqueEmail("demo-seeker"))
	var p problem
	if code := e.call("POST", "/v1/conversations", seeker, map[string]any{"listing_id": demo, "body": "Dobrý den, mám zájem."}, &p); code != 409 || p.Code != "demo_listing" {
		t.Fatalf("contact demo: %d %+v", code, p)
	}
	p = problem{}
	if code := e.call("POST", "/v1/applications", seeker, map[string]any{"listing_id": demo, "message": "Mám zájem."}, &p); code != 409 || p.Code != "demo_listing" {
		t.Fatalf("apply demo: %d %+v", code, p)
	}
	p = problem{}
	if code := e.call("POST", "/v1/applications/"+app.Application.ID.String()+"/bookings", early, map[string]any{"slot_id": slot.ID}, &p); code != 409 || p.Code != "demo_listing" {
		t.Fatalf("book demo viewing: %d %+v", code, p)
	}
	// The real listing still accepts contact.
	e.must(201, "POST", "/v1/conversations", seeker, map[string]any{"listing_id": real, "body": "Dobrý den, mám zájem."}, nil)
}

// SEO municipality stats, the aggregate view, backoffice metrics and the
// portfolio market statistics count real supply only.
func TestDemoListingsExcludedFromStats(t *testing.T) {
	e := newEnv(t)
	ownerTok, orgID := e.ownerOrg("demo-stats")
	staff := e.staffToken()
	demo := e.publishFlat(ownerTok, orgID, staff, "Byt statistika "+uuid.NewString()[:6], "approximate")
	ctx := context.Background()
	var path string
	if err := e.pool.QueryRow(ctx, "SELECT admin_path::text FROM listing_search WHERE listing_id = $1", demo).Scan(&path); err != nil {
		t.Fatal(err)
	}
	e.markDemo(demo)

	var stats []struct {
		Path     string `json:"path"`
		Listings int    `json:"listings"`
	}
	e.must(200, "GET", "/v1/seo/municipalities?kind=apartment", "", nil, &stats)
	for _, m := range stats {
		var real, all int
		if err := e.pool.QueryRow(ctx, `SELECT count(*) FILTER (WHERE NOT is_demo), count(*) FROM listing_search
			WHERE admin_path <@ $1::ltree AND unit_kind = 'apartment'`, m.Path).Scan(&real, &all); err != nil {
			t.Fatal(err)
		}
		if m.Listings != real {
			t.Fatalf("seo %s counts %d, real supply %d (with demo %d)", m.Path, m.Listings, real, all)
		}
	}
	// A municipality whose only listing is a demo one gets no SEO page.
	var onlyDemo []string
	rows, err := e.pool.Query(ctx, `SELECT a.path::text FROM admin_units a JOIN listing_search s ON s.admin_path <@ a.path
		WHERE a.level = 2 AND s.unit_kind = 'apartment' GROUP BY a.path HAVING bool_and(s.is_demo)`)
	if err != nil {
		t.Fatal(err)
	}
	for rows.Next() {
		var p string
		if err := rows.Scan(&p); err != nil {
			t.Fatal(err)
		}
		onlyDemo = append(onlyDemo, p)
	}
	rows.Close()
	for _, m := range stats {
		for _, p := range onlyDemo {
			if m.Path == p {
				t.Fatalf("demo-only municipality %s on the SEO list", p)
			}
		}
	}

	// The aggregate view (refresh_aggregates) leaves demo listings out.
	if err := db.New(e.svc).RefreshListingAggregates(ctx); err != nil {
		t.Fatal(err)
	}
	var agg, real int
	if err := e.pool.QueryRow(ctx, "SELECT coalesce((SELECT listings FROM listing_aggregates WHERE path = $1::ltree), 0)", path).Scan(&agg); err != nil {
		t.Fatal(err)
	}
	if err := e.pool.QueryRow(ctx, "SELECT count(*) FROM listing_search WHERE admin_path <@ $1::ltree AND NOT is_demo", path).Scan(&real); err != nil {
		t.Fatal(err)
	}
	if agg != real {
		t.Fatalf("aggregate %d, real supply %d", agg, real)
	}

	// Backoffice metrics.
	m, err := db.New(e.svc).BackofficeMetrics(ctx, "CZK")
	if err != nil {
		t.Fatal(err)
	}
	var published int64
	if err := e.pool.QueryRow(ctx, "SELECT count(*) FROM listing_search WHERE NOT is_demo").Scan(&published); err != nil {
		t.Fatal(err)
	}
	if m.ListingsPublished != published {
		t.Fatalf("backoffice counts %d listings, real %d", m.ListingsPublished, published)
	}
}

// writeDemoPhotos builds a photos directory with manifest.json and two flats.
func writeDemoPhotos(t *testing.T) string {
	t.Helper()
	dir := t.TempDir()
	manifest := []map[string]string{{"flat": "flat-01", "type": "panel", "layout": "2+kk"},
		{"flat": "flat-02", "type": "brick", "layout": "3+1"}}
	raw, _ := json.Marshal(manifest)
	if err := os.WriteFile(filepath.Join(dir, "manifest.json"), raw, 0o600); err != nil {
		t.Fatal(err)
	}
	for _, f := range manifest {
		if err := os.MkdirAll(filepath.Join(dir, f["flat"]), 0o700); err != nil {
			t.Fatal(err)
		}
		for _, room := range []string{"living", "kitchen", "bedroom", "bathroom"} {
			if err := os.WriteFile(filepath.Join(dir, f["flat"], room+".jpg"), jpegBytes(t, 640, 480), 0o600); err != nil {
				t.Fatal(err)
			}
		}
	}
	return dir
}

// terractl demo seed/remove: idempotent, photos through the media
// pipeline, published and searchable, then archived with photos deleted.
func TestDemoSeedAndRemove(t *testing.T) {
	e := newEnv(t)
	ctx := context.Background()
	svc := &listing.Service{Pool: e.svc, Blob: e.blob, Scanner: media.NoScanner{}, Search: search.Indexer{}}
	dir := writeDemoPhotos(t)
	orgName := "TerraReality – ukázka " + uuid.NewString()[:6]

	first, err := svc.SeedDemo(ctx, listing.DemoSeed{OrgName: orgName, Dir: dir, Count: 15})
	if err != nil {
		t.Fatal(err)
	}
	if !first.OrgCreated || len(first.Created) != 2 || first.Skipped != 0 {
		t.Fatalf("first seed %+v", first)
	}
	again, err := svc.SeedDemo(ctx, listing.DemoSeed{OrgName: orgName, Dir: dir, Count: 15})
	if err != nil {
		t.Fatal(err)
	}
	if again.OrgCreated || again.OrgID != first.OrgID || len(again.Created) != 0 || again.Skipped != 2 {
		t.Fatalf("second seed is not idempotent %+v", again)
	}
	var members int
	if err := e.pool.QueryRow(ctx, "SELECT count(*) FROM memberships WHERE org_id = $1", first.OrgID).Scan(&members); err != nil {
		t.Fatal(err)
	}
	if members != 0 {
		t.Fatalf("demo org has %d members", members)
	}

	rows, err := svc.DemoListings(ctx)
	if err != nil {
		t.Fatal(err)
	}
	addresses := map[string]bool{}
	mine := 0
	for _, l := range rows {
		if l.OrgID != first.OrgID {
			continue
		}
		mine++
		if l.Status != "published" || !l.InSearch || l.Photos != 4 {
			t.Fatalf("demo listing %+v", l)
		}
		addresses[l.AddressLabel] = true
	}
	if mine != 2 || len(addresses) != 2 {
		t.Fatalf("demo listings %d, distinct addresses %d", mine, len(addresses))
	}

	var keys []string
	for _, id := range first.Created {
		var pub struct {
			IsDemo      bool              `json:"is_demo"`
			Title       map[string]string `json:"title"`
			Description map[string]string `json:"description"`
			RentAmount  int64             `json:"rent_amount"`
			Deposit     int64             `json:"deposit_amount"`
			Photos      []json.RawMessage `json:"photos"`
		}
		e.must(200, "GET", "/v1/listings/"+id.String(), "", nil, &pub)
		if !pub.IsDemo || !strings.HasPrefix(pub.Title["cs"], "Ukázka: ") || len(pub.Photos) != 4 ||
			!strings.HasPrefix(pub.Description["cs"], listing.DemoDisclaimerCS) ||
			!strings.HasPrefix(pub.Description["en"], listing.DemoDisclaimerEN) ||
			pub.RentAmount <= 0 || pub.Deposit != 2*pub.RentAmount {
			t.Fatalf("demo detail %+v", pub)
		}
		r, err := e.pool.Query(ctx, "SELECT object_key FROM media WHERE listing_id = $1 AND status = 'ready'", id)
		if err != nil {
			t.Fatal(err)
		}
		for r.Next() {
			var k string
			if err := r.Scan(&k); err != nil {
				t.Fatal(err)
			}
			keys = append(keys, k)
		}
		r.Close()
	}
	if len(keys) != 8 {
		t.Fatalf("ready photos %d", len(keys))
	}

	n, photos, err := svc.RemoveDemoListings(ctx)
	if err != nil {
		t.Fatal(err)
	}
	if n < 2 || photos < 8 {
		t.Fatalf("removed %d listings, %d photos", n, photos)
	}
	for _, k := range keys {
		if _, err := e.blob.Get(ctx, k); !errors.Is(err, storage.ErrNotFound) {
			t.Fatalf("photo %s still stored: %v", k, err)
		}
	}
	for _, id := range first.Created {
		if code := e.call("GET", "/v1/listings/"+id.String(), "", nil, nil); code != 404 {
			t.Fatalf("removed demo listing still public: %d", code)
		}
	}
	if rows, err := svc.DemoListings(ctx); err != nil || len(rows) != 0 {
		t.Fatalf("demo listings after remove %d %v", len(rows), err)
	}
	n, photos, err = svc.RemoveDemoListings(ctx)
	if err != nil || n != 0 || photos != 0 {
		t.Fatalf("second remove %d %d %v", n, photos, err)
	}

	// Seeding again after a removal creates fresh listings in the same org.
	third, err := svc.SeedDemo(ctx, listing.DemoSeed{OrgName: orgName, Dir: dir, Count: 1})
	if err != nil {
		t.Fatal(err)
	}
	if third.OrgID != first.OrgID || len(third.Created) != 1 {
		t.Fatalf("reseed %+v", third)
	}
	if _, _, err := svc.RemoveDemoListings(ctx); err != nil {
		t.Fatal(err)
	}
}
