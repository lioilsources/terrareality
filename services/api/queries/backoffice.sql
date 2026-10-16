-- M7: backoffice metrics, feature flags and the queue of AI-proposed
-- attributes. Staff work runs in system context; authorization is in code.

-- ---------------------------------------------------------------------------
-- Feature flags.

-- name: ListFeatureFlags :many
SELECT * FROM feature_flags ORDER BY key;

-- name: GetFeatureFlag :one
SELECT * FROM feature_flags WHERE key = $1;

-- name: UpsertFeatureFlag :one
INSERT INTO feature_flags (key, enabled, description, updated_by)
VALUES (sqlc.arg(key), sqlc.arg(enabled), coalesce(sqlc.narg(description), ''), sqlc.narg(updated_by))
ON CONFLICT (key) DO UPDATE SET enabled = EXCLUDED.enabled,
  description = coalesce(sqlc.narg(description), feature_flags.description),
  updated_by = EXCLUDED.updated_by, updated_at = now()
RETURNING *;

-- ---------------------------------------------------------------------------
-- Metrics.

-- name: BackofficeMetrics :one
SELECT
  (SELECT count(*) FROM users WHERE pseudonymized_at IS NULL)::bigint AS users,
  -- Demo listings and the demo organization (terractl demo seed) are not supply.
  (SELECT count(*) FROM organizations o WHERE o.deleted_at IS NULL
    AND NOT EXISTS (SELECT 1 FROM listings l WHERE l.org_id = o.id AND l.is_demo))::bigint AS orgs,
  (SELECT count(*) FROM listing_search WHERE NOT is_demo)::bigint AS listings_published,
  (SELECT count(*) FROM listing_search WHERE NOT is_demo
    AND (boosted_until > now() OR highlighted_until > now()))::bigint AS listings_promoted,
  (SELECT count(*) FROM applications WHERE submitted_at >= now() - interval '30 days')::bigint AS applications_30d,
  (SELECT count(*) FROM leases WHERE signed_at >= now() - interval '30 days')::bigint AS leases_signed_30d,
  ((SELECT count(*) FROM moderation_cases WHERE status = 'open')
    + (SELECT count(*) FROM listing_versions WHERE status = 'pending'))::bigint AS moderation_open,
  (SELECT count(*) FROM attribute_suggestions WHERE status = 'open')::bigint AS attribute_suggestions_open,
  (SELECT coalesce(sum(gross_amount), 0) FROM orders
    WHERE status = 'paid' AND paid_at >= now() - interval '30 days' AND currency = sqlc.arg(currency)::text)::bigint AS revenue_30d,
  (SELECT count(*) FROM orders WHERE status = 'paid' AND paid_at >= now() - interval '30 days')::bigint AS orders_paid_30d;

-- ---------------------------------------------------------------------------
-- AI-proposed attributes (ADR 0003: staff decide, nothing is applied
-- automatically).

-- name: UpsertAttributeSuggestion :one
-- AI ingest found an attribute the catalog does not have; repeated finds
-- count occurrences while the suggestion is open.
INSERT INTO attribute_suggestions (key, type, group_key, label, options, example_listing_id, model)
VALUES ($1, $2, $3, $4, $5, $6, $7)
ON CONFLICT (key) DO UPDATE SET occurrences = attribute_suggestions.occurrences + 1
WHERE attribute_suggestions.status = 'open'
RETURNING *;

-- name: ListAttributeSuggestions :many
SELECT * FROM attribute_suggestions WHERE status = $1 ORDER BY occurrences DESC, created_at LIMIT 200;

-- name: GetAttributeSuggestion :one
SELECT * FROM attribute_suggestions WHERE id = $1;

-- name: DecideAttributeSuggestion :one
UPDATE attribute_suggestions SET status = sqlc.arg(status), note = sqlc.narg(note), decided_by = sqlc.arg(decided_by),
  decided_at = now()
WHERE id = sqlc.arg(id) AND status = 'open'
RETURNING *;
