package httpx

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestSecurityHeaders(t *testing.T) {
	handler := func(ct string) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
			w.Header().Set("Content-Type", ct)
			_, _ = w.Write([]byte("x"))
		})
	}
	cases := []struct {
		name, path, ct string
		hsts, wantCSP  bool
	}{
		{"json", "/v1/me", "application/json", false, true},
		{"problem", "/nope", "application/problem+json", true, true},
		{"pdf preview", "/v1/backoffice/templates/lease/preview", "application/pdf", false, false},
		{"mock checkout page", "/mock/stripe/checkout/cs_1", "text/html; charset=utf-8", false, false},
		{"dev idp page", "/dev/idp/authorize", "text/html; charset=utf-8", false, false},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			h := Security(SecurityOptions{HSTS: tc.hsts, DocumentPrefixes: DefaultDocumentPrefixes})(handler(tc.ct))
			rec := httptest.NewRecorder()
			h.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, tc.path, nil))
			got := rec.Header()
			if got.Get("X-Content-Type-Options") != "nosniff" || got.Get("Referrer-Policy") != "no-referrer" ||
				got.Get("Permissions-Policy") == "" {
				t.Fatalf("base headers missing: %v", got)
			}
			if (got.Get("Content-Security-Policy") == APIContentSecurityPolicy) != tc.wantCSP {
				t.Fatalf("CSP %q, want %v", got.Get("Content-Security-Policy"), tc.wantCSP)
			}
			if (got.Get("Strict-Transport-Security") != "") != tc.hsts {
				t.Fatalf("HSTS %q, want %v", got.Get("Strict-Transport-Security"), tc.hsts)
			}
		})
	}
}

func TestSecurityHeadersWriteHeaderOnly(t *testing.T) {
	h := Security(SecurityOptions{})(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusNoContent)
	}))
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, httptest.NewRequest(http.MethodDelete, "/v1/x", nil))
	if rec.Header().Get("Content-Security-Policy") != APIContentSecurityPolicy {
		t.Fatal("204 must carry the API CSP")
	}
}

func TestNoStore(t *testing.T) {
	ok := http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) { _, _ = w.Write([]byte("{}")) })
	cases := []struct {
		name, method, path, auth string
		want                     bool
	}{
		{"authenticated GET", http.MethodGet, "/v1/me", "Bearer tok", true},
		{"authenticated search", http.MethodGet, "/v1/search", "Bearer tok", true},
		{"login", http.MethodPost, "/v1/auth/login", "", true},
		{"auth GET", http.MethodGet, "/v1/auth/oidc/google/start", "", true},
		{"anonymous POST", http.MethodPost, "/v1/search/chat", "", true},
		{"public search", http.MethodGet, "/v1/search", "", false},
		{"public listing", http.MethodGet, "/v1/listings/019a0000-0000-7000-8000-000000000000", "", false},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			req := httptest.NewRequest(tc.method, tc.path, nil)
			if tc.auth != "" {
				req.Header.Set("Authorization", tc.auth)
			}
			rec := httptest.NewRecorder()
			NoStore(ok).ServeHTTP(rec, req)
			if got := rec.Header().Get("Cache-Control") == "no-store"; got != tc.want {
				t.Fatalf("Cache-Control %q, want no-store=%v", rec.Header().Get("Cache-Control"), tc.want)
			}
		})
	}
}
