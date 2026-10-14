package api

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/terrareality/terrareality/services/api/internal/health"
)

func newTestRouter(checks map[string]health.CheckFunc) http.Handler {
	c := health.New(time.Second)
	for k, v := range checks {
		c.Add(k, v)
	}
	log := slog.New(slog.NewTextHandler(io.Discard, nil))
	return NewRouter(NewServer(nil, c), RouterConfig{Log: log, CORSOrigins: []string{"http://localhost:5173"}})
}

func TestHealthOK(t *testing.T) {
	h := newTestRouter(map[string]health.CheckFunc{"database": func(context.Context) error { return nil }})
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/healthz", nil))
	if rec.Code != http.StatusOK {
		t.Fatalf("status %d body %s", rec.Code, rec.Body)
	}
	var body struct {
		Status string                    `json:"status"`
		Checks map[string]map[string]any `json:"checks"`
	}
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
		t.Fatal(err)
	}
	if body.Status != "ok" || body.Checks["database"]["status"] != "ok" {
		t.Fatalf("unexpected body %+v", body)
	}
}

func TestHealthDegraded(t *testing.T) {
	h := newTestRouter(map[string]health.CheckFunc{"database": func(context.Context) error { return errors.New("down") }})
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/healthz", nil))
	if rec.Code != http.StatusServiceUnavailable {
		t.Fatalf("status %d", rec.Code)
	}
}

func TestNotFoundIsProblemJSON(t *testing.T) {
	h := newTestRouter(nil)
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/nope", nil))
	if rec.Code != http.StatusNotFound || rec.Header().Get("Content-Type") != "application/problem+json" {
		t.Fatalf("status %d ct %q", rec.Code, rec.Header().Get("Content-Type"))
	}
}

func TestCORSPreflight(t *testing.T) {
	h := newTestRouter(nil)
	req := httptest.NewRequest(http.MethodOptions, "/healthz", nil)
	req.Header.Set("Origin", "http://localhost:5173")
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)
	if rec.Code != http.StatusNoContent || rec.Header().Get("Access-Control-Allow-Origin") != "http://localhost:5173" {
		t.Fatalf("status %d headers %v", rec.Code, rec.Header())
	}
	req.Header.Set("Origin", "https://evil.example")
	rec = httptest.NewRecorder()
	h.ServeHTTP(rec, req)
	if rec.Header().Get("Access-Control-Allow-Origin") != "" {
		t.Fatal("foreign origin must not be allowed")
	}
}

func TestOpenAPIServed(t *testing.T) {
	h := newTestRouter(nil)
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/openapi.json", nil))
	if rec.Code != http.StatusOK {
		t.Fatalf("status %d", rec.Code)
	}
}
