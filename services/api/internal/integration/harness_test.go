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
	"os"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/terrareality/terrareality/services/api/internal/account"
	"github.com/terrareality/terrareality/services/api/internal/ai"
	"github.com/terrareality/terrareality/services/api/internal/api"
	"github.com/terrareality/terrareality/services/api/internal/applications"
	"github.com/terrareality/terrareality/services/api/internal/auth"
	"github.com/terrareality/terrareality/services/api/internal/catalog"
	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/health"
	"github.com/terrareality/terrareality/services/api/internal/identity"
	"github.com/terrareality/terrareality/services/api/internal/isir"
	"github.com/terrareality/terrareality/services/api/internal/leasing"
	"github.com/terrareality/terrareality/services/api/internal/listing"
	"github.com/terrareality/terrareality/services/api/internal/media"
	"github.com/terrareality/terrareality/services/api/internal/messaging"
	"github.com/terrareality/terrareality/services/api/internal/notify"
	"github.com/terrareality/terrareality/services/api/internal/org"
	"github.com/terrareality/terrareality/services/api/internal/platform/secretbox"
	"github.com/terrareality/terrareality/services/api/internal/portfolio"
	"github.com/terrareality/terrareality/services/api/internal/realtime"
	"github.com/terrareality/terrareality/services/api/internal/ruian"
	"github.com/terrareality/terrareality/services/api/internal/search"
	"github.com/terrareality/terrareality/services/api/internal/storage"
	"github.com/terrareality/terrareality/services/api/internal/vision"
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

// recJobs records catalog jobs; tests run them explicitly.
type recJobs struct {
	mu          sync.Mutex
	media       []uuid.UUID
	suggestions []uuid.UUID
}

func (r *recJobs) ProcessMedia(_ context.Context, _ pgx.Tx, id uuid.UUID) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.media = append(r.media, id)
	return nil
}

func (r *recJobs) RunSuggestion(_ context.Context, _ pgx.Tx, id uuid.UUID) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.suggestions = append(r.suggestions, id)
	return nil
}

// recMsgJobs records messaging jobs; tests run them explicitly.
type recMsgJobs struct {
	mu       sync.Mutex
	messages []uuid.UUID
	cases    []uuid.UUID
}

func (r *recMsgJobs) NotifyMessage(_ context.Context, _ pgx.Tx, id uuid.UUID, _ time.Duration) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.messages = append(r.messages, id)
	return nil
}

func (r *recMsgJobs) SuggestVerdict(_ context.Context, _ pgx.Tx, id uuid.UUID) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.cases = append(r.cases, id)
	return nil
}

// recPusher records push notifications.
type recPusher struct {
	mu    sync.Mutex
	items []notify.Push
}

func (r *recPusher) Push(_ context.Context, p notify.Push) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.items = append(r.items, p)
	return nil
}

func (r *recPusher) count(userID uuid.UUID) int {
	r.mu.Lock()
	defer r.mu.Unlock()
	n := 0
	for _, p := range r.items {
		if p.UserID == userID.String() {
			n++
		}
	}
	return n
}

// recAppJobs records application jobs.
type recAppJobs struct {
	mu        sync.Mutex
	summaries []uuid.UUID
	reminders []time.Time
}

func (r *recAppJobs) SummarizeApplication(_ context.Context, _ pgx.Tx, id uuid.UUID) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.summaries = append(r.summaries, id)
	return nil
}

func (r *recAppJobs) ViewingReminder(_ context.Context, _ pgx.Tx, _ uuid.UUID, at time.Time) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.reminders = append(r.reminders, at)
	return nil
}

// recLeaseJobs records lifecycle starts.
type recLeaseJobs struct {
	mu      sync.Mutex
	started []uuid.UUID
}

func (r *recLeaseJobs) StartLifecycle(_ context.Context, _ pgx.Tx, id uuid.UUID) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.started = append(r.started, id)
	return nil
}

type env struct {
	t        *testing.T
	pool     *pgxpool.Pool
	srv      *httptest.Server
	outbox   *notify.MemoryOutbox
	sched    *recScheduler
	acct     *account.Service
	listings *listing.Service
	jobs     *recJobs
	blob     *storage.Memory
	vision   *httptest.Server
	rt       *realtime.Memory
	msgJobs  *recMsgJobs
	pusher   *recPusher
	notifier *messaging.Notifier
	verdicts *messaging.Verdicts
	appJobs  *recAppJobs
	summary  *applications.Summaries
	leases   *leasing.Service
	bank     *leasing.MockBank
	leaseJob *recLeaseJobs
	risk     *portfolio.Scorer
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
	e := &env{t: t, pool: pool, outbox: &notify.MemoryOutbox{}, sched: &recScheduler{}, jobs: &recJobs{},
		blob: storage.NewMemory("http://blob.test")}
	if err := catalog.Sync(context.Background(), db.New(pool)); err != nil {
		t.Fatal(err)
	}
	if _, err := ruian.SeedSample(context.Background(), pool); err != nil {
		t.Fatal(err)
	}
	if _, err := search.SeedFromRuian(context.Background(), pool); err != nil {
		t.Fatal(err)
	}
	e.vision = fakeVision(t)
	img, err := media.NewImgproxy("http://img.test", "terra", "6b6579", "73616c74")
	if err != nil {
		t.Fatal(err)
	}
	mux := http.NewServeMux()
	e.srv = httptest.NewServer(mux)
	t.Cleanup(e.srv.Close)

	mocks := map[string]*identity.Mock{
		"google": identity.NewMock("google", e.srv.URL, box),
		"bankid": identity.NewMock("bankid", e.srv.URL, box),
	}
	idp := identity.NewRegistry(mocks["bankid"], mocks["google"])
	e.acct = &account.Service{Pool: pool, Box: box, Outbox: e.outbox, Render: render, IDP: idp,
		Blob: e.blob, Scheduler: e.sched, Cfg: account.Config{
			WebBaseURL: "http://web.test", SessionTTLWeb: time.Hour, SessionTTLMobile: time.Hour,
			RedirectAllow: []string{redirectBase}, TermsVersion: "t1", PrivacyVersion: "p1", ErasureGrace: 0,
		}}
	orgs := &org.Service{Pool: pool, Outbox: e.outbox, Render: render, WebBaseURL: "http://web.test"}
	e.listings = &listing.Service{Pool: pool, Blob: e.blob, Img: img, Scanner: media.NoScanner{}, Vision: vision.New(e.vision.URL),
		AI: ai.Mock{}, Jobs: e.jobs, Outbox: e.outbox, Render: render, WebBaseURL: "http://web.test",
		Flags: listing.Flags{AIAttributes: true, AIText: true, Vision: true}, Search: search.Indexer{}}
	log := slog.New(slog.NewTextHandler(io.Discard, nil))
	if os.Getenv("TEST_LOG") != "" {
		log = slog.New(slog.NewTextHandler(os.Stderr, nil))
	}
	e.rt, e.msgJobs, e.pusher = &realtime.Memory{}, &recMsgJobs{}, &recPusher{}
	messages := &messaging.Service{Pool: pool, RT: e.rt, Tokens: realtime.Tokens{Secret: []byte("rt"), TTL: time.Hour},
		WSURL: "ws://rt.test", Jobs: e.msgJobs, Blob: e.blob, Scanner: media.NoScanner{}, Outbox: e.outbox, Render: render,
		WebBaseURL: "http://web.test", Log: log}
	e.notifier = &messaging.Notifier{Pool: pool, RT: e.rt, Pusher: e.pusher, Outbox: e.outbox, Render: render,
		WebBaseURL: "http://web.test", Log: log}
	e.verdicts = &messaging.Verdicts{Pool: pool, AI: ai.Mock{}, Enabled: true}
	e.appJobs = &recAppJobs{}
	e.summary = &applications.Summaries{Pool: pool, AI: ai.Mock{}, Enabled: true}
	apps := &applications.Service{Pool: pool, RT: e.rt, Jobs: e.appJobs, Outbox: e.outbox, Render: render, Blob: e.blob,
		Scanner: media.NoScanner{}, ISIR: isir.Mock{}, WebBaseURL: "http://web.test", Log: log}
	e.bank, e.leaseJob = &leasing.MockBank{}, &recLeaseJobs{}
	e.leases = &leasing.Service{Pool: pool, Render: leasing.Typst{}, Signers: map[string]leasing.SignatureProvider{"mock": leasing.MockSigner{}},
		Bank: e.bank, Blob: e.blob, Jobs: e.leaseJob, Outbox: e.outbox, Mail: render, WebBaseURL: "http://web.test", Log: log}
	e.risk = &portfolio.Scorer{Pool: pool}
	folio := &portfolio.Service{Pool: pool, Scorer: e.risk, AI: ai.Mock{}}
	h := api.NewRouter(api.NewServer(pool, health.New(time.Second), api.Services{Account: e.acct, Orgs: orgs, IDP: idp, Listings: e.listings, RateBurst: 10000,
		Engine: &search.Engine{Pool: pool}, Chat: &search.Chat{Pool: pool, Model: "rules"}, Messages: messages, Applications: apps, Leases: e.leases,
		Portfolio: folio}),
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

// callRaw performs a request and returns the raw body.
func (e *env) callRaw(method, path, token string, out *[]byte) int {
	e.t.Helper()
	req, _ := http.NewRequest(method, e.srv.URL+path, nil)
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}
	res, err := http.DefaultClient.Do(req)
	if err != nil {
		e.t.Fatal(err)
	}
	defer res.Body.Close()
	*out, _ = io.ReadAll(res.Body)
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
