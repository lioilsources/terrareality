-- Org-scoped queries run in db.AsUser transactions (row-level security).

-- name: CreateAddress :one
INSERT INTO addresses (org_id, ruian_id, street, house_number, orientation_number, city, city_part, postal_code, location, label)
VALUES (sqlc.arg(org_id), sqlc.narg(ruian_id), sqlc.narg(street), sqlc.arg(house_number), sqlc.narg(orientation_number),
  sqlc.arg(city), sqlc.narg(city_part), sqlc.arg(postal_code),
  ST_SetSRID(ST_MakePoint(sqlc.arg(lng)::float8, sqlc.arg(lat)::float8), 4326)::geography,
  sqlc.arg(label))
RETURNING id;

-- name: CreateProperty :one
INSERT INTO properties (org_id, address_id, kind, name) VALUES ($1, $2, $3, $4) RETURNING *;

-- name: FindPropertyByRuian :one
SELECT p.* FROM properties p JOIN addresses a ON a.id = p.address_id
WHERE p.org_id = $1 AND a.ruian_id = $2 AND p.deleted_at IS NULL
ORDER BY p.created_at LIMIT 1;

-- name: ListProperties :many
SELECT p.*, a.label AS address_label FROM properties p JOIN addresses a ON a.id = p.address_id
WHERE p.org_id = $1 AND p.deleted_at IS NULL ORDER BY p.created_at DESC;

-- name: GetProperty :one
SELECT p.*, a.label AS address_label FROM properties p JOIN addresses a ON a.id = p.address_id
WHERE p.id = $1 AND p.org_id = $2 AND p.deleted_at IS NULL;

-- name: CreateUnit :one
INSERT INTO units (org_id, property_id, parent_id, kind, label, floor, floor_area, layout)
VALUES (sqlc.arg(org_id), sqlc.arg(property_id), sqlc.narg(parent_id), sqlc.arg(kind), sqlc.arg(label),
  sqlc.narg(floor), sqlc.narg(floor_area)::numeric, sqlc.narg(layout))
RETURNING *;

-- name: GetUnit :one
SELECT * FROM units WHERE id = $1 AND org_id = $2 AND deleted_at IS NULL;

-- name: ListUnits :many
SELECT * FROM units WHERE property_id = $1 AND deleted_at IS NULL ORDER BY parent_id NULLS FIRST, created_at;

-- name: UpdateUnit :one
UPDATE units SET label = sqlc.arg(label), floor = sqlc.narg(floor), floor_area = sqlc.narg(floor_area)::numeric,
  layout = sqlc.narg(layout)
WHERE id = sqlc.arg(id) AND org_id = sqlc.arg(org_id) RETURNING *;

-- name: CreateListing :one
INSERT INTO listings (org_id, unit_id, title, description, rent_amount, currency, deposit_amount, utilities_amount,
  available_from, min_term_months, attributes, location_precision, created_by)
VALUES (sqlc.arg(org_id), sqlc.arg(unit_id), sqlc.arg(title), sqlc.arg(description), sqlc.narg(rent_amount),
  sqlc.arg(currency), sqlc.narg(deposit_amount), sqlc.narg(utilities_amount), sqlc.narg(available_from),
  sqlc.narg(min_term_months), sqlc.arg(attributes), sqlc.arg(location_precision), sqlc.narg(created_by))
RETURNING *;

-- name: GetListing :one
SELECT * FROM listings WHERE id = $1 AND org_id = $2 AND deleted_at IS NULL;

-- name: GetListingContext :one
-- Unit, parent unit, property and address of a listing.
SELECT l.id AS listing_id, u.id AS unit_id, u.kind AS unit_kind, u.label AS unit_label, u.floor, u.floor_area,
  u.layout, u.parent_id, pu.label AS parent_label, pu.layout AS parent_layout, p.id AS property_id, p.name AS property_name,
  p.kind AS property_kind, a.label AS address_label, a.city, a.city_part, a.postal_code, a.ruian_id,
  ST_Y(a.location::geometry)::float8 AS lat, ST_X(a.location::geometry)::float8 AS lng, o.jurisdiction_code
FROM listings l
JOIN units u ON u.id = l.unit_id
LEFT JOIN units pu ON pu.id = u.parent_id
JOIN properties p ON p.id = u.property_id
JOIN addresses a ON a.id = p.address_id
JOIN organizations o ON o.id = l.org_id
WHERE l.id = $1;

-- name: ListListings :many
SELECT l.*, u.kind AS unit_kind, u.label AS unit_label, a.label AS address_label,
  coalesce((SELECT m.object_key FROM media m WHERE m.listing_id = l.id AND m.status = 'ready' ORDER BY m.position, m.created_at LIMIT 1), '')::text AS cover_key,
  coalesce((SELECT m.orientation FROM media m WHERE m.listing_id = l.id AND m.status = 'ready' ORDER BY m.position, m.created_at LIMIT 1), 1)::int AS cover_orientation,
  EXISTS (SELECT 1 FROM listing_versions v WHERE v.listing_id = l.id AND v.status = 'pending') AS pending_review
FROM listings l
JOIN units u ON u.id = l.unit_id
JOIN properties p ON p.id = u.property_id
JOIN addresses a ON a.id = p.address_id
WHERE l.org_id = sqlc.arg(org_id) AND l.deleted_at IS NULL
  AND (sqlc.narg(status)::text IS NULL OR l.status = sqlc.narg(status))
ORDER BY l.updated_at DESC
LIMIT 200;

-- name: UpdateListing :one
UPDATE listings SET title = sqlc.arg(title), description = sqlc.arg(description), rent_amount = sqlc.narg(rent_amount),
  deposit_amount = sqlc.narg(deposit_amount), utilities_amount = sqlc.narg(utilities_amount),
  available_from = sqlc.narg(available_from), min_term_months = sqlc.narg(min_term_months),
  attributes = sqlc.arg(attributes), location_precision = sqlc.arg(location_precision)
WHERE id = sqlc.arg(id) AND org_id = sqlc.arg(org_id) AND deleted_at IS NULL
RETURNING *;

-- name: SetListingAttributes :exec
UPDATE listings SET attributes = $3 WHERE id = $1 AND org_id = $2;

-- name: SetListingTexts :exec
UPDATE listings SET title = $3, description = $4 WHERE id = $1 AND org_id = $2;

-- name: SetListingStatus :exec
UPDATE listings SET status = $3 WHERE id = $1 AND org_id = $2;

-- name: PublishListingVersion :exec
-- System context (backoffice review).
UPDATE listings SET published_version = $2, published_at = now(),
  status = CASE WHEN status IN ('draft', 'review') THEN 'published' ELSE status END
WHERE id = $1;

-- name: SystemSetListingStatus :exec
UPDATE listings SET status = $2 WHERE id = $1;

-- name: SoftDeleteListing :exec
UPDATE listings SET deleted_at = now(), status = 'archived' WHERE id = $1 AND org_id = $2;

-- name: NextListingVersion :one
SELECT coalesce(max(version), 0)::int + 1 AS next FROM listing_versions WHERE listing_id = $1;

-- name: CreateListingVersion :one
INSERT INTO listing_versions (listing_id, org_id, version, snapshot, submitted_by)
VALUES ($1, $2, $3, $4, $5) RETURNING *;

-- name: ListListingVersions :many
SELECT id, listing_id, org_id, version, status, submitted_by, submitted_at, reviewed_by, reviewed_at, review_note
FROM listing_versions WHERE listing_id = $1 ORDER BY version DESC;

-- name: GetListingVersion :one
SELECT * FROM listing_versions WHERE id = $1;

-- name: GetPublishedSnapshot :one
SELECT v.* FROM listing_versions v JOIN listings l ON l.id = v.listing_id AND l.published_version = v.version
WHERE l.id = $1;

-- name: WithdrawPendingVersions :exec
-- System context, after the caller's access was checked.
UPDATE listing_versions SET status = 'withdrawn' WHERE listing_id = $1 AND status = 'pending';

-- name: WithdrawMyPendingVersions :exec
-- Row-level security context: only versions of the caller's organizations.
SELECT withdraw_pending_versions($1);

-- name: ReviewListingVersion :execrows
UPDATE listing_versions SET status = $2, reviewed_by = $3, reviewed_at = now(), review_note = $4
WHERE id = $1 AND status = 'pending';

-- name: ListPendingVersions :many
-- Backoffice moderation queue (system context).
SELECT v.id, v.listing_id, v.org_id, v.version, v.submitted_at, v.snapshot, o.name AS org_name,
  coalesce(u.email, '')::text AS submitted_by_email, l.published_version
FROM listing_versions v
JOIN organizations o ON o.id = v.org_id
JOIN listings l ON l.id = v.listing_id
LEFT JOIN users u ON u.id = v.submitted_by
WHERE v.status = 'pending'
ORDER BY v.submitted_at
LIMIT 100;

-- Media ---------------------------------------------------------------------

-- name: CreateMedia :one
INSERT INTO media (id, org_id, listing_id, kind, object_key, filename, content_type, size_bytes, position, created_by)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8,
  (SELECT coalesce(max(position), -1) + 1 FROM media WHERE listing_id = $3), $9)
RETURNING *;

-- name: GetMedia :one
SELECT * FROM media WHERE id = $1 AND org_id = $2;

-- name: SystemGetMedia :one
SELECT * FROM media WHERE id = $1;

-- name: ListListingMedia :many
SELECT * FROM media WHERE listing_id = $1 AND status <> 'rejected' ORDER BY position, created_at;

-- name: SetMediaStatus :exec
UPDATE media SET status = $2, rejection_reason = $3 WHERE id = $1;

-- name: SetMediaProcessed :exec
UPDATE media SET status = 'ready', size_bytes = $2, sha256 = $3, width = $4, height = $5, orientation = $6,
  av_status = $7, content_type = $8
WHERE id = $1;

-- name: SetMediaVision :exec
UPDATE media SET vision = $2 WHERE id = $1;

-- name: UpdateMediaMeta :one
UPDATE media SET position = $3, caption = $4 WHERE id = $1 AND org_id = $2 RETURNING *;

-- name: DeleteMedia :one
DELETE FROM media WHERE id = $1 AND org_id = $2 RETURNING object_key;

-- name: CountReadyPhotos :one
SELECT count(*) FROM media WHERE listing_id = $1 AND status = 'ready';

-- AI suggestions -------------------------------------------------------------

-- name: CreateSuggestion :one
INSERT INTO ai_suggestions (org_id, listing_id, media_id, kind, created_by) VALUES ($1, $2, $3, $4, $5) RETURNING *;

-- name: CompleteSuggestion :exec
UPDATE ai_suggestions SET status = 'pending', payload = $2, model = $3 WHERE id = $1 AND status = 'generating';

-- name: FailSuggestion :exec
UPDATE ai_suggestions SET status = 'failed', error = $2 WHERE id = $1;

-- name: GetSuggestion :one
SELECT * FROM ai_suggestions WHERE id = $1 AND org_id = $2;

-- name: SystemGetSuggestion :one
SELECT * FROM ai_suggestions WHERE id = $1;

-- name: ListSuggestions :many
SELECT * FROM ai_suggestions WHERE listing_id = $1 ORDER BY created_at DESC LIMIT 50;

-- name: DecideSuggestion :execrows
UPDATE ai_suggestions SET status = $3, decision = $4, decided_by = $5, decided_at = now()
WHERE id = $1 AND org_id = $2 AND status = 'pending';
