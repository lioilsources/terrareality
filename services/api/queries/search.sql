-- Administrative units ------------------------------------------------------

-- name: UpsertAdminUnit :exec
INSERT INTO admin_units (code, level, name, slug, path, geom, centroid, search)
VALUES (sqlc.arg(code), sqlc.arg(level), sqlc.arg(name), sqlc.arg(slug), sqlc.arg(path)::ltree,
  ST_Multi(ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(sqlc.arg(geojson)::text), 4326))),
  ST_PointOnSurface(ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(sqlc.arg(geojson)::text), 4326))),
  lower(unaccent(sqlc.arg(name)::text)))
ON CONFLICT (code) DO UPDATE SET level = EXCLUDED.level, name = EXCLUDED.name, slug = EXCLUDED.slug,
  path = EXCLUDED.path, geom = EXCLUDED.geom, centroid = EXCLUDED.centroid, search = EXCLUDED.search;

-- name: CountAdminUnits :one
SELECT count(*) FROM admin_units;

-- name: RuianMunicipalityHull :many
-- Dev seed: approximate polygons from address points (500 m around their hull).
SELECT municipality_code, municipality,
  ST_AsGeoJSON(ST_Buffer(ST_ConvexHull(ST_Collect(location::geometry))::geography, 1500)::geometry)::text AS geojson
FROM ruian_places GROUP BY municipality_code, municipality;

-- name: RuianDistrictHull :many
SELECT municipality_code, coalesce(district, '')::text AS district,
  ST_AsGeoJSON(ST_Buffer(ST_ConvexHull(ST_Collect(location::geometry))::geography, 900)::geometry)::text AS geojson
FROM ruian_places WHERE district IS NOT NULL AND district <> municipality
GROUP BY municipality_code, district;

-- name: RuianPartHull :many
SELECT municipality_code, coalesce(district, '')::text AS district, coalesce(city_part, '')::text AS city_part,
  ST_AsGeoJSON(ST_Buffer(ST_ConvexHull(ST_Collect(location::geometry))::geography, 450)::geometry)::text AS geojson
FROM ruian_places WHERE city_part IS NOT NULL
GROUP BY municipality_code, district, city_part;

-- name: AdminPathAt :one
-- Deepest administrative unit covering a point.
SELECT path::text FROM admin_units
WHERE ST_Covers(geom, ST_SetSRID(ST_MakePoint(sqlc.arg(lng)::float8, sqlc.arg(lat)::float8), 4326))
ORDER BY level DESC, ST_Area(geom) LIMIT 1;

-- name: AssignAddressAdminPaths :execrows
UPDATE addresses a SET admin_path = (
  SELECT u.path FROM admin_units u WHERE ST_Covers(u.geom, a.location::geometry)
  ORDER BY u.level DESC, ST_Area(u.geom) LIMIT 1)
WHERE sqlc.narg(only_missing)::boolean IS NOT TRUE OR a.admin_path IS NULL;

-- name: GetAdminUnit :one
SELECT id, code, level, name, slug, path::text AS path,
  ST_X(centroid)::float8 AS lng, ST_Y(centroid)::float8 AS lat,
  ST_XMin(geom)::float8 AS west, ST_YMin(geom)::float8 AS south, ST_XMax(geom)::float8 AS east, ST_YMax(geom)::float8 AS north
FROM admin_units WHERE path = sqlc.arg(path)::ltree;

-- name: ListAdminChildren :many
-- Children of a unit (or regions when path is empty) with simplified outlines.
SELECT id, code, level, name, slug, path::text AS path,
  ST_X(centroid)::float8 AS lng, ST_Y(centroid)::float8 AS lat,
  ST_AsGeoJSON(ST_SimplifyPreserveTopology(geom, sqlc.arg(tolerance)::float8), 5)::text AS geojson
FROM admin_units
WHERE CASE WHEN sqlc.arg(parent)::text = '' THEN level = 1
           ELSE path <@ sqlc.arg(parent)::text::ltree AND nlevel(path) = nlevel(sqlc.arg(parent)::text::ltree) + 1 END
ORDER BY name;

-- name: FindAdminUnits :many
-- Place lookup for chat search ("Praha 6", "Dejvice").
SELECT id, code, level, name, slug, path::text AS path,
  ST_XMin(geom)::float8 AS west, ST_YMin(geom)::float8 AS south, ST_XMax(geom)::float8 AS east, ST_YMax(geom)::float8 AS north,
  similarity(search, lower(unaccent(sqlc.arg(q)::text)))::float8 AS score
FROM admin_units
WHERE search % lower(unaccent(sqlc.arg(q)::text)) OR search = lower(unaccent(sqlc.arg(q)::text))
ORDER BY (search = lower(unaccent(sqlc.arg(q)::text))) DESC, score DESC, level
LIMIT 5;

-- name: ListAdminBySlug :many
SELECT id, code, level, name, slug, path::text AS path FROM admin_units WHERE slug = $1 ORDER BY level;

-- Search index ---------------------------------------------------------------

-- name: UpsertListingSearch :exec
INSERT INTO listing_search (listing_id, org_id, version, unit_kind, layout, rent_amount, currency, deposit_amount,
  floor_area, attributes, title, location, admin_path, city, city_part, cover_key, cover_orientation, tsv, published_at)
VALUES (sqlc.arg(listing_id), sqlc.arg(org_id), sqlc.arg(version), sqlc.arg(unit_kind), sqlc.narg(layout),
  sqlc.arg(rent_amount), sqlc.arg(currency), sqlc.narg(deposit_amount), sqlc.narg(floor_area)::numeric,
  sqlc.arg(attributes), sqlc.arg(title),
  ST_SetSRID(ST_MakePoint(sqlc.arg(lng)::float8, sqlc.arg(lat)::float8), 4326)::geography,
  sqlc.narg(admin_path)::text::ltree, sqlc.arg(city), sqlc.narg(city_part), sqlc.narg(cover_key),
  sqlc.arg(cover_orientation), to_tsvector('simple', lower(unaccent(sqlc.arg(search_text)::text))), sqlc.arg(published_at))
ON CONFLICT (listing_id) DO UPDATE SET version = EXCLUDED.version, unit_kind = EXCLUDED.unit_kind, layout = EXCLUDED.layout,
  rent_amount = EXCLUDED.rent_amount, currency = EXCLUDED.currency, deposit_amount = EXCLUDED.deposit_amount,
  floor_area = EXCLUDED.floor_area, attributes = EXCLUDED.attributes, title = EXCLUDED.title, location = EXCLUDED.location,
  admin_path = EXCLUDED.admin_path, city = EXCLUDED.city, city_part = EXCLUDED.city_part, cover_key = EXCLUDED.cover_key,
  cover_orientation = EXCLUDED.cover_orientation, tsv = EXCLUDED.tsv, published_at = EXCLUDED.published_at;

-- name: DeleteListingSearch :exec
DELETE FROM listing_search WHERE listing_id = $1;

-- name: SetListingEmbedding :exec
UPDATE listing_search SET embedding = sqlc.arg(embedding)::vector WHERE listing_id = sqlc.arg(listing_id);

-- name: RefreshListingAggregates :exec
REFRESH MATERIALIZED VIEW CONCURRENTLY listing_aggregates;

-- name: GetPublicListing :one
SELECT s.listing_id, s.org_id, s.version, ST_Y(s.location::geometry)::float8 AS lat,
  ST_X(s.location::geometry)::float8 AS lng, s.admin_path::text AS admin_path, s.published_at, v.snapshot,
  l.prescreen
FROM listing_search s
JOIN listing_versions v ON v.listing_id = s.listing_id AND v.version = s.version
JOIN listings l ON l.id = s.listing_id
WHERE s.listing_id = $1;

-- name: SimilarByEmbedding :many
SELECT s2.listing_id FROM listing_search s1 JOIN listing_search s2 ON s2.listing_id <> s1.listing_id
WHERE s1.listing_id = $1 AND s1.embedding IS NOT NULL AND s2.embedding IS NOT NULL
ORDER BY s2.embedding <=> s1.embedding LIMIT $2;

-- name: SimilarByAttributes :many
-- Fallback without embeddings: same kind, nearby, similar rent.
SELECT s2.listing_id FROM listing_search s1 JOIN listing_search s2 ON s2.listing_id <> s1.listing_id
WHERE s1.listing_id = $1 AND s2.unit_kind = s1.unit_kind
  AND s2.rent_amount BETWEEN s1.rent_amount * 0.75 AND s1.rent_amount * 1.25
  AND ST_DWithin(s2.location, s1.location, 5000)
ORDER BY ST_Distance(s2.location, s1.location) LIMIT $2;

-- name: MunicipalitiesWithListings :many
-- Astro SEO pages: municipalities (level 2) with at least one listing of a kind.
SELECT a.name, a.slug, a.path::text AS path, count(*)::int AS listings,
  percentile_cont(0.5) WITHIN GROUP (ORDER BY s.rent_amount)::bigint AS median_rent
FROM admin_units a JOIN listing_search s ON s.admin_path <@ a.path
WHERE a.level = 2 AND (sqlc.narg(kind)::text IS NULL OR s.unit_kind = sqlc.narg(kind))
GROUP BY a.name, a.slug, a.path
ORDER BY listings DESC;

-- Saved searches ---------------------------------------------------------------

-- name: CreateSavedSearch :one
INSERT INTO saved_searches (user_id, name, query, notify) VALUES ($1, $2, $3, $4) RETURNING *;

-- name: ListSavedSearches :many
SELECT * FROM saved_searches WHERE user_id = $1 ORDER BY created_at DESC;

-- name: DeleteSavedSearch :execrows
DELETE FROM saved_searches WHERE id = $1 AND user_id = $2;

-- name: SavedSearchesToNotify :many
SELECT s.*, u.email, u.locale FROM saved_searches s JOIN users u ON u.id = s.user_id
WHERE s.notify AND u.pseudonymized_at IS NULL AND s.last_notified_at < now() - interval '20 hours'
ORDER BY s.last_notified_at LIMIT 500;

-- name: MarkSavedSearchNotified :exec
UPDATE saved_searches SET last_notified_at = $2 WHERE id = $1;

-- name: GetIndexSource :one
-- Everything the search index needs about a published listing (system context).
SELECT l.id, l.org_id, l.status, l.published_version, l.location_precision, l.published_at,
  v.snapshot, coalesce(a.admin_path::text, '')::text AS admin_path
FROM listings l
JOIN listing_versions v ON v.listing_id = l.id AND v.version = l.published_version
JOIN units u ON u.id = l.unit_id
JOIN properties p ON p.id = u.property_id
JOIN addresses a ON a.id = p.address_id
WHERE l.id = $1 AND l.deleted_at IS NULL;

-- name: SetAddressAdminPath :exec
UPDATE addresses SET admin_path = sqlc.narg(admin_path)::text::ltree WHERE id = sqlc.arg(id);

-- name: PublishedListingIDs :many
-- Only listings with an approved version (synthetic load-test rows have none).
SELECT l.id FROM listings l
JOIN listing_versions v ON v.listing_id = l.id AND v.version = l.published_version
WHERE l.status = 'published' AND l.deleted_at IS NULL;
