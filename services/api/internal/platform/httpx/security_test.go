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
