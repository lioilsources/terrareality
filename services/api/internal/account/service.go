// Package account implements identity flows: registration, login, second
// factor, magic links, social login, identity verification (BankID), phone
// verification, sessions, consents and GDPR requests.
package account

import (
	"context"
	"encoding/json"
	"errors"
	"log/slog"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/terrareality/terrareality/services/api/internal/auth"
	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/identity"
	"github.com/terrareality/terrareality/services/api/internal/notify"
	"github.com/terrareality/terrareality/services/api/internal/platform/apperr"
	"github.com/terrareality/terrareality/services/api/internal/platform/pwned"
	"github.com/terrareality/terrareality/services/api/internal/platform/secretbox"
	"github.com/terrareality/terrareality/services/api/internal/platform/tokens"
	"github.com/terrareality/terrareality/services/api/internal/storage"
)

// Token lifetimes.
const (
	ttlEmailVerify   = 48 * time.Hour
	ttlMagicLink     = 15 * time.Minute
	ttlPasswordReset = time.Hour
	ttlMFAChallenge  = 5 * time.Minute
	ttlOIDCState     = 10 * time.Minute
	ttlPhoneCode     = 10 * time.Minute
	ttlImpersonation = time.Hour
	maxCodeAttempts  = 5
)

// Config holds the settings the service needs.
type Config struct {
	WebBaseURL       string
	SessionTTLWeb    time.Duration
	SessionTTLMobile time.Duration
	SessionMaxAge    time.Duration // absolute lifetime regardless of activity; 0 = none
	RedirectAllow    []string
	TermsVersion     string
	PrivacyVersion   string
	ErasureGrace     time.Duration
	StaffRequireMFA  bool
	// DisablePhoneVerification turns SMS phone verification off (no real
	// SMS provider outside dev/test, config PHONE_VERIFICATION).
	DisablePhoneVerification bool
}

// Scheduler enqueues GDPR jobs inside a transaction (implemented by jobs).
type Scheduler interface {
	ScheduleExport(ctx context.Context, tx pgx.Tx, requestID uuid.UUID) error
	ScheduleErasure(ctx context.Context, tx pgx.Tx, requestID uuid.UUID, at time.Time) error
}

// Service implements the account flows.
type Service struct {
	Pool      *pgxpool.Pool
	Box       *secretbox.Box
	Outbox    notify.Outbox
	Render    *notify.Renderer
	IDP       *identity.Registry
	Blob      storage.Blob
	Scheduler Scheduler
	Pwned     pwned.Checker // breached-password check; nil = skipped
	Cfg       Config
	Log       *slog.Logger // optional

	guard lockout // failed logins per account (lockout.go)
}

// Result is the outcome of an authentication step.
type Result struct {
	Token     string    // session token when authenticated
	ExpiresAt time.Time // session expiry
	MFAToken  string    // set when a second factor is required
}

// Authenticated reports whether a session was created.
func (r Result) Authenticated() bool { return r.Token != "" }

// TTL returns the sliding session lifetime for a client, capped at the
// absolute session lifetime.
func (s *Service) TTL(client string) time.Duration {
	ttl := s.Cfg.SessionTTLWeb
	if client == "mobile" {
		ttl = s.Cfg.SessionTTLMobile
	}
	if s.Cfg.SessionMaxAge > 0 && ttl > s.Cfg.SessionMaxAge {
		ttl = s.Cfg.SessionMaxAge
	}
	return ttl
}

func normEmail(e string) string { return strings.ToLower(strings.TrimSpace(e)) }

func normClient(c string) string {
	if c == "mobile" {
		return "mobile"
	}
	return "web"
}

func (s *Service) tx(ctx context.Context, fn func(q *db.Queries, tx pgx.Tx) error) error {
	return pgx.BeginFunc(ctx, s.Pool, func(tx pgx.Tx) error { return fn(db.New(tx), tx) })
}

// newSession stores a session and returns the raw token. mfa marks a session
// that passed the second factor (sessions.mfa_at, Server.staff).
func (s *Service) newSession(ctx context.Context, q *db.Queries, userID uuid.UUID, client string,
	impersonator *uuid.UUID, ttl time.Duration, mfa bool) (Result, error) {
	tok := tokens.New()
	meta := auth.Meta(ctx)
	exp := time.Now().Add(ttl)
	var ua *string
	if meta.UserAgent != "" {
		ua = &meta.UserAgent
	}
	var mfaAt *time.Time
	if mfa {
		now := time.Now()
		mfaAt = &now
	}
	_, err := q.CreateSession(ctx, db.CreateSessionParams{
		UserID: userID, TokenHash: tokens.Hash(tok), Client: client, ImpersonatorID: impersonator,
		Ip: parseIP(meta.IP), UserAgent: ua, ExpiresAt: exp, MfaAt: mfaAt,
	})
	if err != nil {
		return Result{}, err
	}
	return Result{Token: tok, ExpiresAt: exp}, nil
}

// finishLogin creates a session, or an MFA challenge when TOTP is enabled.
func (s *Service) finishLogin(ctx context.Context, q *db.Queries, u db.User, client string) (Result, error) {
	if u.TotpEnabledAt != nil {
		tok := tokens.New()
		data, _ := json.Marshal(map[string]string{"client": client})
		if _, err := q.CreateAuthToken(ctx, db.CreateAuthTokenParams{
			Purpose: "mfa_challenge", UserID: &u.ID, TokenHash: tokens.Hash(tok), Data: data,
			ExpiresAt: time.Now().Add(ttlMFAChallenge),
		}); err != nil {
			return Result{}, err
		}
		return Result{MFAToken: tok}, nil
	}
	return s.newSession(ctx, q, u.ID, client, nil, s.TTL(client), false)
}

// createToken stores a one-time token and returns the raw value.
func createToken(ctx context.Context, q *db.Queries, purpose string, userID *uuid.UUID, email *string,
	ttl time.Duration, data map[string]any) (string, error) {
	tok := tokens.New()
	raw := []byte("{}")
	if data != nil {
		raw, _ = json.Marshal(data)
	}
	_, err := q.CreateAuthToken(ctx, db.CreateAuthTokenParams{
		Purpose: purpose, UserID: userID, Email: email, TokenHash: tokens.Hash(tok), Data: raw,
		ExpiresAt: time.Now().Add(ttl),
	})
	return tok, err
}

// consume marks a one-time token used or returns invalid_token.
func consume(ctx context.Context, q *db.Queries, token, purpose string) (db.AuthToken, error) {
	t, err := q.ConsumeAuthToken(ctx, db.ConsumeAuthTokenParams{TokenHash: tokens.Hash(token), Purpose: purpose})
	if errors.Is(err, pgx.ErrNoRows) {
		return t, apperr.BadRequest("invalid_token", "the link is invalid or has expired")
	}
	return t, err
}

// send renders and enqueues a message in tx.
func (s *Service) send(ctx context.Context, tx pgx.Tx, channel, to, locale, key string, data map[string]any) error {
	m, err := s.Render.Render(channel, to, locale, key, data)
	if err != nil {
		return err
	}
	return s.Outbox.Enqueue(ctx, tx, m)
}

func (s *Service) link(path, token string) string {
	return s.Cfg.WebBaseURL + path + "?token=" + token
}

// createPersonalOrg gives every new user an implicit personal organization.
func createPersonalOrg(ctx context.Context, q *db.Queries, u db.User) (db.Organization, error) {
	name := u.DisplayName
	if name == "" {
		name, _, _ = strings.Cut(u.Email, "@")
	}
	o, err := q.CreateOrganization(ctx, db.CreateOrganizationParams{
		Kind: "personal", Name: name, JurisdictionCode: "CZ", PersonalOwnerID: &u.ID,
	})
	if err != nil {
		return o, err
	}
	return o, q.AddMembership(ctx, db.AddMembershipParams{OrgID: o.ID, UserID: u.ID, Role: "owner"})
}

func (s *Service) recordConsent(ctx context.Context, q *db.Queries, userID uuid.UUID, kind, version string, granted bool) error {
	meta := auth.Meta(ctx)
	var ua *string
	if meta.UserAgent != "" {
		ua = &meta.UserAgent
	}
	_, err := q.InsertConsent(ctx, db.InsertConsentParams{UserID: userID, Kind: kind, Version: version,
		Granted: granted, Ip: parseIP(meta.IP), UserAgent: ua})
	return err
}

func isUniqueViolation(err error) bool {
	var pe *pgconn.PgError
	return errors.As(err, &pe) && pe.Code == "23505"
}
