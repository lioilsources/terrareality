package identity

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"html/template"
	"net/http"
	"net/url"
	"strings"
	"time"

	"github.com/terrareality/terrareality/services/api/internal/platform/secretbox"
)

// Mock is a local stand-in for Google, Apple and BankID. Its authorize page
// (served by MockHandler under /dev/idp/authorize) lets a developer or a
// Playwright test pick the identity; the code is an HMAC-signed claim set.
type Mock struct {
	id      string
	baseURL string
	box     *secretbox.Box
}

// NewMock creates a mock provider whose authorize page lives at baseURL.
func NewMock(id, baseURL string, box *secretbox.Box) *Mock {
	return &Mock{id: id, baseURL: strings.TrimRight(baseURL, "/"), box: box}
}

// ID implements Provider.
func (m *Mock) ID() string { return m.id }

// Mock implements Provider.
func (m *Mock) Mock() bool { return true }

// AuthURL implements Provider.
func (m *Mock) AuthURL(state, nonce, redirectURI string) string {
	q := url.Values{"provider": {m.id}, "state": {state}, "nonce": {nonce}, "redirect_uri": {redirectURI}}
	return m.baseURL + "/dev/idp/authorize?" + q.Encode()
}

type mockCode struct {
	Claims      Claims `json:"c"`
	Provider    string `json:"p"`
	Nonce       string `json:"n"`
	RedirectURI string `json:"r"`
	Expires     int64  `json:"e"`
}

func (m *Mock) issue(c mockCode) (string, error) {
	payload, err := json.Marshal(c)
	if err != nil {
		return "", err
	}
	sig := m.box.Sign(payload)
	return base64.RawURLEncoding.EncodeToString(payload) + "." + base64.RawURLEncoding.EncodeToString(sig), nil
}

// Exchange implements Provider.
func (m *Mock) Exchange(_ context.Context, code, redirectURI, nonce string) (Claims, error) {
	p, s, ok := strings.Cut(code, ".")
	if !ok {
		return Claims{}, ErrInvalidCode
	}
	payload, err1 := base64.RawURLEncoding.DecodeString(p)
	sig, err2 := base64.RawURLEncoding.DecodeString(s)
	if err1 != nil || err2 != nil || !m.box.Verify(payload, sig) {
		return Claims{}, ErrInvalidCode
	}
	var c mockCode
	if err := json.Unmarshal(payload, &c); err != nil {
		return Claims{}, ErrInvalidCode
	}
	if c.Provider != m.id || c.Nonce != nonce || c.RedirectURI != redirectURI || time.Now().Unix() > c.Expires {
		return Claims{}, ErrInvalidCode
	}
	return c.Claims, nil
}

// MockHandler serves the mock authorize page for all mock providers.
func MockHandler(providers map[string]*Mock) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		q := r.URL.Query()
		m, ok := providers[q.Get("provider")]
		if !ok {
			http.Error(w, "unknown mock provider", http.StatusNotFound)
			return
		}
		if r.Method == http.MethodPost {
			if err := r.ParseForm(); err != nil {
				http.Error(w, err.Error(), http.StatusBadRequest)
				return
			}
			f := r.PostForm
			c := Claims{
				Subject: f.Get("sub"), Email: f.Get("email"), EmailVerified: f.Get("email") != "",
				Name:      strings.TrimSpace(f.Get("given_name") + " " + f.Get("family_name")),
				GivenName: f.Get("given_name"), FamilyName: f.Get("family_name"), Birthdate: f.Get("birthdate"),
			}
			if street := f.Get("street"); street != "" {
				c.Address = map[string]any{"street": street, "city": f.Get("city"), "zipcode": f.Get("zipcode"), "country": "CZ"}
			}
			if c.Subject == "" {
				c.Subject = m.id + "-" + strings.ToLower(c.Email+c.GivenName+c.FamilyName+c.Birthdate)
			}
			code, err := m.issue(mockCode{Claims: c, Provider: m.id, Nonce: q.Get("nonce"),
				RedirectURI: q.Get("redirect_uri"), Expires: time.Now().Add(5 * time.Minute).Unix()})
			if err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}
			target, err := url.Parse(q.Get("redirect_uri"))
			if err != nil {
				http.Error(w, "bad redirect_uri", http.StatusBadRequest)
				return
			}
			tq := target.Query()
			tq.Set("code", code)
			tq.Set("state", q.Get("state"))
			target.RawQuery = tq.Encode()
			http.Redirect(w, r, target.String(), http.StatusFound)
			return
		}
		w.Header().Set("Content-Type", "text/html; charset=utf-8")
		w.Header().Set("Content-Security-Policy", "default-src 'none'; style-src 'unsafe-inline'; form-action *")
		_ = mockPage.Execute(w, map[string]any{"Provider": m.id, "BankID": m.id == "bankid", "Action": r.URL.RequestURI()})
	})
}

var mockPage = template.Must(template.New("mock").Parse(`<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Mock {{.Provider}} sign-in</title>
<style>body{font:16px system-ui;max-width:28rem;margin:3rem auto;padding:0 1rem}label{display:block;margin:.6rem 0}
input{width:100%;padding:.4rem;box-sizing:border-box}button{margin-top:1rem;padding:.6rem 1rem}
.note{color:#666;font-size:.9rem}</style></head><body>
<h1>Mock {{.Provider}}</h1>
<p class="note">Local development identity provider. No real account is used.</p>
<form method="post" action="{{.Action}}">
{{if .BankID}}
<label>Given name <input name="given_name" value="Jana"></label>
<label>Family name <input name="family_name" value="Nováková"></label>
<label>Birthdate <input name="birthdate" value="1990-05-17"></label>
<label>Street <input name="street" value="Dejvická 1"></label>
<label>City <input name="city" value="Praha"></label>
<label>ZIP <input name="zipcode" value="16000"></label>
<label>Subject <input name="sub" value=""></label>
{{else}}
<label>E-mail <input name="email" type="email" value="mock.user@example.com"></label>
<label>Given name <input name="given_name" value="Mock"></label>
<label>Family name <input name="family_name" value="User"></label>
<label>Subject <input name="sub" value=""></label>
{{end}}
<button type="submit">Continue</button>
</form></body></html>`))

// String helps debugging.
func (m *Mock) String() string { return fmt.Sprintf("mock(%s)", m.id) }
