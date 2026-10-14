// Package listing implements the catalog: properties, units, listings with
// versioned publication, photos and AI suggestions. Owner-facing operations
// run with row-level security (db.AsUser); review and background jobs run in
// system context.
package listing

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/terrareality/terrareality/services/api/internal/ai"
	"github.com/terrareality/terrareality/services/api/internal/audit"
	"github.com/terrareality/terrareality/services/api/internal/auth"
	"github.com/terrareality/terrareality/services/api/internal/catalog"
	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/media"
	"github.com/terrareality/terrareality/services/api/internal/notify"
	"github.com/terrareality/terrareality/services/api/internal/org"
	"github.com/terrareality/terrareality/services/api/internal/platform/apperr"
	platformdb "github.com/terrareality/terrareality/services/api/internal/platform/db"
	"github.com/terrareality/terrareality/services/api/internal/storage"
	"github.com/terrareality/terrareality/services/api/internal/vision"
)

// Jobs enqueues background work in the caller's transaction.
type Jobs interface {
	ProcessMedia(ctx context.Context, tx pgx.Tx, mediaID uuid.UUID) error
	RunSuggestion(ctx context.Context, tx pgx.Tx, suggestionID uuid.UUID) error
}

// Flags switch AI features (plan section 5: everything AI behind a flag).
type Flags struct {
	AIAttributes bool
	AIText       bool
	Vision       bool
}

// Service implements the catalog.
type Service struct {
	Pool       *pgxpool.Pool
	Blob       storage.Blob
	Img        *media.Imgproxy
	Scanner    media.Scanner
	Vision     *vision.Client
	AI         ai.Assistant
	Jobs       Jobs
	Outbox     notify.Outbox
	Render     *notify.Renderer
	Flags      Flags
	WebBaseURL string
}

var errListingNotFound = apperr.NotFound("listing_not_found", "listing not found")

func (s *Service) asUser(ctx context.Context, p *auth.Principal, fn func(q *db.Queries, tx pgx.Tx) error) error {
	return platformdb.AsUser(ctx, s.Pool, p.UserID, func(tx pgx.Tx) error { return fn(db.New(tx), tx) })
}

func (s *Service) system(ctx context.Context, fn func(q *db.Queries, tx pgx.Tx) error) error {
	return pgx.BeginFunc(ctx, s.Pool, func(tx pgx.Tx) error { return fn(db.New(tx), tx) })
}

// Schema returns the live attribute schema.
func (s *Service) Schema(ctx context.Context) (*catalog.Schema, error) {
	return catalog.Load(ctx, db.New(s.Pool))
}

// Address is a RÚIAN address point for autocomplete.
type Address = db.SearchRuianRow

// SearchAddresses autocompletes Czech addresses.
func (s *Service) SearchAddresses(ctx context.Context, q string, limit int32) ([]Address, error) {
	q = strings.TrimSpace(q)
	if len([]rune(q)) < 3 {
		return []Address{}, nil
	}
	return db.New(s.Pool).SearchRuian(ctx, db.SearchRuianParams{Q: q, Lim: limit})
}

// I18n is a Czech/English text pair stored as JSON.
type I18n = ai.Texts

func i18n(b []byte) I18n {
	var t I18n
	_ = json.Unmarshal(b, &t)
	return t
}

func jsonb(v any) []byte {
	b, _ := json.Marshal(v)
	return b
}

// CreateInput creates a property (or reuses the one at the same address), a
// unit and a draft listing in one step of the wizard.
type CreateInput struct {
	RuianID      int64
	UnitKind     string
	UnitLabel    string
	Floor        *int32
	FloorArea    *float64
	Layout       *string
	ParentUnitID *uuid.UUID // rooms: existing apartment
	ParentLayout *string    // rooms: create the apartment when no parent is given
	ParentArea   *float64
}

var unitKinds = map[string]bool{"apartment": true, "house": true, "room": true, "parking": true, "storage": true, "commercial": true}

// Create runs the first wizard step.
func (s *Service) Create(ctx context.Context, p *auth.Principal, orgID uuid.UUID, in CreateInput) (uuid.UUID, error) {
	if !unitKinds[in.UnitKind] {
		return uuid.Nil, apperr.Unprocessable("invalid_unit_kind", "unknown unit kind")
	}
	place, err := db.New(s.Pool).GetRuianPlace(ctx, in.RuianID)
	if errors.Is(err, pgx.ErrNoRows) {
		return uuid.Nil, apperr.Unprocessable("unknown_address", "pick an address from the list")
	}
	if err != nil {
		return uuid.Nil, err
	}
	var id uuid.UUID
	err = s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		m, err := org.Access(ctx, q, p.UserID, orgID, org.PermCatalogWrite)
		if err != nil {
			return err
		}
		prop, err := q.FindPropertyByRuian(ctx, db.FindPropertyByRuianParams{OrgID: orgID, RuianID: &place.ID})
		if errors.Is(err, pgx.ErrNoRows) {
			addrID, err := q.CreateAddress(ctx, db.CreateAddressParams{OrgID: orgID, RuianID: &place.ID, Street: place.Street,
				HouseNumber: houseNumber(place), OrientationNumber: orientation(place), City: place.Municipality,
				CityPart: firstNonNil(place.District, place.CityPart), PostalCode: place.PostalCode,
				Lat: place.Lat, Lng: place.Lng, Label: place.Label})
			if err != nil {
				return err
			}
			kind := "apartment_building"
			if in.UnitKind == "house" {
				kind = "family_house"
			}
			prop, err = q.CreateProperty(ctx, db.CreatePropertyParams{OrgID: orgID, AddressID: addrID, Kind: kind, Name: place.Label})
			if err != nil {
				return err
			}
			if err := audit.Record(ctx, q, audit.Event{OrgID: &orgID, Entity: "property", EntityID: &prop.ID, Action: "property.created",
				Diff: map[string]any{"address": place.Label}}); err != nil {
				return err
			}
		} else if err != nil {
			return err
		}
		var parent *uuid.UUID
		if in.UnitKind == "room" {
			switch {
			case in.ParentUnitID != nil:
				pu, err := q.GetUnit(ctx, db.GetUnitParams{ID: *in.ParentUnitID, OrgID: orgID})
				if err != nil || pu.PropertyID != prop.ID || pu.Kind != "apartment" && pu.Kind != "house" {
					return apperr.Unprocessable("invalid_parent_unit", "rooms belong to an apartment or house at the same address")
				}
				parent = &pu.ID
			default:
				pu, err := q.CreateUnit(ctx, db.CreateUnitParams{OrgID: orgID, PropertyID: prop.ID, Kind: "apartment",
					Label: labelOr(in.ParentLayout, "Byt"), Floor: in.Floor, FloorArea: in.ParentArea, Layout: in.ParentLayout})
				if err != nil {
					return err
				}
				parent = &pu.ID
			}
		}
		label := strings.TrimSpace(in.UnitLabel)
		if label == "" {
			label = labelOr(in.Layout, in.UnitKind)
		}
		u, err := q.CreateUnit(ctx, db.CreateUnitParams{OrgID: orgID, PropertyID: prop.ID, ParentID: parent, Kind: in.UnitKind,
			Label: label, Floor: in.Floor, FloorArea: in.FloorArea, Layout: in.Layout})
		if err != nil {
			return err
		}
		attrs := map[string]any{}
		if in.Layout != nil && in.UnitKind != "room" {
			attrs["layout"] = *in.Layout
		}
		if in.FloorArea != nil {
			attrs["floor_area"] = *in.FloorArea
		}
		if in.Floor != nil {
			attrs["floor"] = float64(*in.Floor)
		}
		jur, err := q.GetJurisdiction(ctx, m.Org.JurisdictionCode)
		if err != nil {
			return err
		}
		l, err := q.CreateListing(ctx, db.CreateListingParams{OrgID: orgID, UnitID: u.ID, Title: []byte("{}"), Description: []byte("{}"),
			Currency: jur.Currency, Attributes: jsonb(attrs), LocationPrecision: "approximate", CreatedBy: &p.UserID})
		if err != nil {
			return err
		}
		id = l.ID
		return audit.Record(ctx, q, audit.Event{OrgID: &orgID, Entity: "listing", EntityID: &l.ID, Action: "listing.created",
			Diff: map[string]any{"unit_kind": in.UnitKind, "address": place.Label}})
	})
	return id, err
}

func houseNumber(p db.GetRuianPlaceRow) string {
	if p.HouseNumberType == "ce" {
		return fmt.Sprintf("ev. %d", p.HouseNumber)
	}
	return fmt.Sprint(p.HouseNumber)
}

func orientation(p db.GetRuianPlaceRow) *string {
	if p.OrientationNumber == nil {
		return nil
	}
	v := fmt.Sprint(*p.OrientationNumber)
	if p.OrientationLetter != nil {
		v += *p.OrientationLetter
	}
	return &v
}

func firstNonNil(a, b *string) *string {
	if a != nil {
		return a
	}
	return b
}

func labelOr(s *string, def string) string {
	if s != nil && strings.TrimSpace(*s) != "" {
		return strings.TrimSpace(*s)
	}
	return def
}

// View is a listing with everything the editor shows.
type View struct {
	Listing     db.Listing
	Context     db.GetListingContextRow
	Media       []db.Medium
	Suggestions []db.AiSuggestion
	Versions    []db.ListListingVersionsRow
	Role        string
}

// Get loads a listing for the editor.
func (s *Service) Get(ctx context.Context, p *auth.Principal, orgID, id uuid.UUID) (View, error) {
	var v View
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		m, err := org.Access(ctx, q, p.UserID, orgID, org.PermCatalogRead)
		if err != nil {
			return err
		}
		v.Role = m.Role
		return loadView(ctx, q, orgID, id, &v)
	})
	return v, err
}

func loadView(ctx context.Context, q *db.Queries, orgID, id uuid.UUID, v *View) error {
	l, err := q.GetListing(ctx, db.GetListingParams{ID: id, OrgID: orgID})
	if errors.Is(err, pgx.ErrNoRows) {
		return errListingNotFound
	}
	if err != nil {
		return err
	}
	v.Listing = l
	if v.Context, err = q.GetListingContext(ctx, id); err != nil {
		return err
	}
	if v.Media, err = q.ListListingMedia(ctx, &id); err != nil {
		return err
	}
	if v.Suggestions, err = q.ListSuggestions(ctx, id); err != nil {
		return err
	}
	v.Versions, err = q.ListListingVersions(ctx, id)
	return err
}

// List returns an organization's listings.
func (s *Service) List(ctx context.Context, p *auth.Principal, orgID uuid.UUID, status *string) ([]db.ListListingsRow, error) {
	var out []db.ListListingsRow
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		if _, err := org.Access(ctx, q, p.UserID, orgID, org.PermCatalogRead); err != nil {
			return err
		}
		var err error
		out, err = q.ListListings(ctx, db.ListListingsParams{OrgID: orgID, Status: status})
		return err
	})
	return out, err
}

// UpdateInput is a full replacement of the editable fields.
type UpdateInput struct {
	Title, Description I18n
	Rent, Deposit      *int64
	Utilities          *int64
	AvailableFrom      *time.Time
	MinTermMonths      *int32
	Attributes         map[string]any
	LocationPrecision  string
	UnitLabel          *string
	Floor              *int32
	FloorArea          *float64
	Layout             *string
}

// FieldErrors is returned when attributes or prices do not validate.
type FieldErrors struct {
	Errors []catalog.FieldError
}

func (e *FieldErrors) Error() string { return fmt.Sprintf("%d invalid fields", len(e.Errors)) }

// Update saves the working copy. Editing withdraws a pending review.
func (s *Service) Update(ctx context.Context, p *auth.Principal, orgID, id uuid.UUID, in UpdateInput) error {
	schema, err := s.Schema(ctx)
	if err != nil {
		return err
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
		if l.Status == "archived" || l.Status == "rented" {
			return apperr.Conflict("listing_locked", "archived or rented listings cannot be edited")
		}
		c, err := q.GetListingContext(ctx, id)
		if err != nil {
			return err
		}
		attrs, ferrs := schema.Validate(in.Attributes, c.UnitKind)
		ferrs = append(ferrs, s.checkMoney(ctx, q, c.JurisdictionCode, in)...)
		ferrs = append(ferrs, checkTexts(in.Title, in.Description)...)
		if len(ferrs) > 0 {
			return &FieldErrors{Errors: ferrs}
		}
		precision := in.LocationPrecision
		if precision != "exact" {
			precision = "approximate"
		}
		var af = pgDate(in.AvailableFrom)
		if _, err := q.UpdateListing(ctx, db.UpdateListingParams{ID: id, OrgID: orgID, Title: jsonb(in.Title),
			Description: jsonb(in.Description), RentAmount: in.Rent, DepositAmount: in.Deposit, UtilitiesAmount: in.Utilities,
			AvailableFrom: af, MinTermMonths: in.MinTermMonths, Attributes: jsonb(attrs), LocationPrecision: precision}); err != nil {
			return err
		}
		if in.UnitLabel != nil || in.Floor != nil || in.FloorArea != nil || in.Layout != nil {
			if _, err := q.UpdateUnit(ctx, db.UpdateUnitParams{ID: c.UnitID, OrgID: orgID, Label: labelOr(in.UnitLabel, c.UnitLabel),
				Floor: in.Floor, FloorArea: in.FloorArea, Layout: in.Layout}); err != nil {
				return err
			}
		}
		if l.Status == "review" {
			if err := q.SetListingStatus(ctx, db.SetListingStatusParams{ID: id, OrgID: orgID, Status: "draft"}); err != nil {
				return err
			}
		}
		return audit.Record(ctx, q, audit.Event{OrgID: &orgID, Entity: "listing", EntityID: &id, Action: "listing.updated",
			Diff: diffListing(l, in, attrs)})
	})
}

func diffListing(l db.Listing, in UpdateInput, attrs map[string]any) map[string]any {
	d := map[string]any{}
	if !jsonEqual(l.Attributes, attrs) {
		d["attributes"] = true
	}
	if !jsonEqual(l.Title, in.Title) || !jsonEqual(l.Description, in.Description) {
		d["texts"] = true
	}
	if !int64PtrEqual(l.RentAmount, in.Rent) {
		d["rent"] = []any{l.RentAmount, in.Rent}
	}
	if !int64PtrEqual(l.DepositAmount, in.Deposit) {
		d["deposit"] = []any{l.DepositAmount, in.Deposit}
	}
	return d
}

func jsonEqual(raw []byte, v any) bool {
	var a any
	_ = json.Unmarshal(raw, &a)
	b, _ := json.Marshal(v)
	var bb any
	_ = json.Unmarshal(b, &bb)
	x, _ := json.Marshal(a)
	y, _ := json.Marshal(bb)
	return string(x) == string(y)
}

func int64PtrEqual(a, b *int64) bool {
	return (a == nil && b == nil) || (a != nil && b != nil && *a == *b)
}

// checkMoney validates prices against the jurisdiction (deposit cap).
func (s *Service) checkMoney(ctx context.Context, q *db.Queries, jurisdiction string, in UpdateInput) []catalog.FieldError {
	var errs []catalog.FieldError
	if in.Rent != nil && *in.Rent <= 0 {
		errs = append(errs, catalog.FieldError{Key: "rent", Reason: "must be positive"})
	}
	if in.Deposit != nil && in.Rent != nil {
		j, err := q.GetJurisdiction(ctx, jurisdiction)
		if err == nil && *in.Deposit > int64(j.DepositMaxMonths)*(*in.Rent) {
			errs = append(errs, catalog.FieldError{Key: "deposit",
				Reason: fmt.Sprintf("deposit_over_limit:%d", j.DepositMaxMonths)})
		}
	}
	return errs
}

func checkTexts(title, desc I18n) []catalog.FieldError {
	var errs []catalog.FieldError
	if len([]rune(title.CS)) > 120 || len([]rune(title.EN)) > 120 {
		errs = append(errs, catalog.FieldError{Key: "title", Reason: "too long"})
	}
	if len([]rune(desc.CS)) > 10000 || len([]rune(desc.EN)) > 10000 {
		errs = append(errs, catalog.FieldError{Key: "description", Reason: "too long"})
	}
	return errs
}
