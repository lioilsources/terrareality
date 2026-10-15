-- name: CreateSession :one
INSERT INTO sessions (user_id, token_hash, client, impersonator_id, ip, user_agent, expires_at)
VALUES ($1, $2, $3, $4, $5, $6, $7)
RETURNING *;

-- name: GetActiveSession :one
-- created_after (now - SESSION_MAX_AGE) enforces the absolute lifetime on
-- every lookup, also for sessions whose stored expiry predates the cap.
SELECT s.*, u.is_staff, u.pseudonymized_at, u.totp_enabled_at
FROM sessions s JOIN users u ON u.id = s.user_id
WHERE s.token_hash = sqlc.arg(token_hash) AND s.revoked_at IS NULL AND s.expires_at > now()
  AND s.created_at > sqlc.arg(created_after)::timestamptz;

-- name: TouchSession :exec
-- Sliding expiry, written at most once per minute per session.
UPDATE sessions SET last_seen_at = now(), expires_at = greatest(expires_at, $2)
WHERE id = $1 AND last_seen_at < now() - interval '1 minute';

-- name: ListUserSessions :many
SELECT * FROM sessions
WHERE user_id = $1 AND revoked_at IS NULL AND expires_at > now()
ORDER BY last_seen_at DESC;

-- name: RevokeSession :execrows
UPDATE sessions SET revoked_at = now() WHERE id = $1 AND user_id = $2 AND revoked_at IS NULL;

-- name: RevokeUserSessions :exec
UPDATE sessions SET revoked_at = now()
WHERE user_id = $1 AND revoked_at IS NULL AND (sqlc.narg(keep)::uuid IS NULL OR id <> sqlc.narg(keep));

-- name: CreateAuthToken :one
INSERT INTO auth_tokens (purpose, user_id, email, token_hash, data, expires_at)
VALUES ($1, $2, $3, $4, $5, $6)
RETURNING *;

-- name: ConsumeAuthToken :one
-- Atomically marks a valid token as used and returns it.
UPDATE auth_tokens SET used_at = now()
WHERE token_hash = $1 AND purpose = $2 AND used_at IS NULL AND expires_at > now()
RETURNING *;

-- name: GetAuthTokenForUser :one
-- Latest open code of a purpose for a user (phone codes are short, so they
-- are looked up by user and compared in constant time).
SELECT * FROM auth_tokens
WHERE user_id = $1 AND purpose = $2 AND used_at IS NULL AND expires_at > now()
ORDER BY created_at DESC LIMIT 1;

-- name: IncrementAuthTokenAttempts :one
UPDATE auth_tokens SET attempts = attempts + 1 WHERE id = $1 RETURNING attempts;

-- name: MarkAuthTokenUsed :exec
UPDATE auth_tokens SET used_at = now() WHERE id = $1;

-- name: InvalidateAuthTokens :exec
UPDATE auth_tokens SET used_at = now() WHERE user_id = $1 AND purpose = $2 AND used_at IS NULL;

-- name: DeleteExpiredAuthTokens :execrows
DELETE FROM auth_tokens WHERE expires_at < now() - interval '1 day';

-- name: GetOpenAuthToken :one
SELECT * FROM auth_tokens
WHERE token_hash = $1 AND purpose = $2 AND used_at IS NULL AND expires_at > now();

-- name: DeleteExpiredSessions :execrows
-- Housekeeping (cleanup job): sessions expired or revoked more than 30 days
-- ago. The window keeps recent ones for "where was I signed in" questions.
DELETE FROM sessions
WHERE expires_at < now() - interval '30 days' OR revoked_at < now() - interval '30 days';
