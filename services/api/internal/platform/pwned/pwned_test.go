package pwned

import (
	"context"
	"crypto/sha1" //nolint:gosec // test mirrors the HIBP key
	"encoding/hex"
	"fmt"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"
)

func TestLocal(t *testing.T) {
	l := Local()
	ctx := context.Background()
	for _, pw := range []string{"password1234", "Password1234", "QWERTY123456", "heslo12345678"} {
		if !l.Breached(ctx, pw) {
			t.Errorf("%q should be breached", pw)
		}
	}
	// Fixtures used by integration and e2e tests must stay accepted.
	for _, pw := range []string{"Sup3r-secret-pw", "N3w-password-123", "E2e-secret-pass", "terra-dev-password", "Flutter-pass-123"} {
		if l.Breached(ctx, pw) {
			t.Errorf("%q must not be in the local list", pw)
		}
	}
}

func TestNewModes(t *testing.T) {
	for _, m := range []string{"hibp", "local", "off"} {
		if _, err := New(m, nil); err != nil {
			t.Errorf("%s: %v", m, err)
		}
	}
	if _, err := New("bogus", nil); err == nil {
		t.Error("unknown mode accepted")
	}
	if (Off{}).Breached(context.Background(), "password1234") {
		t.Error("off reported a breach")
	}
}

func TestHIBP(t *testing.T) {
	sum := sha1.Sum([]byte("password1234")) //nolint:gosec
	hash := strings.ToUpper(hex.EncodeToString(sum[:]))
	var gotPath, gotPadding string
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		gotPath, gotPadding = r.URL.Path, r.Header.Get("Add-Padding")
		fmt.Fprintf(w, "0018A45C4D1DEF81644B54AB7F969B88D65:1\r\n%s:2412\r\nFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF:0\r\n", hash[5:])
	}))
	defer srv.Close()
	h := &HIBP{BaseURL: srv.URL + "/range/"}
	if !h.Breached(context.Background(), "password1234") {
		t.Fatal("expected breach")
	}
	if gotPath != "/range/"+hash[:5] {
		t.Errorf("path %q: only the 5-character prefix may be sent", gotPath)
	}
	if gotPadding != "true" {
		t.Errorf("Add-Padding = %q", gotPadding)
	}
	if h.Breached(context.Background(), "a-very-unusual-passphrase-42") {
		t.Error("unexpected breach")
	}
}

func TestHIBPPaddingIgnored(t *testing.T) {
	sum := sha1.Sum([]byte("a-very-unusual-passphrase-42")) //nolint:gosec
	hash := strings.ToUpper(hex.EncodeToString(sum[:]))
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		fmt.Fprintf(w, "%s:0\r\n", hash[5:])
	}))
	defer srv.Close()
	if (&HIBP{BaseURL: srv.URL + "/"}).Breached(context.Background(), "a-very-unusual-passphrase-42") {
		t.Error("padding entry (count 0) counted as breach")
	}
}

func TestHIBPFailOpen(t *testing.T) {
	slow := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		select {
		case <-r.Context().Done():
		case <-time.After(2 * time.Second):
		}
	}))
	defer slow.Close()
	h := &HIBP{BaseURL: slow.URL + "/", Timeout: 50 * time.Millisecond}
	if h.Breached(context.Background(), "password1234") {
		t.Error("timeout must fail open")
	}
	down := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusServiceUnavailable)
	}))
	defer down.Close()
	if (&HIBP{BaseURL: down.URL + "/"}).Breached(context.Background(), "password1234") {
		t.Error("5xx must fail open")
	}
}
