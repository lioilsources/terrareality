package identity

import (
	"context"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"

	"github.com/terrareality/terrareality/services/api/internal/platform/secretbox"
)

func TestMockFlow(t *testing.T) {
	box, _ := secretbox.New(strings.Repeat("k", 32))
	m := NewMock("bankid", "http://api.test", box)
	h := MockHandler(map[string]*Mock{"bankid": m})

	auth := m.AuthURL("state-1", "nonce-1", "http://web.test/auth/identity")
	u, _ := url.Parse(auth)
	form := url.Values{"given_name": {"Jana"}, "family_name": {"Nováková"}, "birthdate": {"1990-05-17"}, "sub": {"bid-1"}}
	req := httptest.NewRequest(http.MethodPost, u.RequestURI(), strings.NewReader(form.Encode()))
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)
	if rec.Code != http.StatusFound {
		t.Fatalf("status %d: %s", rec.Code, rec.Body)
	}
	loc, _ := url.Parse(rec.Header().Get("Location"))
	if loc.Query().Get("state") != "state-1" {
		t.Fatalf("state not echoed: %s", loc)
	}
	code := loc.Query().Get("code")
	c, err := m.Exchange(context.Background(), code, "http://web.test/auth/identity", "nonce-1")
	if err != nil {
		t.Fatal(err)
	}
	if c.Subject != "bid-1" || c.FamilyName != "Nováková" || c.Birthdate != "1990-05-17" {
		t.Fatalf("claims %+v", c)
	}
	if _, err := m.Exchange(context.Background(), code, "http://evil.test/", "nonce-1"); err == nil {
		t.Fatal("redirect mismatch accepted")
	}
	if _, err := m.Exchange(context.Background(), code, "http://web.test/auth/identity", "other"); err == nil {
		t.Fatal("nonce mismatch accepted")
	}
	if _, err := m.Exchange(context.Background(), code+"x", "http://web.test/auth/identity", "nonce-1"); err == nil {
		t.Fatal("tampered code accepted")
	}
}
