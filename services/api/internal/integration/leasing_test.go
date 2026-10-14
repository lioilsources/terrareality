package integration

import (
	"context"
	"errors"
	"os/exec"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/terrareality/terrareality/services/api/internal/leasing"
)

type leaseDetail struct {
	Lease struct {
		ID    uuid.UUID `json:"id"`
		Code  int64     `json:"code"`
		State string    `json:"state"`
	} `json:"lease"`
	Parties []struct {
		ID       uuid.UUID  `json:"id"`
		Role     string     `json:"role"`
		ShareBps int        `json:"share_bps"`
		Position int        `json:"position"`
		Me       bool       `json:"me"`
		SignedAt *time.Time `json:"signed_at"`
		Debt     *int64     `json:"debt"`
	} `json:"parties"`
	Documents []struct {
		Kind   string `json:"kind"`
		Sha256 string `json:"sha256"`
		URL    string `json:"url"`
	} `json:"documents"`
	TotalDebt int64 `json:"total_debt"`
}

type share struct {
	ID         uuid.UUID `json:"id"`
	Kind       string    `json:"kind"`
	Period     string    `json:"period"`
	DueOn      string    `json:"due_on"`
	Amount     int64     `json:"amount"`
	PaidAmount int64     `json:"paid_amount"`
	PartyID    uuid.UUID `json:"party_id"`
	Mine       bool      `json:"mine"`
	Status     string    `json:"status"`
	SPAYD      *string   `json:"spayd"`
}

// Acceptance M6: a landlord and two flatmates; joint tenancy -> both sign
// (mock) -> a schedule split 50/50 -> QR -> a simulated bank transaction is
// matched -> debt 0; the hash chain verifies.
func TestLeaseAcceptance(t *testing.T) {
	if _, err := exec.LookPath("typst"); err != nil {
		t.Skip("typst not installed")
	}
	e := newEnv(t)
	ownerTok, orgID := e.ownerOrg("lease-owner")
	anna, ben := uniqueEmail("anna"), uniqueEmail("ben")
	annaTok, benTok := e.register(anna), e.register(ben)
	stranger := e.register(uniqueEmail("stranger"))
	today := time.Now().UTC()
	start := today.Format("2006-01-02")
	end := today.AddDate(1, 0, -1).Format("2006-01-02")
	lpath := "/v1/orgs/" + orgID.String() + "/leases"

	base := map[string]any{"template": "spolecny_najem", "starts_on": start, "ends_on": end, "rent_amount": 2_000_000,
		"services_amount": 400_000, "deposit_amount": 4_000_000, "due_day": 15, "payee_iban": "CZ65 0800 0000 1920 0014 5399",
		"payee_name": "Lucie Pronajímatelka", "property_address": "Dejvická 12, Praha 6", "unit_label": "3+kk",
		"clauses": []string{"no_smoking", "inventory"},
		"parties": []map[string]any{{"name": "Anna Nováková", "email": anna, "role": "co_tenant"},
			{"name": "Ben Dvořák", "email": ben, "role": "co_tenant"}}}

	// Validation: the deposit is capped at 3 months of rent; joint tenancy needs two tenants.
	var p problem
	tooHigh := clone(base, "deposit_amount", 7_000_000)
	if code := e.call("POST", lpath, ownerTok, tooHigh, &p); code != 422 || p.Code != "deposit_too_high" {
		t.Fatalf("deposit cap: %d %+v", code, p)
	}
	single := clone(base, "parties", []map[string]any{{"name": "Anna", "email": anna, "role": "co_tenant"}})
	if code := e.call("POST", lpath, ownerTok, single, &p); code != 422 || p.Code != "joint_needs_two" {
		t.Fatalf("joint tenancy: %d %+v", code, p)
	}

	var d leaseDetail
	e.must(201, "POST", lpath, ownerTok, base, &d)
	id := d.Lease.ID
	if d.Lease.State != "draft" || len(d.Parties) != 3 || d.Parties[1].ShareBps != 5000 || d.Parties[2].ShareBps != 5000 {
		t.Fatalf("draft %+v", d)
	}
	if code := e.call("GET", "/v1/leases/"+id.String(), stranger, nil, nil); code != 404 {
		t.Fatalf("stranger reads lease: %d", code)
	}
	e.must(200, "POST", lpath+"/"+id.String()+"/propose", ownerTok, nil, &d)
	if d.Lease.State != "proposed" || len(d.Documents) != 1 || d.Documents[0].Kind != "final" {
		t.Fatalf("proposed %+v", d)
	}
	key := strings.TrimPrefix(d.Documents[0].URL, "http://blob.test/")
	pdf, err := e.blob.Get(context.Background(), key[:strings.Index(key, "?")])
	if err != nil || !strings.HasPrefix(string(pdf), "%PDF") {
		t.Fatalf("document: %v", err)
	}
	if _, ok := e.outbox.Last(anna, "lease_proposed"); !ok {
		t.Fatal("no proposal e-mail")
	}

	// Negotiation: Anna asks for a change, the landlord edits and proposes again.
	e.must(204, "POST", "/v1/leases/"+id.String()+"/request-changes", annaTok, map[string]string{"comment": "Prosíme povolit kočku."}, nil)
	withPets := clone(base, "clauses", []string{"no_smoking", "inventory", "pets_allowed"})
	e.must(200, "PUT", lpath+"/"+id.String(), ownerTok, withPets, nil)
	e.must(200, "POST", lpath+"/"+id.String()+"/propose", ownerTok, nil, &d)
	if len(d.Documents) != 2 {
		t.Fatalf("documents after re-proposal %+v", d.Documents)
	}

	// Everyone signs (mock); the last signature makes the schedule.
	sign := map[string]string{"provider": "mock"}
	e.must(200, "POST", "/v1/leases/"+id.String()+"/sign", annaTok, sign, nil)
	if code := e.call("POST", "/v1/leases/"+id.String()+"/sign", annaTok, sign, &p); code != 409 {
		t.Fatalf("double signature: %d", code)
	}
	if code := e.call("POST", "/v1/leases/"+id.String()+"/sign", stranger, sign, nil); code != 404 {
		t.Fatalf("stranger signs: %d", code)
	}
	e.must(200, "POST", "/v1/leases/"+id.String()+"/sign", benTok, sign, nil)
	e.must(200, "POST", "/v1/leases/"+id.String()+"/sign", ownerTok, sign, nil)
	e.must(200, "GET", "/v1/leases/"+id.String(), annaTok, nil, &d)
	if d.Lease.State != "signed" || len(e.leaseJob.started) != 1 {
		t.Fatalf("after signatures: %s, workflows %d", d.Lease.State, len(e.leaseJob.started))
	}

	// Schedule: the deposit and every month the lease touches (13 for a year
	// starting mid-month; no proration in v0), each split 50/50.
	var shares []share
	e.must(200, "GET", "/v1/leases/"+id.String()+"/obligations", annaTok, nil, &shares)
	if len(shares) != 2*14 {
		t.Fatalf("shares %d", len(shares))
	}
	var mine []share
	for _, s := range shares {
		if s.Kind == "rent" && s.Amount != 1_200_000 {
			t.Fatalf("rent share %+v", s)
		}
		if s.Kind == "deposit" && s.Amount != 2_000_000 {
			t.Fatalf("deposit share %+v", s)
		}
		if s.Mine {
			mine = append(mine, s)
			if s.SPAYD == nil || !strings.Contains(*s.SPAYD, "X-VS:") || !strings.Contains(*s.SPAYD, "X-SS:1") {
				t.Fatalf("qr %+v", s)
			}
		} else if s.SPAYD != nil {
			t.Fatal("QR of another tenant's share")
		}
	}
	var png []byte
	if code := e.callRaw("GET", "/v1/obligation-shares/"+mine[0].ID.String()+"/qr", annaTok, &png); code != 200 || !strings.HasPrefix(string(png), "\x89PNG") {
		t.Fatalf("qr png: %d", code)
	}

	// Debt today: the deposit and the first month (both due on the start date).
	if d.TotalDebt != 4_000_000+2_400_000 {
		t.Fatalf("debt before payments %d", d.TotalDebt)
	}

	// The landlord links the (mock) bank; payments arrive.
	var link struct {
		Connection struct {
			ID     uuid.UUID `json:"id"`
			Status string    `json:"status"`
		} `json:"connection"`
	}
	e.must(201, "POST", "/v1/orgs/"+orgID.String()+"/bank/connections", ownerTok, map[string]string{"redirect_uri": "http://web.test/bank"}, &link)
	if link.Connection.Status != "linked" {
		t.Fatalf("bank %+v", link)
	}
	conn, _ := e.leases.Pool.Query(context.Background(), "SELECT account_id FROM bank_connections WHERE id = $1", link.Connection.ID)
	var account string
	for conn.Next() {
		_ = conn.Scan(&account)
	}
	conn.Close()
	vs := strings.TrimSpace(strings.Split(strings.Split(*mine[0].SPAYD, "X-VS:")[1], "*")[0])
	// Anna pays her deposit and rent shares with VS and SS: matched automatically.
	e.bank.Add(account, leasing.Transaction{ExternalID: "t1", BookedOn: today, Amount: 2_000_000, Currency: "CZK",
		VariableSymbol: vs, SpecificSymbol: "1", CounterpartyName: "Anna Nováková"})
	e.bank.Add(account, leasing.Transaction{ExternalID: "t1b", BookedOn: today, Amount: 1_200_000, Currency: "CZK",
		VariableSymbol: vs, SpecificSymbol: "1", CounterpartyName: "Anna Nováková"})
	// Ben pays the rent with symbols, the deposit without: only a suggestion.
	e.bank.Add(account, leasing.Transaction{ExternalID: "t2", BookedOn: today, Amount: 1_200_000, Currency: "CZK",
		VariableSymbol: vs, SpecificSymbol: "2", CounterpartyName: "Ben Dvořák"})
	e.bank.Add(account, leasing.Transaction{ExternalID: "t2b", BookedOn: today, Amount: 2_000_000, Currency: "CZK",
		CounterpartyName: "Ben Dvořák"})
	// An outgoing payment is ignored.
	e.bank.Add(account, leasing.Transaction{ExternalID: "t3", BookedOn: today, Amount: -50_000, Currency: "CZK"})
	var sync struct {
		New, Matched, Suggested int
	}
	e.must(200, "POST", "/v1/orgs/"+orgID.String()+"/bank/sync", ownerTok, nil, &sync)
	if sync.New != 5 || sync.Matched != 3 || sync.Suggested != 1 {
		t.Fatalf("sync %+v", sync)
	}
	e.must(200, "POST", "/v1/orgs/"+orgID.String()+"/bank/sync", ownerTok, nil, &sync)
	if sync.New != 0 {
		t.Fatalf("second sync imported again: %+v", sync)
	}
	var overview struct {
		Transactions []struct {
			ID          uuid.UUID  `json:"id"`
			MatchStatus string     `json:"match_status"`
			ShareID     *uuid.UUID `json:"share_id"`
		} `json:"transactions"`
	}
	e.must(200, "GET", "/v1/orgs/"+orgID.String()+"/bank?status=suggested", ownerTok, nil, &overview)
	if len(overview.Transactions) != 1 || overview.Transactions[0].ShareID == nil {
		t.Fatalf("suggestions %+v", overview)
	}
	e.must(204, "POST", "/v1/orgs/"+orgID.String()+"/bank/transactions/"+overview.Transactions[0].ID.String()+"/match", ownerTok,
		map[string]any{"share_id": overview.Transactions[0].ShareID}, nil)
	e.must(200, "GET", "/v1/leases/"+id.String(), benTok, nil, &d)
	if d.TotalDebt != 0 {
		t.Fatalf("debt after payments %d", d.TotalDebt)
	}

	// Ledger: every posting balances; CSV export works.
	var ledger []struct {
		PostingID uuid.UUID `json:"posting_id"`
		Amount    int64     `json:"amount"`
	}
	e.must(200, "GET", "/v1/leases/"+id.String()+"/ledger", ownerTok, nil, &ledger)
	sums := map[uuid.UUID]int64{}
	for _, l := range ledger {
		sums[l.PostingID] += l.Amount
	}
	for pid, sum := range sums {
		if sum != 0 {
			t.Fatalf("posting %s unbalanced: %d", pid, sum)
		}
	}
	var csv []byte
	if code := e.callRaw("GET", "/v1/leases/"+id.String()+"/ledger?format=csv", annaTok, &csv); code != 200 || !strings.HasPrefix(string(csv), "booked_on,") {
		t.Fatalf("csv %d %q", code, csv)
	}

	// The event log verifies; tampering is detected.
	var log struct {
		Events []struct {
			Kind string `json:"kind"`
		} `json:"events"`
		Valid    bool   `json:"valid"`
		Verified int    `json:"verified"`
		Head     string `json:"head"`
	}
	e.must(200, "GET", "/v1/leases/"+id.String()+"/events", benTok, nil, &log)
	kinds := []string{}
	for _, ev := range log.Events {
		kinds = append(kinds, ev.Kind)
	}
	if !log.Valid || log.Verified != len(log.Events) || !strings.Contains(strings.Join(kinds, ","), "fully_signed") ||
		strings.Count(strings.Join(kinds, ","), "payment_recorded") != 4 {
		t.Fatalf("event log %+v", log)
	}
	if _, err := e.pool.Exec(context.Background(), `UPDATE lease_events SET payload = jsonb_set(payload, '{data,rent}', '1') WHERE lease_id = $1 AND seq = 1`, id); err != nil {
		t.Fatal(err)
	}
	e.must(200, "GET", "/v1/leases/"+id.String()+"/events", benTok, nil, &log)
	if log.Valid || log.Verified != 0 {
		t.Fatalf("tampering not detected: %+v", log.Valid)
	}
	var appErr error
	if _, err := e.pool.Exec(context.Background(), `SET ROLE terra_app; UPDATE lease_events SET kind = 'x' WHERE lease_id = $1`, id); err == nil {
		appErr = errors.New("app role may update events")
	}
	_, _ = e.pool.Exec(context.Background(), "RESET ROLE")
	if appErr != nil {
		t.Fatal(appErr)
	}
}

func clone(m map[string]any, k string, v any) map[string]any {
	out := map[string]any{}
	for kk, vv := range m {
		out[kk] = vv
	}
	out[k] = v
	return out
}
