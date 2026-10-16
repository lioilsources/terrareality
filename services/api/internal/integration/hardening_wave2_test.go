package integration

import (
	"context"
	"errors"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"

	"github.com/terrareality/terrareality/services/api/internal/account"
	"github.com/terrareality/terrareality/services/api/internal/auth"
	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/notify"
	"github.com/terrareality/terrareality/services/api/internal/org"
	"github.com/terrareality/terrareality/services/api/internal/platform/apperr"
	"github.com/terrareality/terrareality/services/api/internal/portfolio"
)

// S-F7/S-D8: organization lists page by a UUIDv7 cursor (before = id of the
// last item received) with a capped limit instead of silent hard caps.
func TestListPagination(t *testing.T) {
	e := newEnv(t)
	ownerTok, orgID := e.ownerOrg("pager")
	opath := "/v1/orgs/" + orgID.String()

	// Leases, newest first.
	var leaseIDs []uuid.UUID
	for range 3 {
		var d leaseDetail
		e.must(201, "POST", opath+"/leases", ownerTok, leaseBody("byt_doba_neurcita",
			map[string]any{"name": "Nájemce", "email": uniqueEmail("pager-tenant"), "role": "tenant"}), &d)
		leaseIDs = append(leaseIDs, d.Lease.ID)
	}
	type idOnly struct {
		ID uuid.UUID `json:"id"`
	}
	var page1, page2 []idOnly
	e.must(200, "GET", opath+"/leases?limit=2", ownerTok, nil, &page1)
	if len(page1) != 2 || page1[0].ID != leaseIDs[2] || page1[1].ID != leaseIDs[1] {
		t.Fatalf("lease page 1 %+v, created %v", page1, leaseIDs)
	}
	e.must(200, "GET", opath+"/leases?limit=2&before="+page1[1].ID.String(), ownerTok, nil, &page2)
	if len(page2) != 1 || page2[0].ID != leaseIDs[0] {
		t.Fatalf("lease page 2 %+v", page2)
	}

	// Listings, recently edited first.
	var addrs []struct {
		RuianID int64 `json:"ruian_id"`
	}
	e.must(200, "GET", "/v1/addresses/search?q=vinohradska", "", nil, &addrs)
	seen := map[uuid.UUID]bool{}
	for range 3 {
		var l listingDTO
		e.must(201, "POST", opath+"/listings", ownerTok, map[string]any{"ruian_id": addrs[0].RuianID, "unit_kind": "apartment"}, &l)
		seen[l.ID] = false
	}
	cursor := ""
	for pages := 0; ; pages++ {
		var page []idOnly
		e.must(200, "GET", opath+"/listings?limit=2"+cursor, ownerTok, nil, &page)
		for _, l := range page {
			if seen[l.ID] {
				t.Fatalf("listing %s on two pages", l.ID)
			}
			seen[l.ID] = true
		}
		if len(page) < 2 || pages > 3 {
			break
		}
		cursor = "&before=" + page[len(page)-1].ID.String()
	}
	for id, ok := range seen {
		if !ok {
			t.Fatalf("listing %s never listed", id)
		}
	}

	// The other paged lists answer (cursor of an unknown id: empty page).
	ghost := uuid.NewString()
	for _, path := range []string{opath + "/orders", opath + "/invoices", opath + "/bank", "/v1/conversations",
		"/v1/conversations?as=seeker", "/v1/conversations?org_id=" + orgID.String()} {
		sep := "?"
		if strings.Contains(path, "?") {
			sep = "&"
		}
		e.must(200, "GET", path+sep+"limit=5&before="+ghost, ownerTok, nil, nil)
		e.must(200, "GET", path, ownerTok, nil, nil)
	}
	var orders struct {
		Items      []any      `json:"items"`
		NextBefore *uuid.UUID `json:"next_before"`
	}
	e.must(200, "GET", opath+"/orders?limit=1", ownerTok, nil, &orders)
	if len(orders.Items) != 0 || orders.NextBefore != nil {
		t.Fatalf("empty order page %+v", orders)
	}
	staff := e.staffToken()
	e.must(200, "GET", "/v1/backoffice/moderation?limit=2&after="+ghost, staff, nil, nil)
	e.must(200, "GET", "/v1/backoffice/moderation?limit=2", staff, nil, nil)
	// The limit stays capped.
	for _, lim := range []string{"0", "201"} {
		if code := e.call("GET", opath+"/leases?limit="+lim, ownerTok, nil, nil); code != 400 {
			t.Fatalf("limit=%s: %d", lim, code)
		}
	}
}

// S-A1: failed logins also count on the account row, so the lock survives a
// restart (a fresh in-memory limiter) and the owner is e-mailed once at the
// fifth failure. A complete login clears the counter.
func TestPersistentLoginLockout(t *testing.T) {
	e := newEnv(t)
	em := uniqueEmail("persist-lock")
	e.register(em)
	for range 6 {
		e.call("POST", "/v1/auth/login", "", map[string]string{"email": em, "password": "Wrong-password-1"}, nil)
	}
	var failures int
	var lockedUntil *time.Time
	if err := e.pool.QueryRow(context.Background(), "SELECT failed_logins, locked_until FROM users WHERE email = $1", em).
		Scan(&failures, &lockedUntil); err != nil {
		t.Fatal(err)
	}
	if failures != 6 || lockedUntil == nil || !lockedUntil.After(time.Now()) {
		t.Fatalf("failed_logins %d, locked_until %v", failures, lockedUntil)
	}
	if n := len(e.outbox.All(em, "login_failures")); n != 1 {
		t.Fatalf("login_failures e-mails: %d", n)
	}
	// A new API instance (no in-memory state) still refuses the right password.
	fresh := &account.Service{Pool: e.acct.Pool, Box: e.acct.Box, Outbox: e.acct.Outbox, Render: e.acct.Render,
		IDP: e.acct.IDP, Blob: e.acct.Blob, Scheduler: e.acct.Scheduler, Pwned: e.acct.Pwned, Cfg: e.acct.Cfg}
	_, err := fresh.Login(context.Background(), em, "Sup3r-secret-pw", "web")
	if ae, ok := apperr.As(err); !ok || ae.Status != 429 {
		t.Fatalf("persistent lock ignored: %v", err)
	}
	// Once the lock ran out the right password works and resets the count.
	if _, err := e.pool.Exec(context.Background(), "UPDATE users SET locked_until = now() - interval '1 second' WHERE email = $1", em); err != nil {
		t.Fatal(err)
	}
	if _, err := fresh.Login(context.Background(), em, "Sup3r-secret-pw", "web"); err != nil {
		t.Fatalf("login after the lock: %v", err)
	}
	if err := e.pool.QueryRow(context.Background(), "SELECT failed_logins, locked_until FROM users WHERE email = $1", em).
		Scan(&failures, &lockedUntil); err != nil || failures != 0 || lockedUntil != nil {
		t.Fatalf("after success: %d %v %v", failures, lockedUntil, err)
	}
}

// S-W7: sessions carry their expiry.
func TestSessionInfoExpiresAt(t *testing.T) {
	e := newEnv(t)
	tok := e.register(uniqueEmail("expiry"))
	var sessions []struct {
		Current   bool      `json:"current"`
		ExpiresAt time.Time `json:"expires_at"`
	}
	e.must(200, "GET", "/v1/me/sessions", tok, nil, &sessions)
	if len(sessions) != 1 || !sessions[0].Current || !sessions[0].ExpiresAt.After(time.Now()) {
		t.Fatalf("sessions %+v", sessions)
	}
}

// N: request bounds of the contract are enforced before handlers run.
func TestContractBounds(t *testing.T) {
	e := newEnv(t)
	ownerTok, orgID := e.ownerOrg("bounds")
	long := strings.Repeat("a", 300)
	if code := e.call("POST", "/v1/me/push-devices", ownerTok, map[string]any{"platform": "webpush", "token": "https://push.example/x",
		"keys": map[string]string{"p256dh": long, "auth": "x"}}, nil); code != 400 {
		t.Fatalf("long p256dh: %d", code)
	}
	clauses := make([]string, 13)
	for i := range clauses {
		clauses[i] = "no_smoking"
	}
	body := leaseBody("byt_doba_neurcita", map[string]any{"name": "N", "email": uniqueEmail("b"), "role": "tenant"})
	body["clauses"] = clauses
	if code := e.call("POST", "/v1/orgs/"+orgID.String()+"/leases", ownerTok, body, nil); code != 400 {
		t.Fatalf("too many clauses: %d", code)
	}
	weights := map[string]int{}
	for i := range 33 {
		weights["w"+strings.Repeat("x", i)] = 1
	}
	if code := e.call("PUT", "/v1/orgs/"+orgID.String()+"/portfolio/risk-weights", ownerTok, map[string]any{"weights": weights}, nil); code != 400 {
		t.Fatalf("too many weights: %d", code)
	}
}

// N: read-only members (viewer, investor) do not get the team's e-mails;
// invitations never grant ownership (422 in Go behind the contract's enum).
func TestMemberEmailsAndInvitableRoles(t *testing.T) {
	e := newEnv(t)
	ownerTok, orgID := e.ownerOrg("roster")
	opath := "/v1/orgs/" + orgID.String()
	viewerEmail := uniqueEmail("roster-viewer")
	e.must(201, "POST", opath+"/invitations", ownerTok, map[string]string{"email": viewerEmail, "role": "viewer"}, nil)
	inv, ok := e.outbox.Last(viewerEmail, "invitation")
	if !ok {
		t.Fatal("no invitation e-mail")
	}
	viewerTok := e.register(viewerEmail)
	e.must(200, "POST", "/v1/invitations/accept", viewerTok, map[string]string{"token": notify.LinkToken(inv.Text)}, nil)
	type member struct {
		Role  string  `json:"role"`
		Email *string `json:"email"`
	}
	var asViewer, asOwner []member
	e.must(200, "GET", opath+"/members", viewerTok, nil, &asViewer)
	e.must(200, "GET", opath+"/members", ownerTok, nil, &asOwner)
	if len(asViewer) != 2 || len(asOwner) != 2 {
		t.Fatalf("members %+v %+v", asViewer, asOwner)
	}
	for _, m := range asViewer {
		if (m.Role == "viewer") != (m.Email != nil) {
			t.Fatalf("viewer sees e-mails: %+v", asViewer)
		}
	}
	for _, m := range asOwner {
		if m.Email == nil {
			t.Fatalf("owner misses e-mails: %+v", asOwner)
		}
	}

	if code := e.call("POST", opath+"/invitations", ownerTok, map[string]string{"email": uniqueEmail("x"), "role": "owner"}, nil); code != 400 {
		t.Fatalf("owner invitation through the API: %d", code)
	}
	var me struct {
		ID uuid.UUID `json:"id"`
	}
	e.must(200, "GET", "/v1/me", ownerTok, nil, &me)
	svc := &org.Service{Pool: e.svc, Outbox: e.outbox, WebBaseURL: "http://web.test"}
	_, err := svc.Invite(context.Background(), &auth.Principal{UserID: me.ID}, orgID, uniqueEmail("y"), "owner", "cs")
	if ae, ok := apperr.As(err); !ok || ae.Code != "invalid_role" || ae.Status != 422 {
		t.Fatalf("service allowlist: %v", err)
	}
}

// S-D1: the backoffice review lists submitted photos whose privacy flag the
// owner kept (rejected the blur), as a dedicated field.
func TestReviewShowsPrivacyFlags(t *testing.T) {
	e := newEnv(t)
	tok, orgID := e.ownerOrg("flags")
	var addrs []struct {
		RuianID int64 `json:"ruian_id"`
	}
	e.must(200, "GET", "/v1/addresses/search?q=vinohradska", "", nil, &addrs)
	var l listingDTO
	e.must(201, "POST", "/v1/orgs/"+orgID.String()+"/listings", tok, map[string]any{"ruian_id": addrs[0].RuianID, "unit_kind": "apartment"}, &l)
	visionPeople.Store(true)
	mediaID := e.uploadPhoto(tok, orgID, l.ID, "people.jpg")
	visionPeople.Store(false)
	lpath := "/v1/orgs/" + orgID.String() + "/listings/" + l.ID.String()
	e.must(200, "GET", lpath, tok, nil, &l)
	sg := findSuggestion(l, "privacy_blur")
	e.must(200, "PUT", lpath, tok, map[string]any{"title": map[string]string{"cs": "Byt s lidmi na fotce", "en": ""},
		"description": map[string]string{"cs": strings.Repeat("Světlý byt s balkonem a výhledem do parku. ", 3), "en": ""},
		"rent_amount": 2000000, "attributes": l.Attributes, "location_precision": "approximate"}, nil)
	e.must(200, "POST", "/v1/orgs/"+orgID.String()+"/suggestions/"+sg.ID.String()+"/decision", tok, map[string]any{"accept": false}, nil)
	e.must(200, "POST", lpath+"/submit", tok, nil, nil)
	staff := e.staffToken()
	var queue []struct {
		VersionID uuid.UUID `json:"version_id"`
		ListingID uuid.UUID `json:"listing_id"`
	}
	e.must(200, "GET", "/v1/backoffice/reviews", staff, nil, &queue)
	var versionID uuid.UUID
	for _, q := range queue {
		if q.ListingID == l.ID {
			versionID = q.VersionID
		}
	}
	var detail struct {
		Snapshot     map[string]any `json:"snapshot"`
		PrivacyFlags []struct {
			MediaID uuid.UUID `json:"media_id"`
			Status  string    `json:"status"`
		} `json:"privacy_flags"`
	}
	e.must(200, "GET", "/v1/backoffice/reviews/"+versionID.String(), staff, nil, &detail)
	if len(detail.PrivacyFlags) != 1 || detail.PrivacyFlags[0].MediaID != mediaID || detail.PrivacyFlags[0].Status != "rejected" {
		t.Fatalf("privacy flags %+v", detail.PrivacyFlags)
	}
	if _, ok := detail.Snapshot["privacy_flags"]; ok {
		t.Fatal("privacy flags still mixed into the snapshot")
	}
}

// V-12: the lease detail lists the signature methods this server offers; any
// other provider is refused.
func TestLeaseSignProviders(t *testing.T) {
	e := newEnv(t)
	ownerTok, orgID := e.ownerOrg("signers")
	var d struct {
		Lease struct {
			ID uuid.UUID `json:"id"`
		} `json:"lease"`
		SignProviders []struct {
			ID    string `json:"id"`
			Level string `json:"level"`
		} `json:"sign_providers"`
	}
	e.must(201, "POST", "/v1/orgs/"+orgID.String()+"/leases", ownerTok, leaseBody("byt_doba_neurcita",
		map[string]any{"name": "Nájemce", "email": uniqueEmail("signer"), "role": "tenant"}), &d)
	if len(d.SignProviders) != 1 || d.SignProviders[0].ID != "mock" || d.SignProviders[0].Level != "simple" {
		t.Fatalf("sign providers %+v", d.SignProviders)
	}
	needTypst(t)
	e.must(200, "POST", "/v1/orgs/"+orgID.String()+"/leases/"+d.Lease.ID.String()+"/propose", ownerTok, nil, nil)
	var p problem
	if code := e.call("POST", "/v1/leases/"+d.Lease.ID.String()+"/sign", ownerTok, map[string]string{"provider": "bankid_sign"}, &p); code != 422 || p.Code != "invalid_provider" {
		t.Fatalf("disabled provider: %d %+v", code, p)
	}
}

// N (migration 00014): only owners and admins change an organization under
// RLS; nobody deletes or creates one as the app role.
func TestOrganizationWritePolicies(t *testing.T) {
	pool := setup(t)
	f := &rlsFixture{t: t, pool: pool}
	t.Cleanup(f.cleanup)
	owner, _ := f.user(true)
	admin, _ := f.user(true)
	agent, _ := f.user(true)
	o := f.org("Policy s.r.o.", map[uuid.UUID]string{owner: "owner", admin: "admin", agent: "agent"})

	n, err := execAs(pool, agent, "UPDATE organizations SET name = 'Agent' WHERE id = $1", o)
	wantRows(t, "agent renames", 0, n, err)
	n, err = execAs(pool, admin, "UPDATE organizations SET name = 'Admin' WHERE id = $1", o)
	wantRows(t, "admin renames", 1, n, err)
	_, err = execAs(pool, owner, "DELETE FROM organizations WHERE id = $1", o)
	wantDenied(t, "owner deletes", err)
	_, err = execAs(pool, owner, "INSERT INTO organizations (kind, name) VALUES ('company', 'New')")
	wantDenied(t, "member creates", err)
	var name string
	scanAs(t, pool, agent, &name, "SELECT name FROM organizations WHERE id = $1", o)
	if name != "Admin" {
		t.Fatalf("name %q", name)
	}
}

// N (migration 00014): the tenant shares of a signed or active lease add up
// to 10000 basis points, checked at commit.
func TestLeaseSharesAddUp(t *testing.T) {
	pool := setup(t)
	f := &rlsFixture{t: t, pool: pool}
	t.Cleanup(f.cleanup)
	owner, _ := f.user(true)
	o := f.org("Shares s.r.o.", map[uuid.UUID]string{owner: "owner"})
	newLease := func() uuid.UUID {
		return f.one(`INSERT INTO leases (org_id, jurisdiction_code, currency, template, template_version, property_address,
			starts_on, rent_amount, payee_iban, payee_name)
			VALUES ($1, 'CZ', 'CZK', 'spolecny_najem', '1', 'Shares 1, Praha', '2026-01-01', 1500000, 'CZ6508000000192000145399', 'S')
			RETURNING id`, o)
	}
	ctx := context.Background()
	bad := newLease()
	f.exec(`INSERT INTO lease_parties (lease_id, org_id, role, name, share_bps, position) VALUES ($1, $2, 'tenant', 'A', 5000, 1)`, bad, o)
	_, err := pool.Exec(ctx, "UPDATE leases SET state = 'active' WHERE id = $1", bad)
	var pe *pgconn.PgError
	if !errors.As(err, &pe) || pe.Code != "23514" {
		t.Fatalf("active lease with 50 %% shares: %v", err)
	}

	good := newLease()
	f.exec(`INSERT INTO lease_parties (lease_id, org_id, role, name, share_bps, position) VALUES ($1, $2, 'tenant', 'A', 10000, 1)`, good, o)
	f.exec(`INSERT INTO lease_parties (lease_id, org_id, role, name, share_bps, position) VALUES ($1, $2, 'guarantor', 'G', 0, 2)`, good, o)
	f.exec("UPDATE leases SET state = 'active' WHERE id = $1", good)
	// Rewriting shares inside one transaction passes through other sums.
	err = pgx.BeginFunc(ctx, pool, func(tx pgx.Tx) error {
		if _, err := tx.Exec(ctx, "UPDATE lease_parties SET share_bps = 6000 WHERE lease_id = $1 AND role = 'tenant'", good); err != nil {
			return err
		}
		_, err := tx.Exec(ctx, `INSERT INTO lease_parties (lease_id, org_id, role, name, share_bps, position)
			VALUES ($1, $2, 'co_tenant', 'B', 4000, 3)`, good, o)
		return err
	})
	if err != nil {
		t.Fatalf("balanced rewrite: %v", err)
	}
	if _, err := pool.Exec(ctx, "UPDATE lease_parties SET share_bps = 1000 WHERE lease_id = $1 AND role = 'co_tenant'", good); err == nil {
		t.Fatal("unbalanced change of an active lease committed")
	}
}

// S-P1 (migration 00014): a failed recompute is recorded on the score, the
// lease waits an hour before the next attempt and a success clears it.
func TestRiskRecomputeFailureIsRecorded(t *testing.T) {
	pool := setup(t)
	f := &rlsFixture{t: t, pool: pool}
	t.Cleanup(f.cleanup)
	owner, _ := f.user(true)
	o := f.org("Risk s.r.o.", map[uuid.UUID]string{owner: "owner"})
	lease := f.one(`INSERT INTO leases (org_id, jurisdiction_code, currency, template, template_version, property_address,
		starts_on, rent_amount, payee_iban, payee_name)
		VALUES ($1, 'CZ', 'CZK', 'byt_doba_neurcita', '1', 'Risk 1, Praha', '2026-01-01', 1500000, 'CZ6508000000192000145399', 'R')
		RETURNING id`, o)
	f.exec(`INSERT INTO lease_parties (lease_id, org_id, role, name, share_bps, position) VALUES ($1, $2, 'tenant', 'A', 10000, 1)`, lease, o)
	f.exec("UPDATE leases SET state = 'active' WHERE id = $1", lease)
	f.exec(`INSERT INTO lease_risk (lease_id, org_id, score, band, factors, model_version) VALUES ($1, $2, 10, 'low', '[]', 'old-model')`, lease, o)

	ctx := context.Background()
	q := db.New(pool)
	stale := func() bool {
		ids, err := q.StaleRiskLeaseIDs(ctx, portfolio.ModelVersion)
		if err != nil {
			t.Fatal(err)
		}
		for _, id := range ids {
			if id == lease {
				return true
			}
		}
		return false
	}
	if !stale() {
		t.Fatal("outdated score not stale")
	}
	if n, err := q.MarkLeaseRiskFailed(ctx, db.MarkLeaseRiskFailedParams{LeaseID: lease, LastError: strings.Repeat("x", 3000)}); err != nil || n != 1 {
		t.Fatalf("mark failed: %d %v", n, err)
	}
	var lastErr string
	if err := pool.QueryRow(ctx, "SELECT last_error FROM lease_risk WHERE lease_id = $1", lease).Scan(&lastErr); err != nil || len(lastErr) != 2000 {
		t.Fatalf("last_error %d %v", len(lastErr), err)
	}
	if stale() {
		t.Fatal("recently failed lease retried at once")
	}
	f.exec("UPDATE lease_risk SET failed_at = now() - interval '2 hours' WHERE lease_id = $1", lease)
	if !stale() {
		t.Fatal("failed lease never retried")
	}
	if err := q.UpsertLeaseRisk(ctx, db.UpsertLeaseRiskParams{LeaseID: lease, OrgID: o, Score: 20, Band: "low", Factors: []byte("[]"),
		ModelVersion: portfolio.ModelVersion}); err != nil {
		t.Fatal(err)
	}
	var failedAt *time.Time
	if err := pool.QueryRow(ctx, "SELECT failed_at FROM lease_risk WHERE lease_id = $1", lease).Scan(&failedAt); err != nil || failedAt != nil {
		t.Fatalf("success kept the failure: %v %v", failedAt, err)
	}
}
