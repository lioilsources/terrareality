package api

import (
	"encoding/json"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"strconv"
	"testing"
	"time"

	"github.com/terrareality/terrareality/services/api/internal/health"
	"github.com/terrareality/terrareality/services/api/internal/platform/ratelimit"
)

func TestRateLimitMiddleware(t *testing.T) {
	h := rateLimit(RateLimits{Search: ratelimit.Rule{Every: time.Minute, Burst: 2},
		Message: ratelimit.Rule{Every: time.Minute, Burst: 1}})(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusNoContent)
	}))
	do := func(method, path string) *httptest.ResponseRecorder {
		rec := httptest.NewRecorder()
		h.ServeHTTP(rec, httptest.NewRequest(method, path, nil))
		return rec
	}
	for range 2 {
		if rec := do(http.MethodGet, "/v1/search"); rec.Code != http.StatusNoContent {
			t.Fatalf("within burst: %d", rec.Code)
		}
	}
	rec := do(http.MethodGet, "/v1/search")
	if rec.Code != http.StatusTooManyRequests || rec.Header().Get("Content-Type") != "application/problem+json" {
		t.Fatalf("over limit: %d %s", rec.Code, rec.Header().Get("Content-Type"))
	}
	if s, err := strconv.Atoi(rec.Header().Get("Retry-After")); err != nil || s < 1 || s > 60 {
		t.Fatalf("Retry-After %q", rec.Header().Get("Retry-After"))
	}
	var p struct {
		Status int    `json:"status"`
		Code   string `json:"code"`
	}
	if err := json.NewDecoder(rec.Body).Decode(&p); err != nil || p.Status != 429 || p.Code != "rate_limited" {
		t.Fatalf("problem %+v %v", p, err)
	}
	// Other routes and methods are not affected by the search limit.
	if rec := do(http.MethodGet, "/v1/search/chat"); rec.Code != http.StatusNoContent {
		t.Fatalf("unlimited route: %d", rec.Code)
	}
	// Message routes share one bucket.
	if rec := do(http.MethodPost, "/v1/conversations/abc/messages"); rec.Code != http.StatusNoContent {
		t.Fatalf("first message: %d", rec.Code)
	}
	if rec := do(http.MethodPost, "/v1/groups/xyz/messages"); rec.Code != http.StatusTooManyRequests {
		t.Fatalf("second message in another thread: %d", rec.Code)
	}
	// Disabled rules (zero value) let everything through.
	if rec := do(http.MethodPost, "/v1/webhooks/stripe"); rec.Code != http.StatusNoContent {
		t.Fatalf("webhook without rule: %d", rec.Code)
	}
}

// Through the full router: the limit answers before validation and handlers.
func TestRateLimitRouter(t *testing.T) {
	log := slog.New(slog.NewTextHandler(io.Discard, nil))
	c := health.New(time.Second)
	h := NewRouter(NewServer(nil, c, Services{}), RouterConfig{Log: log,
		RateLimits: RateLimits{Webhook: ratelimit.Rule{Every: time.Hour, Burst: 1}}})
	var codes []int
	for range 2 {
		rec := httptest.NewRecorder()
		h.ServeHTTP(rec, httptest.NewRequest(http.MethodPost, "/v1/webhooks/stripe", nil))
		codes = append(codes, rec.Code)
	}
	if codes[0] == http.StatusTooManyRequests || codes[1] != http.StatusTooManyRequests {
		t.Fatalf("codes %v", codes)
	}
}

func TestRateLimitReports(t *testing.T) {
	h := rateLimit(RateLimits{Report: ratelimit.Rule{Every: time.Hour, Burst: 1}})(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusCreated)
	}))
	do := func(path string) int {
		rec := httptest.NewRecorder()
		h.ServeHTTP(rec, httptest.NewRequest(http.MethodPost, path, nil))
		return rec.Code
	}
	if c := do("/v1/listings/abc/reports"); c != http.StatusCreated {
		t.Fatalf("first report: %d", c)
	}
	// Listing and conversation reports share one bucket per caller.
	if c := do("/v1/conversations/xyz/reports"); c != http.StatusTooManyRequests {
		t.Fatalf("second report: %d", c)
	}
	if c := do("/v1/listings/abc/similar"); c != http.StatusCreated {
		t.Fatalf("unrelated route: %d", c)
	}
}
