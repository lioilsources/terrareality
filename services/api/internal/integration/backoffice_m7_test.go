package integration

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/terrareality/terrareality/services/api/internal/flags"
)

type featureFlagDTO struct {
	Key         string     `json:"key"`
	Enabled     bool       `json:"enabled"`
	Description string     `json:"description"`
	Source      string     `json:"source"`
	UpdatedAt   *time.Time `json:"updated_at"`
}

func findFlag(items []featureFlagDTO, key string) (featureFlagDTO, bool) {
	for _, f := range items {
		if f.Key == key {
			return f, true
		}
	}
	return featureFlagDTO{}, false
}

// M7: feature flags fall back to config defaults, a backoffice override wins,
// writes invalidate the cache and are audited; other processes see the change
// after the TTL.
func TestBackofficeFeatureFlags(t *testing.T) {
	e := newEnv(t)
	ctx := context.Background()
	start := time.Now().Add(-time.Second)
	if _, err := e.pool.Exec(ctx, "DELETE FROM feature_flags WHERE key = 'test.m7_flag'"); err != nil {
		t.Fatal(err)
	}
	e.flags.Invalidate()
	staff := e.staffToken()
	userTok, _ := e.ownerOrg("flags")

	// Non-staff are refused everywhere.
	for _, c := range []struct{ method, path string }{{"GET", "/v1/backoffice/feature-flags"}, {"GET", "/v1/backoffice/metrics"},
		{"GET", "/v1/backoffice/promo-products"}, {"GET", "/v1/backoffice/attribute-suggestions"}, {"GET", "/v1/backoffice/templates"}} {
		if code := e.call(c.method, c.path, userTok, nil, nil); code != 403 {
			t.Fatalf("%s %s as owner: %d", c.method, c.path, code)
		}
	}
	if code := e.call("PUT", "/v1/backoffice/feature-flags/test.m7_flag", userTok, map[string]any{"enabled": true}, nil); code != 403 {
		t.Fatalf("owner set flag: %d", code)
	}

	// Fallback to defaults.
	if e.flags.Enabled(ctx, "test.m7_flag") {
		t.Fatal("default off flag is on")
	}
	var list struct{ Items []featureFlagDTO }
	e.must(200, "GET", "/v1/backoffice/feature-flags", staff, nil, &list)
	f, ok := findFlag(list.Items, "test.m7_flag")
	if !ok || f.Enabled || f.Source != "default" || f.UpdatedAt != nil {
		t.Fatalf("default flag %+v (found %v)", f, ok)
	}
	if rv, ok := findFlag(list.Items, "payments.revolut"); !ok || rv.Description == "" {
		t.Fatalf("payments.revolut missing or without description: %+v", rv)
	}

	// Another process with a warm cache.
	other := flags.New(e.pool, map[string]bool{"test.m7_flag": false})
	now := time.Now()
	other.Now = func() time.Time { return now }
	if other.Enabled(ctx, "test.m7_flag") {
		t.Fatal("other store: default off flag is on")
	}

	// Override.
	var set featureFlagDTO
	e.must(200, "PUT", "/v1/backoffice/feature-flags/test.m7_flag", staff, map[string]any{"enabled": true, "description": "integration"}, &set)
	if !set.Enabled || set.Source != "db" || set.Description != "integration" || set.UpdatedAt == nil {
		t.Fatalf("set flag %+v", set)
	}
	if !e.flags.Enabled(ctx, "test.m7_flag") {
		t.Fatal("cache not invalidated on Set")
	}
	if other.Enabled(ctx, "test.m7_flag") {
		t.Fatal("other store reloaded before its TTL")
	}
	now = now.Add(flags.DefaultTTL + time.Second)
	if !other.Enabled(ctx, "test.m7_flag") {
		t.Fatal("other store did not reload after its TTL")
	}

	// Description is kept when omitted; switching off works.
	e.must(200, "PUT", "/v1/backoffice/feature-flags/test.m7_flag", staff, map[string]any{"enabled": false}, &set)
	if set.Enabled || set.Description != "integration" || e.flags.Enabled(ctx, "test.m7_flag") {
		t.Fatalf("switch off %+v", set)
	}
	e.must(200, "GET", "/v1/backoffice/feature-flags", staff, nil, &list)
	if f, _ := findFlag(list.Items, "test.m7_flag"); f.Source != "db" || f.Enabled {
		t.Fatalf("listed override %+v", f)
	}

	// Unknown keys are refused.
	if code := e.call("PUT", "/v1/backoffice/feature-flags/no.such_flag", staff, map[string]any{"enabled": true}, nil); code != 404 {
		t.Fatalf("unknown flag: %d", code)
	}

	// Audited.
	var n int
	if err := e.pool.QueryRow(ctx, "SELECT count(*) FROM audit_events WHERE entity = 'feature_flag' AND diff->>'key' = 'test.m7_flag' AND occurred_at >= $1",
		start).Scan(&n); err != nil || n < 2 {
		t.Fatalf("flag audit events: %d %v", n, err)
	}
}

// M7: metrics shape, promo product catalog management and the contract template overview.
func TestBackofficeMetricsAndPromoProducts(t *testing.T) {
	e := newEnv(t)
	staff := e.staffToken()

	var m map[string]any
	e.must(200, "GET", "/v1/backoffice/metrics", staff, nil, &m)
	for _, k := range []string{"users", "orgs", "listings_published", "listings_promoted", "applications_30d", "leases_signed_30d",
		"moderation_open", "attribute_suggestions_open", "orders_paid_30d"} {
		if _, ok := m[k].(float64); !ok {
			t.Fatalf("metrics %s missing: %v", k, m)
		}
	}
	if rev, ok := m["revenue_30d"].(map[string]any); !ok || rev["currency"] != "CZK" {
		t.Fatalf("revenue %v", m["revenue_30d"])
	} else if _, ok := rev["gross_amount"].(float64); !ok {
		t.Fatalf("revenue amount %v", rev)
	}
	if m["users"].(float64) < 1 {
		t.Fatalf("users %v", m["users"])
	}

	type product struct {
		ID           uuid.UUID         `json:"id"`
		Code         string            `json:"code"`
		Kind         string            `json:"kind"`
		DurationDays int               `json:"duration_days"`
		NetAmount    int64             `json:"net_amount"`
		VatAmount    int64             `json:"vat_amount"`
		GrossAmount  int64             `json:"gross_amount"`
		VatRateBp    int               `json:"vat_rate_bp"`
		Currency     string            `json:"currency"`
		Name         map[string]string `json:"name"`
		Active       bool              `json:"active"`
	}
	var list struct{ Items []product }
	e.must(200, "GET", "/v1/backoffice/promo-products", staff, nil, &list)
	seeded := map[string]bool{}
	for _, p := range list.Items {
		seeded[p.Code] = true
	}
	for _, c := range []string{"top_7d", "top_30d", "highlight_30d", "bundle_top_highlight_30d"} {
		if !seeded[c] {
			t.Fatalf("seed product %s missing: %+v", c, list.Items)
		}
	}

	code := "test_" + uuid.NewString()[:8]
	in := map[string]any{"code": code, "kind": "top", "duration_days": 14, "net_amount": 29900,
		"name": map[string]string{"cs": "Topování 14 dní", "en": "Top 14 days"}}
	var p product
	e.must(201, "POST", "/v1/backoffice/promo-products", staff, in, &p)
	if p.Code != code || p.VatRateBp != 2100 || p.Currency != "CZK" || p.VatAmount != 6279 || p.GrossAmount != 36179 || !p.Active {
		t.Fatalf("created %+v", p)
	}
	if c := e.call("POST", "/v1/backoffice/promo-products", staff, in, nil); c != 409 {
		t.Fatalf("duplicate code: %d", c)
	}
	bad := map[string]any{"code": "test_bad_" + uuid.NewString()[:4], "kind": "top", "duration_days": 0, "net_amount": 100,
		"name": map[string]string{"cs": "x", "en": "x"}}
	if c := e.call("POST", "/v1/backoffice/promo-products", staff, bad, nil); c != 400 { // contract minimum: 1
		t.Fatalf("zero duration: %d", c)
	}

	var u product
	e.must(200, "PATCH", "/v1/backoffice/promo-products/"+p.ID.String(), staff, map[string]any{"net_amount": 39900, "active": false}, &u)
	if u.NetAmount != 39900 || u.Active || u.DurationDays != 14 || u.Name["cs"] != "Topování 14 dní" {
		t.Fatalf("updated %+v", u)
	}
	if c := e.call("PATCH", "/v1/backoffice/promo-products/"+uuid.NewString(), staff, map[string]any{"active": true}, nil); c != 404 {
		t.Fatalf("unknown product: %d", c)
	}
	// Inactive products stay in the backoffice list but leave the public catalog.
	e.must(200, "GET", "/v1/backoffice/promo-products", staff, nil, &list)
	found := false
	for _, x := range list.Items {
		found = found || x.ID == p.ID
	}
	if !found {
		t.Fatal("inactive product missing from the backoffice list")
	}
	var n int
	if err := e.pool.QueryRow(context.Background(), "SELECT count(*) FROM audit_events WHERE entity = 'promo_product' AND entity_id = $1",
		p.ID).Scan(&n); err != nil || n != 2 {
		t.Fatalf("promo audit events: %d %v", n, err)
	}

	var tpl struct {
		Version string
		Items   []struct {
			Name     string
			Title    string
			Reviewed bool
		}
	}
	e.must(200, "GET", "/v1/backoffice/templates", staff, nil, &tpl)
	if tpl.Version == "" || len(tpl.Items) != 4 || tpl.Items[0].Title == "" {
		t.Fatalf("templates %+v", tpl)
	}
	var pdf []byte
	switch c := e.callRaw("GET", "/v1/backoffice/templates/pokoj/preview", staff, &pdf); c {
	case 200:
		if len(pdf) < 4 || string(pdf[:4]) != "%PDF" {
			t.Fatal("preview is not a PDF")
		}
	case 503: // typst not installed
	default:
		t.Fatalf("preview: %d", c)
	}
	if c := e.call("GET", "/v1/backoffice/templates/nope/preview", staff, nil, nil); c != 404 {
		t.Fatalf("unknown template: %d", c)
	}
}

// M7: AI ingest proposes attributes the catalog lacks; staff decide each
// suggestion exactly once and approval does not change the catalog (ADR 0003).
func TestBackofficeAttributeSuggestions(t *testing.T) {
	e := newEnv(t)
	ctx := context.Background()
	if _, err := e.pool.Exec(ctx, "DELETE FROM attribute_suggestions WHERE key = 'sauna'"); err != nil {
		t.Fatal(err)
	}
	staff := e.staffToken()
	tok, orgID := e.ownerOrg("attrsugg")
	base := "/v1/orgs/" + orgID.String()

	var addrs []struct {
		RuianID int64 `json:"ruian_id"`
	}
	e.must(200, "GET", "/v1/addresses/search?q=dejvicka", "", nil, &addrs)
	var flat listingDTO
	e.must(201, "POST", base+"/listings", tok, map[string]any{"ruian_id": addrs[0].RuianID, "unit_kind": "apartment",
		"layout": "2+kk", "floor_area": 54, "floor": 3}, &flat)
	flatPath := base + "/listings/" + flat.ID.String()
	e.must(200, "PUT", flatPath, tok, map[string]any{"title": map[string]string{"cs": "", "en": ""},
		"description": map[string]string{"cs": "Byt 2+kk, v domě je sauna a balkon.", "en": ""}, "rent_amount": 2200000,
		"deposit_amount": 4400000, "attributes": flat.Attributes, "location_precision": "approximate"}, &flat)
	e.must(202, "POST", flatPath+"/suggestions", tok, map[string]string{"kind": "attributes"}, nil)
	e.runSuggestions()

	type suggestion struct {
		ID               uuid.UUID         `json:"id"`
		Key              string            `json:"key"`
		Type             string            `json:"type"`
		GroupKey         string            `json:"group_key"`
		Label            map[string]string `json:"label"`
		Status           string            `json:"status"`
		Occurrences      int               `json:"occurrences"`
		ExampleListingID *uuid.UUID        `json:"example_listing_id"`
		Note             *string           `json:"note"`
		DecidedAt        *time.Time        `json:"decided_at"`
	}
	var list struct{ Items []suggestion }
	e.must(200, "GET", "/v1/backoffice/attribute-suggestions?status=open", staff, nil, &list)
	var sg suggestion
	for _, s := range list.Items {
		if s.Key == "sauna" {
			sg = s
		}
	}
	if sg.ID == uuid.Nil || sg.Type != "bool" || sg.Status != "open" || sg.ExampleListingID == nil || *sg.ExampleListingID != flat.ID {
		t.Fatalf("sauna suggestion %+v in %+v", sg, list.Items)
	}

	// A second find counts an occurrence instead of a new row.
	e.must(202, "POST", flatPath+"/suggestions", tok, map[string]string{"kind": "attributes"}, nil)
	e.runSuggestions()
	e.must(200, "GET", "/v1/backoffice/attribute-suggestions", staff, nil, &list)
	for _, s := range list.Items {
		if s.Key == "sauna" && s.Occurrences != sg.Occurrences+1 {
			t.Fatalf("occurrences %d after %d", s.Occurrences, sg.Occurrences)
		}
	}

	userTok, _ := e.ownerOrg("attrsugg2")
	if c := e.call("POST", "/v1/backoffice/attribute-suggestions/"+sg.ID.String()+"/decision", userTok,
		map[string]any{"decision": "approve"}, nil); c != 403 {
		t.Fatalf("owner decided: %d", c)
	}
	var decided suggestion
	e.must(200, "POST", "/v1/backoffice/attribute-suggestions/"+sg.ID.String()+"/decision", staff,
		map[string]any{"decision": "approve", "note": "add to packages/attributes"}, &decided)
	if decided.Status != "approved" || decided.DecidedAt == nil || decided.Note == nil || *decided.Note != "add to packages/attributes" {
		t.Fatalf("decided %+v", decided)
	}
	if c := e.call("POST", "/v1/backoffice/attribute-suggestions/"+sg.ID.String()+"/decision", staff,
		map[string]any{"decision": "reject"}, nil); c != 409 {
		t.Fatalf("second decision: %d", c)
	}
	if c := e.call("POST", "/v1/backoffice/attribute-suggestions/"+uuid.NewString()+"/decision", staff,
		map[string]any{"decision": "reject"}, nil); c != 404 {
		t.Fatalf("unknown suggestion: %d", c)
	}

	// Approval does not touch the catalog.
	var schema struct {
		Attributes []struct{ Key string } `json:"attributes"`
	}
	e.must(200, "GET", "/v1/attributes", "", nil, &schema)
	for _, a := range schema.Attributes {
		if a.Key == "sauna" {
			t.Fatal("approved suggestion was added to the catalog")
		}
	}
	e.must(200, "GET", "/v1/backoffice/attribute-suggestions?status=approved", staff, nil, &list)
	found := false
	for _, s := range list.Items {
		found = found || s.ID == sg.ID
	}
	if !found {
		t.Fatal("approved suggestion not listed")
	}
}
