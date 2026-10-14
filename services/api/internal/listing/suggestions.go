package listing

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"sort"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"github.com/terrareality/terrareality/services/api/internal/ai"
	"github.com/terrareality/terrareality/services/api/internal/audit"
	"github.com/terrareality/terrareality/services/api/internal/auth"
	"github.com/terrareality/terrareality/services/api/internal/catalog"
	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/org"
	"github.com/terrareality/terrareality/services/api/internal/platform/apperr"
	"github.com/terrareality/terrareality/services/api/internal/vision"
)

// AttributePayload is the stored result of an attribute suggestion.
type AttributePayload struct {
	Values     map[string]any       `json:"values"`      // valid suggested values
	Current    map[string]any       `json:"current"`     // listing values when generated
	NewOptions []ai.NewOption       `json:"new_options"` // values waiting for schema approval
	Invalid    []catalog.FieldError `json:"invalid,omitempty"`
}

// RequestSuggestion starts an AI suggestion (attributes or text) for a listing.
func (s *Service) RequestSuggestion(ctx context.Context, p *auth.Principal, orgID, listingID uuid.UUID, kind string) (db.AiSuggestion, error) {
	switch {
	case kind == "attributes" && !s.Flags.AIAttributes, kind == "text" && !s.Flags.AIText:
		return db.AiSuggestion{}, apperr.Forbidden("feature_disabled", "this AI feature is turned off")
	case kind != "attributes" && kind != "text":
		return db.AiSuggestion{}, apperr.Unprocessable("invalid_kind", "unknown suggestion kind")
	}
	var sg db.AiSuggestion
	err := s.asUser(ctx, p, func(q *db.Queries, tx pgx.Tx) error {
		if _, err := org.Access(ctx, q, p.UserID, orgID, org.PermCatalogWrite); err != nil {
			return err
		}
		if _, err := q.GetListing(ctx, db.GetListingParams{ID: listingID, OrgID: orgID}); err != nil {
			return errListingNotFound
		}
		var err error
		sg, err = q.CreateSuggestion(ctx, db.CreateSuggestionParams{OrgID: orgID, ListingID: listingID, Kind: kind, CreatedBy: &p.UserID})
		if err != nil {
			return err
		}
		return s.Jobs.RunSuggestion(ctx, tx, sg.ID)
	})
	return sg, err
}

// RunSuggestion generates the suggestion content (worker job).
func (s *Service) RunSuggestion(ctx context.Context, id uuid.UUID) error {
	q := db.New(s.Pool)
	sg, err := q.SystemGetSuggestion(ctx, id)
	if err != nil {
		return err
	}
	if sg.Status != "generating" {
		return nil
	}
	l, err := q.GetListing(ctx, db.GetListingParams{ID: sg.ListingID, OrgID: sg.OrgID})
	if err != nil {
		return err
	}
	c, err := q.GetListingContext(ctx, l.ID)
	if err != nil {
		return err
	}
	schema, err := catalog.Load(ctx, q)
	if err != nil {
		return err
	}
	var payload any
	var model string
	switch sg.Kind {
	case "attributes":
		p, m, err := s.extract(ctx, q, l, c, schema)
		if err != nil {
			return s.fail(ctx, q, sg.ID, err)
		}
		payload, model = p, m
	case "text":
		d, err := s.AI.DraftText(ctx, draftRequest(l, c, schema))
		if err != nil {
			return s.fail(ctx, q, sg.ID, err)
		}
		payload, model = map[string]any{"title": d.Title, "description": d.Description}, d.Model
	default:
		return nil
	}
	return q.CompleteSuggestion(ctx, db.CompleteSuggestionParams{ID: sg.ID, Payload: jsonb(payload), Model: &model})
}

func (s *Service) fail(ctx context.Context, q *db.Queries, id uuid.UUID, cause error) error {
	msg := cause.Error()
	if len(msg) > 500 {
		msg = msg[:500]
	}
	return q.FailSuggestion(ctx, db.FailSuggestionParams{ID: id, Error: &msg})
}

func (s *Service) extract(ctx context.Context, q *db.Queries, l db.Listing, c db.GetListingContextRow, schema *catalog.Schema) (AttributePayload, string, error) {
	t, d := i18n(l.Title), i18n(l.Description)
	text := strings.TrimSpace(strings.Join([]string{t.CS, d.CS, t.EN, d.EN}, "\n"))
	photos, err := q.ListListingMedia(ctx, &l.ID)
	if err != nil {
		return AttributePayload{}, "", err
	}
	tagSet := map[string]bool{}
	for _, m := range photos {
		var v vision.Analysis
		if json.Unmarshal(m.Vision, &v) == nil {
			for _, tag := range v.Tags {
				tagSet[tag] = true
			}
		}
	}
	tags := make([]string, 0, len(tagSet))
	for tag := range tagSet {
		tags = append(tags, tag)
	}
	sort.Strings(tags)
	res, err := s.AI.ExtractAttributes(ctx, ai.ExtractRequest{Text: text, PhotoTags: tags, UnitKind: c.UnitKind, Attrs: schema.For(c.UnitKind)})
	if err != nil {
		return AttributePayload{}, "", err
	}
	// New option values are proposed to the backoffice and left out of the
	// values until a human approves them.
	pending := map[string]map[string]bool{}
	for _, n := range res.NewOptions {
		a, ok := schema.Get(n.Key)
		if !ok || a.HasOption(n.Value) {
			continue
		}
		if err := q.UpsertFilterProposal(ctx, db.UpsertFilterProposalParams{AttributeKey: n.Key, Value: n.Value,
			Label: jsonb(n.Label), ExampleListingID: &l.ID}); err != nil {
			return AttributePayload{}, "", err
		}
		if pending[n.Key] == nil {
			pending[n.Key] = map[string]bool{}
		}
		pending[n.Key][n.Value] = true
	}
	for k, v := range res.Values {
		switch x := v.(type) {
		case string:
			if pending[k][x] {
				delete(res.Values, k)
			}
		case []any:
			var keep []any
			for _, e := range x {
				if sv, ok := e.(string); !ok || !pending[k][sv] {
					keep = append(keep, e)
				}
			}
			res.Values[k] = keep
		}
	}
	valid, invalid := schema.Validate(res.Values, c.UnitKind)
	var current map[string]any
	_ = json.Unmarshal(l.Attributes, &current)
	for k, v := range valid {
		if jsonEqualAny(current[k], v) {
			delete(valid, k) // nothing new to suggest
		}
	}
	return AttributePayload{Values: valid, Current: current, NewOptions: nonNilOptions(res.NewOptions), Invalid: invalid}, res.Model, nil
}

func nonNilOptions(o []ai.NewOption) []ai.NewOption {
	if o == nil {
		return []ai.NewOption{}
	}
	return o
}

func jsonEqualAny(a, b any) bool {
	x, _ := json.Marshal(a)
	y, _ := json.Marshal(b)
	return string(x) == string(y)
}

// draftRequest collects the facts for a text draft, with labels in both languages.
func draftRequest(l db.Listing, c db.GetListingContextRow, schema *catalog.Schema) ai.DraftRequest {
	var attrs map[string]any
	_ = json.Unmarshal(l.Attributes, &attrs)
	r := ai.DraftRequest{UnitKind: c.UnitKind, Floor: c.Floor, Currency: l.Currency,
		Features: map[string]string{}, FeaturesEN: map[string]string{}}
	if c.Layout != nil {
		r.Layout = *c.Layout
	}
	if c.FloorArea != nil {
		r.FloorArea = *c.FloorArea
	}
	if l.RentAmount != nil {
		r.Rent = *l.RentAmount / 100
	}
	loc := c.City
	if c.CityPart != nil && *c.CityPart != c.City {
		loc = *c.CityPart + ", " + c.City
	}
	r.Location = loc
	for k, v := range attrs {
		if k == "layout" || k == "floor_area" || k == "floor" {
			continue
		}
		a, ok := schema.Get(k)
		if !ok {
			continue
		}
		cs, en := valueLabels(a, v)
		if cs == "-" {
			continue
		}
		r.Features[a.Label.CS], r.FeaturesEN[a.Label.EN] = cs, en
	}
	return r
}

// valueLabels renders a value for texts ("" for true booleans, "-" to skip).
func valueLabels(a *catalog.Attribute, v any) (string, string) {
	opt := func(val string) (string, string) {
		for _, o := range a.Options {
			if o.Value == val {
				return o.Label.CS, o.Label.EN
			}
		}
		return val, val
	}
	switch x := v.(type) {
	case bool:
		if x {
			return "", ""
		}
		return "-", "-"
	case float64:
		n := fmt.Sprintf("%g", x)
		if a.Unit != "" {
			n += " " + strings.ReplaceAll(a.Unit, "m2", "m²")
		}
		return n, n
	case string:
		return opt(x)
	case []any:
		var cs, en []string
		for _, e := range x {
			if sv, ok := e.(string); ok {
				c, e := opt(sv)
				cs, en = append(cs, c), append(en, e)
			}
		}
		return strings.Join(cs, ", "), strings.Join(en, ", ")
	}
	return "-", "-"
}

// Decision is the owner's answer to a suggestion.
type Decision struct {
	Accept bool
	Keys   []string // attributes: accept only these (nil = all)
}

// Decide applies or rejects a suggestion. Nothing AI-generated reaches the
// listing without this explicit human step (ADR 0003).
func (s *Service) Decide(ctx context.Context, p *auth.Principal, orgID, suggestionID uuid.UUID, d Decision) (db.AiSuggestion, error) {
	schema, err := s.Schema(ctx)
	if err != nil {
		return db.AiSuggestion{}, err
	}
	var sg db.AiSuggestion
	var redact *db.Medium
	err = s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		if _, err := org.Access(ctx, q, p.UserID, orgID, org.PermCatalogWrite); err != nil {
			return err
		}
		var err error
		sg, err = q.GetSuggestion(ctx, db.GetSuggestionParams{ID: suggestionID, OrgID: orgID})
		if errors.Is(err, pgx.ErrNoRows) {
			return apperr.NotFound("suggestion_not_found", "suggestion not found")
		}
		if err != nil {
			return err
		}
		if sg.Status != "pending" {
			return apperr.Conflict("suggestion_decided", "this suggestion was already decided")
		}
		status := "rejected"
		decision := map[string]any{"accept": d.Accept}
		if d.Accept {
			status = "accepted"
			l, err := q.GetListing(ctx, db.GetListingParams{ID: sg.ListingID, OrgID: orgID})
			if err != nil {
				return err
			}
			switch sg.Kind {
			case "attributes":
				var pl AttributePayload
				_ = json.Unmarshal(sg.Payload, &pl)
				var attrs map[string]any
				_ = json.Unmarshal(l.Attributes, &attrs)
				if attrs == nil {
					attrs = map[string]any{}
				}
				var applied []string
				for k, v := range pl.Values {
					if d.Keys != nil && !contains(d.Keys, k) {
						continue
					}
					attrs[k] = v
					applied = append(applied, k)
				}
				c, err := q.GetListingContext(ctx, l.ID)
				if err != nil {
					return err
				}
				clean, ferrs := schema.Validate(attrs, c.UnitKind)
				if len(ferrs) > 0 {
					return &FieldErrors{Errors: ferrs}
				}
				if err := q.SetListingAttributes(ctx, db.SetListingAttributesParams{ID: l.ID, OrgID: orgID, Attributes: jsonb(clean)}); err != nil {
					return err
				}
				sort.Strings(applied)
				decision["keys"] = applied
				if len(applied) == 0 {
					status = "rejected"
				} else if len(applied) < len(pl.Values) {
					status = "partially_accepted"
				}
			case "text":
				var pl struct {
					Title, Description I18n
				}
				_ = json.Unmarshal(sg.Payload, &pl)
				if err := q.SetListingTexts(ctx, db.SetListingTextsParams{ID: l.ID, OrgID: orgID,
					Title: jsonb(pl.Title), Description: jsonb(pl.Description)}); err != nil {
					return err
				}
			case "photo_tags":
				var pl struct {
					Caption string `json:"caption"`
				}
				_ = json.Unmarshal(sg.Payload, &pl)
				if sg.MediaID != nil && pl.Caption != "" {
					m, err := q.GetMedia(ctx, db.GetMediaParams{ID: *sg.MediaID, OrgID: orgID})
					if err != nil {
						return err
					}
					caption := i18n(m.Caption)
					caption.CS = pl.Caption
					if _, err := q.UpdateMediaMeta(ctx, db.UpdateMediaMetaParams{ID: m.ID, OrgID: orgID, Position: m.Position, Caption: jsonb(caption)}); err != nil {
						return err
					}
				}
			case "privacy_blur":
				if sg.MediaID != nil {
					m, err := q.GetMedia(ctx, db.GetMediaParams{ID: *sg.MediaID, OrgID: orgID})
					if err != nil {
						return err
					}
					redact = &m
				}
			}
		}
		if _, err := q.DecideSuggestion(ctx, db.DecideSuggestionParams{ID: sg.ID, OrgID: orgID, Status: status,
			Decision: jsonb(decision), DecidedBy: &p.UserID}); err != nil {
			return err
		}
		sg.Status = status
		return audit.Record(ctx, q, audit.Event{OrgID: &orgID, Entity: "ai_suggestion", EntityID: &sg.ID,
			Action: "ai_suggestion." + status, Diff: map[string]any{"kind": sg.Kind, "listing_id": sg.ListingID, "decision": decision}})
	})
	if err == nil && redact != nil {
		err = s.applyRedaction(ctx, *redact, sg)
	}
	return sg, err
}

func (s *Service) applyRedaction(ctx context.Context, m db.Medium, sg db.AiSuggestion) error {
	var pl struct {
		Regions []vision.Region `json:"regions"`
	}
	_ = json.Unmarshal(sg.Payload, &pl)
	if !s.Vision.Enabled() {
		return apperr.Unavailable("vision_unavailable", "photo blurring is not available")
	}
	u, err := s.Blob.PresignGet(ctx, m.ObjectKey, 10*time.Minute)
	if err != nil {
		return err
	}
	img, err := s.Vision.Redact(ctx, u, pl.Regions)
	if err != nil {
		return err
	}
	return s.Blob.Put(ctx, m.ObjectKey, "image/jpeg", img)
}

func contains(list []string, v string) bool {
	for _, x := range list {
		if x == v {
			return true
		}
	}
	return false
}

// Proposals lists filter schema proposals (staff).
func (s *Service) Proposals(ctx context.Context, status string) ([]db.FilterSchemaProposal, error) {
	return db.New(s.Pool).ListFilterProposals(ctx, status)
}

// DecideProposal approves (adds the option to the schema) or rejects a proposal (staff).
func (s *Service) DecideProposal(ctx context.Context, staff *auth.Principal, id uuid.UUID, approve bool, label *I18n, note string) error {
	return s.system(ctx, func(q *db.Queries, _ pgx.Tx) error {
		pr, err := q.GetFilterProposal(ctx, id)
		if errors.Is(err, pgx.ErrNoRows) {
			return apperr.NotFound("proposal_not_found", "proposal not found")
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
		n, err := q.DecideFilterProposal(ctx, db.DecideFilterProposalParams{ID: id, Status: status, Note: notePtr, DecidedBy: &staff.UserID})
		if err != nil {
			return err
		}
		if n == 0 {
			return apperr.Conflict("proposal_decided", "this proposal was already decided")
		}
		if approve {
			l := i18n(pr.Label)
			if label != nil {
				l = *label
			}
			opt := map[string]any{"value": pr.Value, "label": l, "source": "ingest"}
			if err := q.AddFilterOption(ctx, db.AddFilterOptionParams{Key: pr.AttributeKey, Option: jsonb(opt)}); err != nil {
				return err
			}
		}
		return audit.Record(ctx, q, audit.Event{Entity: "filter_schema", Action: "filter_option." + status,
			Diff: map[string]any{"attribute": pr.AttributeKey, "value": pr.Value}})
	})
}
