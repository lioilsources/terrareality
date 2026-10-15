package integration

import (
	"context"
	"encoding/base32"
	"net/url"
	"strings"
	"testing"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"github.com/terrareality/terrareality/services/api/internal/notify"
	platformdb "github.com/terrareality/terrareality/services/api/internal/platform/db"
)

func base32Decode(s string) ([]byte, error) {
	return base32.StdEncoding.WithPadding(base32.NoPadding).DecodeString(s)
}

type me struct {
	ID                uuid.UUID `json:"id"`
	Email             string    `json:"email"`
	EmailVerified     bool      `json:"email_verified"`
	VerificationLevel string    `json:"verification_level"`
	MfaEnabled        bool      `json:"mfa_enabled"`
	Impersonator      *struct {
		Email string `json:"email"`
	} `json:"impersonator"`
	Identity *struct {
		FamilyName string `json:"family_name"`
		Birthdate  string `json:"birthdate"`
	} `json:"identity"`
	Organizations []membership `json:"organizations"`
}

type membership struct {
	Role         string `json:"role"`
	Organization struct {
		ID   uuid.UUID `json:"id"`
		Kind string    `json:"kind"`
		Name string    `json:"name"`
	} `json:"organization"`
}

// Acceptance M1: registration → 2FA → organization → invitation of a member.
func TestRegistrationMFAOrgInvitation(t *testing.T) {
	e := newEnv(t)
	alice := uniqueEmail("alice")
	tok := e.register(alice)

	var m me
	e.must(200, "GET", "/v1/me", tok, nil, &m)
	if m.VerificationLevel != "none" || len(m.Organizations) != 1 || m.Organizations[0].Organization.Kind != "personal" {
		t.Fatalf("fresh user: %+v", m)
	}
	// Company organizations need a verified e-mail.
	var p problem
	if code := e.call("POST", "/v1/orgs", tok, map[string]string{"name": "Alice Reality s.r.o."}, &p); code != 403 || p.Code != "email_not_verified" {
		t.Fatalf("unverified org create: %d %+v", code, p)
	}
	e.verifyEmail(alice)
	e.must(200, "GET", "/v1/me", tok, nil, &m)
	if m.VerificationLevel != "email" {
		t.Fatalf("level after verify: %s", m.VerificationLevel)
	}

	// Enable TOTP.
	var setup struct {
		Secret     string `json:"secret"`
		OtpauthURI string `json:"otpauth_uri"`
	}
	e.must(200, "POST", "/v1/me/mfa/totp/setup", tok, nil, &setup)
	if !strings.HasPrefix(setup.OtpauthURI, "otpauth://totp/TerraReality") {
		t.Fatalf("uri %s", setup.OtpauthURI)
	}
	var rc struct {
		RecoveryCodes []string `json:"recovery_codes"`
	}
	enableCode := totpNow(t, setup.Secret, -1)
	e.must(200, "POST", "/v1/me/mfa/totp/enable", tok, map[string]string{"code": enableCode}, &rc)
	if len(rc.RecoveryCodes) != 10 {
		t.Fatalf("recovery codes %v", rc.RecoveryCodes)
	}
	e.must(204, "POST", "/v1/auth/logout", tok, nil, nil)
	if code := e.call("GET", "/v1/me", tok, nil, nil); code != 401 {
		t.Fatalf("revoked session still works: %d", code)
	}

	// Login now needs the second factor; the same TOTP step cannot be replayed.
	var lr authRes
	e.must(200, "POST", "/v1/auth/login", "", map[string]string{"email": alice, "password": "Sup3r-secret-pw"}, &lr)
	if lr.Status != "mfa_required" || lr.MfaToken == "" {
		t.Fatalf("login: %+v", lr)
	}
	if code := e.call("POST", "/v1/auth/mfa", "", map[string]string{"mfa_token": lr.MfaToken, "code": enableCode}, &p); code != 401 {
		t.Fatalf("replayed code accepted: %d", code)
	}
	e.must(200, "POST", "/v1/auth/mfa", "", map[string]string{"mfa_token": lr.MfaToken, "code": totpNow(t, setup.Secret, 0)}, &lr)
	tok = lr.Session.Token
	if tok == "" {
		t.Fatal("no session after mfa")
	}
	// A recovery code works once.
	e.must(200, "POST", "/v1/auth/login", "", map[string]string{"email": alice, "password": "Sup3r-secret-pw"}, &lr)
	e.must(200, "POST", "/v1/auth/mfa", "", map[string]string{"mfa_token": lr.MfaToken, "code": strings.ToUpper(rc.RecoveryCodes[0])}, nil)
	e.must(200, "POST", "/v1/auth/login", "", map[string]string{"email": alice, "password": "Sup3r-secret-pw"}, &lr)
	if code := e.call("POST", "/v1/auth/mfa", "", map[string]string{"mfa_token": lr.MfaToken, "code": rc.RecoveryCodes[0]}, nil); code != 401 {
		t.Fatalf("recovery code reused: %d", code)
	}

	// Organization and invitation.
	var org membership
	e.must(201, "POST", "/v1/orgs", tok, map[string]string{"name": "Alice Reality s.r.o.", "registration_no": "12345678"}, &org)
	if org.Role != "owner" || org.Organization.Kind != "company" {
		t.Fatalf("org %+v", org)
	}
	bob := uniqueEmail("bob")
	orgPath := "/v1/orgs/" + org.Organization.ID.String()
	e.must(201, "POST", orgPath+"/invitations", tok, map[string]string{"email": bob, "role": "agent"}, nil)
	inv, ok := e.outbox.Last(bob, "invitation")
	if !ok || !strings.Contains(inv.Text, "Alice Reality") {
		t.Fatalf("invitation e-mail: %+v", inv)
	}
	invTok := notify.LinkToken(inv.Text)
	var preview struct {
		OrgName string `json:"org_name"`
		Status  string `json:"status"`
	}
	e.must(200, "GET", "/v1/invitations/"+invTok, "", nil, &preview)
	if preview.Status != "open" || preview.OrgName != "Alice Reality s.r.o." {
		t.Fatalf("preview %+v", preview)
	}
	// Someone else cannot use Bob's invitation.
	mallory := e.register(uniqueEmail("mallory"))
	if code := e.call("POST", "/v1/invitations/"+invTok+"/accept", mallory, nil, &p); code != 403 || p.Code != "invitation_email_mismatch" {
		t.Fatalf("foreign accept: %d %+v", code, p)
	}
	bobTok := e.register(bob)
	var joined membership
	e.must(200, "POST", "/v1/invitations/"+invTok+"/accept", bobTok, nil, &joined)
	if joined.Role != "agent" || joined.Organization.ID != org.Organization.ID {
		t.Fatalf("joined %+v", joined)
	}
	if code := e.call("POST", "/v1/invitations/"+invTok+"/accept", bobTok, nil, &p); code != 409 {
		t.Fatalf("second accept: %d", code)
	}
	var members []struct {
		Email string `json:"email"`
		Role  string `json:"role"`
	}
	e.must(200, "GET", orgPath+"/members", tok, nil, &members)
	if len(members) != 2 {
		t.Fatalf("members %+v", members)
	}
	// Agents cannot manage members; the last owner cannot be demoted.
	if code := e.call("POST", orgPath+"/invitations", bobTok, map[string]string{"email": uniqueEmail("x"), "role": "viewer"}, &p); code != 403 {
		t.Fatalf("agent invite: %d %+v", code, p)
	}
	if code := e.call("PATCH", orgPath+"/members/"+m.ID.String(), tok, map[string]string{"role": "admin"}, &p); code != 409 || p.Code != "last_owner" {
		t.Fatalf("demote last owner: %d %+v", code, p)
	}
	var audit struct {
		Items []struct {
			Action string `json:"action"`
		} `json:"items"`
	}
	e.must(200, "GET", orgPath+"/audit", tok, nil, &audit)
	actions := map[string]bool{}
	for _, a := range audit.Items {
		actions[a.Action] = true
	}
	for _, want := range []string{"org.created", "invitation.created", "invitation.accepted"} {
		if !actions[want] {
			t.Errorf("audit missing %s: %+v", want, audit.Items)
		}
	}
}

// Acceptance M1: organization A never sees data of organization B (RLS).
func TestRowLevelSecurityIsolatesOrganizations(t *testing.T) {
	e := newEnv(t)
	emails := []string{uniqueEmail("rls-a"), uniqueEmail("rls-b")}
	toks := make([]string, 2)
	orgs := make([]membership, 2)
	for i, em := range emails {
		toks[i] = e.register(em)
		e.verifyEmail(em)
		e.must(201, "POST", "/v1/orgs", toks[i], map[string]string{"name": "Org " + em[:5]}, &orgs[i])
	}
	var p problem
	if code := e.call("GET", "/v1/orgs/"+orgs[0].Organization.ID.String(), toks[1], nil, &p); code != 404 {
		t.Fatalf("B read A's org: %d", code)
	}
	if code := e.call("GET", "/v1/orgs/"+orgs[0].Organization.ID.String()+"/members", toks[1], nil, &p); code != 404 {
		t.Fatalf("B listed A's members: %d", code)
	}
	if code := e.call("PATCH", "/v1/orgs/"+orgs[0].Organization.ID.String(), toks[1], map[string]string{"name": "pwned"}, &p); code != 404 {
		t.Fatalf("B renamed A's org: %d", code)
	}

	// Database level: as user B, only B's rows exist, whatever the query.
	var bID uuid.UUID
	var m me
	e.must(200, "GET", "/v1/me", toks[1], nil, &m)
	bID = m.ID
	ctx := context.Background()
	err := platformdb.AsUser(ctx, e.pool, bID, func(tx pgx.Tx) error {
		rows, err := tx.Query(ctx, "SELECT id FROM organizations")
		if err != nil {
			return err
		}
		defer rows.Close()
		for rows.Next() {
			var id uuid.UUID
			if err := rows.Scan(&id); err != nil {
				return err
			}
			if id == orgs[0].Organization.ID {
				t.Errorf("RLS leak: B sees org A")
			}
		}
		var n int
		if err := tx.QueryRow(ctx, "SELECT count(*) FROM memberships WHERE org_id = $1", orgs[0].Organization.ID).Scan(&n); err != nil {
			return err
		}
		if n != 0 {
			t.Errorf("RLS leak: B sees %d memberships of A", n)
		}
		if err := tx.QueryRow(ctx, "SELECT count(*) FROM audit_events WHERE org_id = $1", orgs[0].Organization.ID).Scan(&n); err != nil {
			return err
		}
		if n != 0 {
			t.Errorf("RLS leak: B sees %d audit events of A", n)
		}
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
	// Credentials are not readable from the app role at all.
	for _, q := range []string{"SELECT password_hash FROM users LIMIT 1", "SELECT token_hash FROM sessions LIMIT 1"} {
		err := platformdb.AsUser(ctx, e.pool, bID, func(tx pgx.Tx) error {
			_, err := tx.Exec(ctx, q)
			return err
		})
		if err == nil || !strings.Contains(err.Error(), "permission denied") {
			t.Errorf("%s: want permission denied, got %v", q, err)
		}
	}
	// Inserting into another organization is rejected by the policy.
	err = platformdb.AsUser(ctx, e.pool, bID, func(tx pgx.Tx) error {
		_, err := tx.Exec(ctx, "INSERT INTO memberships (org_id, user_id, role) VALUES ($1, $2, 'owner')", orgs[0].Organization.ID, bID)
		return err
	})
	if err == nil || !strings.Contains(err.Error(), "row-level security") {
		t.Errorf("cross-org insert: %v", err)
	}
}

// Acceptance M1: the BankID mock flow raises the verification level.
func TestBankIDMockFlow(t *testing.T) {
	e := newEnv(t)
	em := uniqueEmail("bankid")
	tok := e.register(em)
	redirect := redirectBase + "identity"
	var start struct {
		AuthorizationURL string `json:"authorization_url"`
	}
	var p problem
	if code := e.call("POST", "/v1/me/identity/start", tok, map[string]string{"redirect_uri": "http://evil.test/cb"}, &p); code != 400 || p.Code != "redirect_not_allowed" {
		t.Fatalf("evil redirect: %d %+v", code, p)
	}
	e.must(200, "POST", "/v1/me/identity/start", tok, map[string]string{"redirect_uri": redirect}, &start)
	sub := "bankid-" + uuid.NewString()
	code, state := e.followMock(start.AuthorizationURL, url.Values{"given_name": {"Jana"}, "family_name": {"Nováková"},
		"birthdate": {"1990-05-17"}, "street": {"Dejvická 1"}, "city": {"Praha"}, "zipcode": {"16000"}, "sub": {sub}})
	var m me
	e.must(200, "POST", "/v1/me/identity/callback", tok, map[string]string{"code": code, "state": state, "redirect_uri": redirect}, &m)
	if m.VerificationLevel != "identity" || m.Identity == nil || m.Identity.FamilyName != "Nováková" || m.Identity.Birthdate != "1990-05-17" {
		t.Fatalf("after bankid: %+v %+v", m, m.Identity)
	}
	// The state is single use.
	if c := e.call("POST", "/v1/me/identity/callback", tok, map[string]string{"code": code, "state": state, "redirect_uri": redirect}, &p); c != 400 {
		t.Fatalf("state reuse: %d", c)
	}
	// The same bank identity cannot verify a second account.
	other := e.register(uniqueEmail("bankid2"))
	e.must(200, "POST", "/v1/me/identity/start", other, map[string]string{"redirect_uri": redirect}, &start)
	code, state = e.followMock(start.AuthorizationURL, url.Values{"given_name": {"Jana"}, "family_name": {"Nováková"}, "sub": {sub}})
	if c := e.call("POST", "/v1/me/identity/callback", other, map[string]string{"code": code, "state": state, "redirect_uri": redirect}, &p); c != 409 || p.Code != "identity_in_use" {
		t.Fatalf("identity reuse: %d %+v", c, p)
	}
}

func TestSocialLoginMockLinksAccounts(t *testing.T) {
	e := newEnv(t)
	em := uniqueEmail("social")
	redirect := redirectBase + "callback/google"
	login := func(sub string) authRes {
		var start struct {
			AuthorizationURL string `json:"authorization_url"`
		}
		e.must(200, "POST", "/v1/auth/oidc/google/start", "", map[string]string{"redirect_uri": redirect}, &start)
		code, state := e.followMock(start.AuthorizationURL, url.Values{"email": {em}, "given_name": {"Soc"}, "family_name": {"Ial"}, "sub": {sub}})
		var r authRes
		e.must(200, "POST", "/v1/auth/oidc/google/callback", "", map[string]string{"code": code, "state": state, "redirect_uri": redirect}, &r)
		return r
	}
	sub := "g-" + uuid.NewString()
	first := login(sub)
	second := login(sub)
	var m1, m2 me
	e.must(200, "GET", "/v1/me", first.Session.Token, nil, &m1)
	e.must(200, "GET", "/v1/me", second.Session.Token, nil, &m2)
	if m1.ID != m2.ID || !m1.EmailVerified || len(m1.Organizations) != 1 {
		t.Fatalf("social users differ or incomplete: %+v %+v", m1, m2)
	}
	var providers []struct {
		ID   string `json:"id"`
		Mock bool   `json:"mock"`
	}
	e.must(200, "GET", "/v1/auth/providers", "", nil, &providers)
	if len(providers) != 1 || providers[0].ID != "google" || !providers[0].Mock {
		t.Fatalf("providers %+v", providers)
	}
}

func TestMagicLinkAndPasswordReset(t *testing.T) {
	e := newEnv(t)
	em := uniqueEmail("magic")
	old := e.register(em)
	e.must(202, "POST", "/v1/auth/magic-link", "", map[string]string{"email": em}, nil)
	e.must(202, "POST", "/v1/auth/magic-link", "", map[string]string{"email": uniqueEmail("nobody")}, nil)
	msg, ok := e.outbox.Last(em, "magic_link")
	if !ok {
		t.Fatal("no magic link")
	}
	var r authRes
	e.must(200, "POST", "/v1/auth/magic-link/verify", "", map[string]string{"token": notify.LinkToken(msg.Text)}, &r)
	if r.Status != "authenticated" {
		t.Fatalf("magic: %+v", r)
	}
	if c := e.call("POST", "/v1/auth/magic-link/verify", "", map[string]string{"token": notify.LinkToken(msg.Text)}, nil); c != 400 {
		t.Fatalf("magic link reuse: %d", c)
	}
	e.must(202, "POST", "/v1/auth/password/forgot", "", map[string]string{"email": em}, nil)
	msg, _ = e.outbox.Last(em, "password_reset")
	e.must(204, "POST", "/v1/auth/password/reset", "", map[string]string{"token": notify.LinkToken(msg.Text), "password": "N3w-password-123"}, nil)
	if c := e.call("GET", "/v1/me", old, nil, nil); c != 401 {
		t.Fatalf("sessions survive reset: %d", c)
	}
	e.must(200, "POST", "/v1/auth/login", "", map[string]string{"email": em, "password": "N3w-password-123"}, &r)
	var p problem
	if c := e.call("POST", "/v1/auth/login", "", map[string]string{"email": em, "password": "Sup3r-secret-pw"}, &p); c != 401 || p.Code != "invalid_credentials" {
		t.Fatalf("old password: %d %+v", c, p)
	}
}

func TestValidationAndAuthErrors(t *testing.T) {
	e := newEnv(t)
	var p problem
	if c := e.call("POST", "/v1/auth/register", "", map[string]any{"email": "not-an-email", "password": "x"}, &p); c != 400 || p.Code != "validation_failed" {
		t.Fatalf("validation: %d %+v", c, p)
	}
	if c := e.call("GET", "/v1/me", "", nil, &p); c != 401 || p.Code != "unauthenticated" {
		t.Fatalf("anonymous me: %d %+v", c, p)
	}
	if c := e.call("GET", "/v1/me", "garbage-token", nil, &p); c != 401 {
		t.Fatalf("bad token: %d", c)
	}
	// ASVS V2.1.1 / V2.1.7: 12-character minimum and breached-password check.
	if c := e.call("POST", "/v1/auth/register", "", map[string]any{"email": uniqueEmail("short"), "password": "Short-pw-11",
		"display_name": "x", "accept_terms_version": "t1", "accept_privacy_version": "p1"}, &p); c != 400 {
		t.Fatalf("11-character password: %d %+v", c, p)
	}
	if c := e.call("POST", "/v1/auth/register", "", map[string]any{"email": uniqueEmail("pwned"), "password": "Password1234",
		"display_name": "x", "accept_terms_version": "t1", "accept_privacy_version": "p1"}, &p); c != 422 || p.Code != "password_breached" {
		t.Fatalf("breached password: %d %+v", c, p)
	}
	em := uniqueEmail("dup")
	tok := e.register(em)
	if c := e.call("POST", "/v1/me/password", tok, map[string]any{"current_password": "Sup3r-secret-pw", "new_password": "qwerty123456"}, &p); c != 422 || p.Code != "password_breached" {
		t.Fatalf("breached new password: %d %+v", c, p)
	}
	if c := e.call("POST", "/v1/me/password", tok, map[string]any{"new_password": "An0ther-long-secret"}, &p); c != 401 || p.Code != "invalid_credentials" {
		t.Fatalf("password change without current password: %d %+v", c, p)
	}
	if c := e.call("POST", "/v1/auth/register", "", map[string]any{"email": strings.ToUpper(em), "password": "Sup3r-secret-pw",
		"display_name": "x", "accept_terms_version": "t1", "accept_privacy_version": "p1"}, &p); c != 409 || p.Code != "email_taken" {
		t.Fatalf("duplicate: %d %+v", c, p)
	}
	var j []struct {
		Code             string `json:"code"`
		DepositMaxMonths int    `json:"deposit_max_months"`
		Currency         string `json:"currency"`
	}
	e.must(200, "GET", "/v1/jurisdictions", "", nil, &j)
	if len(j) == 0 || j[0].Code != "CZ" || j[0].DepositMaxMonths != 3 || j[0].Currency != "CZK" {
		t.Fatalf("jurisdictions %+v", j)
	}
}

func TestPhoneVerification(t *testing.T) {
	e := newEnv(t)
	em := uniqueEmail("phone")
	tok := e.register(em)
	e.verifyEmail(em)
	e.must(202, "POST", "/v1/me/phone", tok, map[string]string{"phone": "+420601234567"}, nil)
	sms, ok := e.outbox.Last("+420601234567", "sms_code")
	if !ok {
		t.Fatal("no sms")
	}
	code := sms.Text[strings.Index(sms.Text, "je ")+3:][:6]
	var p problem
	if c := e.call("POST", "/v1/me/phone/verify", tok, map[string]string{"code": "000000"}, &p); c != 400 {
		t.Fatalf("wrong code: %d", c)
	}
	var m me
	e.must(200, "POST", "/v1/me/phone/verify", tok, map[string]string{"code": code}, &m)
	if m.VerificationLevel != "phone" {
		t.Fatalf("level %s", m.VerificationLevel)
	}
}

func TestImpersonationIsAuditedAndRestricted(t *testing.T) {
	e := newEnv(t)
	staffEmail, userEmail := uniqueEmail("staff"), uniqueEmail("victim")
	staffTok := e.register(staffEmail)
	userTok := e.register(userEmail)
	var target me
	e.must(200, "GET", "/v1/me", userTok, nil, &target)
	if c := e.call("GET", "/v1/backoffice/users", staffTok, nil, nil); c != 403 {
		t.Fatalf("non-staff backoffice: %d", c)
	}
	if _, err := e.pool.Exec(context.Background(), "UPDATE users SET is_staff = true WHERE email = $1", staffEmail); err != nil {
		t.Fatal(err)
	}
	var page struct {
		Items []struct {
			ID    uuid.UUID `json:"id"`
			Email string    `json:"email"`
		} `json:"items"`
	}
	e.must(200, "GET", "/v1/backoffice/users?q="+url.QueryEscape(userEmail), staffTok, nil, &page)
	if len(page.Items) != 1 || page.Items[0].ID != target.ID {
		t.Fatalf("search %+v", page)
	}
	var r authRes
	e.must(200, "POST", "/v1/backoffice/users/"+target.ID.String()+"/impersonate", staffTok, map[string]string{"reason": "support ticket #42"}, &r)
	imp := r.Session.Token
	var m me
	e.must(200, "GET", "/v1/me", imp, nil, &m)
	if m.ID != target.ID || m.Impersonator == nil || m.Impersonator.Email != staffEmail {
		t.Fatalf("impersonated me: %+v", m)
	}
	var p problem
	if c := e.call("POST", "/v1/me/password", imp, map[string]string{"current_password": "Sup3r-secret-pw", "new_password": "Hijack-pass-123"}, &p); c != 403 || p.Code != "impersonation_forbidden" {
		t.Fatalf("password change while impersonating: %d %+v", c, p)
	}
	if c := e.call("GET", "/v1/backoffice/users", imp, nil, nil); c != 403 {
		t.Fatalf("impersonation session has staff rights: %d", c)
	}
	var audit struct {
		Items []struct {
			Action string         `json:"action"`
			Diff   map[string]any `json:"diff"`
		} `json:"items"`
	}
	e.must(200, "GET", "/v1/backoffice/audit?entity=user&limit=200", staffTok, nil, &audit)
	found := false
	for _, a := range audit.Items {
		if a.Action == "impersonation.start" && a.Diff["reason"] == "support ticket #42" {
			found = true
		}
	}
	if !found {
		t.Fatal("impersonation not audited")
	}
}

func TestGDPRExportAndErasure(t *testing.T) {
	e := newEnv(t)
	em := uniqueEmail("gdpr")
	tok := e.register(em)
	var req struct {
		ID     uuid.UUID `json:"id"`
		Status string    `json:"status"`
	}
	e.must(202, "POST", "/v1/me/data-exports", tok, nil, &req)
	var p problem
	if c := e.call("GET", "/v1/me/data-exports/"+req.ID.String()+"/download", tok, nil, &p); c != 409 {
		t.Fatalf("download before ready: %d", c)
	}
	if err := e.acct.RunExport(context.Background(), req.ID); err != nil {
		t.Fatal(err)
	}
	var link struct {
		URL string `json:"url"`
	}
	e.must(200, "GET", "/v1/me/data-exports/"+req.ID.String()+"/download", tok, nil, &link)
	if !strings.Contains(link.URL, "gdpr/exports/") {
		t.Fatalf("link %s", link.URL)
	}
	body, err := e.acct.Blob.Get(context.Background(), link.URL[len("http://blob.test/"):strings.Index(link.URL, "?")])
	if err != nil || !strings.Contains(string(body), em) {
		t.Fatalf("export body %v %s", err, body)
	}

	e.must(202, "POST", "/v1/me/erasure", tok, nil, &req)
	if err := e.acct.RunErasure(context.Background(), req.ID); err != nil {
		t.Fatal(err)
	}
	if c := e.call("GET", "/v1/me", tok, nil, nil); c != 401 {
		t.Fatalf("session after erasure: %d", c)
	}
	if c := e.call("POST", "/v1/auth/login", "", map[string]string{"email": em, "password": "Sup3r-secret-pw"}, &p); c != 401 {
		t.Fatalf("login after erasure: %d", c)
	}
	var count int
	if err := e.pool.QueryRow(context.Background(), "SELECT count(*) FROM users WHERE email = $1", em).Scan(&count); err != nil || count != 0 {
		t.Fatalf("e-mail still stored: %d %v", count, err)
	}
}
