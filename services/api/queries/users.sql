-- name: CreateUser :one
INSERT INTO users (email, password_hash, display_name, locale, email_verified_at)
VALUES ($1, $2, $3, $4, $5)
RETURNING *;

-- name: GetUser :one
SELECT * FROM users WHERE id = $1;

-- name: GetUserByEmail :one
SELECT * FROM users WHERE email = $1;

-- name: RecordLoginFailure :one
-- S-A1: counts a failed password or second-factor attempt. From the sixth
-- failure on the account is locked for 30 s, doubling per failure up to an
-- hour; a lock that ran out is not counted against the next attempt's wait.
UPDATE users SET failed_logins = failed_logins + 1,
  locked_until = CASE WHEN failed_logins + 1 > sqlc.arg(free)::int
    THEN now() + least(interval '30 seconds' * power(2, least(failed_logins + 1 - sqlc.arg(free)::int - 1, 12)), interval '1 hour')
    ELSE locked_until END
WHERE id = sqlc.arg(id)
RETURNING failed_logins, locked_until;

-- name: ResetLoginFailures :exec
UPDATE users SET failed_logins = 0, locked_until = NULL
WHERE id = $1 AND (failed_logins <> 0 OR locked_until IS NOT NULL);

-- name: UpdateUserProfile :one
UPDATE users SET display_name = $2, locale = $3 WHERE id = $1 RETURNING *;

-- name: SetUserPassword :exec
UPDATE users SET password_hash = $2 WHERE id = $1;

-- name: MarkEmailVerified :exec
UPDATE users SET email_verified_at = coalesce(email_verified_at, now()) WHERE id = $1;

-- name: SetUserPhone :exec
UPDATE users SET phone = $2, phone_verified_at = NULL WHERE id = $1;

-- name: MarkPhoneVerified :exec
UPDATE users SET phone = $2, phone_verified_at = now() WHERE id = $1;

-- name: MarkIdentityVerified :exec
UPDATE users SET identity_verified_at = now() WHERE id = $1;

-- name: SetTOTPPending :exec
UPDATE users SET totp_pending_secret = $2 WHERE id = $1;

-- name: EnableTOTP :exec
UPDATE users SET totp_secret = totp_pending_secret, totp_pending_secret = NULL,
  totp_enabled_at = now(), totp_last_step = $2
WHERE id = $1 AND totp_pending_secret IS NOT NULL;

-- name: DisableTOTP :exec
UPDATE users SET totp_secret = NULL, totp_pending_secret = NULL, totp_enabled_at = NULL, totp_last_step = 0
WHERE id = $1;

-- name: AdvanceTOTPStep :execrows
-- Accepts a TOTP step only once (replay protection).
UPDATE users SET totp_last_step = $2 WHERE id = $1 AND totp_last_step < $2;

-- name: SetStaff :exec
UPDATE users SET is_staff = $2 WHERE id = $1;

-- name: SearchUsers :many
-- The search text is matched literally (LIKE wildcards and the escape
-- character are escaped).
SELECT * FROM users
WHERE (sqlc.narg(q)::text IS NULL
    OR email ILIKE '%' || replace(replace(replace(sqlc.narg(q), '\', '\\'), '%', '\%'), '_', '\_') || '%'
    OR display_name ILIKE '%' || replace(replace(replace(sqlc.narg(q), '\', '\\'), '%', '\%'), '_', '\_') || '%')
  AND (sqlc.narg(before)::uuid IS NULL OR id < sqlc.narg(before))
ORDER BY id DESC
LIMIT sqlc.arg(lim);

-- name: PseudonymizeUser :exec
UPDATE users SET email = 'erased-' || id::text || '@invalid.terrareality',
  email_verified_at = NULL, password_hash = NULL, display_name = '', phone = NULL,
  phone_verified_at = NULL, totp_secret = NULL, totp_pending_secret = NULL,
  totp_enabled_at = NULL, is_staff = false, pseudonymized_at = now()
WHERE id = $1;

-- name: InsertRecoveryCode :exec
INSERT INTO user_recovery_codes (user_id, code_hash) VALUES ($1, $2);

-- name: DeleteRecoveryCodes :exec
DELETE FROM user_recovery_codes WHERE user_id = $1;

-- name: UseRecoveryCode :execrows
UPDATE user_recovery_codes SET used_at = now()
WHERE user_id = $1 AND code_hash = $2 AND used_at IS NULL;

-- name: CountRecoveryCodes :one
SELECT count(*) FROM user_recovery_codes WHERE user_id = $1 AND used_at IS NULL;

-- name: GetOAuthIdentity :one
SELECT * FROM oauth_identities WHERE provider = $1 AND subject = $2;

-- name: CreateOAuthIdentity :exec
INSERT INTO oauth_identities (user_id, provider, subject, email) VALUES ($1, $2, $3, $4)
ON CONFLICT (provider, subject) DO NOTHING;

-- name: DeleteOAuthIdentities :exec
DELETE FROM oauth_identities WHERE user_id = $1;

-- name: UpsertIdentityVerification :one
INSERT INTO identity_verifications (user_id, provider, subject, given_name, family_name, birthdate, address)
VALUES ($1, $2, $3, $4, $5, $6, $7)
ON CONFLICT (provider, subject) DO UPDATE SET given_name = EXCLUDED.given_name,
  family_name = EXCLUDED.family_name, birthdate = EXCLUDED.birthdate, address = EXCLUDED.address,
  verified_at = now()
WHERE identity_verifications.user_id = EXCLUDED.user_id
RETURNING *;

-- name: GetIdentityVerification :one
SELECT * FROM identity_verifications WHERE user_id = $1 ORDER BY verified_at DESC LIMIT 1;
