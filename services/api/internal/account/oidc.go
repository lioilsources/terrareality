package account

import (
	"context"
	"encoding/json"
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/terrareality/terrareality/services/api/internal/audit"
	"github.com/terrareality/terrareality/services/api/internal/auth"
	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/identity"
	"github.com/terrareality/terrareality/services/api/internal/platform/apperr"
	"github.com/terrareality/terrareality/services/api/internal/platform/tokens"
)

const (
	purposeLogin    = "login"
	purposeIdentity = "identity"
)

type oidcState struct {
	Provider    string     `json:"provider"`
	Nonce       string     `json:"nonce"`
	RedirectURI string     `json:"redirect_uri"`
	Purpose     string     `json:"purpose"`
	UserID      *uuid.UUID `json:"user_id,omitempty"`
}

func (s *Service) redirectAllowed(uri string) bool {
	for _, prefix := range s.Cfg.RedirectAllow {
		if strings.HasPrefix(uri, prefix) {
			return true
		}
	}
	return false
}

func (s *Service) startFlow(ctx context.Context, p identity.Provider, redirectURI, purpose string, userID *uuid.UUID) (string, error) {
	if !s.redirectAllowed(redirectURI) {
		return "", apperr.BadRequest("redirect_not_allowed", "redirect_uri is not on the allowlist")
	}
	state := tokens.New()
	nonce := tokens.New()
	data, _ := json.Marshal(oidcState{Provider: p.ID(), Nonce: nonce, RedirectURI: redirectURI, Purpose: purpose, UserID: userID})
	if _, err := db.New(s.Pool).CreateAuthToken(ctx, db.CreateAuthTokenParams{
		Purpose: "oidc_state", UserID: userID, TokenHash: tokens.Hash(state), Data: data,
		ExpiresAt: time.Now().Add(ttlOIDCState),
	}); err != nil {
		return "", err
	}
	u := p.AuthURL(state, nonce, redirectURI)
	if u == "" {
		return "", apperr.Unavailable("provider_unavailable", "the identity provider is not reachable")
	}
	return u, nil
}

// finishFlow consumes the state and exchanges the code.
func (s *Service) finishFlow(ctx context.Context, q *db.Queries, p identity.Provider, code, state, redirectURI, purpose string) (identity.Claims, oidcState, error) {
	t, err := consume(ctx, q, state, "oidc_state")
	if _, ok := apperr.As(err); ok {
		return identity.Claims{}, oidcState{}, apperr.BadRequest("invalid_state", "the sign-in attempt expired, try again")
	}
	if err != nil {
		return identity.Claims{}, oidcState{}, err // database failure: 500, not the user's fault
	}
	var st oidcState
	if err := json.Unmarshal(t.Data, &st); err != nil {
		return identity.Claims{}, st, err
	}
	if st.Provider != p.ID() || st.RedirectURI != redirectURI || st.Purpose != purpose {
		return identity.Claims{}, st, apperr.BadRequest("invalid_state", "state does not match this flow")
	}
	c, err := p.Exchange(ctx, code, redirectURI, st.Nonce)
	if errors.Is(err, identity.ErrInvalidCode) {
		return c, st, apperr.BadRequest("invalid_code", "the provider rejected the sign-in")
	}
	if err != nil {
		// The provider's error text (URLs, internal hosts) goes to the log only.
		if s.Log != nil {
			s.Log.Warn("oidc exchange failed", "provider", p.ID(), "err", err)
		}
		return c, st, apperr.Unavailable("provider_unavailable", "the identity provider is not reachable, try again later")
	}
	if c.Subject == "" {
		return c, st, apperr.BadRequest("invalid_code", "the provider returned no subject")
	}
	return c, st, nil
}

// StartSocialLogin returns the provider authorization URL.
func (s *Service) StartSocialLogin(ctx context.Context, provider, redirectURI string) (string, error) {
	p, err := s.IDP.Social(provider)
	if err != nil {
		return "", apperr.NotFound("provider_not_configured", "this sign-in method is not available")
	}
	return s.startFlow(ctx, p, redirectURI, purposeLogin, nil)
}

// FinishSocialLogin links or creates the account and logs in.
func (s *Service) FinishSocialLogin(ctx context.Context, provider, code, state, redirectURI, client string) (Result, error) {
	p, err := s.IDP.Social(provider)
	if err != nil {
		return Result{}, apperr.NotFound("provider_not_configured", "this sign-in method is not available")
	}
	var res Result
	err = s.tx(ctx, func(q *db.Queries, _ pgx.Tx) error {
		c, _, err := s.finishFlow(ctx, q, p, code, state, redirectURI, purposeLogin)
		if err != nil {
			return err
		}
		u, err := s.userForSocial(ctx, q, provider, c)
		if err != nil {
			return err
		}
		res, err = s.finishLogin(ctx, q, u, normClient(client))
		return err
	})
	return res, err
}

func (s *Service) userForSocial(ctx context.Context, q *db.Queries, provider string, c identity.Claims) (db.User, error) {
	link, err := q.GetOAuthIdentity(ctx, db.GetOAuthIdentityParams{Provider: provider, Subject: c.Subject})
	if err == nil {
		u, err := q.GetUser(ctx, link.UserID)
		if err == nil && u.PseudonymizedAt != nil {
			return u, apperr.Unauthorized("account_erased", "this account was erased")
		}
		return u, err
	}
	if !errors.Is(err, pgx.ErrNoRows) {
		return db.User{}, err
	}
	email := normEmail(c.Email)
	if email == "" || !c.EmailVerified {
		return db.User{}, apperr.BadRequest("email_required", "the provider did not share a verified e-mail")
	}
	var emailPtr = &email
	u, err := q.GetUserByEmail(ctx, email)
	switch {
	case err == nil:
		// The provider verified the address, so linking to the existing account is safe.
		if u.PseudonymizedAt != nil {
			return u, apperr.Unauthorized("account_erased", "this account was erased")
		}
		if err := q.MarkEmailVerified(ctx, u.ID); err != nil {
			return u, err
		}
	case errors.Is(err, pgx.ErrNoRows):
		now := time.Now()
		name := c.Name
		if name == "" {
			name = strings.TrimSpace(c.GivenName + " " + c.FamilyName)
		}
		if len(name) > 120 {
			name = name[:120]
		}
		u, err = q.CreateUser(ctx, db.CreateUserParams{Email: email, DisplayName: name, Locale: "cs", EmailVerifiedAt: &now})
		if err != nil {
			return u, err
		}
		if _, err := createPersonalOrg(ctx, q, u); err != nil {
			return u, err
		}
		// The sign-in page states that continuing accepts the current terms.
		if err := s.recordConsent(ctx, q, u.ID, "terms", s.Cfg.TermsVersion, true); err != nil {
			return u, err
		}
		if err := s.recordConsent(ctx, q, u.ID, "privacy", s.Cfg.PrivacyVersion, true); err != nil {
			return u, err
		}
		if err := audit.Record(ctx, q, audit.Event{Entity: "user", EntityID: &u.ID, Action: "user.registered",
			ActorID: &u.ID, Diff: map[string]any{"method": provider}}); err != nil {
			return u, err
		}
	default:
		return u, err
	}
	if err := q.CreateOAuthIdentity(ctx, db.CreateOAuthIdentityParams{UserID: u.ID, Provider: provider, Subject: c.Subject, Email: emailPtr}); err != nil {
		return u, err
	}
	return u, nil
}

// StartIdentityVerification begins BankID (or the mock) for the current user.
func (s *Service) StartIdentityVerification(ctx context.Context, p *auth.Principal, redirectURI string) (string, error) {
	if p.Impersonated() {
		return "", apperr.ErrImpersonation
	}
	v, err := s.IDP.Verifier()
	if err != nil {
		return "", apperr.NotFound("provider_not_configured", "identity verification is not available")
	}
	return s.startFlow(ctx, v, redirectURI, purposeIdentity, &p.UserID)
}

// FinishIdentityVerification stores the verified identity and raises the level.
func (s *Service) FinishIdentityVerification(ctx context.Context, p *auth.Principal, code, state, redirectURI string) error {
	v, err := s.IDP.Verifier()
	if err != nil {
		return apperr.NotFound("provider_not_configured", "identity verification is not available")
	}
	return s.tx(ctx, func(q *db.Queries, _ pgx.Tx) error {
		c, st, err := s.finishFlow(ctx, q, v, code, state, redirectURI, purposeIdentity)
		if err != nil {
			return err
		}
		if st.UserID == nil || *st.UserID != p.UserID {
			return apperr.BadRequest("invalid_state", "the verification was started by another account")
		}
		var bd pgtype.Date
		if t, err := time.Parse("2006-01-02", c.Birthdate); err == nil {
			bd = pgtype.Date{Time: t, Valid: true}
		}
		addr, _ := json.Marshal(c.Address)
		if c.Address == nil {
			addr = nil
		}
		_, err = q.UpsertIdentityVerification(ctx, db.UpsertIdentityVerificationParams{
			UserID: p.UserID, Provider: v.ID(), Subject: c.Subject, GivenName: nilIfEmpty(c.GivenName),
			FamilyName: nilIfEmpty(c.FamilyName), Birthdate: bd, Address: addr,
		})
		if errors.Is(err, pgx.ErrNoRows) {
			return apperr.Conflict("identity_in_use", "this identity is already linked to another account")
		}
		if err != nil {
			return err
		}
		if err := q.MarkIdentityVerified(ctx, p.UserID); err != nil {
			return err
		}
		return audit.Record(ctx, q, audit.Event{Entity: "user", EntityID: &p.UserID, Action: "user.identity_verified",
			Diff: map[string]any{"provider": v.ID()}})
	})
}

func nilIfEmpty(s string) *string {
	if s == "" {
		return nil
	}
	return &s
}
