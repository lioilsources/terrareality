package auth

import (
	"context"

	"github.com/google/uuid"
)

// Principal is the authenticated caller of a request.
type Principal struct {
	UserID         uuid.UUID
	SessionID      uuid.UUID
	Client         string
	IsStaff        bool
	ImpersonatorID *uuid.UUID
	// MFA reports that this session passed the second factor at login
	// (sessions.mfa_at, set by CompleteMFA) and the user still has TOTP on.
	// A session opened before TOTP was enabled (possibly stolen) did not.
	MFA bool
}

// Impersonated reports whether a staff member acts as this user.
func (p *Principal) Impersonated() bool { return p.ImpersonatorID != nil }

type principalKey struct{}

// WithPrincipal stores p in ctx.
func WithPrincipal(ctx context.Context, p *Principal) context.Context {
	return context.WithValue(ctx, principalKey{}, p)
}

// FromContext returns the principal or nil for anonymous requests.
func FromContext(ctx context.Context) *Principal {
	p, _ := ctx.Value(principalKey{}).(*Principal)
	return p
}

// RequestMeta carries request facts recorded in audit events and sessions.
type RequestMeta struct {
	IP        string
	UserAgent string
	RequestID string
}

type metaKey struct{}

// WithMeta stores request metadata in ctx.
func WithMeta(ctx context.Context, m RequestMeta) context.Context {
	return context.WithValue(ctx, metaKey{}, m)
}

// Meta returns request metadata (zero value outside HTTP requests).
func Meta(ctx context.Context) RequestMeta {
	m, _ := ctx.Value(metaKey{}).(RequestMeta)
	return m
}
