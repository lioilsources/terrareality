// Package identity holds adapters for external identity providers: social
// login (Google, Apple) and identity verification (BankID in CZ). Every
// provider has a mock implementation so `make dev` works offline.
package identity

import (
	"context"
	"errors"
	"sort"
)

// Claims is the provider-neutral result of a successful authorization.
type Claims struct {
	Subject       string         `json:"sub"`
	Email         string         `json:"email,omitempty"`
	EmailVerified bool           `json:"email_verified,omitempty"`
	Name          string         `json:"name,omitempty"`
	GivenName     string         `json:"given_name,omitempty"`
	FamilyName    string         `json:"family_name,omitempty"`
	Birthdate     string         `json:"birthdate,omitempty"` // YYYY-MM-DD
	Address       map[string]any `json:"address,omitempty"`
}

// Provider is an OAuth 2.0 / OpenID Connect authorization code flow.
type Provider interface {
	ID() string
	Mock() bool
	// AuthURL is where the browser goes to authorize.
	AuthURL(state, nonce, redirectURI string) string
	// Exchange trades the code from the redirect for verified claims.
	Exchange(ctx context.Context, code, redirectURI, nonce string) (Claims, error)
}

// ErrUnknownProvider is returned for providers not configured on this deployment.
var ErrUnknownProvider = errors.New("identity provider not configured")

// ErrInvalidCode is returned when the provider rejects the authorization code.
var ErrInvalidCode = errors.New("invalid authorization code")

// Registry maps provider ids to implementations.
type Registry struct {
	social   map[string]Provider
	verifier Provider
}

// NewRegistry creates a registry. verifier may be nil (identity verification disabled).
func NewRegistry(verifier Provider, social ...Provider) *Registry {
	r := &Registry{social: map[string]Provider{}, verifier: verifier}
	for _, p := range social {
		r.social[p.ID()] = p
	}
	return r
}

// Social returns a social login provider.
func (r *Registry) Social(id string) (Provider, error) {
	p, ok := r.social[id]
	if !ok {
		return nil, ErrUnknownProvider
	}
	return p, nil
}

// SocialProviders lists configured social providers sorted by id.
func (r *Registry) SocialProviders() []Provider {
	out := make([]Provider, 0, len(r.social))
	for _, p := range r.social {
		out = append(out, p)
	}
	sort.Slice(out, func(i, j int) bool { return out[i].ID() < out[j].ID() })
	return out
}

// Verifier returns the identity verification provider of the jurisdiction.
func (r *Registry) Verifier() (Provider, error) {
	if r.verifier == nil {
		return nil, ErrUnknownProvider
	}
	return r.verifier, nil
}
