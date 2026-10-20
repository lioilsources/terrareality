package integration

import (
	"context"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/terrareality/terrareality/services/api/internal/leasing"
	"github.com/terrareality/terrareality/services/api/internal/notify"
)

type importedDetail struct {
	Lease struct {
		ID             uuid.UUID `json:"id"`
		Code           int64     `json:"code"`
		State          string    `json:"state"`
		Origin         string    `json:"origin"`
		CutoverOn      string    `json:"cutover_on"`
		VariableSymbol *string   `json:"variable_symbol"`
	} `json:"lease"`
	Parties []struct {
		ID         uuid.UUID  `json:"id"`
		Role       string     `json:"role"`
		Name       string     `json:"name"`
		Position   int        `json:"position"`
		HasAccount bool       `json:"has_account"`
		InvitedAt  *time.Time `json:"invited_at"`
	} `json:"parties"`
	Documents []struct {
		Kind string `json:"kind"`
	} `json:"documents"`
	DepositHeld     bool    `json:"deposit_held"`
	ContractScanURL *string `json:"contract_scan_url"`
	TotalDebt       int64   `json:"total_debt"`
}

// mockAccount links the mock bank for an organization and returns its account id.
func (e *env) mockAccount(tok string, orgID uuid.UUID) string {
	e.t.Helper()
	var link struct {
		Connection struct {
			ID uuid.UUID `json:"id"`
		} `json:"connection"`
	}
	e.must(201, "POST", "/v1/orgs/"+orgID.String()+"/bank/connections", tok, map[string]string{"redirect_uri": "http://web.test/bank"}, &link)
	var account string
	if err := e.pool.QueryRow(context.Background(), "SELECT account_id FROM bank_connections WHERE id = $1", link.Connection.ID).Scan(&account); err != nil {
		e.t.Fatal(err)
	}
	return account
}

// M9 acceptance: a lease running on paper since 2024 is imported. It is
// active at once, nothing before the cutover is owed, the risk stays low,
// tenants without an accepted invitation hear nothing (the landlord still
// gets the escalation), a payment with the tenants' own variable symbol is
// matched within the organization only, and another organization cannot see
// the lease. After the invitation the tenant is linked and reminded.
func TestImportExistingLease(t *testing.T) {
	e := newEnv(t)
	ctx := context.Background()
	ownerTok, orgID := e.ownerOrg("paper-owner")
	ownerEmail := e.emailOf(ownerTok)
	otherTok, otherOrg := e.ownerOrg("paper-other")
	eva, ben := uniqueEmail("eva"), uniqueEmail("ben")
	// Ben has a verified account with the address the landlord typed in, but
	// was never invited: he must not be linked or contacted.
	benTok := e.register(ben)
	e.verifyEmail(ben)
	e.pushDevice(benTok)
	benID := e.userID(benTok)
	lpath := "/v1/orgs/" + orgID.String() + "/leases"

	body := map[string]any{"template": "spolecny_najem", "starts_on": "2024-03-01", "rent_amount": 1_800_000,
		"services_amount": 350_000, "deposit_amount": 3_600_000, "deposit_held": true, "due_day": 1,
		"payee_iban": "CZ65 0800 0000 1920 0014 5399", "payee_name": "Jana Nováková",
		"property_address": "Dejvická 12, Praha 6", "unit_label": "2+kk", "variable_symbol": "001203",
		"parties": []map[string]any{
			{"name": "Eva Malá", "email": eva, "role": "co_tenant", "opening_balance": 650_000},
			{"name": "Ben Velký", "email": ben, "role": "co_tenant"}}}
	var d importedDetail
	e.must(201, "POST", lpath+"/import", ownerTok, body, &d)
	id := d.Lease.ID
	now := time.Now().In(time.FixedZone("CET", 3600))
	cutover := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, time.UTC).AddDate(0, 1, 0)
	if d.Lease.State != "active" || d.Lease.Origin != "imported" || d.Lease.VariableSymbol == nil || *d.Lease.VariableSymbol != "1203" ||
		!d.DepositHeld || d.TotalDebt != 0 || len(d.Documents) != 0 {
		t.Fatalf("imported %+v", d)
	}
	// The default cutover is the first day of next month (Prague; tolerate the
	// midnight between the two clocks).
	if c, _ := time.Parse("2006-01-02", d.Lease.CutoverOn); c.Day() != 1 || c.Before(cutover.AddDate(0, -1, 0)) || c.After(cutover) {
		t.Fatalf("cutover %s", d.Lease.CutoverOn)
	} else {
		cutover = c
	}
	for _, p := range d.Parties {
		if p.Role != "landlord" && (p.HasAccount || p.InvitedAt != nil) {
			t.Fatalf("party linked at import: %+v", p)
		}
	}
	if len(e.leaseJob.started) != 1 || e.leaseJob.started[0] != id {
		t.Fatalf("lifecycle not started: %v", e.leaseJob.started)
	}
	var evaParty, benParty uuid.UUID
	for _, p := range d.Parties {
		switch p.Name {
		case "Eva Malá":
			evaParty = p.ID
		case "Ben Velký":
			benParty = p.ID
		}
	}

	// The same symbol cannot be used by another lease of the organization.
	var p problem
	if code := e.call("POST", lpath+"/import", ownerTok, clone(body, "variable_symbol", "1203"), &p); code != 409 || p.Code != "variable_symbol_taken" {
		t.Fatalf("duplicate symbol: %d %+v", code, p)
	}
	if code := e.call("POST", lpath+"/import", ownerTok, clone(body, "cutover_on", "2024-03-01"), &p); code != 422 || p.Code != "cutover_too_old" {
		t.Fatalf("old cutover: %d %+v", code, p)
	}

	// Schedule: nothing before the cutover, no deposit, the opening balance
	// due on the cutover; QR payments carry the tenants' symbol.
	var shares []share
	e.must(200, "GET", "/v1/leases/"+id.String()+"/obligations", ownerTok, nil, &shares)
	opening := 0
	for _, s := range shares {
		due, _ := time.Parse("2006-01-02", s.DueOn)
		if due.Before(cutover) {
			t.Fatalf("obligation before the cutover: %+v", s)
		}
		if s.Kind == "deposit" {
			t.Fatalf("held deposit scheduled: %+v", s)
		}
		if s.Kind == "opening_balance" {
			opening++
			if s.PartyID != evaParty || s.Amount != 650_000 || !due.Equal(cutover) {
				t.Fatalf("opening balance %+v", s)
			}
		}
		if s.SPAYD == nil || !strings.Contains(*s.SPAYD, "X-VS:1203*") || strings.Contains(*s.SPAYD, "X-VS:26") {
			t.Fatalf("qr %+v", s)
		}
	}
	if opening != 1 || len(shares) != 1+2*leasing.IndefiniteHorizon {
		t.Fatalf("shares %d, opening %d", len(shares), opening)
	}
	var overdue int
	if err := e.pool.QueryRow(ctx, `SELECT count(*) FROM payment_obligations WHERE lease_id = $1 AND due_on < $2`, id, cutover).Scan(&overdue); err != nil || overdue != 0 {
		t.Fatalf("obligations before the cutover: %d %v", overdue, err)
	}

	// The ledger balances, the held deposit is no receivable.
	var unbalanced, heldReceivable int
	if err := e.pool.QueryRow(ctx, `SELECT count(*) FROM (SELECT posting_id FROM ledger_entries WHERE lease_id = $1
		GROUP BY posting_id HAVING sum(amount) <> 0) x`, id).Scan(&unbalanced); err != nil || unbalanced != 0 {
		t.Fatalf("unbalanced postings %d %v", unbalanced, err)
	}
	if err := e.pool.QueryRow(ctx, `SELECT count(*) FROM ledger_entries WHERE lease_id = $1 AND account = 'deposit_held' AND amount = -3600000
		AND memo = 'deposit held before cutover'`, id).Scan(&heldReceivable); err != nil || heldReceivable != 1 {
		t.Fatalf("held deposit posting %d %v", heldReceivable, err)
	}

	// Risk: no debt, no overdue days, the held deposit covers; low band.
	res, err := e.risk.Recompute(ctx, id)
	if err != nil {
		t.Fatal(err)
	}
	for _, f := range res.Factors {
		switch f.Key {
		case "debt", "overdue_days", "escalations", "deposit_coverage", "joint_nonpayer":
			if f.Value != 0 {
				t.Fatalf("risk factor %s raised: %+v", f.Key, f)
			}
		}
	}
	if res.Band != "low" {
		t.Fatalf("risk %d %s", res.Score, res.Band)
	}

	// The event log says it was signed outside the platform and verifies.
	var log struct {
		Events []struct {
			Kind    string         `json:"kind"`
			Payload map[string]any `json:"payload"`
		} `json:"events"`
		Valid bool `json:"valid"`
	}
	e.must(200, "GET", "/v1/leases/"+id.String()+"/events", ownerTok, nil, &log)
	if !log.Valid || len(log.Events) != 1 || log.Events[0].Kind != "imported" ||
		log.Events[0].Payload["data"].(map[string]any)["signed_outside_platform"] != true {
		t.Fatalf("event log %+v", log)
	}

	// Ben opens the lease: not invited, so not linked.
	if code := e.call("GET", "/v1/leases/"+id.String(), benTok, nil, nil); code != 404 {
		t.Fatalf("uninvited tenant reads the lease: %d", code)
	}

	// Escalation of the cutover day: Eva owes the opening balance and both owe
	// rent. No tenant mail or push; the landlord is told as usual.
	act := &leasing.Activities{S: e.leases}
	if unpaid, err := act.Remind(ctx, id, cutover, "escalation"); err != nil || unpaid != 3 {
		t.Fatalf("remind %d %v", unpaid, err)
	}
	for _, em := range []string{eva, ben} {
		if ms := e.outbox.All(em, "payment_escalation"); len(ms) != 0 {
			t.Fatalf("tenant without an accepted invitation e-mailed: %s %+v", em, ms)
		}
	}
	if ps := e.pusher.of(benID, notify.PushObligation); len(ps) != 0 {
		t.Fatalf("tenant without an accepted invitation pushed: %+v", ps)
	}
	if _, ok := e.outbox.Last(ownerEmail, "payment_escalation_landlord"); !ok {
		t.Fatal("landlord not told about the escalation")
	}

	// Another organization sees nothing and cannot act on the lease.
	if code := e.call("GET", "/v1/leases/"+id.String(), otherTok, nil, nil); code != 404 {
		t.Fatalf("other organization reads the lease: %d", code)
	}
	if code := e.call("GET", "/v1/leases/"+id.String()+"/obligations", otherTok, nil, nil); code != 404 {
		t.Fatalf("other organization reads the schedule: %d", code)
	}
	var list []struct {
		ID uuid.UUID `json:"id"`
	}
	e.must(200, "GET", "/v1/orgs/"+otherOrg.String()+"/leases", otherTok, nil, &list)
	for _, l := range list {
		if l.ID == id {
			t.Fatal("imported lease listed for another organization")
		}
	}
	if code := e.call("POST", lpath+"/import", otherTok, clone(body, "variable_symbol", "9"), nil); code != 403 && code != 404 {
		t.Fatalf("other organization imports into this one: %d", code)
	}
	if code := e.call("POST", lpath+"/"+id.String()+"/parties/"+benParty.String()+"/invite", otherTok, nil, nil); code != 404 {
		t.Fatalf("other organization invites: %d", code)
	}

	// Payments with the tenants' symbol: matched in this organization (leading
	// zeros dropped by the bank or not); the same symbol at another
	// organization's account matches nothing.
	account := e.mockAccount(ownerTok, orgID)
	e.bank.Add(account, leasing.Transaction{ExternalID: "paper-1", BookedOn: cutover, Amount: 650_000, Currency: "CZK",
		VariableSymbol: "0001203", SpecificSymbol: "1", CounterpartyName: "Eva Malá"})
	var sync struct{ New, Matched, Suggested int }
	e.must(200, "POST", "/v1/orgs/"+orgID.String()+"/bank/sync", ownerTok, nil, &sync)
	if sync.New != 1 || sync.Matched != 1 {
		t.Fatalf("sync %+v", sync)
	}
	var paid int64
	if err := e.pool.QueryRow(ctx, `SELECT s.paid_amount FROM obligation_splits s JOIN payment_obligations o ON o.id = s.obligation_id
		WHERE o.lease_id = $1 AND o.kind = 'opening_balance'`, id).Scan(&paid); err != nil || paid != 650_000 {
		t.Fatalf("opening balance paid %d %v", paid, err)
	}
	otherAccount := e.mockAccount(otherTok, otherOrg)
	e.bank.Add(otherAccount, leasing.Transaction{ExternalID: "paper-2", BookedOn: cutover, Amount: 1_075_000, Currency: "CZK",
		VariableSymbol: "1203", SpecificSymbol: "2"})
	e.must(200, "POST", "/v1/orgs/"+otherOrg.String()+"/bank/sync", otherTok, nil, &sync)
	if sync.New != 1 || sync.Matched != 0 || sync.Suggested != 0 {
		t.Fatalf("symbol matched across organizations: %+v", sync)
	}

	// The scan of the paper contract.
	var up struct {
		Key       string `json:"key"`
		UploadURL string `json:"upload_url"`
	}
	e.must(201, "POST", lpath+"/"+id.String()+"/contract-scan", ownerTok, map[string]any{"content_type": "application/pdf", "size_bytes": 64}, &up)
	if err := e.blob.Put(ctx, up.Key, "application/pdf", []byte("%PDF-1.4\n% paper contract scan\n%%EOF\n")); err != nil {
		t.Fatal(err)
	}
	if code := e.call("POST", lpath+"/"+id.String()+"/contract-scan/complete", ownerTok,
		map[string]any{"key": "leases/" + uuid.NewString() + "/scan-x", "filename": "x.pdf"}, &p); code != 404 {
		t.Fatalf("foreign key accepted: %d", code)
	}
	e.must(200, "POST", lpath+"/"+id.String()+"/contract-scan/complete", ownerTok, map[string]any{"key": up.Key, "filename": "smlouva.exe"}, &d)
	if d.ContractScanURL == nil || !strings.Contains(*d.ContractScanURL, "smlouva.pdf") || len(d.Documents) != 1 || d.Documents[0].Kind != "scan" {
		t.Fatalf("scan %+v", d)
	}

	// The landlord invites Ben; once he signs in he is linked and reminded,
	// Eva (not invited) still gets nothing.
	e.must(200, "POST", lpath+"/"+id.String()+"/parties/"+benParty.String()+"/invite", ownerTok, map[string]any{}, &d)
	inv, ok := e.outbox.Last(ben, "lease_invitation")
	if !ok || !strings.Contains(inv.Text, "http://web.test/smlouvy/"+id.String()) {
		t.Fatalf("invitation %+v", inv)
	}
	if code := e.call("POST", lpath+"/"+id.String()+"/parties/"+evaParty.String()+"/invite", ownerTok,
		map[string]any{"email": "not-an-email"}, nil); code != 400 && code != 422 {
		t.Fatalf("invalid invitation e-mail: %d", code)
	}
	e.must(200, "GET", "/v1/leases/"+id.String(), benTok, nil, &d)
	if code := e.call("POST", lpath+"/"+id.String()+"/parties/"+benParty.String()+"/invite", ownerTok, nil, &p); code != 409 || p.Code != "party_linked" {
		t.Fatalf("re-invite a linked tenant: %d %+v", code, p)
	}
	if _, err := act.Remind(ctx, id, cutover, "overdue"); err != nil {
		t.Fatal(err)
	}
	m, ok := e.outbox.Last(ben, "payment_overdue")
	if !ok || !strings.Contains(m.Text, "VS 1203") {
		t.Fatalf("linked tenant not reminded with the symbol: %+v", m)
	}
	if len(e.outbox.All(eva, "payment_overdue")) != 0 {
		t.Fatal("uninvited tenant reminded")
	}
}

// terractl leases import: the CSV is parsed and checked, a dry run writes
// nothing, the real run imports all leases in one transaction for the
// owner, and a batch with one bad lease writes none.
func TestImportLeasesCSV(t *testing.T) {
	e := newEnv(t)
	ctx := context.Background()
	ownerTok, orgID := e.ownerOrg("csv-owner")
	ownerID := e.userID(ownerTok)
	csv := strings.Join(leasing.ImportColumns, ",") + "\n" +
		`a1,"Dejvická 12, Praha 6",,2+kk,,2024-03-01,,18000,3500,36000,ano,5,3,CZ65 0800 0000 1920 0014 5399,Jana Nováková,555,,Petr Svoboda,,,1200` + "\n" +
		`b2,"Vinohradská 40, Praha 2",,3+1,spolecny_najem,1.9.2025,31.8.2027,26000,5000,0,,15,,CZ6508000000192000145399,Jana Nováková,,,Eva Malá,eva@example.cz,60,` + "\n" +
		`b2,,,,,,,,,,,,,,,,,Tomáš Velký,,40,` + "\n"
	today := time.Now()
	leases, errs := leasing.ParseImportCSV(strings.NewReader(csv), 3, today)
	if len(errs) > 0 || len(leases) != 2 {
		t.Fatalf("parse %v %+v", errs, leases)
	}
	count := func() int {
		var n int
		if err := e.pool.QueryRow(ctx, "SELECT count(*) FROM leases WHERE org_id = $1 AND origin = 'imported'", orgID).Scan(&n); err != nil {
			t.Fatal(err)
		}
		return n
	}

	res, err := e.leases.ImportBatch(ctx, orgID, &ownerID, leases, true)
	if err != nil || len(res) != 2 || res[0].Ref != "a1" || res[0].State != "active" {
		t.Fatalf("dry run %+v %v", res, err)
	}
	if n := count(); n != 0 || len(e.leaseJob.started) != 0 {
		t.Fatalf("dry run wrote %d leases, %d workflows", n, len(e.leaseJob.started))
	}

	res, err = e.leases.ImportBatch(ctx, orgID, &ownerID, leases, false)
	if err != nil || len(res) != 2 {
		t.Fatalf("import %+v %v", res, err)
	}
	if n := count(); n != 2 || len(e.leaseJob.started) != 2 {
		t.Fatalf("imported %d leases, %d workflows", n, len(e.leaseJob.started))
	}
	// The operator acted for the owner: landlord party linked to the owner,
	// no user actor in the audit, source terractl.
	var landlord *uuid.UUID
	if err := e.pool.QueryRow(ctx, "SELECT user_id FROM lease_parties WHERE lease_id = $1 AND role = 'landlord'", res[0].ID).Scan(&landlord); err != nil ||
		landlord == nil || *landlord != ownerID {
		t.Fatalf("landlord party %v %v", landlord, err)
	}
	var audits int
	if err := e.pool.QueryRow(ctx, `SELECT count(*) FROM audit_events WHERE org_id = $1 AND action = 'lease.import'
		AND actor_id IS NULL AND diff->>'source' = 'terractl'`, orgID).Scan(&audits); err != nil || audits != 2 {
		t.Fatalf("audit %d %v", audits, err)
	}
	var d importedDetail
	e.must(200, "GET", "/v1/leases/"+res[1].ID.String(), ownerTok, nil, &d)
	if d.Lease.Origin != "imported" || len(d.Parties) != 3 || d.Lease.VariableSymbol != nil {
		t.Fatalf("csv lease %+v", d)
	}
	// Opening balance of 1 200 Kč on the first lease, owed from the cutover.
	var opening int64
	if err := e.pool.QueryRow(ctx, "SELECT amount FROM payment_obligations WHERE lease_id = $1 AND kind = 'opening_balance'", res[0].ID).Scan(&opening); err != nil ||
		opening != 120_000 {
		t.Fatalf("opening balance %d %v", opening, err)
	}

	// All or nothing: the second lease reuses symbol 555, so the first is not
	// written either.
	again := strings.Join(leasing.ImportColumns, ",") + "\n" +
		`c3,"Korunní 5, Praha 2",,1+kk,,2024-01-01,,12000,,,,1,,CZ6508000000192000145399,Jana Nováková,777,,Ida,,,` + "\n" +
		`d4,"Korunní 7, Praha 2",,1+kk,,2024-01-01,,12000,,,,1,,CZ6508000000192000145399,Jana Nováková,555,,Ota,,,` + "\n"
	more, errs := leasing.ParseImportCSV(strings.NewReader(again), 3, today)
	if len(errs) > 0 || len(more) != 2 {
		t.Fatalf("parse %v", errs)
	}
	if _, err := e.leases.ImportBatch(ctx, orgID, &ownerID, more, false); err == nil || !strings.Contains(err.Error(), "variable_symbol_taken") ||
		!strings.Contains(err.Error(), "d4") {
		t.Fatalf("batch with a taken symbol: %v", err)
	}
	if n := count(); n != 2 {
		t.Fatalf("partial batch written: %d leases", n)
	}
}
