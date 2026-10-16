package integration

import (
	"context"
	"errors"
	"os/exec"
	"strconv"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"github.com/terrareality/terrareality/services/api/internal/leasing"
	"github.com/terrareality/terrareality/services/api/internal/notify"
)

// leaseBody is a minimal lease draft starting today.
func leaseBody(template string, parties ...map[string]any) map[string]any {
	today := time.Now().UTC()
	b := map[string]any{"template": template, "starts_on": today.Format("2006-01-02"), "rent_amount": 2_000_000,
		"services_amount": 400_000, "deposit_amount": 4_000_000, "due_day": min(today.Day(), 28),
		"payee_iban": "CZ65 0800 0000 1920 0014 5399", "payee_name": "Lucie Pronajímatelka",
		"property_address": "Dejvická 12, Praha 6", "unit_label": "2+kk", "parties": parties}
	if template == "byt_doba_urcita" || template == "spolecny_najem" {
		b["ends_on"] = today.AddDate(1, 0, -1).Format("2006-01-02")
	}
	return b
}

func needTypst(t *testing.T) {
	t.Helper()
	if _, err := exec.LookPath("typst"); err != nil {
		t.Skip("typst not installed")
	}
}

// B-1: an account registered with a tenant's e-mail but not verified does
// not become a party of the lease (no detail, no list, no signature, no
// push); after verification the owner of the address is linked.
func TestUnverifiedAccountCannotClaimLeaseParty(t *testing.T) {
	e := newEnv(t)
	ownerTok, orgID := e.ownerOrg("claim-owner")
	victim := uniqueEmail("claim-tenant")
	// Registered before the draft (writeParties) ...
	early := e.register(victim)
	e.pushDevice(early)
	var d leaseDetail
	e.must(201, "POST", "/v1/orgs/"+orgID.String()+"/leases", ownerTok,
		leaseBody("byt_doba_neurcita", map[string]any{"name": "Tereza Nájemnice", "email": victim, "role": "tenant"}), &d)
	id := d.Lease.ID.String()
	var linked int
	if err := e.pool.QueryRow(context.Background(), `SELECT count(*) FROM lease_parties WHERE lease_id = $1 AND user_id IS NOT NULL
		AND role <> 'landlord'`, d.Lease.ID).Scan(&linked); err != nil || linked != 0 {
		t.Fatalf("draft linked an unverified account: %d %v", linked, err)
	}
	// ... and on access (ClaimLeaseParties).
	var mine []struct {
		ID uuid.UUID `json:"id"`
	}
	e.must(200, "GET", "/v1/me/leases", early, nil, &mine)
	if len(mine) != 0 {
		t.Fatalf("unverified account sees leases %+v", mine)
	}
	if code := e.call("GET", "/v1/leases/"+id, early, nil, nil); code != 404 {
		t.Fatalf("unverified account reads the lease: %d", code)
	}
	if code := e.call("POST", "/v1/leases/"+id+"/sign", early, map[string]string{"provider": "mock"}, nil); code != 404 {
		t.Fatalf("unverified account signs: %d", code)
	}
	if code := e.call("POST", "/v1/leases/"+id+"/notice", early, map[string]string{"delivered_on": time.Now().Format("2006-01-02")}, nil); code != 404 {
		t.Fatalf("unverified account gives notice: %d", code)
	}
	if _, err := exec.LookPath("typst"); err == nil {
		e.must(200, "POST", "/v1/orgs/"+orgID.String()+"/leases/"+id+"/propose", ownerTok, nil, nil)
		if ps := e.pusher.of(e.userID(early), notify.PushLease); len(ps) != 0 {
			t.Fatalf("push to an unverified account %+v", ps)
		}
	}
	// Proving the address links the party.
	e.verifyEmail(victim)
	e.must(200, "GET", "/v1/me/leases", early, nil, &mine)
	if len(mine) != 1 || mine[0].ID != d.Lease.ID {
		t.Fatalf("verified account not linked: %+v", mine)
	}
	e.must(200, "GET", "/v1/leases/"+id, early, nil, &d)
}

// signedLease drafts, proposes and signs a lease with the given parties
// (tokens sign in order, the owner last) and returns its id.
func (e *env) signedLease(ownerTok string, orgID uuid.UUID, template string, parties []map[string]any, signers ...string) uuid.UUID {
	e.t.Helper()
	var d leaseDetail
	e.must(201, "POST", "/v1/orgs/"+orgID.String()+"/leases", ownerTok, leaseBody(template, parties...), &d)
	e.must(200, "POST", "/v1/orgs/"+orgID.String()+"/leases/"+d.Lease.ID.String()+"/propose", ownerTok, nil, nil)
	for _, tok := range append(signers, ownerTok) {
		e.must(200, "POST", "/v1/leases/"+d.Lease.ID.String()+"/sign", tok, map[string]string{"provider": "mock"}, nil)
	}
	return d.Lease.ID
}

func (e *env) verifiedUser(prefix string) (string, string) {
	em := uniqueEmail(prefix)
	tok := e.register(em)
	e.verifyEmail(em)
	return em, tok
}

// V-1: only a tenant or co-tenant gives notice, delivered within the window;
// a landlord's notice (needs a statutory reason) is refused for now; the
// event records who gave it.
func TestLeaseNoticeRules(t *testing.T) {
	needTypst(t)
	e := newEnv(t)
	ownerTok, orgID := e.ownerOrg("notice-owner")
	tenant, tenantTok := e.verifiedUser("notice-tenant")
	guarantor, guarantorTok := e.verifiedUser("notice-guarantor")
	id := e.signedLease(ownerTok, orgID, "byt_doba_neurcita", []map[string]any{
		{"name": "Nájemce", "email": tenant, "role": "tenant"},
		{"name": "Ručitel", "email": guarantor, "role": "guarantor"}}, tenantTok)
	path := "/v1/leases/" + id.String() + "/notice"
	today := time.Now().In(time.UTC)
	on := func(d time.Time) map[string]string { return map[string]string{"delivered_on": d.Format("2006-01-02")} }

	var p problem
	if code := e.call("POST", path, ownerTok, on(today), &p); code != 422 || p.Code != "landlord_notice_reason_required" {
		t.Fatalf("landlord notice: %d %+v", code, p)
	}
	if code := e.call("POST", path, guarantorTok, on(today), &p); code != 403 || p.Code != "notice_not_allowed" {
		t.Fatalf("guarantor notice: %d %+v", code, p)
	}
	for _, d := range []time.Time{time.Date(2020, 1, 1, 0, 0, 0, 0, time.UTC), today.AddDate(0, 0, -leasing.NoticeBackDays-2),
		today.AddDate(0, 0, leasing.NoticeAheadDays+2)} {
		if code := e.call("POST", path, tenantTok, on(d), &p); code != 422 || p.Code != "invalid_delivered_on" {
			t.Fatalf("delivered_on %s: %d %+v", d.Format("2006-01-02"), code, p)
		}
	}
	var state string
	if err := e.pool.QueryRow(context.Background(), `SELECT state FROM leases WHERE id = $1`, id).Scan(&state); err != nil || state != "signed" {
		t.Fatalf("refused notices changed the lease: %s %v", state, err)
	}
	e.must(200, "POST", path, tenantTok, on(today.AddDate(0, 0, -3)), nil)
	var by, role, party string
	if err := e.pool.QueryRow(context.Background(), `SELECT payload->'data'->>'by', payload->'data'->>'role', payload->'data'->>'party_id'
		FROM lease_events WHERE lease_id = $1 AND kind = 'notice_given'`, id).Scan(&by, &role, &party); err != nil {
		t.Fatal(err)
	}
	if by != "tenant" || role != "tenant" || party == "" {
		t.Fatalf("notice event by=%s role=%s party=%s", by, role, party)
	}
}

// V-2: a co-tenant's signature racing their own request for changes: exactly
// one wins and the lease is never signed over disputed terms.
func TestSignRacesRequestChanges(t *testing.T) {
	needTypst(t)
	e := newEnv(t)
	ownerTok, orgID := e.ownerOrg("race-owner")
	a, aTok := e.verifiedUser("race-a")
	b, bTok := e.verifiedUser("race-b")
	var d leaseDetail
	e.must(201, "POST", "/v1/orgs/"+orgID.String()+"/leases", ownerTok, leaseBody("spolecny_najem",
		map[string]any{"name": "A", "email": a, "role": "co_tenant"}, map[string]any{"name": "B", "email": b, "role": "co_tenant"}), &d)
	id := d.Lease.ID.String()
	e.must(200, "POST", "/v1/orgs/"+orgID.String()+"/leases/"+id+"/propose", ownerTok, nil, nil)
	sign := map[string]string{"provider": "mock"}
	e.must(200, "POST", "/v1/leases/"+id+"/sign", ownerTok, sign, nil)
	e.must(200, "POST", "/v1/leases/"+id+"/sign", aTok, sign, nil)
	started := len(e.leaseJob.started)

	var wg sync.WaitGroup
	var signCode, changeCode int
	wg.Add(2)
	go func() { defer wg.Done(); signCode = e.call("POST", "/v1/leases/"+id+"/sign", bTok, sign, nil) }()
	go func() {
		defer wg.Done()
		changeCode = e.call("POST", "/v1/leases/"+id+"/request-changes", bTok, map[string]string{"comment": "Jiná kauce."}, nil)
	}()
	wg.Wait()
	e.must(200, "GET", "/v1/leases/"+id, ownerTok, nil, &d)
	switch {
	case signCode == 200 && changeCode == 409:
		if d.Lease.State != "signed" || len(e.leaseJob.started) != started+1 {
			t.Fatalf("signature won but state %s, workflows %d", d.Lease.State, len(e.leaseJob.started)-started)
		}
	case changeCode == 204 && signCode == 409:
		if d.Lease.State != "negotiating" || len(e.leaseJob.started) != started {
			t.Fatalf("changes won but state %s, workflows %d", d.Lease.State, len(e.leaseJob.started)-started)
		}
	default:
		t.Fatalf("sign %d, request-changes %d, state %s", signCode, changeCode, d.Lease.State)
	}
}

// S-L1, S-L2, S-L5: a payment in another currency is never matched; without
// a specific symbol an amount several co-tenants owe is only suggested; a
// share is never overpaid by concurrent manual entries.
func TestBankMatchingAndOverpayment(t *testing.T) {
	needTypst(t)
	e := newEnv(t)
	ownerTok, orgID := e.ownerOrg("match-owner")
	a, aTok := e.verifiedUser("match-a")
	b, bTok := e.verifiedUser("match-b")
	id := e.signedLease(ownerTok, orgID, "spolecny_najem", []map[string]any{
		{"name": "A", "email": a, "role": "co_tenant"}, {"name": "B", "email": b, "role": "co_tenant"}}, aTok, bTok)
	orgPath := "/v1/orgs/" + orgID.String()
	var shares []share
	e.must(200, "GET", "/v1/leases/"+id.String()+"/obligations", ownerTok, nil, &shares)
	var rentA share
	for _, s := range shares {
		if s.Kind == "rent" && rentA.ID == uuid.Nil {
			rentA = s
		}
	}
	var code int64
	if err := e.pool.QueryRow(context.Background(), `SELECT code FROM leases WHERE id = $1`, id).Scan(&code); err != nil {
		t.Fatal(err)
	}
	var link struct {
		Connection struct {
			ID uuid.UUID `json:"id"`
		} `json:"connection"`
	}
	e.must(201, "POST", orgPath+"/bank/connections", ownerTok, map[string]string{"redirect_uri": "http://web.test/bank"}, &link)
	var account string
	if err := e.pool.QueryRow(context.Background(), `SELECT account_id FROM bank_connections WHERE id = $1`, link.Connection.ID).Scan(&account); err != nil {
		t.Fatal(err)
	}
	today := time.Now().UTC()
	vs := strconv.FormatInt(code, 10)
	e.bank.Add(account, leasing.Transaction{ExternalID: "eur", BookedOn: today, Amount: rentA.Amount, Currency: "EUR",
		VariableSymbol: vs, SpecificSymbol: "1"})
	e.bank.Add(account, leasing.Transaction{ExternalID: "no-ss", BookedOn: today, Amount: rentA.Amount, Currency: "CZK",
		VariableSymbol: vs})
	var res struct{ New, Matched, Suggested int }
	e.must(200, "POST", orgPath+"/bank/sync", ownerTok, nil, &res)
	if res.New != 2 || res.Matched != 0 || res.Suggested != 1 {
		t.Fatalf("sync %+v", res)
	}
	var status, note string
	if err := e.pool.QueryRow(context.Background(), `SELECT match_status FROM bank_transactions WHERE connection_id = $1 AND external_id = 'eur'`,
		link.Connection.ID).Scan(&status); err != nil || status != "unmatched" {
		t.Fatalf("EUR payment: %s %v", status, err)
	}
	if err := e.pool.QueryRow(context.Background(), `SELECT match_status, match_note FROM bank_transactions WHERE connection_id = $1
		AND external_id = 'no-ss'`, link.Connection.ID).Scan(&status, &note); err != nil || status != "suggested" || !strings.Contains(note, "several") {
		t.Fatalf("payment without specific symbol: %s %q %v", status, note, err)
	}
	// Confirming the EUR transaction for a CZK share is refused.
	var eurID uuid.UUID
	_ = e.pool.QueryRow(context.Background(), `SELECT id FROM bank_transactions WHERE connection_id = $1 AND external_id = 'eur'`,
		link.Connection.ID).Scan(&eurID)
	var p problem
	if c := e.call("POST", orgPath+"/bank/transactions/"+eurID.String()+"/match", ownerTok, map[string]any{"share_id": rentA.ID}, &p); c != 422 ||
		p.Code != "currency_mismatch" {
		t.Fatalf("currency mismatch confirm: %d %+v", c, p)
	}

	// Overpayment: more than due is refused; two concurrent full payments book once.
	paid := orgPath + "/obligation-shares/" + rentA.ID.String() + "/paid"
	if c := e.call("POST", paid, ownerTok, map[string]any{"amount": rentA.Amount + 1}, &p); c != 422 || p.Code != "invalid_amount" {
		t.Fatalf("overpayment: %d %+v", c, p)
	}
	var wg sync.WaitGroup
	codes := make([]int, 2)
	for i := range codes {
		wg.Add(1)
		go func() {
			defer wg.Done()
			codes[i] = e.call("POST", paid, ownerTok, map[string]any{"amount": rentA.Amount}, nil)
		}()
	}
	wg.Wait()
	if !((codes[0] == 204 && codes[1] == 422) || (codes[0] == 422 && codes[1] == 204)) {
		t.Fatalf("concurrent payments %v", codes)
	}
	var paidAmount, amount int64
	if err := e.pool.QueryRow(context.Background(), `SELECT paid_amount, amount FROM obligation_splits WHERE id = $1`, rentA.ID).
		Scan(&paidAmount, &amount); err != nil || paidAmount != amount {
		t.Fatalf("split paid %d of %d %v", paidAmount, amount, err)
	}
}

// W-5: pushes are queued in the business transaction; a failing queue never
// fails it (savepoint) and a rolled back transaction queues nothing.
func TestPushesQueuedInTransaction(t *testing.T) {
	e := newEnv(t)
	ctx := context.Background()
	user := uuid.New()
	q := &recQueue{}
	ps := notify.Pushes{Queue: q, Pusher: e.pusher}
	if err := pgx.BeginFunc(ctx, e.svc, func(tx pgx.Tx) error {
		ps.Send(ctx, tx, user, notify.Push{Title: "a"})
		q.fail = true
		ps.Send(ctx, tx, user, notify.Push{Title: "b"}) // fails inside its savepoint
		_, err := tx.Exec(ctx, "SELECT 1")              // the transaction is still usable
		return err
	}); err != nil {
		t.Fatalf("a failing push queue failed the transaction: %v", err)
	}
	if len(q.items) != 1 || q.items[0] != "a" {
		t.Fatalf("queued %v", q.items)
	}
	if e.pusher.count(user) != 0 {
		t.Fatal("a queued push was delivered inline")
	}
	if (notify.Pushes{}).Enabled() {
		t.Fatal("pushes without a pusher are enabled")
	}
}

type recQueue struct {
	items []string
	fail  bool
}

func (r *recQueue) EnqueuePush(ctx context.Context, tx pgx.Tx, _ uuid.UUID, p notify.Push) error {
	if r.fail {
		_, err := tx.Exec(ctx, "SELECT 1/0") // aborts the savepoint like a failed insert
		if err == nil {
			err = errors.New("queue down")
		}
		return err
	}
	r.items = append(r.items, p.Title)
	return nil
}

// N (workflows): an escalation retried after its transaction committed
// (lost activity result) is not recorded, mailed or pushed twice.
func TestEscalationIsIdempotent(t *testing.T) {
	needTypst(t)
	e := newEnv(t)
	ctx := context.Background()
	ownerTok, orgID := e.ownerOrg("esc-owner")
	tenant, tenantTok := e.verifiedUser("esc-tenant")
	e.pushDevice(tenantTok)
	id := e.signedLease(ownerTok, orgID, "byt_doba_neurcita", []map[string]any{{"name": "Nájemce", "email": tenant, "role": "tenant"}}, tenantTok)
	today := time.Now().UTC()
	act := &leasing.Activities{S: e.leases}
	for i := 0; i < 2; i++ {
		if unpaid, err := act.Remind(ctx, id, today, "escalation"); err != nil || unpaid == 0 {
			t.Fatalf("escalation %d: %d %v", i, unpaid, err)
		}
	}
	var n int
	if err := e.pool.QueryRow(ctx, `SELECT count(*) FROM lease_events WHERE lease_id = $1 AND kind = 'payment_escalated'`, id).Scan(&n); err != nil || n != 1 {
		t.Fatalf("escalation events %d %v", n, err)
	}
	if mails := e.outbox.All(tenant, "payment_escalation"); len(mails) != 2 { // deposit and first month, once each
		t.Fatalf("escalation e-mails %d", len(mails))
	}
	esc := 0
	for _, p := range e.pusher.of(e.userID(tenantTok), notify.PushObligation) {
		if p.Data["stage"] == "payment_escalation" {
			esc++
		}
	}
	if esc != 2 {
		t.Fatalf("escalation pushes %d", esc)
	}
	// Info of a lease that no longer exists ends the workflow instead of retrying.
	if info, err := act.Info(ctx, uuid.New()); err != nil || info.State != leasing.StateGone {
		t.Fatalf("info of a missing lease: %+v %v", info, err)
	}
}
