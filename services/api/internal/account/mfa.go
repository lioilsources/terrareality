package account

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"github.com/terrareality/terrareality/services/api/internal/audit"
	"github.com/terrareality/terrareality/services/api/internal/auth"
	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/platform/apperr"
)

const totpIssuer = "TerraReality"

// TOTPSetup is shown once to the user.
type TOTPSetup struct{ Secret, URI string }

// SetupTOTP generates a pending secret.
func (s *Service) SetupTOTP(ctx context.Context, p *auth.Principal) (TOTPSetup, error) {
	if p.Impersonated() {
		return TOTPSetup{}, apperr.ErrImpersonation
	}
	q := db.New(s.Pool)
	u, err := q.GetUser(ctx, p.UserID)
	if err != nil {
		return TOTPSetup{}, err
	}
	if u.TotpEnabledAt != nil {
		return TOTPSetup{}, apperr.Conflict("mfa_already_enabled", "two-factor authentication is already enabled")
	}
	secret := auth.NewTOTPSecret()
	sealed, err := s.Box.Seal(secret)
	if err != nil {
		return TOTPSetup{}, err
	}
	if err := q.SetTOTPPending(ctx, db.SetTOTPPendingParams{ID: u.ID, TotpPendingSecret: sealed}); err != nil {
		return TOTPSetup{}, err
	}
	return TOTPSetup{Secret: auth.TOTPSecretString(secret), URI: auth.TOTPURI(secret, totpIssuer, u.Email)}, nil
}

// EnableTOTP confirms the pending secret and returns fresh recovery codes.
func (s *Service) EnableTOTP(ctx context.Context, p *auth.Principal, code string) ([]string, error) {
	if p.Impersonated() {
		return nil, apperr.ErrImpersonation
	}
	var codes []string
	err := s.tx(ctx, func(q *db.Queries, _ pgx.Tx) error {
		u, err := q.GetUser(ctx, p.UserID)
		if err != nil {
			return err
		}
		if u.TotpPendingSecret == nil {
			return apperr.Conflict("mfa_not_pending", "start the setup first")
		}
		secret, err := s.Box.Open(u.TotpPendingSecret)
		if err != nil {
			return err
		}
		step := auth.ValidateTOTP(secret, code, time.Now())
		if step == 0 {
			return apperr.Unauthorized("invalid_code", "the code is not valid")
		}
		if err := q.EnableTOTP(ctx, db.EnableTOTPParams{ID: u.ID, TotpLastStep: step}); err != nil {
			return err
		}
		codes, err = s.replaceRecoveryCodes(ctx, q, u.ID)
		if err != nil {
			return err
		}
		return audit.Record(ctx, q, audit.Event{Entity: "user", EntityID: &u.ID, Action: "user.mfa_enabled"})
	})
	return codes, err
}

// DisableTOTP turns off the second factor after checking a current code.
func (s *Service) DisableTOTP(ctx context.Context, p *auth.Principal, code string) error {
	if p.Impersonated() {
		return apperr.ErrImpersonation
	}
	return s.tx(ctx, func(q *db.Queries, _ pgx.Tx) error {
		u, err := q.GetUser(ctx, p.UserID)
		if err != nil {
			return err
		}
		if u.TotpEnabledAt == nil {
			return apperr.Conflict("mfa_not_enabled", "two-factor authentication is not enabled")
		}
		ok, err := s.checkSecondFactor(ctx, q, u, code)
		if err != nil {
			return err
		}
		if !ok {
			return apperr.Unauthorized("invalid_code", "the code is not valid")
		}
		if err := q.DisableTOTP(ctx, u.ID); err != nil {
			return err
		}
		if err := q.DeleteRecoveryCodes(ctx, u.ID); err != nil {
			return err
		}
		return audit.Record(ctx, q, audit.Event{Entity: "user", EntityID: &u.ID, Action: "user.mfa_disabled"})
	})
}

func (s *Service) replaceRecoveryCodes(ctx context.Context, q *db.Queries, userID uuid.UUID) ([]string, error) {
	if err := q.DeleteRecoveryCodes(ctx, userID); err != nil {
		return nil, err
	}
	codes := auth.NewRecoveryCodes(10)
	for _, c := range codes {
		if err := q.InsertRecoveryCode(ctx, db.InsertRecoveryCodeParams{UserID: userID, CodeHash: s.recoveryHash(userID, c)}); err != nil {
			return nil, err
		}
	}
	return codes, nil
}

func (s *Service) recoveryHash(userID uuid.UUID, code string) []byte {
	return s.Box.Sign([]byte("recovery:" + userID.String() + ":" + auth.NormalizeRecoveryCode(code)))
}

// checkSecondFactor accepts a TOTP code (once per step) or an unused recovery code.
func (s *Service) checkSecondFactor(ctx context.Context, q *db.Queries, u db.User, code string) (bool, error) {
	if u.TotpSecret == nil {
		return false, nil
	}
	if digitsOnly.MatchString(code) && len(code) == 6 {
		secret, err := s.Box.Open(u.TotpSecret)
		if err != nil {
			return false, err
		}
		step := auth.ValidateTOTP(secret, code, time.Now())
		if step == 0 {
			return false, nil
		}
		n, err := q.AdvanceTOTPStep(ctx, db.AdvanceTOTPStepParams{ID: u.ID, TotpLastStep: step})
		return n == 1, err
	}
	n, err := q.UseRecoveryCode(ctx, db.UseRecoveryCodeParams{UserID: u.ID, CodeHash: s.recoveryHash(u.ID, code)})
	return n == 1, err
}
