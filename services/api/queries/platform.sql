-- name: ListJurisdictions :many
SELECT * FROM jurisdictions WHERE active ORDER BY code;

-- name: GetJurisdiction :one
SELECT * FROM jurisdictions WHERE code = $1;

-- name: InsertAuditEvent :exec
INSERT INTO audit_events (actor_id, impersonator_id, org_id, entity, entity_id, action, diff, ip, request_id)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9);

-- name: ListAuditEvents :many
SELECT a.*, coalesce(u.email, '')::text AS actor_email
FROM audit_events a LEFT JOIN users u ON u.id = a.actor_id
WHERE (sqlc.narg(org_id)::uuid IS NULL OR a.org_id = sqlc.narg(org_id))
  AND (sqlc.narg(actor_id)::uuid IS NULL OR a.actor_id = sqlc.narg(actor_id))
  AND (sqlc.narg(entity)::text IS NULL OR a.entity = sqlc.narg(entity))
  AND (sqlc.narg(before)::uuid IS NULL OR a.id < sqlc.narg(before))
ORDER BY a.id DESC
LIMIT sqlc.arg(lim);

-- name: InsertConsent :one
INSERT INTO consents (user_id, kind, version, granted, ip, user_agent)
VALUES ($1, $2, $3, $4, $5, $6)
RETURNING *;

-- name: ListConsents :many
SELECT * FROM consents WHERE user_id = $1 ORDER BY created_at DESC;

-- name: CreateGDPRRequest :one
INSERT INTO gdpr_requests (user_id, kind, scheduled_at) VALUES ($1, $2, $3) RETURNING *;

-- name: GetGDPRRequest :one
SELECT * FROM gdpr_requests WHERE id = $1;

-- name: ListGDPRRequests :many
SELECT * FROM gdpr_requests WHERE user_id = $1 ORDER BY created_at DESC LIMIT 20;

-- name: GetOpenErasureRequest :one
SELECT * FROM gdpr_requests
WHERE user_id = $1 AND kind = 'erasure' AND status IN ('pending', 'processing')
ORDER BY created_at DESC LIMIT 1;

-- name: UpdateGDPRRequest :exec
UPDATE gdpr_requests SET status = $2, object_key = $3, detail = $4,
  completed_at = CASE WHEN $2 IN ('done', 'failed', 'cancelled', 'rejected') THEN now() END
WHERE id = $1;

-- name: ListAuditEventsByActor :many
-- System context: GDPR export.
SELECT * FROM audit_events WHERE actor_id = $1 ORDER BY id DESC LIMIT 1000;
