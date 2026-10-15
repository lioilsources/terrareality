package api

// M7 backoffice: metrics, feature flags, promo product catalog, the queue of
// AI-proposed attributes and the contract template overview. Staff only;
// staff work runs in system context (authorization is the staff check) and
// every change is audited.

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"regexp"
	"slices"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/terrareality/terrareality/services/api/internal/api/gen"
	"github.com/terrareality/terrareality/services/api/internal/audit"
	"github.com/terrareality/terrareality/services/api/internal/billing"
	"github.com/terrareality/terrareality/services/api/internal/catalog"
	dbq "github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/flags"
	"github.com/terrareality/terrareality/services/api/internal/leasing"
	"github.com/terrareality/terrareality/services/api/internal/platform/apperr"
	"github.com/terrareality/terrareality/services/api/internal/platform/db"
)

// metricsCurrency is the currency revenue is reported in.
const metricsCurrency = "CZK"

// BackofficeGetMetrics implements GET /v1/backoffice/metrics.
func (s *Server) BackofficeGetMetrics(ctx context.Context, _ gen.BackofficeGetMetricsRequestObject) (gen.BackofficeGetMetricsResponseObject, error) {
	if _, err := s.staff(ctx); err != nil {
		return nil, err
	}
	m, err := dbq.New(s.pool).BackofficeMetrics(ctx, metricsCurrency)
	if err != nil {
		return nil, err
	}
	return gen.BackofficeGetMetrics200JSONResponse{Users: m.Users, Orgs: m.Orgs, ListingsPublished: m.ListingsPublished,
		ListingsPromoted: m.ListingsPromoted, Applications30d: m.Applications30d, LeasesSigned30d: m.LeasesSigned30d,
		ModerationOpen: m.ModerationOpen, AttributeSuggestionsOpen: m.AttributeSuggestionsOpen,
		Revenue30d:    gen.Money{GrossAmount: m.Revenue30d, Currency: metricsCurrency},
		OrdersPaid30d: m.OrdersPaid30d}, nil
}

// ---------------------------------------------------------------------------
// Feature flags.

func (s *Server) flagStore() (*flags.Store, error) {
	if s.Flags == nil {
		return nil, apperr.Unavailable("flags_unavailable", "feature flags are not configured")
	}
	return s.Flags, nil
}

func flagDTO(f flags.Flag) gen.FeatureFlag {
	return gen.FeatureFlag{Key: f.Key, Enabled: f.Enabled, Description: f.Description,
		Source: gen.FeatureFlagSource(f.Source), UpdatedAt: f.UpdatedAt}
}

// BackofficeListFeatureFlags implements GET /v1/backoffice/feature-flags.
func (s *Server) BackofficeListFeatureFlags(ctx context.Context, _ gen.BackofficeListFeatureFlagsRequestObject) (gen.BackofficeListFeatureFlagsResponseObject, error) {
	if _, err := s.staff(ctx); err != nil {
		return nil, err
	}
	st, err := s.flagStore()
	if err != nil {
		return nil, err
	}
	list, err := st.List(ctx)
	if err != nil {
		return nil, err
	}
	out := gen.BackofficeListFeatureFlags200JSONResponse{Items: make([]gen.FeatureFlag, 0, len(list))}
	for _, f := range list {
		out.Items = append(out.Items, flagDTO(f))
	}
	return out, nil
}

// BackofficeSetFeatureFlag implements PUT /v1/backoffice/feature-flags/{key}.
// Only known keys (a config default or an existing row) can be set.
func (s *Server) BackofficeSetFeatureFlag(ctx context.Context, r gen.BackofficeSetFeatureFlagRequestObject) (gen.BackofficeSetFeatureFlagResponseObject, error) {
	p, err := s.staff(ctx)
	if err != nil {
		return nil, err
	}
	st, err := s.flagStore()
	if err != nil {
		return nil, err
	}
	if r.Body.Description != nil && len(*r.Body.Description) > 500 {
		return nil, apperr.Unprocessable("invalid_description", "description is too long")
	}
	f, err := st.Set(ctx, p.UserID, r.Key, r.Body.Enabled, r.Body.Description)
	if err != nil {
		return nil, err
	}
	return gen.BackofficeSetFeatureFlag200JSONResponse(flagDTO(f)), nil
}

// ---------------------------------------------------------------------------
// Promo product catalog.

var rePromoCode = regexp.MustCompile(`^[a-z][a-z0-9_]{0,62}$`)

func backofficePromoDTO(p dbq.PromoProduct) gen.PromoProduct {
	vat, gross := billing.ComputeVAT(p.NetAmount, int(p.VatRateBp))
	return gen.PromoProduct{Id: p.ID, Code: p.Code, Kind: gen.PromoProductKind(p.Kind), DurationDays: int(p.DurationDays),
		NetAmount: p.NetAmount, VatRateBp: int(p.VatRateBp), VatAmount: vat, GrossAmount: gross,
		Currency: strings.TrimSpace(p.Currency), Name: i18nDTO(p.Name), Active: p.Active}
}

func promoAuditDiff(p dbq.PromoProduct) map[string]any {
	return map[string]any{"code": p.Code, "kind": p.Kind, "duration_days": p.DurationDays, "net_amount": p.NetAmount,
		"currency": strings.TrimSpace(p.Currency), "vat_rate_bp": p.VatRateBp, "active": p.Active, "name": objectOf(p.Name)}
}

func validPromoName(n gen.I18nText) error {
	if strings.TrimSpace(n.Cs) == "" || strings.TrimSpace(n.En) == "" || len(n.Cs) > 200 || len(n.En) > 200 {
		return apperr.Unprocessable("invalid_name", "name needs Czech and English text (max 200 characters)")
	}
	return nil
}

func validPromoDuration(d int) error {
	if d < 1 || d > 365 {
		return apperr.Unprocessable("invalid_duration", "duration_days must be 1-365")
	}
	return nil
}

func validPromoNet(n int64) error {
	if n < 0 {
		return apperr.Unprocessable("invalid_amount", "net_amount must not be negative")
	}
	return nil
}

// BackofficeListPromoProducts implements GET /v1/backoffice/promo-products (incl. inactive).
func (s *Server) BackofficeListPromoProducts(ctx context.Context, _ gen.BackofficeListPromoProductsRequestObject) (gen.BackofficeListPromoProductsResponseObject, error) {
	if _, err := s.staff(ctx); err != nil {
		return nil, err
	}
	rows, err := dbq.New(s.pool).ListPromoProducts(ctx, true)
	if err != nil {
		return nil, err
	}
	out := gen.BackofficeListPromoProducts200JSONResponse{Items: make([]gen.PromoProduct, 0, len(rows))}
	for _, p := range rows {
		out.Items = append(out.Items, backofficePromoDTO(p))
	}
	return out, nil
}

// BackofficeCreatePromoProduct implements POST /v1/backoffice/promo-products.
func (s *Server) BackofficeCreatePromoProduct(ctx context.Context, r gen.BackofficeCreatePromoProductRequestObject) (gen.BackofficeCreatePromoProductResponseObject, error) {
	if _, err := s.staff(ctx); err != nil {
		return nil, err
	}
	in := r.Body
	if !rePromoCode.MatchString(in.Code) {
		return nil, apperr.Unprocessable("invalid_code", "code must be snake_case")
	}
	if !slices.Contains([]string{"top", "highlight", "bundle"}, string(in.Kind)) {
		return nil, apperr.Unprocessable("invalid_kind", "kind must be top, highlight or bundle")
	}
	for _, err := range []error{validPromoDuration(in.DurationDays), validPromoNet(in.NetAmount), validPromoName(in.Name)} {
		if err != nil {
			return nil, err
		}
	}
	currency, rate, active := metricsCurrency, 2100, true
	if in.Currency != nil {
		currency = strings.ToUpper(*in.Currency)
	}
	if len(currency) != 3 {
		return nil, apperr.Unprocessable("invalid_currency", "currency must be an ISO 4217 code")
	}
	if in.VatRateBp != nil {
		rate = *in.VatRateBp
	}
	if rate < 0 || rate > 10000 {
		return nil, apperr.Unprocessable("invalid_vat_rate", "vat_rate_bp must be 0-10000")
	}
	if in.Active != nil {
		active = *in.Active
	}
	name, _ := json.Marshal(map[string]string{"cs": in.Name.Cs, "en": in.Name.En})
	var p dbq.PromoProduct
	err := db.InTx(ctx, s.pool, func(tx pgx.Tx) error {
		q := dbq.New(tx)
		var err error
		p, err = q.CreatePromoProduct(ctx, dbq.CreatePromoProductParams{Code: in.Code, Kind: string(in.Kind),
			DurationDays: int32(in.DurationDays), NetAmount: in.NetAmount, Currency: currency, VatRateBp: int32(rate),
			Name: name, Active: active})
		var pgErr *pgconn.PgError
		if errors.As(err, &pgErr) && pgErr.Code == "23505" {
			return apperr.Conflict("promo_code_taken", "a promo product with this code already exists")
		}
		if err != nil {
			return err
		}
		return audit.Record(ctx, q, audit.Event{Entity: "promo_product", EntityID: audit.Ptr(p.ID),
			Action: "promo_product.create", Diff: promoAuditDiff(p)})
	})
	if err != nil {
		return nil, err
	}
	return gen.BackofficeCreatePromoProduct201JSONResponse(backofficePromoDTO(p)), nil
}

// BackofficeUpdatePromoProduct implements PATCH /v1/backoffice/promo-products/{productId}.
// Existing orders keep the price they were created with.
func (s *Server) BackofficeUpdatePromoProduct(ctx context.Context, r gen.BackofficeUpdatePromoProductRequestObject) (gen.BackofficeUpdatePromoProductResponseObject, error) {
	if _, err := s.staff(ctx); err != nil {
		return nil, err
	}
	in := r.Body
	arg := dbq.UpdatePromoProductParams{ID: r.ProductId, NetAmount: in.NetAmount}
	if in.NetAmount != nil {
		if err := validPromoNet(*in.NetAmount); err != nil {
			return nil, err
		}
	}
	if in.DurationDays != nil {
		if err := validPromoDuration(*in.DurationDays); err != nil {
			return nil, err
		}
		d := int32(*in.DurationDays)
		arg.DurationDays = &d
	}
	if in.Name != nil {
		if err := validPromoName(*in.Name); err != nil {
			return nil, err
		}
		arg.Name, _ = json.Marshal(map[string]string{"cs": in.Name.Cs, "en": in.Name.En})
	}
	if in.Active != nil {
		arg.Active = pgtype.Bool{Bool: *in.Active, Valid: true}
	}
	var p dbq.PromoProduct
	err := db.InTx(ctx, s.pool, func(tx pgx.Tx) error {
		q := dbq.New(tx)
		before, err := q.GetPromoProduct(ctx, r.ProductId)
		if errors.Is(err, pgx.ErrNoRows) {
			return apperr.NotFound("promo_product_not_found", "promo product not found")
		}
		if err != nil {
			return err
		}
		if p, err = q.UpdatePromoProduct(ctx, arg); err != nil {
			return err
		}
		return audit.Record(ctx, q, audit.Event{Entity: "promo_product", EntityID: audit.Ptr(p.ID),
			Action: "promo_product.update", Diff: map[string]any{"before": promoAuditDiff(before), "after": promoAuditDiff(p)}})
	})
	if err != nil {
		return nil, err
	}
	return gen.BackofficeUpdatePromoProduct200JSONResponse(backofficePromoDTO(p)), nil
}

// ---------------------------------------------------------------------------
// AI-proposed attributes (ADR 0003: staff decide; approval does not touch the
// catalog, a developer adds approved keys to packages/attributes).

func attributeSuggestionDTO(a dbq.AttributeSuggestion) gen.AttributeSuggestion {
	out := gen.AttributeSuggestion{Id: a.ID, Key: a.Key, Type: gen.AttributeSuggestionType(a.Type), GroupKey: a.GroupKey,
		Label: i18nDTO(a.Label), ExampleListingId: a.ExampleListingID, Occurrences: int(a.Occurrences), Model: a.Model,
		Status: gen.AttributeSuggestionStatus(a.Status), Note: a.Note, DecidedAt: a.DecidedAt, CreatedAt: a.CreatedAt}
	var opts []catalog.Option
	_ = json.Unmarshal(a.Options, &opts)
	out.Options = make([]struct {
		Label gen.I18nText `json:"label"`
		Value string       `json:"value"`
	}, 0, len(opts))
	for _, o := range opts {
		out.Options = append(out.Options, struct {
			Label gen.I18nText `json:"label"`
			Value string       `json:"value"`
		}{Label: gen.I18nText{Cs: o.Label.CS, En: o.Label.EN}, Value: o.Value})
	}
	return out
}

// BackofficeListAttributeSuggestions implements GET /v1/backoffice/attribute-suggestions.
func (s *Server) BackofficeListAttributeSuggestions(ctx context.Context, r gen.BackofficeListAttributeSuggestionsRequestObject) (gen.BackofficeListAttributeSuggestionsResponseObject, error) {
	if _, err := s.staff(ctx); err != nil {
		return nil, err
	}
	status := "open"
	if r.Params.Status != nil {
		status = string(*r.Params.Status)
	}
	rows, err := dbq.New(s.pool).ListAttributeSuggestions(ctx, status)
	if err != nil {
		return nil, err
	}
	out := gen.BackofficeListAttributeSuggestions200JSONResponse{Items: make([]gen.AttributeSuggestion, 0, len(rows))}
	for _, a := range rows {
		out.Items = append(out.Items, attributeSuggestionDTO(a))
	}
	return out, nil
}

// BackofficeDecideAttributeSuggestion implements
// POST /v1/backoffice/attribute-suggestions/{suggestionId}/decision.
func (s *Server) BackofficeDecideAttributeSuggestion(ctx context.Context, r gen.BackofficeDecideAttributeSuggestionRequestObject) (gen.BackofficeDecideAttributeSuggestionResponseObject, error) {
	p, err := s.staff(ctx)
	if err != nil {
		return nil, err
	}
	status := map[string]string{"approve": "approved", "reject": "rejected"}[string(r.Body.Decision)]
	if status == "" {
		return nil, apperr.Unprocessable("invalid_decision", "decision must be approve or reject")
	}
	var note *string
	if r.Body.Note != nil && strings.TrimSpace(*r.Body.Note) != "" {
		n := strings.TrimSpace(*r.Body.Note)
		if len(n) > 2000 {
			return nil, apperr.Unprocessable("invalid_note", "note is too long")
		}
		note = &n
	}
	var a dbq.AttributeSuggestion
	err = db.InTx(ctx, s.pool, func(tx pgx.Tx) error {
		q := dbq.New(tx)
		if _, err := q.GetAttributeSuggestion(ctx, r.SuggestionId); errors.Is(err, pgx.ErrNoRows) {
			return apperr.NotFound("attribute_suggestion_not_found", "attribute suggestion not found")
		} else if err != nil {
			return err
		}
		var err error
		a, err = q.DecideAttributeSuggestion(ctx, dbq.DecideAttributeSuggestionParams{ID: r.SuggestionId, Status: status,
			Note: note, DecidedBy: &p.UserID})
		if errors.Is(err, pgx.ErrNoRows) {
			return apperr.Conflict("attribute_suggestion_decided", "this suggestion was already decided")
		}
		if err != nil {
			return err
		}
		return audit.Record(ctx, q, audit.Event{Entity: "attribute_suggestion", EntityID: audit.Ptr(a.ID),
			Action: "attribute_suggestion." + status, Diff: map[string]any{"key": a.Key, "type": a.Type, "note": note}})
	})
	if err != nil {
		return nil, err
	}
	return gen.BackofficeDecideAttributeSuggestion200JSONResponse(attributeSuggestionDTO(a)), nil
}

// ---------------------------------------------------------------------------
// Contract templates.

var templateTitles = map[string][2]string{
	"byt_doba_urcita":   {"Nájemní smlouva k bytu na dobu určitou", "Flat lease, fixed term"},
	"byt_doba_neurcita": {"Nájemní smlouva k bytu na dobu neurčitou", "Flat lease, indefinite term"},
	"spolecny_najem":    {"Smlouva o společném nájmu bytu", "Joint tenancy of a flat"},
	"pokoj":             {"Nájemní smlouva k pokoji", "Room lease"},
}

func templateTitle(name string) string {
	if t, ok := templateTitles[name]; ok {
		return t[0] + " / " + t[1]
	}
	return name
}

// BackofficeListTemplates implements GET /v1/backoffice/templates.
func (s *Server) BackofficeListTemplates(ctx context.Context, _ gen.BackofficeListTemplatesRequestObject) (gen.BackofficeListTemplatesResponseObject, error) {
	if _, err := s.staff(ctx); err != nil {
		return nil, err
	}
	reviewed := s.Leases != nil && s.Leases.TemplatesReviewed
	out := gen.BackofficeListTemplates200JSONResponse{Version: leasing.TemplateVersion,
		Items: make([]gen.ContractTemplate, 0, len(leasing.Templates))}
	for _, name := range leasing.Templates {
		out.Items = append(out.Items, gen.ContractTemplate{Name: name, Title: templateTitle(name), Reviewed: reviewed})
	}
	return out, nil
}

// templateSample is fictitious data for previews.
func templateSample(draft bool) map[string]any {
	return map[string]any{"draft": draft, "code": 2600000001, "document_id": "preview", "generated_at": "1. 10. 2026",
		"parties": []map[string]any{{"role": "landlord", "name": "Jan Novák", "email": "pronajimatel@example.cz"},
			{"role": "tenant", "name": "Eva Svobodová", "email": "najemce@example.cz", "share_pct": 100}},
		"property":  map[string]string{"address": "Dejvická 1, 160 00 Praha 6", "unit": "2+kk, byt č. 12"},
		"starts_on": "1. 11. 2026", "ends_on": "31. 10. 2027",
		"rent": "22 000 Kč", "services": "3 500 Kč", "deposit": "44 000 Kč", "due_day": 15, "notice_months": 3,
		"payee":   map[string]string{"iban": "CZ65 0800 0000 1920 0014 5399", "name": "Jan Novák"},
		"clauses": []string{"no_smoking"}}
}

// BackofficePreviewTemplate implements GET /v1/backoffice/templates/{name}/preview.
func (s *Server) BackofficePreviewTemplate(ctx context.Context, r gen.BackofficePreviewTemplateRequestObject) (gen.BackofficePreviewTemplateResponseObject, error) {
	if _, err := s.staff(ctx); err != nil {
		return nil, err
	}
	if !slices.Contains(leasing.Templates, r.Name) {
		return nil, apperr.NotFound("template_not_found", "unknown contract template")
	}
	if s.Leases == nil || s.Leases.Render == nil {
		return nil, apperr.Unavailable("renderer_unavailable", "contract rendering is not configured")
	}
	data := templateSample(!s.Leases.TemplatesReviewed)
	if r.Name != "byt_doba_urcita" {
		data["ends_on"] = nil
	}
	pdf, err := s.Leases.Render.Render(ctx, r.Name, data)
	if errors.Is(err, leasing.ErrNoTypst) {
		return nil, apperr.Unavailable("typst_unavailable", "the typst binary is not installed on the server")
	}
	if err != nil {
		return nil, err
	}
	return gen.BackofficePreviewTemplate200ApplicationpdfResponse{Body: bytes.NewReader(pdf), ContentLength: int64(len(pdf))}, nil
}
