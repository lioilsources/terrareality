package account

import (
	"context"
	"encoding/json"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"

	"github.com/terrareality/terrareality/services/api/internal/audit"
	"github.com/terrareality/terrareality/services/api/internal/auth"
	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/notify"
	"github.com/terrareality/terrareality/services/api/internal/platform/apperr"
	"github.com/terrareality/terrareality/services/api/internal/platform/tokens"
)

// StartPhoneVerification texts a 6-digit code to phone (E.164).
func (s *Service) StartPhoneVerification(ctx context.Context, p *auth.Principal, phone string) error {
	if p.Impersonated() {
		return apperr.ErrImpersonation
	}
	if s.Cfg.DisablePhoneVerification {
		return errPhoneUnavailable
	}
	return s.tx(ctx, func(q *db.Queries, tx pgx.Tx) error {
		u, err := q.GetUser(ctx, p.UserID)
		if err != nil {
			return err
		}
		if u.EmailVerifiedAt == nil {
			return apperr.Forbidden("email_not_verified", "verify your e-mail first")
		}
		if err := q.InvalidateAuthTokens(ctx, db.InvalidateAuthTokensParams{UserID: &u.ID, Purpose: "phone_verify"}); err != nil {
			return err
		}
		code := tokens.Digits(6)
		data, _ := json.Marshal(map[string]string{"phone": phone})
		if _, err := q.CreateAuthToken(ctx, db.CreateAuthTokenParams{
			Purpose: "phone_verify", UserID: &u.ID, TokenHash: s.phoneHash(u.ID.String(), code),
			Data: data, ExpiresAt: time.Now().Add(ttlPhoneCode),
		}); err != nil {
			return err
		}
		return s.send(ctx, tx, notify.SMS, phone, u.Locale, "sms_code", map[string]any{"Code": code})
	})
}

var errPhoneUnavailable = apperr.Unavailable("phone_verification_unavailable", "phone verification is not available yet")

// phoneHash binds the short code to the user so hashes are unique per user.
// Verification accepts hashes made under a previous key (Box.Verify).
func (s *Service) phoneHash(userID, code string) []byte {
	return s.Box.Sign(phonePayload(userID, code))
}

func phonePayload(userID, code string) []byte { return []byte("phone:" + userID + ":" + code) }

// VerifyPhone checks the SMS code.
func (s *Service) VerifyPhone(ctx context.Context, p *auth.Principal, code string) error {
	if p.Impersonated() {
		return apperr.ErrImpersonation
	}
	if s.Cfg.DisablePhoneVerification {
		return errPhoneUnavailable
	}
	var failed error
	err := s.tx(ctx, func(q *db.Queries, _ pgx.Tx) error {
		t, err := q.GetAuthTokenForUser(ctx, db.GetAuthTokenForUserParams{UserID: &p.UserID, Purpose: "phone_verify"})
		if errors.Is(err, pgx.ErrNoRows) {
			return apperr.BadRequest("invalid_code", "request a new code")
		}
		if err != nil {
			return err
		}
		if !s.Box.Verify(phonePayload(p.UserID.String(), code), t.TokenHash) {
			n, err := q.IncrementAuthTokenAttempts(ctx, t.ID)
			if err != nil {
				return err
			}
			if n >= maxCodeAttempts {
				if err := q.MarkAuthTokenUsed(ctx, t.ID); err != nil {
					return err
				}
			}
			failed = apperr.BadRequest("invalid_code", "the code is not valid")
			return nil
		}
		var data struct{ Phone string }
		_ = json.Unmarshal(t.Data, &data)
		if err := q.MarkAuthTokenUsed(ctx, t.ID); err != nil {
			return err
		}
		if err := q.MarkPhoneVerified(ctx, db.MarkPhoneVerifiedParams{ID: p.UserID, Phone: &data.Phone}); err != nil {
			return err
		}
		return audit.Record(ctx, q, audit.Event{Entity: "user", EntityID: &p.UserID, Action: "user.phone_verified"})
	})
	if err == nil {
		err = failed
	}
	return err
}
