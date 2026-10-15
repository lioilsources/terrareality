package account

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"github.com/terrareality/terrareality/services/api/internal/audit"
	"github.com/terrareality/terrareality/services/api/internal/auth"
	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/platform/apperr"
)

// MeView is everything GET /v1/me returns.
type MeView struct {
	User          db.User
	Orgs          []db.ListMyOrganizationsRow
	Identity      *db.IdentityVerification
	RecoveryLeft  int64
	Impersonator  *db.User
	SessionClient string
}

// Me loads the current user view.
func (s *Service) Me(ctx context.Context, p *auth.Principal) (MeView, error) {
	q := db.New(s.Pool)
	u, err := q.GetUser(ctx, p.UserID)
	if err != nil {
		return MeView{}, err
	}
	v := MeView{User: u, SessionClient: p.Client}
	if v.Orgs, err = q.ListMyOrganizations(ctx, u.ID); err != nil {
		return v, err
	}
	if iv, err := q.GetIdentityVerification(ctx, u.ID); err == nil {
		v.Identity = &iv
	} else if !errors.Is(err, pgx.ErrNoRows) {
		return v, err
	}
	if u.TotpEnabledAt != nil {
		if v.RecoveryLeft, err = q.CountRecoveryCodes(ctx, u.ID); err != nil {
			return v, err
		}
	}
	if p.ImpersonatorID != nil {
		if imp, err := q.GetUser(ctx, *p.ImpersonatorID); err == nil {
			v.Impersonator = &imp
		}
	}
	return v, nil
}

// UpdateProfile changes display name and/or locale.
func (s *Service) UpdateProfile(ctx context.Context, p *auth.Principal, name, locale *string) error {
	return s.tx(ctx, func(q *db.Queries, _ pgx.Tx) error {
		u, err := q.GetUser(ctx, p.UserID)
		if err != nil {
			return err
		}
		diff := map[string]any{}
		n, l := u.DisplayName, u.Locale
		if name != nil && *name != n {
			diff["display_name"] = []string{n, *name}
			n = *name
		}
		if locale != nil && *locale != l {
			diff["locale"] = []string{l, *locale}
			l = *locale
		}
		if len(diff) == 0 {
			return nil
		}
		if _, err := q.UpdateUserProfile(ctx, db.UpdateUserProfileParams{ID: u.ID, DisplayName: n, Locale: l}); err != nil {
			return err
		}
		return audit.Record(ctx, q, audit.Event{Entity: "user", EntityID: &u.ID, Action: "user.updated", Diff: diff})
	})
}

// Sessions lists active sessions.
func (s *Service) Sessions(ctx context.Context, p *auth.Principal) ([]db.Session, error) {
	return db.New(s.Pool).ListUserSessions(ctx, p.UserID)
}

// RevokeSession ends one of the user's sessions.
func (s *Service) RevokeSession(ctx context.Context, p *auth.Principal, id uuid.UUID) error {
	if p.Impersonated() {
		return apperr.ErrImpersonation
	}
	n, err := db.New(s.Pool).RevokeSession(ctx, db.RevokeSessionParams{ID: id, UserID: p.UserID})
	if err != nil {
		return err
	}
	if n == 0 {
		return apperr.NotFound("session_not_found", "session not found")
	}
	return nil
}

// Consents returns the consent history.
func (s *Service) Consents(ctx context.Context, p *auth.Principal) ([]db.Consent, error) {
	return db.New(s.Pool).ListConsents(ctx, p.UserID)
}

// RecordConsent appends a consent decision.
func (s *Service) RecordConsent(ctx context.Context, p *auth.Principal, kind, version string, granted bool) (db.Consent, error) {
	if p.Impersonated() {
		return db.Consent{}, apperr.ErrImpersonation
	}
	var c db.Consent
	err := s.tx(ctx, func(q *db.Queries, _ pgx.Tx) error {
		if err := s.recordConsent(ctx, q, p.UserID, kind, version, granted); err != nil {
			return err
		}
		list, err := q.ListConsents(ctx, p.UserID)
		if err != nil || len(list) == 0 {
			return err
		}
		c = list[0]
		return audit.Record(ctx, q, audit.Event{Entity: "consent", EntityID: &c.ID, Action: "consent.recorded",
			Diff: map[string]any{"kind": kind, "version": version, "granted": granted}})
	})
	return c, err
}
