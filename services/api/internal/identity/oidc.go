package identity

import (
	"context"
	"encoding/json"
	"fmt"
	"sync"

	"github.com/coreos/go-oidc/v3/oidc"
	"golang.org/x/oauth2"
)

// OIDCConfig configures a standards-based OpenID Connect provider.
type OIDCConfig struct {
	ID           string
	Issuer       string
	ClientID     string
	ClientSecret string
	Scopes       []string
	// UseUserInfo merges claims from the userinfo endpoint (BankID delivers
	// name, birthdate and address there, not in the ID token).
	UseUserInfo bool
	// FormPost asks the provider to POST the code back (Apple requires it
	// when the name or email scope is requested).
	FormPost bool
}

// OIDC implements Provider with discovery and ID token verification.
type OIDC struct {
	cfg  OIDCConfig
	once sync.Once
	prov *oidc.Provider
	err  error
}

// NewOIDC creates a provider; discovery happens lazily on first use so the
// API starts even when the provider is unreachable.
func NewOIDC(cfg OIDCConfig) *OIDC { return &OIDC{cfg: cfg} }

// ID implements Provider.
func (o *OIDC) ID() string { return o.cfg.ID }

// Mock implements Provider.
func (o *OIDC) Mock() bool { return false }

func (o *OIDC) provider(ctx context.Context) (*oidc.Provider, error) {
	o.once.Do(func() { o.prov, o.err = oidc.NewProvider(context.WithoutCancel(ctx), o.cfg.Issuer) })
	return o.prov, o.err
}

func (o *OIDC) oauth(p *oidc.Provider, redirectURI string) *oauth2.Config {
	return &oauth2.Config{ClientID: o.cfg.ClientID, ClientSecret: o.cfg.ClientSecret,
		Endpoint: p.Endpoint(), RedirectURL: redirectURI, Scopes: o.cfg.Scopes}
}

// AuthURL implements Provider. Discovery errors surface in Exchange; here we
// fall back to an empty URL which the handler reports as unavailable.
func (o *OIDC) AuthURL(state, nonce, redirectURI string) string {
	p, err := o.provider(context.Background())
	if err != nil {
		return ""
	}
	opts := []oauth2.AuthCodeOption{oidc.Nonce(nonce)}
	if o.cfg.FormPost {
		opts = append(opts, oauth2.SetAuthURLParam("response_mode", "form_post"))
	}
	return o.oauth(p, redirectURI).AuthCodeURL(state, opts...)
}

// Exchange implements Provider.
func (o *OIDC) Exchange(ctx context.Context, code, redirectURI, nonce string) (Claims, error) {
	p, err := o.provider(ctx)
	if err != nil {
		return Claims{}, fmt.Errorf("%s discovery: %w", o.cfg.ID, err)
	}
	conf := o.oauth(p, redirectURI)
	tok, err := conf.Exchange(ctx, code)
	if err != nil {
		return Claims{}, fmt.Errorf("%w: %v", ErrInvalidCode, err)
	}
	raw, ok := tok.Extra("id_token").(string)
	if !ok {
		return Claims{}, fmt.Errorf("%s: no id_token in response", o.cfg.ID)
	}
	idt, err := p.Verifier(&oidc.Config{ClientID: o.cfg.ClientID}).Verify(ctx, raw)
	if err != nil {
		return Claims{}, fmt.Errorf("%s: verify id_token: %w", o.cfg.ID, err)
	}
	if idt.Nonce != nonce {
		return Claims{}, fmt.Errorf("%s: nonce mismatch", o.cfg.ID)
	}
	var c Claims
	if err := idt.Claims(&c); err != nil {
		return Claims{}, err
	}
	// Apple sends email_verified as a string.
	var loose struct {
		EmailVerified any `json:"email_verified"`
	}
	_ = idt.Claims(&loose)
	c.EmailVerified = loose.EmailVerified == true || loose.EmailVerified == "true"
	if o.cfg.UseUserInfo {
		ui, err := p.UserInfo(ctx, oauth2.StaticTokenSource(tok))
		if err != nil {
			return Claims{}, fmt.Errorf("%s: userinfo: %w", o.cfg.ID, err)
		}
		var extra map[string]json.RawMessage
		if err := ui.Claims(&extra); err != nil {
			return Claims{}, err
		}
		mergeUserInfo(&c, extra)
	}
	if c.Subject == "" {
		c.Subject = idt.Subject
	}
	return c, nil
}

// mergeUserInfo maps BankID-style userinfo claims onto Claims.
func mergeUserInfo(c *Claims, m map[string]json.RawMessage) {
	str := func(k string) string {
		var s string
		_ = json.Unmarshal(m[k], &s)
		return s
	}
	if v := str("given_name"); v != "" {
		c.GivenName = v
	}
	if v := str("family_name"); v != "" {
		c.FamilyName = v
	}
	if v := str("birthdate"); v != "" {
		c.Birthdate = v
	}
	if raw, ok := m["addresses"]; ok {
		var addrs []map[string]any
		if json.Unmarshal(raw, &addrs) == nil && len(addrs) > 0 {
			c.Address = addrs[0]
		}
	} else if raw, ok := m["address"]; ok {
		var addr map[string]any
		if json.Unmarshal(raw, &addr) == nil {
			c.Address = addr
		}
	}
}
