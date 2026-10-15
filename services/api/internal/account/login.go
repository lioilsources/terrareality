package account

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"regexp"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"github.com/terrareality/terrareality/services/api/internal/audit"
	"github.com/terrareality/terrareality/services/api/internal/auth"
	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/notify"
	"github.com/terrareality/terrareality/services/api/internal/platform/apperr"
	"github.com/terrareality/terrareality/services/api/internal/platform/tokens"
)

// RegisterInput is a new e-mail + password account.
type RegisterInput struct {
	Email, Password, DisplayName, Locale string
	TermsVersion, PrivacyVersion         string
	Marketing                            bool
	Client                               string
}

var errInvalidCredentials = apperr.Unauthorized("invalid_credentials", "e-mail or password is incorrect")

// Register creates the user, their personal organization and consents, sends
// the verification e-mail and logs the user in.
func (s *Service) Register(ctx context.Context, in RegisterInput) (Result, error) {
	email := normEmail(in.Email)
	// Consent must name the documents in force, not whatever the client sent.
	if (s.Cfg.TermsVersion != "" && in.TermsVersion != s.Cfg.TermsVersion) ||
		(s.Cfg.PrivacyVersion != "" && in.PrivacyVersion != s.Cfg.PrivacyVersion) {
		return Result{}, apperr.Unprocessable("terms_outdated", "accept the current terms and privacy policy (reload the page)")
	}
	if err := checkPassword(in.Password, email); err != nil {
		return Result{}, err
	}
	if err := s.checkBreached(ctx, in.Password); err != nil {
		return Result{}, err
	}
	hash, err := auth.HashPassword(in.Password)
	if err != nil {
		return Result{}, err
	}
	locale := in.Locale
	if locale != "en" {
		locale = "cs"
	}
	var res Result
	err = s.tx(ctx, func(q *db.Queries, tx pgx.Tx) error {
		u, err := q.CreateUser(ctx, db.CreateUserParams{Email: email, PasswordHash: &hash,
			DisplayName: in.DisplayName, Locale: locale})
		if isUniqueViolation(err) {
			return apperr.Conflict("email_taken", "an account with this e-mail already exists")
		}
		if err != nil {
			return err
		}
		if _, err := createPersonalOrg(ctx, q, u); err != nil {
			return err
		}
		for _, c := range []struct {
			kind, version string
			granted       bool
		}{{"terms", in.TermsVersion, true}, {"privacy", in.PrivacyVersion, true}, {"marketing", s.Cfg.PrivacyVersion, in.Marketing}} {
			if err := s.recordConsent(ctx, q, u.ID, c.kind, c.version, c.granted); err != nil {
				return err
			}
		}
		if err := s.sendVerification(ctx, q, tx, u); err != nil {
			return err
		}
		if err := audit.Record(ctx, q, audit.Event{Entity: "user", EntityID: &u.ID, Action: "user.registered",
			ActorID: &u.ID, Diff: map[string]any{"method": "password"}}); err != nil {
			return err
		}
		res, err = s.newSession(ctx, q, u.ID, normClient(in.Client), nil, s.TTL(in.Client))
		return err
	})
	return res, err
}

var digitsOnly = regexp.MustCompile(`^[0-9]+$`)

// minPasswordLen matches the Password schema in the contract (ASVS V2.1.1).
const minPasswordLen = 12

// checkBreached rejects passwords found in breach corpora (ASVS V2.1.7). The
// adapter fails open when the external service is unreachable.
func (s *Service) checkBreached(ctx context.Context, pw string) error {
	if s.Pwned != nil && s.Pwned.Breached(ctx, pw) {
		return apperr.Unprocessable("password_breached", "this password appeared in a data breach; choose a different one")
	}
	return nil
}

// checkPassword applies NIST 800-63B style rules: length, not the e-mail, not trivially weak.
func checkPassword(pw, email string) error {
	if len([]rune(pw)) < minPasswordLen {
		return apperr.Unprocessable("password_too_short", fmt.Sprintf("password must have at least %d characters", minPasswordLen))
	}
	if pw == email || digitsOnly.MatchString(pw) {
		return apperr.Unprocessable("password_too_weak", "choose a less predictable password")
	}
	return nil
}

func (s *Service) sendVerification(ctx context.Context, q *db.Queries, tx pgx.Tx, u db.User) error {
	if err := q.InvalidateAuthTokens(ctx, db.InvalidateAuthTokensParams{UserID: &u.ID, Purpose: "email_verify"}); err != nil {
		return err
	}
	tok, err := createToken(ctx, q, "email_verify", &u.ID, &u.Email, ttlEmailVerify, nil)
	if err != nil {
		return err
	}
	return s.send(ctx, tx, notify.Email, u.Email, u.Locale, "verify_email",
		map[string]any{"Name": u.DisplayName, "Link": s.link("/auth/verify-email", tok)})
}

// Login checks e-mail and password. Failures count per e-mail (unknown
// addresses too, so the lockout does not reveal which accounts exist).
func (s *Service) Login(ctx context.Context, email, password, client string) (Result, error) {
	key := passwordKey(email)
	if err := s.guard.check(key); err != nil {
		return Result{}, err
	}
	var res Result
	var target *uuid.UUID
	err := s.tx(ctx, func(q *db.Queries, _ pgx.Tx) error {
		u, err := q.GetUserByEmail(ctx, normEmail(email))
		if errors.Is(err, pgx.ErrNoRows) || (err == nil && (u.PasswordHash == nil || u.PseudonymizedAt != nil)) {
			auth.EqualizeTiming(password)
			return errInvalidCredentials
		}
		if err != nil {
			return err
		}
		if err := auth.VerifyPassword(password, *u.PasswordHash); err != nil {
			target = &u.ID
			return errInvalidCredentials
		}
		res, err = s.finishLogin(ctx, q, u, normClient(client))
		return err
	})
	switch {
	case errors.Is(err, errInvalidCredentials):
		s.loginFailed(ctx, key, target, "password")
	case err == nil:
		s.guard.reset(key)
	}
	return res, err
}

func passwordKey(email string) string { return "password:" + normEmail(email) }

// loginFailed counts a failed attempt and, for an existing account, records
// user.login_failed outside the (rolled back) login transaction.
func (s *Service) loginFailed(ctx context.Context, key string, userID *uuid.UUID, factor string) {
	n := s.guard.fail(key)
	if userID == nil {
		return
	}
	_ = audit.Record(ctx, db.New(s.Pool), audit.Event{Entity: "user", EntityID: userID, Action: "user.login_failed",
		Diff: map[string]any{"factor": factor, "failures": n}})
}

// CompleteMFA finishes a login with a TOTP or recovery code.
func (s *Service) CompleteMFA(ctx context.Context, mfaToken, code string) (Result, error) {
	var res Result
	var failed bool
	var target *uuid.UUID
	err := s.tx(ctx, func(q *db.Queries, _ pgx.Tx) error {
		t, err := q.GetOpenAuthToken(ctx, db.GetOpenAuthTokenParams{TokenHash: tokens.Hash(mfaToken), Purpose: "mfa_challenge"})
		if errors.Is(err, pgx.ErrNoRows) {
			return apperr.Unauthorized("mfa_expired", "the login attempt expired, sign in again")
		}
		if err != nil {
			return err
		}
		u, err := q.GetUser(ctx, *t.UserID)
		if err != nil {
			return err
		}
		// Per account, not per challenge: whoever knows the password can
		// open a fresh challenge (5 tries each) at will.
		target = &u.ID
		if err := s.guard.check(mfaKey(u.ID)); err != nil {
			return err
		}
		ok, err := s.checkSecondFactor(ctx, q, u, code)
		if err != nil {
			return err
		}
		if !ok {
			n, err := q.IncrementAuthTokenAttempts(ctx, t.ID)
			if err != nil {
				return err
			}
			if n >= maxCodeAttempts {
				if err := q.MarkAuthTokenUsed(ctx, t.ID); err != nil {
					return err
				}
			}
			failed = true
			return nil // commit the attempt counter
		}
		if err := q.MarkAuthTokenUsed(ctx, t.ID); err != nil {
			return err
		}
		var data struct{ Client string }
		_ = json.Unmarshal(t.Data, &data)
		res, err = s.newSession(ctx, q, u.ID, normClient(data.Client), nil, s.TTL(data.Client))
		return err
	})
	if err == nil && failed {
		s.loginFailed(ctx, mfaKey(*target), target, "mfa")
		return Result{}, apperr.Unauthorized("invalid_code", "the code is not valid")
	}
	if err == nil && target != nil {
		s.guard.reset(mfaKey(*target))
	}
	return res, err
}

func mfaKey(userID uuid.UUID) string { return "mfa:" + userID.String() }

// RequestMagicLink e-mails a login link to an existing account. Unknown
// addresses get no e-mail and the same response (no account enumeration).
func (s *Service) RequestMagicLink(ctx context.Context, email, locale string) error {
	return s.tx(ctx, func(q *db.Queries, tx pgx.Tx) error {
		u, err := q.GetUserByEmail(ctx, normEmail(email))
		if errors.Is(err, pgx.ErrNoRows) || (err == nil && u.PseudonymizedAt != nil) {
			return nil
		}
		if err != nil {
			return err
		}
		tok, err := createToken(ctx, q, "magic_link", &u.ID, &u.Email, ttlMagicLink, nil)
		if err != nil {
			return err
		}
		if locale == "" {
			locale = u.Locale
		}
		return s.send(ctx, tx, notify.Email, u.Email, locale, "magic_link",
			map[string]any{"Link": s.link("/auth/magic", tok)})
	})
}

// VerifyMagicLink exchanges a magic link token for a session. Opening the link
// proves control of the inbox, so the e-mail becomes verified.
func (s *Service) VerifyMagicLink(ctx context.Context, token, client string) (Result, error) {
	var res Result
	err := s.tx(ctx, func(q *db.Queries, _ pgx.Tx) error {
		t, err := consume(ctx, q, token, "magic_link")
		if err != nil {
			return err
		}
		if err := q.MarkEmailVerified(ctx, *t.UserID); err != nil {
			return err
		}
		u, err := q.GetUser(ctx, *t.UserID)
		if err != nil {
			return err
		}
		res, err = s.finishLogin(ctx, q, u, normClient(client))
		return err
	})
	return res, err
}

// VerifyEmail confirms the address from the verification e-mail.
func (s *Service) VerifyEmail(ctx context.Context, token string) error {
	return s.tx(ctx, func(q *db.Queries, _ pgx.Tx) error {
		t, err := consume(ctx, q, token, "email_verify")
		if err != nil {
			return err
		}
		u, err := q.GetUser(ctx, *t.UserID)
		if err != nil {
			return err
		}
		if t.Email == nil || *t.Email != u.Email {
			return apperr.BadRequest("invalid_token", "the e-mail address has changed since the link was sent")
		}
		if err := q.MarkEmailVerified(ctx, u.ID); err != nil {
			return err
		}
		return audit.Record(ctx, q, audit.Event{Entity: "user", EntityID: &u.ID, Action: "user.email_verified", ActorID: &u.ID})
	})
}

// ResendVerification sends a fresh verification e-mail.
func (s *Service) ResendVerification(ctx context.Context, userID uuid.UUID) error {
	return s.tx(ctx, func(q *db.Queries, tx pgx.Tx) error {
		u, err := q.GetUser(ctx, userID)
		if err != nil {
			return err
		}
		if u.EmailVerifiedAt != nil {
			return nil
		}
		return s.sendVerification(ctx, q, tx, u)
	})
}

// ForgotPassword e-mails a reset link to an existing account.
func (s *Service) ForgotPassword(ctx context.Context, email, locale string) error {
	return s.tx(ctx, func(q *db.Queries, tx pgx.Tx) error {
		u, err := q.GetUserByEmail(ctx, normEmail(email))
		if errors.Is(err, pgx.ErrNoRows) || (err == nil && u.PseudonymizedAt != nil) {
			return nil
		}
		if err != nil {
			return err
		}
		if err := q.InvalidateAuthTokens(ctx, db.InvalidateAuthTokensParams{UserID: &u.ID, Purpose: "password_reset"}); err != nil {
			return err
		}
		tok, err := createToken(ctx, q, "password_reset", &u.ID, &u.Email, ttlPasswordReset, nil)
		if err != nil {
			return err
		}
		if locale == "" {
			locale = u.Locale
		}
		return s.send(ctx, tx, notify.Email, u.Email, locale, "password_reset",
			map[string]any{"Link": s.link("/auth/reset", tok)})
	})
}

// ResetPassword sets a new password and signs the user out everywhere.
func (s *Service) ResetPassword(ctx context.Context, token, password string) error {
	// The token and the local rules are checked first (read only), so the
	// unauthenticated endpoint makes no breach lookup for a bogus token. The
	// lookup runs before the transaction so it holds no connection, and a
	// rejected password does not burn the reset link.
	q := db.New(s.Pool)
	t, err := q.GetOpenAuthToken(ctx, db.GetOpenAuthTokenParams{TokenHash: tokens.Hash(token), Purpose: "password_reset"})
	if errors.Is(err, pgx.ErrNoRows) {
		return apperr.BadRequest("invalid_token", "the link is invalid or has expired")
	}
	if err != nil {
		return err
	}
	u, err := q.GetUser(ctx, *t.UserID)
	if err != nil {
		return err
	}
	if err := checkPassword(password, u.Email); err != nil {
		return err
	}
	if err := s.checkBreached(ctx, password); err != nil {
		return err
	}
	return s.tx(ctx, func(q *db.Queries, _ pgx.Tx) error {
		t, err := consume(ctx, q, token, "password_reset")
		if err != nil {
			return err
		}
		u, err := q.GetUser(ctx, *t.UserID)
		if err != nil {
			return err
		}
		if err := checkPassword(password, u.Email); err != nil {
			return err
		}
		hash, err := auth.HashPassword(password)
		if err != nil {
			return err
		}
		if err := q.SetUserPassword(ctx, db.SetUserPasswordParams{ID: u.ID, PasswordHash: &hash}); err != nil {
			return err
		}
		if err := q.MarkEmailVerified(ctx, u.ID); err != nil {
			return err
		}
		if err := q.RevokeUserSessions(ctx, db.RevokeUserSessionsParams{UserID: u.ID}); err != nil {
			return err
		}
		return audit.Record(ctx, q, audit.Event{Entity: "user", EntityID: &u.ID, Action: "user.password_reset", ActorID: &u.ID})
	})
}

// Logout revokes the current session.
func (s *Service) Logout(ctx context.Context, p *auth.Principal) error {
	_, err := db.New(s.Pool).RevokeSession(ctx, db.RevokeSessionParams{ID: p.SessionID, UserID: p.UserID})
	if err == nil && p.Impersonated() {
		err = audit.Record(ctx, db.New(s.Pool), audit.Event{Entity: "user", EntityID: &p.UserID,
			Action: "impersonation.end"})
	}
	return err
}

// ChangePassword sets or changes the password and revokes other sessions.
func (s *Service) ChangePassword(ctx context.Context, p *auth.Principal, current *string, newPassword string) error {
	if p.Impersonated() {
		return apperr.ErrImpersonation
	}
	// Step-up first: changing an existing password requires the current one
	// (ASVS V3.7.1), so a stolen session cannot probe passwords against the
	// breach corpus. Wrong guesses count towards the login lockout.
	u, err := db.New(s.Pool).GetUser(ctx, p.UserID)
	if err != nil {
		return err
	}
	if u.PasswordHash != nil {
		key := passwordKey(u.Email)
		if err := s.guard.check(key); err != nil {
			return err
		}
		if current == nil || auth.VerifyPassword(*current, *u.PasswordHash) != nil {
			s.loginFailed(ctx, key, &u.ID, "password_change")
			return apperr.Unauthorized("invalid_credentials", "current password is incorrect")
		}
	}
	if err := checkPassword(newPassword, u.Email); err != nil {
		return err
	}
	if err := s.checkBreached(ctx, newPassword); err != nil {
		return err
	}
	return s.tx(ctx, func(q *db.Queries, _ pgx.Tx) error {
		cur, err := q.GetUser(ctx, p.UserID)
		if err != nil {
			return err
		}
		// The password changed while we checked: the verified one is stale.
		if !samePtr(cur.PasswordHash, u.PasswordHash) {
			return apperr.Unauthorized("invalid_credentials", "current password is incorrect")
		}
		hash, err := auth.HashPassword(newPassword)
		if err != nil {
			return err
		}
		if err := q.SetUserPassword(ctx, db.SetUserPasswordParams{ID: u.ID, PasswordHash: &hash}); err != nil {
			return err
		}
		if err := q.RevokeUserSessions(ctx, db.RevokeUserSessionsParams{UserID: u.ID, Keep: &p.SessionID}); err != nil {
			return err
		}
		return audit.Record(ctx, q, audit.Event{Entity: "user", EntityID: &u.ID, Action: "user.password_changed"})
	})
}

func samePtr(a, b *string) bool { return (a == nil) == (b == nil) && (a == nil || *a == *b) }

// Impersonate starts a fixed one-hour session as target for a staff member.
func (s *Service) Impersonate(ctx context.Context, staff *auth.Principal, target uuid.UUID, reason string) (Result, error) {
	var res Result
	err := s.tx(ctx, func(q *db.Queries, _ pgx.Tx) error {
		u, err := q.GetUser(ctx, target)
		if errors.Is(err, pgx.ErrNoRows) {
			return apperr.NotFound("user_not_found", "user not found")
		}
		if err != nil {
			return err
		}
		if u.IsStaff || u.PseudonymizedAt != nil || u.ID == staff.UserID {
			return apperr.Forbidden("impersonation_not_allowed", "this account cannot be impersonated")
		}
		res, err = s.newSession(ctx, q, u.ID, "web", &staff.UserID, ttlImpersonation)
		if err != nil {
			return err
		}
		return audit.Record(ctx, q, audit.Event{Entity: "user", EntityID: &u.ID, Action: "impersonation.start",
			ActorID: &staff.UserID, Diff: map[string]any{"reason": reason, "expires_at": res.ExpiresAt.Format(time.RFC3339)}})
	})
	return res, err
}
