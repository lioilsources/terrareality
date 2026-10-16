package api

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"regexp"
	"strings"
	"testing"

	"github.com/terrareality/terrareality/services/api/internal/api/gen"
	"github.com/terrareality/terrareality/services/api/internal/auth"
	"github.com/terrareality/terrareality/services/api/internal/health"
	"github.com/terrareality/terrareality/services/api/internal/platform/apperr"
)

var pathParam = regexp.MustCompile(`\{[^}]+\}`)

// TestBearerAuthEnforcedForEveryOperation walks the contract: every operation
// that declares bearerAuth (explicitly or through the document default) must
// answer 401 without a session before any handler code runs, and every
// `security: []` operation must not.
func TestBearerAuthEnforcedForEveryOperation(t *testing.T) {
	spec, err := gen.GetSpec()
	if err != nil {
		t.Fatal(err)
	}
	h := newTestRouter(nil)
	var protected, public int
	for path, item := range spec.Paths.Map() {
		for method, op := range item.Operations() {
			sec := op.Security
			if sec == nil {
				sec = &spec.Security
			}
			needsAuth := len(*sec) > 0
			for _, req := range *sec {
				if len(req) == 0 { // `- {}`: anonymous allowed
					needsAuth = false
				}
			}
			url := pathParam.ReplaceAllString(path, "0190a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b")
			rec := httptest.NewRecorder()
			req := httptest.NewRequest(method, url, strings.NewReader("{}"))
			req.Header.Set("Content-Type", "application/json")
			func() {
				defer func() { _ = recover() }() // public handlers may need services the test lacks
				h.ServeHTTP(rec, req)
			}()
			if !needsAuth {
				public++
				if rec.Code == http.StatusUnauthorized {
					t.Errorf("%s %s (%s) is public in the contract but answered 401", method, path, op.OperationID)
				}
				continue
			}
			protected++
			var p struct {
				Code string `json:"code"`
			}
			_ = json.Unmarshal(rec.Body.Bytes(), &p)
			if rec.Code != http.StatusUnauthorized || p.Code != "unauthenticated" {
				t.Errorf("%s %s (%s) without a session: %d %s", method, path, op.OperationID, rec.Code, rec.Body)
			}
		}
	}
	if protected == 0 || public == 0 {
		t.Fatalf("walked %d protected and %d public operations", protected, public)
	}
}

func TestHealthHidesDetailsFromThePublic(t *testing.T) {
	h := newTestRouter(map[string]health.CheckFunc{
		"vision": func(context.Context) error { return errors.New("dial tcp 172.20.0.7:8000: connection refused") },
		"db":     func(context.Context) error { return nil },
	})
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/healthz", nil))
	if rec.Code != http.StatusServiceUnavailable {
		t.Fatalf("status %d", rec.Code)
	}
	body := rec.Body.String()
	if strings.Contains(body, "172.20.0.7") || strings.Contains(body, "latency_ms") {
		t.Fatalf("public health leaks details: %s", body)
	}
	if !strings.Contains(body, `"vision":{"status":"fail"}`) {
		t.Fatalf("check names and statuses must stay: %s", body)
	}
}

func TestStaffNeedsSecondFactorSession(t *testing.T) {
	s := NewServer(nil, nil, Services{StaffRequireMFA: true})
	ctx := auth.WithPrincipal(context.Background(), &auth.Principal{IsStaff: true})
	if _, err := s.staff(ctx); err == nil {
		t.Fatal("pre-MFA staff session accepted")
	} else if e, ok := apperr.As(err); !ok || e.Code != "staff_mfa_required" {
		t.Fatalf("err %v", err)
	}
	ctx = auth.WithPrincipal(context.Background(), &auth.Principal{IsStaff: true, MFA: true})
	if _, err := s.staff(ctx); err != nil {
		t.Fatalf("MFA session refused: %v", err)
	}
	s.StaffRequireMFA = false
	ctx = auth.WithPrincipal(context.Background(), &auth.Principal{IsStaff: true})
	if _, err := s.staff(ctx); err != nil {
		t.Fatalf("MFA not required: %v", err)
	}
}
