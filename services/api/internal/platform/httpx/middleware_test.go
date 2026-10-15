package httpx

import (
	"bytes"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestLogPathRedactsInvitationTokens(t *testing.T) {
	cases := map[string]string{
		"/v1/invitations/tok3n-secret-value-123":        "/v1/invitations/{redacted}",
		"/v1/invitations/tok3n-secret-value-123/accept": "/v1/invitations/{redacted}/accept",
		"/v1/invitations/":                              "/v1/invitations/",
		"/v1/orgs/42/invitations/abc":                   "/v1/orgs/42/invitations/abc", // id, not a secret
		"/v1/me":                                        "/v1/me",
	}
	for in, want := range cases {
		if got := LogPath(in); got != want {
			t.Errorf("LogPath(%q) = %q, want %q", in, got, want)
		}
	}
}

func TestAccessLogOmitsSecrets(t *testing.T) {
	var buf bytes.Buffer
	log := slog.New(slog.NewTextHandler(&buf, nil))
	h := AccessLog(log)(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {}))
	h.ServeHTTP(httptest.NewRecorder(), httptest.NewRequest(http.MethodGet, "/v1/invitations/s3cret-token-0123456789?x=1", nil))
	h.ServeHTTP(httptest.NewRecorder(), httptest.NewRequest(http.MethodPost, "/v1/auth/magic-link/verify?token=s3cret-query", nil))
	out := buf.String()
	if strings.Contains(out, "s3cret") {
		t.Fatalf("secret in access log: %s", out)
	}
	if !strings.Contains(out, "/v1/invitations/{redacted}") {
		t.Fatalf("redacted path missing: %s", out)
	}
}
