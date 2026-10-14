package listing

import (
	"context"
	"encoding/json"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"github.com/terrareality/terrareality/services/api/internal/audit"
	"github.com/terrareality/terrareality/services/api/internal/auth"
	"github.com/terrareality/terrareality/services/api/internal/catalog"
	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/notify"
	"github.com/terrareality/terrareality/services/api/internal/org"
	"github.com/terrareality/terrareality/services/api/internal/platform/apperr"
)

// Snapshot is the immutable content of a submitted version.
type Snapshot struct {
	Title             I18n            `json:"title"`
	Description       I18n            `json:"description"`
	RentAmount        *int64          `json:"rent_amount"`
	DepositAmount     *int64          `json:"deposit_amount"`
	UtilitiesAmount   *int64          `json:"utilities_amount"`
	Currency          string          `json:"currency"`
	AvailableFrom     *string         `json:"available_from"`
	MinTermMonths     *int32          `json:"min_term_months"`
	Attributes        map[string]any  `json:"attributes"`
	LocationPrecision string          `json:"location_precision"`
	Unit              SnapshotUnit    `json:"unit"`
	Address           SnapshotAddress `json:"address"`
	Photos            []SnapshotPhoto `json:"photos"`
}

// SnapshotUnit describes the offered unit.
type SnapshotUnit struct {
	Kind        string   `json:"kind"`
	Label       string   `json:"label"`
	Floor       *int32   `json:"floor"`
	FloorArea   *float64 `json:"floor_area"`
	Layout      *string  `json:"layout"`
	ParentLabel *string  `json:"parent_label,omitempty"`
}

// SnapshotAddress is the exact address; public views apply the precision.
type SnapshotAddress struct {
	Label    string  `json:"label"`
	City     string  `json:"city"`
	CityPart *string `json:"city_part"`
	Lat      float64 `json:"lat"`
	Lng      float64 `json:"lng"`
}

// SnapshotPhoto references a processed photo.
type SnapshotPhoto struct {
	MediaID     uuid.UUID `json:"media_id"`
	Key         string    `json:"key"`
	Orientation int32     `json:"orientation"`
	Caption     I18n      `json:"caption"`
}

func buildSnapshot(l db.Listing, c db.GetListingContextRow, photos []db.Medium) Snapshot {
	s := Snapshot{Title: i18n(l.Title), Description: i18n(l.Description), RentAmount: l.RentAmount,
		DepositAmount: l.DepositAmount, UtilitiesAmount: l.UtilitiesAmount, Currency: l.Currency,
		MinTermMonths: l.MinTermMonths, LocationPrecision: l.LocationPrecision,
		Unit: SnapshotUnit{Kind: c.UnitKind, Label: c.UnitLabel, Floor: c.Floor, FloorArea: c.FloorArea, Layout: c.Layout,
			ParentLabel: c.ParentLabel},
		Address: SnapshotAddress{Label: c.AddressLabel, City: c.City, CityPart: c.CityPart, Lat: c.Lat, Lng: c.Lng}}
	_ = json.Unmarshal(l.Attributes, &s.Attributes)
	if l.AvailableFrom.Valid {
		d := l.AvailableFrom.Time.Format("2006-01-02")
		s.AvailableFrom = &d
	}
	for _, m := range photos {
		if m.Status == "ready" {
			s.Photos = append(s.Photos, SnapshotPhoto{MediaID: m.ID, Key: m.ObjectKey, Orientation: m.Orientation, Caption: i18n(m.Caption)})
		}
	}
	return s
}

// Submit sends the working copy to moderation as a new version.
func (s *Service) Submit(ctx context.Context, p *auth.Principal, orgID, id uuid.UUID) (int32, error) {
	var version int32
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		if _, err := org.Access(ctx, q, p.UserID, orgID, org.PermCatalogWrite); err != nil {
			return err
		}
		var v View
		if err := loadView(ctx, q, orgID, id, &v); err != nil {
			return err
		}
		l := v.Listing
		if l.Status == "archived" || l.Status == "rented" {
			return apperr.Conflict("listing_locked", "archived or rented listings cannot be submitted")
		}
		var missing []catalog.FieldError
		t, d := i18n(l.Title), i18n(l.Description)
		if t.CS == "" {
			missing = append(missing, catalog.FieldError{Key: "title", Reason: "required"})
		}
		if len([]rune(d.CS)) < 50 {
			missing = append(missing, catalog.FieldError{Key: "description", Reason: "at least 50 characters"})
		}
		if l.RentAmount == nil {
			missing = append(missing, catalog.FieldError{Key: "rent", Reason: "required"})
		}
		ready := 0
		for _, m := range v.Media {
			if m.Status == "ready" {
				ready++
			}
		}
		if ready == 0 {
			missing = append(missing, catalog.FieldError{Key: "photos", Reason: "at least one photo"})
		}
		if len(missing) > 0 {
			return &FieldErrors{Errors: missing}
		}
		snap := buildSnapshot(l, v.Context, v.Media)
		// Earlier pending versions are superseded.
		if err := q.WithdrawMyPendingVersions(ctx, id); err != nil {
			return err
		}
		next, err := q.NextListingVersion(ctx, id)
		if err != nil {
			return err
		}
		if _, err := q.CreateListingVersion(ctx, db.CreateListingVersionParams{ListingID: id, OrgID: orgID, Version: next,
			Snapshot: jsonb(snap), SubmittedBy: &p.UserID}); err != nil {
			return err
		}
		version = next
		if l.Status == "draft" {
			if err := q.SetListingStatus(ctx, db.SetListingStatusParams{ID: id, OrgID: orgID, Status: "review"}); err != nil {
				return err
			}
		}
		return audit.Record(ctx, q, audit.Event{OrgID: &orgID, Entity: "listing", EntityID: &id, Action: "listing.submitted",
			Diff: map[string]any{"version": next}})
	})
	return version, err
}

// Transition changes the visibility state chosen by the owner.
func (s *Service) Transition(ctx context.Context, p *auth.Principal, orgID, id uuid.UUID, to string) error {
	allowed := map[string][]string{
		"paused":    {"published"},
		"published": {"paused"}, // resume; first publication only through review
		"rented":    {"published", "paused"},
		"archived":  {"draft", "review", "published", "paused", "rented"},
	}
	from, ok := allowed[to]
	if !ok {
		return apperr.Unprocessable("invalid_transition", "unknown target state")
	}
	return s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		if _, err := org.Access(ctx, q, p.UserID, orgID, org.PermCatalogWrite); err != nil {
			return err
		}
		l, err := q.GetListing(ctx, db.GetListingParams{ID: id, OrgID: orgID})
		if errors.Is(err, pgx.ErrNoRows) {
			return errListingNotFound
		}
		if err != nil {
			return err
		}
		okFrom := false
		for _, f := range from {
			okFrom = okFrom || f == l.Status
		}
		if !okFrom || (to == "published" && l.PublishedVersion == nil) {
			return apperr.Conflict("invalid_transition", "cannot move from "+l.Status+" to "+to)
		}
		if err := q.SetListingStatus(ctx, db.SetListingStatusParams{ID: id, OrgID: orgID, Status: to}); err != nil {
			return err
		}
		if to == "archived" {
			if err := q.WithdrawMyPendingVersions(ctx, id); err != nil {
				return err
			}
		}
		if err := s.index(ctx, q, id); err != nil {
			return err
		}
		return audit.Record(ctx, q, audit.Event{OrgID: &orgID, Entity: "listing", EntityID: &id, Action: "listing." + to,
			Diff: map[string]any{"status": []string{l.Status, to}}})
	})
}

// Duplicate copies a listing onto a new sibling unit (similar flats in one
// building). Photos are not copied.
func (s *Service) Duplicate(ctx context.Context, p *auth.Principal, orgID, id uuid.UUID) (uuid.UUID, error) {
	var newID uuid.UUID
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		if _, err := org.Access(ctx, q, p.UserID, orgID, org.PermCatalogWrite); err != nil {
			return err
		}
		l, err := q.GetListing(ctx, db.GetListingParams{ID: id, OrgID: orgID})
		if errors.Is(err, pgx.ErrNoRows) {
			return errListingNotFound
		}
		if err != nil {
			return err
		}
		u, err := q.GetUnit(ctx, db.GetUnitParams{ID: l.UnitID, OrgID: orgID})
		if err != nil {
			return err
		}
		nu, err := q.CreateUnit(ctx, db.CreateUnitParams{OrgID: orgID, PropertyID: u.PropertyID, ParentID: u.ParentID, Kind: u.Kind,
			Label: truncate(u.Label+" (kopie)", 120), Floor: u.Floor, FloorArea: u.FloorArea, Layout: u.Layout})
		if err != nil {
			return err
		}
		nl, err := q.CreateListing(ctx, db.CreateListingParams{OrgID: orgID, UnitID: nu.ID, Title: l.Title, Description: l.Description,
			RentAmount: l.RentAmount, Currency: l.Currency, DepositAmount: l.DepositAmount, UtilitiesAmount: l.UtilitiesAmount,
			AvailableFrom: l.AvailableFrom, MinTermMonths: l.MinTermMonths, Attributes: l.Attributes,
			LocationPrecision: l.LocationPrecision, CreatedBy: &p.UserID})
		if err != nil {
			return err
		}
		newID = nl.ID
		return audit.Record(ctx, q, audit.Event{OrgID: &orgID, Entity: "listing", EntityID: &nl.ID, Action: "listing.duplicated",
			Diff: map[string]any{"from": id}})
	})
	return newID, err
}

func truncate(s string, n int) string {
	r := []rune(s)
	if len(r) > n {
		return string(r[:n])
	}
	return s
}

// ReviewItem is one entry of the moderation queue.
type ReviewItem = db.ListPendingVersionsRow

// ReviewQueue lists pending versions (staff).
func (s *Service) ReviewQueue(ctx context.Context) ([]ReviewItem, error) {
	return db.New(s.Pool).ListPendingVersions(ctx)
}

// Version returns one version with its snapshot (staff).
func (s *Service) Version(ctx context.Context, id uuid.UUID) (db.ListingVersion, error) {
	v, err := db.New(s.Pool).GetListingVersion(ctx, id)
	if errors.Is(err, pgx.ErrNoRows) {
		return v, apperr.NotFound("version_not_found", "version not found")
	}
	return v, err
}

// Review approves or rejects a pending version (staff, human decision).
func (s *Service) Review(ctx context.Context, staff *auth.Principal, versionID uuid.UUID, approve bool, note string) error {
	return s.system(ctx, func(q *db.Queries, tx pgx.Tx) error {
		v, err := q.GetListingVersion(ctx, versionID)
		if errors.Is(err, pgx.ErrNoRows) {
			return apperr.NotFound("version_not_found", "version not found")
		}
		if err != nil {
			return err
		}
		status := "rejected"
		if approve {
			status = "approved"
		}
		var notePtr *string
		if note != "" {
			notePtr = &note
		}
		n, err := q.ReviewListingVersion(ctx, db.ReviewListingVersionParams{ID: versionID, Status: status,
			ReviewedBy: &staff.UserID, ReviewNote: notePtr})
		if err != nil {
			return err
		}
		if n == 0 {
			return apperr.Conflict("version_not_pending", "this version was already reviewed or withdrawn")
		}
		l, err := q.GetListing(ctx, db.GetListingParams{ID: v.ListingID, OrgID: v.OrgID})
		if err != nil {
			return err
		}
		if approve {
			if err := q.PublishListingVersion(ctx, db.PublishListingVersionParams{ID: v.ListingID, PublishedVersion: &v.Version}); err != nil {
				return err
			}
			if err := s.index(ctx, q, v.ListingID); err != nil {
				return err
			}
		} else if l.Status == "review" {
			if err := q.SystemSetListingStatus(ctx, db.SystemSetListingStatusParams{ID: v.ListingID, Status: "draft"}); err != nil {
				return err
			}
		}
		if err := audit.Record(ctx, q, audit.Event{OrgID: &v.OrgID, Entity: "listing", EntityID: &v.ListingID,
			Action: "listing.review_" + status, Diff: map[string]any{"version": v.Version, "note": note}}); err != nil {
			return err
		}
		return s.notifyReview(ctx, q, tx, v, approve, note)
	})
}

func (s *Service) notifyReview(ctx context.Context, q *db.Queries, tx pgx.Tx, v db.ListingVersion, approve bool, note string) error {
	if v.SubmittedBy == nil || s.Outbox == nil {
		return nil
	}
	u, err := q.GetUser(ctx, *v.SubmittedBy)
	if err != nil || u.PseudonymizedAt != nil {
		return nil
	}
	var snap Snapshot
	_ = json.Unmarshal(v.Snapshot, &snap)
	key := "listing_rejected"
	if approve {
		key = "listing_approved"
	}
	link := s.WebBaseURL + "/admin/orgs/" + v.OrgID.String() + "/listings/" + v.ListingID.String()
	m, err := s.Render.Render(notify.Email, u.Email, u.Locale, key, map[string]any{
		"Title": snap.Title.CS, "Note": note, "Link": link, "Version": v.Version})
	if err != nil {
		return err
	}
	return s.Outbox.Enqueue(ctx, tx, m)
}

// Versions lists the version history of a listing.
func (s *Service) Versions(ctx context.Context, p *auth.Principal, orgID, id uuid.UUID) ([]db.ListListingVersionsRow, error) {
	var out []db.ListListingVersionsRow
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		if _, err := org.Access(ctx, q, p.UserID, orgID, org.PermCatalogRead); err != nil {
			return err
		}
		var err error
		out, err = q.ListListingVersions(ctx, id)
		return err
	})
	return out, err
}

var _ = time.Now
