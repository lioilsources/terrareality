package integration

import (
	"bytes"
	"context"
	"encoding/json"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/terrareality/terrareality/services/api/internal/account"
	"github.com/terrareality/terrareality/services/api/internal/api"
	"github.com/terrareality/terrareality/services/api/internal/auth"
	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/health"
	"github.com/terrareality/terrareality/services/api/internal/identity"
	"github.com/terrareality/terrareality/services/api/internal/notify"
	"github.com/terrareality/terrareality/services/api/internal/org"
	"github.com/terrareality/terrareality/services/api/internal/platform/secretbox"
	"github.com/terrareality/terrareality/services/api/internal/storage"
)

const redirectBase = "http://web.test/auth/"

// recScheduler records GDPR jobs instead of enqueueing them.
type recScheduler struct {
	mu  sync.Mutex
	ids []uuid.UUID
}

func (r *recScheduler) ScheduleExport(_ context.Context, _ pgx.Tx, id uuid.UUID) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.ids = append(r.ids, id)
	return nil
}

func (r *recScheduler) ScheduleErasure(_ context.Context, _ pgx.Tx, id uuid.UUID, _ time.Time) error {
	return r.ScheduleExport(context.Background(), nil, id)
}

type env struct {
	t      *testing.T
	pool   *pgxpool.Pool
	srv    *httptest.Server
	outbox *notify.MemoryOutbox
	sched  *recScheduler
	acct   *account.Service
}

func newEnv(t *testing.T) *env {
	t.Helper()
	pool := setup(t)
	box, err := secretbox.New(strings.Repeat("s", 32))
	if err != nil {
		t.Fatal(err)
	}
	render, err := notify.NewRenderer()
	if err != nil {
		t.Fatal(err)
	}
	e := &env{t: t, pool: pool, outbox: &notify.MemoryOutbox{}, sched: &recScheduler{}}
	mux := http.NewServeMux()
	e.srv = httptest.NewServer(mux)
	t.Cleanup(e.srv.Close)

	mocks := map[string]*identity.Mock{
		"google": identity.NewMock("google", e.srv.URL, box),
		"bankid": identity.NewMock("bankid", e.srv.URL, box),
	}
	idp := identity.NewRegistry(mocks["bankid"], mocks["google"])
	e.acct = &account.Service{Pool: pool, Box: box, Outbox: e.outbox, Render: render, IDP: idp,
		Blob: storage.NewMemory("http://blob.test"), Scheduler: e.sched, Cfg: account.Config{
			WebBaseURL: "http://web.test", SessionTTLWeb: time.Hour, SessionTTLMobile: time.Hour,
			RedirectAllow: []string{redirectBase}, TermsVersion: "t1", PrivacyVersion: "p1", ErasureGrace: 0,
		}}
	orgs := &org.Service{Pool: pool, Outbox: e.outbox, Render: render, WebBaseURL: "http://web.test"}
	log := slog.New(slog.NewTextHandler(io.Discard, nil))
	h := api.NewRouter(api.NewServer(pool, health.New(time.Second), api.Services{Account: e.acct, Orgs: orgs, IDP: idp, RateBurst: 10000}),
		api.RouterConfig{Log: log, Sessions: db.New(pool), SessionTTL: e.acct.TTL, MockIdP: identity.MockHandler(mocks)})
	mux.Handle("/", h)
	return e
}

// call performs a JSON request and decodes the response into out (if non-nil).
func (e *env) call(method, path, token string, body any, out any) int {
	e.t.Helper()
	var r io.Reader
	if body != nil {
		b, _ := json.Marshal(body)
		r = bytes.NewReader(b)
	}
	req, _ := http.NewRequest(method, e.srv.URL+path, r)
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}
	res, err := http.DefaultClient.Do(req)
	if err != nil {
		e.t.Fatal(err)
	}
	defer res.Body.Close()
	raw, _ := io.ReadAll(res.Body)
	if out != nil && len(raw) > 0 {
		if err := json.Unmarshal(raw, out); err != nil {
			e.t.Fatalf("%s %s: decode %q: %v", method, path, raw, err)
		}
	}
	return res.StatusCode
}

// must fails the test when the status differs.
func (e *env) must(want int, method, path, token string, body any, out any) {
	e.t.Helper()
	var raw json.RawMessage
	got := e.call(method, path, token, body, &raw)
	if got != want {
		e.t.Fatalf("%s %s: status %d want %d: %s", method, path, got, want, raw)
	}
	if out != nil && len(raw) > 0 {
		if err := json.Unmarshal(raw, out); err != nil {
			e.t.Fatal(err)
		}
	}
}

type authRes struct {
	Status   string `json:"status"`
	MfaToken string `json:"mfa_token"`
	Session  struct {
		Token string `json:"token"`
	} `json:"session"`
}

type problem struct {
	Status int    `json:"status"`
	Code   string `json:"code"`
}

func uniqueEmail(prefix string) string {
	return prefix + "-" + strings.ReplaceAll(uuid.NewString()[:13], "-", "") + "@example.com"
}

func (e *env) register(email string) string {
	e.t.Helper()
	var res authRes
	e.must(201, "POST", "/v1/auth/register", "", map[string]any{
		"email": email, "password": "Sup3r-secret-pw", "display_name": "Test " + email[:4],
		"accept_terms_version": "t1", "accept_privacy_version": "p1",
	}, &res)
	if res.Status != "authenticated" || res.Session.Token == "" {
		e.t.Fatalf("register: %+v", res)
	}
	return res.Session.Token
}

func (e *env) verifyEmail(email string) {
	e.t.Helper()
	m, ok := e.outbox.Last(email, "verify_email")
	if !ok {
		e.t.Fatalf("no verification e-mail for %s", email)
	}
	e.must(204, "POST", "/v1/auth/email/verify", "", map[string]string{"token": notify.LinkToken(m.Text)}, nil)
}

// followMock drives the mock IdP page like a browser and returns code, state.
func (e *env) followMock(authURL string, form url.Values) (string, string) {
	e.t.Helper()
	client := &http.Client{CheckRedirect: func(*http.Request, []*http.Request) error { return http.ErrUseLastResponse }}
	res, err := client.PostForm(authURL, form)
	if err != nil {
		e.t.Fatal(err)
	}
	res.Body.Close()
	if res.StatusCode != http.StatusFound {
		e.t.Fatalf("mock idp status %d", res.StatusCode)
	}
	loc, _ := url.Parse(res.Header.Get("Location"))
	return loc.Query().Get("code"), loc.Query().Get("state")
}

func totpNow(t *testing.T, secret string, offset int64) string {
	t.Helper()
	raw, err := base32Decode(secret)
	if err != nil {
		t.Fatal(err)
	}
	return auth.TOTPCode(raw, auth.TOTPStep(time.Now())+offset)
}
