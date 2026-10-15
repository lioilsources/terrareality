package integration

import (
	"context"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/terrareality/terrareality/services/api/internal/auth"
	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/platform/tokens"
)

// principalOf resolves token through the session middleware (absolute
// lifetime maxAge) and returns the principal, nil when the session is refused.
func (e *env) principalOf(token string, maxAge time.Duration) *auth.Principal {
	e.t.Helper()
	var got *auth.Principal
	log := slog.New(slog.NewTextHandler(io.Discard, nil))
	h := auth.Middleware(db.New(e.pool), func(string) time.Duration { return time.Hour }, maxAge, log)(
		http.HandlerFunc(func(_ http.ResponseWriter, r *http.Request) { got = auth.FromContext(r.Context()) }))
	req := httptest.NewRequest(http.MethodGet, "/v1/me", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	h.ServeHTTP(httptest.NewRecorder(), req)
	return got
}

func TestLoginLockoutPerAccountIsAudited(t *testing.T) {
	e := newEnv(t)
	em := uniqueEmail("locked")
	e.register(em)
	var p problem
	for i := range 6 {
		if c := e.call("POST", "/v1/auth/login", "", map[string]string{"email": em, "password": "Wrong-password-1"}, &p); c != 401 {
			t.Fatalf("failure %d: %d %+v", i+1, c, p)
		}
	}
	// Locked now, even with the right password (and from any IP).
	if c := e.call("POST", "/v1/auth/login", "", map[string]string{"email": em, "password": "Sup3r-secret-pw"}, &p); c != 429 {
		t.Fatalf("locked account: %d %+v", c, p)
	}
	// Unknown addresses lock the same way (no account enumeration).
	ghost := uniqueEmail("ghost")
	for range 6 {
		e.call("POST", "/v1/auth/login", "", map[string]string{"email": ghost, "password": "Wrong-password-1"}, nil)
	}
	if c := e.call("POST", "/v1/auth/login", "", map[string]string{"email": ghost, "password": "Wrong-password-1"}, nil); c != 429 {
		t.Fatalf("unknown address: %d", c)
	}
	var n int
	if err := e.pool.QueryRow(context.Background(), `SELECT count(*) FROM audit_events a JOIN users u ON u.id = a.entity_id
		WHERE u.email = $1 AND a.action = 'user.login_failed'`, em).Scan(&n); err != nil {
		t.Fatal(err)
	}
	if n != 6 {
		t.Fatalf("login_failed audit events: %d, want 6", n)
	}
}

func TestEnablingTOTPRevokesOtherSessionsAndMarksMFASessions(t *testing.T) {
	e := newEnv(t)
	em := uniqueEmail("mfa")
	tok := e.register(em)
	var lr authRes
	e.must(200, "POST", "/v1/auth/login", "", map[string]string{"email": em, "password": "Sup3r-secret-pw"}, &lr)
	other := lr.Session.Token
	if p := e.principalOf(tok, 0); p == nil || p.MFA {
		t.Fatalf("pre-MFA session: %+v", p)
	}

	var setup struct {
		Secret string `json:"secret"`
	}
	e.must(200, "POST", "/v1/me/mfa/totp/setup", tok, nil, &setup)
	e.must(200, "POST", "/v1/me/mfa/totp/enable", tok, map[string]string{"code": totpNow(t, setup.Secret, -1)}, nil)
	if c := e.call("GET", "/v1/me", other, nil, nil); c != 401 {
		t.Fatalf("other session survived enabling TOTP: %d", c)
	}
	// The enabling session stays, but it never passed the second factor.
	if p := e.principalOf(tok, 0); p == nil || p.MFA {
		t.Fatalf("enabling session: %+v", p)
	}
	e.must(200, "POST", "/v1/auth/login", "", map[string]string{"email": em, "password": "Sup3r-secret-pw"}, &lr)
	e.must(200, "POST", "/v1/auth/mfa", "", map[string]string{"mfa_token": lr.MfaToken, "code": totpNow(t, setup.Secret, 0)}, &lr)
	if p := e.principalOf(lr.Session.Token, 0); p == nil || !p.MFA {
		t.Fatalf("session after the second factor: %+v", p)
	}
}

func TestSessionAbsoluteLifetimeOnLookup(t *testing.T) {
	e := newEnv(t)
	tok := e.register(uniqueEmail("old"))
	// A session from before the cap: created long ago, stored expiry far ahead.
	if _, err := e.pool.Exec(context.Background(), `UPDATE sessions SET created_at = now() - interval '2 hours',
		expires_at = now() + interval '90 days' WHERE token_hash = $1`, tokens.Hash(tok)); err != nil {
		t.Fatal(err)
	}
	if p := e.principalOf(tok, time.Hour); p != nil {
		t.Fatal("session older than SESSION_MAX_AGE accepted")
	}
	if p := e.principalOf(tok, 0); p == nil {
		t.Fatal("no cap configured: session must work")
	}
}

func TestPasswordChecksPrecedeBreachLookup(t *testing.T) {
	e := newEnv(t)
	var p problem
	// A bogus reset token is refused before the (outbound) breach lookup.
	if c := e.call("POST", "/v1/auth/password/reset", "", map[string]string{"token": "bogus-token-0123456789abcdef", "password": "Password1234"}, &p); c != 400 || p.Code != "invalid_token" {
		t.Fatalf("bogus token with breached password: %d %+v", c, p)
	}
	// A stolen session cannot probe the breach corpus without the current password.
	tok := e.register(uniqueEmail("probe"))
	if c := e.call("POST", "/v1/me/password", tok, map[string]any{"current_password": "Not-the-password", "new_password": "qwerty123456"}, &p); c != 401 || p.Code != "invalid_credentials" {
		t.Fatalf("wrong current password with breached new one: %d %+v", c, p)
	}
	e.must(204, "POST", "/v1/me/password", tok, map[string]any{"current_password": "Sup3r-secret-pw", "new_password": "An0ther-long-secret"}, nil)
}

func TestRegisterRequiresCurrentTerms(t *testing.T) {
	e := newEnv(t)
	var p problem
	if c := e.call("POST", "/v1/auth/register", "", map[string]any{"email": uniqueEmail("terms"), "password": "Sup3r-secret-pw",
		"display_name": "x", "accept_terms_version": "t0", "accept_privacy_version": "p1"}, &p); c != 422 || p.Code != "terms_outdated" {
		t.Fatalf("outdated terms: %d %+v", c, p)
	}
}

func TestImpersonatorCannotTouchPhoneExportOrSessions(t *testing.T) {
	e := newEnv(t)
	staffEmail, userEmail := uniqueEmail("staff"), uniqueEmail("target")
	staffTok := e.register(staffEmail)
	userTok := e.register(userEmail)
	e.verifyEmail(userEmail)
	if _, err := e.pool.Exec(context.Background(), "UPDATE users SET is_staff = true WHERE email = $1", staffEmail); err != nil {
		t.Fatal(err)
	}
	var target me
	e.must(200, "GET", "/v1/me", userTok, nil, &target)
	var r authRes
	e.must(200, "POST", "/v1/backoffice/users/"+target.ID.String()+"/impersonate", staffTok, map[string]string{"reason": "ticket #7"}, &r)
	imp := r.Session.Token

	var sessions []struct {
		ID string `json:"id"`
	}
	e.must(200, "GET", "/v1/me/sessions", imp, nil, &sessions)
	if len(sessions) == 0 {
		t.Fatal("no sessions")
	}
	for _, c := range []struct{ method, path string }{
		{"POST", "/v1/me/phone"},
		{"POST", "/v1/me/phone/verify"},
		{"POST", "/v1/me/data-exports"},
		{"DELETE", "/v1/me/sessions/" + sessions[0].ID},
	} {
		var body any
		switch c.path {
		case "/v1/me/phone":
			body = map[string]string{"phone": "+420601234567"}
		case "/v1/me/phone/verify":
			body = map[string]string{"code": "123456"}
		}
		var p problem
		if code := e.call(c.method, c.path, imp, body, &p); code != 403 || p.Code != "impersonation_forbidden" {
			t.Errorf("%s %s while impersonating: %d %+v", c.method, c.path, code, p)
		}
	}
}

func TestPhoneVerificationCanBeDisabled(t *testing.T) {
	e := newEnv(t)
	e.acct.Cfg.DisablePhoneVerification = true
	em := uniqueEmail("nophone")
	tok := e.register(em)
	e.verifyEmail(em)
	var p problem
	if c := e.call("POST", "/v1/me/phone", tok, map[string]string{"phone": "+420601234567"}, &p); c != 503 || p.Code != "phone_verification_unavailable" {
		t.Fatalf("disabled phone verification: %d %+v", c, p)
	}
	if _, ok := e.outbox.Last("+420601234567", "sms_code"); ok {
		t.Fatal("an SMS code was sent")
	}
}
