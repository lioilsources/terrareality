package integration

import (
	"context"
	"encoding/csv"
	"fmt"
	"os/exec"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/terrareality/terrareality/services/api/internal/leasing"
	"github.com/terrareality/terrareality/services/api/internal/notify"
)

type rentRollDTO struct {
	Role string `json:"role"`
	Rows []struct {
		Kind             string     `json:"kind"`
		LeaseID          *uuid.UUID `json:"lease_id"`
		Municipality     string     `json:"municipality"`
		MunicipalityPath string     `json:"municipality_path"`
		Tenants          *string    `json:"tenants"`
		Debt             *int64     `json:"debt"`
		RiskScore        *int       `json:"risk_score"`
		RiskBand         *string    `json:"risk_band"`
		GroupIDs         []string   `json:"group_ids"`
	} `json:"rows"`
	Totals struct {
		Leases int   `json:"leases"`
		Debt   int64 `json:"debt"`
	} `json:"totals"`
}

type leaseRiskDTO struct {
	Score   *int   `json:"score"`
	Band    string `json:"band"`
	Factors []struct {
		Key    string         `json:"key"`
		Value  float64        `json:"value"`
		Weight *int           `json:"weight"`
		Points *float64       `json:"points"`
		Known  bool           `json:"known"`
		Detail map[string]any `json:"detail"`
	} `json:"factors"`
	Landlord bool `json:"landlord"`
}

// Acceptance M6b: an owner with leases in Praha, Brno and Ostrava with
// different payment histories sees different risks with explained factors,
// the weighted risk and concentration, income by municipality and a list of
// actions; a D+7 escalation raises the score; an investor reads the
// portfolio but cannot change anything; the rent roll CSV matches the
// leases' ledgers.
func TestPortfolioAcceptance(t *testing.T) {
	if _, err := exec.LookPath("typst"); err != nil {
		t.Skip("typst not installed")
	}
	e := newEnv(t)
	ctx := context.Background()
	ownerTok, _ := e.ownerOrg("folio-owner")
	var company membership
	e.must(201, "POST", "/v1/orgs", ownerTok, map[string]string{"name": "Rodinné investice s.r.o.", "registration_no": "87654321"}, &company)
	orgID := company.Organization.ID
	orgPath := "/v1/orgs/" + orgID.String()

	today := time.Now().UTC()
	start := time.Date(today.Year(), today.Month(), 1, 0, 0, 0, 0, time.UTC).AddDate(0, -3, 0)
	type spec struct {
		city, address, template string
		ends                    *time.Time
		rent, services          int64
	}
	ostravaEnd := today.AddDate(0, 0, 40)
	brnoEnd := start.AddDate(1, 0, -1)
	specs := []spec{
		{"Praha", "Dejvická 12, Praha 6", "byt_doba_neurcita", nil, 2_500_000, 400_000},
		{"Brno", "Kounicova 20, Brno", "byt_doba_urcita", &brnoEnd, 1_800_000, 300_000},
		{"Ostrava", "Nádražní 20, Ostrava", "byt_doba_urcita", &ostravaEnd, 1_400_000, 200_000},
	}
	ids := map[string]uuid.UUID{}
	tenants := map[string]string{}
	for _, sp := range specs {
		email := uniqueEmail("t-" + strings.ToLower(sp.city))
		tenants[sp.city] = e.register(email)
		body := map[string]any{"template": sp.template, "starts_on": start.Format("2006-01-02"), "rent_amount": sp.rent,
			"services_amount": sp.services, "deposit_amount": 2 * sp.rent, "due_day": 15, "payee_iban": "CZ65 0800 0000 1920 0014 5399",
			"payee_name": "Rodinné investice s.r.o.", "property_address": sp.address, "unit_label": "2+kk",
			"parties": []map[string]any{{"name": "Nájemce " + sp.city, "email": email, "role": "tenant"}}}
		if sp.ends != nil {
			body["ends_on"] = sp.ends.Format("2006-01-02")
		}
		var d leaseDetail
		e.must(201, "POST", orgPath+"/leases", ownerTok, body, &d)
		ids[sp.city] = d.Lease.ID
		e.must(200, "POST", orgPath+"/leases/"+d.Lease.ID.String()+"/propose", ownerTok, nil, nil)
		e.must(200, "POST", "/v1/leases/"+d.Lease.ID.String()+"/sign", tenants[sp.city], map[string]string{"provider": "mock"}, nil)
		e.must(200, "POST", "/v1/leases/"+d.Lease.ID.String()+"/sign", ownerTok, map[string]string{"provider": "mock"}, nil)
	}
	var where []struct {
		City string
		Path string
	}
	rows, err := e.pool.Query(ctx, `SELECT u.name, l.admin_path::text FROM leases l JOIN admin_units u ON u.path = l.admin_path
		WHERE l.org_id = $1 ORDER BY u.name`, orgID)
	if err != nil {
		t.Fatal(err)
	}
	for rows.Next() {
		var c, p string
		_ = rows.Scan(&c, &p)
		where = append(where, struct{ City, Path string }{c, p})
	}
	rows.Close()
	if len(where) != 3 || where[0].City != "Brno" || where[1].City != "Ostrava" || where[2].City != "Praha" {
		t.Fatalf("leases located in %+v", where)
	}

	// Payment histories: Praha pays everything (tenant with BankID), Ostrava
	// pays the rent but not the deposit and gives notice, Brno pays nothing.
	e.bankID(tenants["Praha"], "Petra", "Pražská")
	pay := func(city string, kinds ...string) {
		var shares []share
		e.must(200, "GET", "/v1/leases/"+ids[city].String()+"/obligations", ownerTok, nil, &shares)
		for _, s := range shares {
			due, _ := time.Parse("2006-01-02", s.DueOn)
			if due.After(today) || s.PaidAmount >= s.Amount {
				continue
			}
			for _, k := range kinds {
				if s.Kind == k {
					e.must(204, "POST", orgPath+"/obligation-shares/"+s.ID.String()+"/paid", ownerTok, map[string]any{}, nil)
				}
			}
		}
	}
	pay("Praha", "deposit", "rent", "services")
	pay("Ostrava", "rent", "services")
	e.must(200, "POST", "/v1/leases/"+ids["Ostrava"].String()+"/notice", tenants["Ostrava"],
		map[string]string{"delivered_on": today.Format("2006-01-02")}, nil)

	if n, err := e.risk.RecomputeStale(ctx); err != nil || n < 3 {
		t.Fatalf("recompute: %d %v", n, err)
	}
	risk := func(city, tok string) leaseRiskDTO {
		var r leaseRiskDTO
		e.must(200, "GET", "/v1/leases/"+ids[city].String()+"/risk", tok, nil, &r)
		return r
	}
	praha, brno, ostrava := risk("Praha", ownerTok), risk("Brno", ownerTok), risk("Ostrava", ownerTok)
	if praha.Band != "low" || *praha.Score >= *ostrava.Score || *ostrava.Score >= *brno.Score {
		t.Fatalf("risks praha %d %s, ostrava %d %s, brno %d %s", *praha.Score, praha.Band, *ostrava.Score, ostrava.Band,
			*brno.Score, brno.Band)
	}
	explained := func(r leaseRiskDTO, key string) float64 {
		for _, f := range r.Factors {
			if f.Key == key {
				if f.Weight == nil || f.Points == nil {
					t.Fatalf("factor %s without weight for the owner", key)
				}
				return f.Value
			}
		}
		t.Fatalf("factor %s missing", key)
		return 0
	}
	if explained(brno, "debt") != 1 || explained(brno, "deposit_coverage") != 1 || explained(praha, "debt") != 0 {
		t.Fatalf("debt factors: brno %+v praha %+v", brno.Factors, praha.Factors)
	}
	if explained(ostrava, "notice") != 1 || explained(ostrava, "term_end") == 0 {
		t.Fatalf("contract factors: %+v", ostrava.Factors)
	}

	// A D+7 escalation (as the workflow timer fires it) raises the score.
	var oldest time.Time
	if err := e.pool.QueryRow(ctx, `SELECT min(o.due_on) FROM payment_obligations o JOIN obligation_splits s ON s.obligation_id = o.id
		WHERE o.lease_id = $1 AND s.paid_amount < s.amount AND o.due_on <= now()`, ids["Brno"]).Scan(&oldest); err != nil {
		t.Fatal(err)
	}
	if unpaid, err := (&leasing.Activities{S: e.leases}).Remind(ctx, ids["Brno"], oldest, "escalation"); err != nil || unpaid == 0 {
		t.Fatalf("escalation: %d %v", unpaid, err)
	}
	if _, err := e.risk.RecomputeStale(ctx); err != nil {
		t.Fatal(err)
	}
	after := risk("Brno", ownerTok)
	if *after.Score <= *brno.Score || explained(after, "escalations") == 0 || after.Band != "high" {
		t.Fatalf("escalation did not raise the score: %d -> %d (%s)", *brno.Score, *after.Score, after.Band)
	}

	// Tenants see the payment factors of their own lease, no score or weights.
	tr := risk("Brno", tenants["Brno"])
	if tr.Score != nil || tr.Landlord || len(tr.Factors) != 4 {
		t.Fatalf("tenant view %+v", tr)
	}
	for _, f := range tr.Factors {
		if f.Weight != nil || f.Points != nil || strings.HasPrefix(f.Key, "market") || f.Key == "passport" {
			t.Fatalf("tenant sees %+v", f)
		}
	}
	if code := e.call("GET", "/v1/leases/"+ids["Praha"].String()+"/risk", tenants["Brno"], nil, nil); code != 404 {
		t.Fatalf("tenant reads another lease's risk: %d", code)
	}

	// Dashboard: three municipalities, weighted risk, concentration, actions.
	var dash struct {
		WeightedRisk *int `json:"weighted_risk"`
		Leases       int  `json:"leases"`
		Cities       []struct {
			Name         string  `json:"name"`
			Monthly      int64   `json:"monthly"`
			Expected     int64   `json:"expected"`
			WeightedRisk *int    `json:"weighted_risk"`
			Band         string  `json:"band"`
			Share        float64 `json:"share"`
		} `json:"cities"`
		Concentration struct {
			TopCity *struct {
				Name  string  `json:"name"`
				Share float64 `json:"share"`
			} `json:"top_city"`
			HHI float64 `json:"hhi"`
		} `json:"concentration"`
		Attention []struct {
			Kind    string     `json:"kind"`
			LeaseID *uuid.UUID `json:"lease_id"`
		} `json:"attention"`
		Trend []struct {
			Period       string `json:"period"`
			Expected     int64  `json:"expected"`
			WeightedRisk *int   `json:"weighted_risk"`
		} `json:"trend"`
	}
	e.must(200, "GET", orgPath+"/portfolio", ownerTok, nil, &dash)
	if dash.Leases != 3 || len(dash.Cities) != 3 || dash.WeightedRisk == nil || len(dash.Trend) != 12 {
		t.Fatalf("dashboard %+v", dash)
	}
	if dash.Cities[0].Name != "Praha" || dash.Concentration.TopCity == nil || dash.Concentration.TopCity.Name != "Praha" ||
		dash.Concentration.HHI <= 0 {
		t.Fatalf("cities %+v concentration %+v", dash.Cities, dash.Concentration)
	}
	kinds := map[string]bool{}
	for _, a := range dash.Attention {
		kinds[a.Kind] = true
	}
	for _, k := range []string{"escalation", "debt", "notice", "high_risk"} {
		if !kinds[k] {
			t.Fatalf("attention lacks %s: %+v", k, dash.Attention)
		}
	}
	if last := dash.Trend[11]; last.WeightedRisk == nil || last.Expected == 0 {
		t.Fatalf("trend %+v", dash.Trend)
	}

	// Rent roll CSV: billed, paid and debt match each lease's ledger.
	var roll []byte
	if code := e.callRaw("GET", orgPath+"/portfolio/rent-roll?format=csv", ownerTok, &roll); code != 200 {
		t.Fatalf("csv %d", code)
	}
	recs, err := csv.NewReader(strings.NewReader(string(roll))).ReadAll()
	if err != nil || len(recs) != 4 {
		t.Fatalf("csv rows %d %v\n%s", len(recs), err, roll)
	}
	col := map[string]int{}
	for i, h := range recs[0] {
		col[h] = i
	}
	codes := map[string]uuid.UUID{}
	for city, id := range ids {
		var d leaseDetail
		e.must(200, "GET", "/v1/leases/"+id.String(), ownerTok, nil, &d)
		codes[fmt.Sprint(d.Lease.Code)] = id
		_ = city
	}
	for _, r := range recs[1:] {
		id := codes[r[col["lease_code"]]]
		var ledger []struct {
			Account  string `json:"account"`
			Amount   int64  `json:"amount"`
			BookedOn string `json:"booked_on"`
		}
		e.must(200, "GET", "/v1/leases/"+id.String()+"/ledger", ownerTok, nil, &ledger)
		var billed, paid int64
		for _, l := range ledger {
			booked, _ := time.Parse("2006-01-02", l.BookedOn)
			if l.Account != "receivable" || booked.After(today) {
				continue
			}
			if l.Amount > 0 {
				billed += l.Amount
			} else {
				paid -= l.Amount
			}
		}
		money := func(v int64) string { return fmt.Sprintf("%d.%02d", v/100, v%100) }
		if r[col["billed"]] != money(billed) || r[col["paid"]] != money(paid) || r[col["debt"]] != money(billed-paid) {
			t.Fatalf("%s: csv billed %s paid %s debt %s, ledger %s %s %s", r[col["municipality"]], r[col["billed"]], r[col["paid"]],
				r[col["debt"]], money(billed), money(paid), money(billed-paid))
		}
	}
	var xlsx []byte
	if code := e.callRaw("GET", orgPath+"/portfolio/rent-roll?format=xlsx", ownerTok, &xlsx); code != 200 || !strings.HasPrefix(string(xlsx), "PK") {
		t.Fatalf("xlsx %d", code)
	}

	// Groups and filters.
	var group struct {
		ID uuid.UUID `json:"id"`
	}
	e.must(201, "POST", orgPath+"/portfolio/groups", ownerTok, map[string]any{"name": "Morava – investiční", "color": "#0ea5e9",
		"lease_ids": []uuid.UUID{ids["Brno"], ids["Ostrava"]}}, &group)
	var rr rentRollDTO
	e.must(200, "GET", orgPath+"/portfolio/rent-roll?group_id="+group.ID.String(), ownerTok, nil, &rr)
	if len(rr.Rows) != 2 {
		t.Fatalf("group filter %+v", rr.Rows)
	}
	e.must(200, "GET", orgPath+"/portfolio/rent-roll?municipality="+where[0].Path, ownerTok, nil, &rr)
	if len(rr.Rows) != 1 || rr.Rows[0].Municipality != "Brno" {
		t.Fatalf("municipality filter %+v", rr.Rows)
	}

	// Rules per municipality and group reach new leases (terms read by the workflow).
	e.must(200, "PUT", orgPath+"/portfolio/rules", ownerTok, map[string]any{"municipality": where[0].Path,
		"rules": map[string]any{"escalation_days": 5, "notice_months": 2, "deposit_months": 3}}, nil)
	var p problem
	if code := e.call("PUT", orgPath+"/portfolio/rules", ownerTok, map[string]any{"municipality": where[0].Path,
		"rules": map[string]any{"deposit_months": 5}}, &p); code != 422 {
		t.Fatalf("deposit over the jurisdiction cap: %d %+v", code, p)
	}
	var resolved struct {
		Rules struct {
			EscalationDays int `json:"escalation_days"`
			DepositMonths  int `json:"deposit_months"`
		} `json:"rules"`
		Place string `json:"place"`
	}
	e.must(200, "GET", orgPath+"/portfolio/rules/resolve?address=Masarykova%2010%2C%20Brno", ownerTok, nil, &resolved)
	if resolved.Place != "Brno" || resolved.Rules.EscalationDays != 5 || resolved.Rules.DepositMonths != 3 {
		t.Fatalf("resolved %+v", resolved)
	}
	var draft leaseDetail
	e.must(201, "POST", orgPath+"/leases", ownerTok, map[string]any{"template": "byt_doba_neurcita", "starts_on": today.Format("2006-01-02"),
		"rent_amount": 1_500_000, "payee_iban": "CZ65 0800 0000 1920 0014 5399", "payee_name": "Rodinné investice s.r.o.",
		"property_address": "Masarykova 10, Brno", "parties": []map[string]any{{"name": "X", "email": uniqueEmail("x"), "role": "tenant"}}}, &draft)
	var notice int
	var terms []byte
	if err := e.pool.QueryRow(ctx, "SELECT notice_months, terms FROM leases WHERE id = $1", draft.Lease.ID).Scan(&notice, &terms); err != nil {
		t.Fatal(err)
	}
	if st := leasing.StagesFor(terms); notice != 2 || st[2].Offset != 5 || st[0].Offset != -3 {
		t.Fatalf("new lease notice %d stages %+v (%s)", notice, st, terms)
	}

	// The investor reads the portfolio with initials only and changes nothing.
	investor := uniqueEmail("investor")
	invTok := e.register(investor)
	e.must(201, "POST", orgPath+"/invitations", ownerTok, map[string]string{"email": investor, "role": "investor"}, nil)
	inv, ok := e.outbox.Last(investor, "invitation")
	if !ok {
		t.Fatal("no invitation")
	}
	e.must(200, "POST", "/v1/invitations/"+notify.LinkToken(inv.Text)+"/accept", invTok, nil, nil)
	e.must(200, "GET", orgPath+"/portfolio", invTok, nil, nil)
	e.must(200, "GET", orgPath+"/portfolio/rent-roll", invTok, nil, &rr)
	if rr.Role != "investor" || rr.Totals.Leases != 3 {
		t.Fatalf("investor rent roll %+v", rr)
	}
	for _, row := range rr.Rows {
		if row.Tenants != nil && strings.Contains(*row.Tenants, "Nájemce") {
			t.Fatalf("investor sees the tenant name %q", *row.Tenants)
		}
	}
	for _, c := range []struct{ method, path string }{
		{"POST", orgPath + "/portfolio/groups"},
		{"PUT", orgPath + "/portfolio/risk-weights"},
		{"PUT", orgPath + "/portfolio/rules"},
		{"DELETE", orgPath + "/portfolio/groups/" + group.ID.String()},
	} {
		body := map[string]any{"name": "x", "weights": map[string]int{"debt": 1}, "rules": map[string]any{}, "municipality": where[0].Path}
		if code := e.call(c.method, c.path, invTok, body, &p); code != 403 {
			t.Fatalf("investor %s %s: %d", c.method, c.path, code)
		}
	}
	if code := e.call("GET", orgPath+"/leases", invTok, nil, nil); code != 403 {
		t.Fatalf("investor lists leases: %d", code)
	}
	if code := e.call("POST", orgPath+"/obligation-shares/"+uuid.NewString()+"/paid", invTok, map[string]any{}, nil); code == 204 {
		t.Fatal("investor marks a payment")
	}

	// Weights: switching every factor but debt off rescores the leases.
	w := map[string]int{"debt": 10}
	for _, k := range []string{"escalations", "overdue_days", "deposit_coverage", "passport", "term_end", "notice", "joint_nonpayer", "market_rent", "market_supply"} {
		w[k] = 0
	}
	e.must(200, "PUT", orgPath+"/portfolio/risk-weights", ownerTok, map[string]any{"weights": w}, nil)
	if r := risk("Brno", ownerTok); *r.Score != 100 {
		t.Fatalf("debt-only score %d", *r.Score)
	}
	if r := risk("Praha", ownerTok); *r.Score != 0 {
		t.Fatalf("debt-only score of a payer %d", *r.Score)
	}

	// AI summary: a suggestion from aggregates only.
	var sum struct {
		Summary string   `json:"summary"`
		Actions []string `json:"actions"`
		Model   string   `json:"model"`
	}
	e.must(201, "POST", orgPath+"/portfolio/summary", ownerTok, nil, &sum)
	if sum.Summary == "" || len(sum.Actions) == 0 || strings.Contains(sum.Summary, "Nájemce") {
		t.Fatalf("summary %+v", sum)
	}
	var latest struct {
		Summary *struct {
			Model string `json:"model"`
		} `json:"summary"`
	}
	e.must(200, "GET", orgPath+"/portfolio/summary", invTok, nil, &latest)
	if latest.Summary == nil || latest.Summary.Model != sum.Model {
		t.Fatalf("latest summary %+v", latest)
	}
}
