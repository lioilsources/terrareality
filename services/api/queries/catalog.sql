-- Filter schemas ------------------------------------------------------------

-- name: UpsertFilterSchema :exec
-- Catalog attributes are overwritten from catalog.json; option values that
-- were added through approved ingest proposals are kept.
INSERT INTO filter_schemas (key, type, group_key, label, filter, unit, min_value, max_value, applies_to, options, keywords, position)
VALUES (sqlc.arg(key), sqlc.arg(type), sqlc.arg(group_key), sqlc.arg(label), sqlc.arg(filter), sqlc.narg(unit),
  sqlc.narg(min_value), sqlc.narg(max_value), sqlc.arg(applies_to), sqlc.arg(options), sqlc.arg(keywords), sqlc.arg(position))
ON CONFLICT (key) DO UPDATE SET type = EXCLUDED.type, group_key = EXCLUDED.group_key, label = EXCLUDED.label,
  filter = EXCLUDED.filter, unit = EXCLUDED.unit, min_value = EXCLUDED.min_value, max_value = EXCLUDED.max_value,
  applies_to = EXCLUDED.applies_to, keywords = EXCLUDED.keywords, position = EXCLUDED.position,
  options = EXCLUDED.options || coalesce((
    SELECT jsonb_agg(o) FROM jsonb_array_elements(filter_schemas.options) o
    WHERE o->>'source' = 'ingest'
      AND NOT EXISTS (SELECT 1 FROM jsonb_array_elements(EXCLUDED.options) c WHERE c->>'value' = o->>'value')
  ), '[]'::jsonb);

-- name: UpsertFilterGroup :exec
INSERT INTO filter_schema_groups (key, label, position) VALUES ($1, $2, $3)
ON CONFLICT (key) DO UPDATE SET label = EXCLUDED.label, position = EXCLUDED.position;

-- name: ListFilterSchemas :many
SELECT * FROM filter_schemas ORDER BY position;

-- name: ListFilterGroups :many
SELECT * FROM filter_schema_groups ORDER BY position;

-- name: AddFilterOption :exec
UPDATE filter_schemas SET options = options || jsonb_build_array(sqlc.arg(option)::jsonb)
WHERE key = sqlc.arg(key)
  AND NOT EXISTS (SELECT 1 FROM jsonb_array_elements(options) o WHERE o->>'value' = sqlc.arg(option)::jsonb->>'value');

-- name: UpsertFilterProposal :exec
INSERT INTO filter_schema_proposals (attribute_key, value, label, example_listing_id)
VALUES ($1, $2, $3, $4)
ON CONFLICT (attribute_key, value) DO UPDATE SET occurrences = filter_schema_proposals.occurrences + 1
WHERE filter_schema_proposals.status = 'pending';

-- name: ListFilterProposals :many
SELECT * FROM filter_schema_proposals WHERE status = $1 ORDER BY occurrences DESC, created_at LIMIT 200;

-- name: GetFilterProposal :one
SELECT * FROM filter_schema_proposals WHERE id = $1;

-- name: DecideFilterProposal :execrows
UPDATE filter_schema_proposals SET status = $2, note = $3, decided_by = $4, decided_at = now()
WHERE id = $1 AND status = 'pending';

-- RÚIAN ---------------------------------------------------------------------

-- name: CopyRuianStaging :copyfrom
INSERT INTO ruian_staging (id, municipality_code, municipality, district, city_part, street, house_number,
  house_number_type, orientation_number, orientation_letter, postal_code, sjtsk_y, sjtsk_x)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13);

-- name: MergeRuianStaging :execrows
-- S-JTSK coordinates in the CSV are positive; EPSG:5514 uses negative axes.
INSERT INTO ruian_places (id, municipality_code, municipality, district, city_part, street, house_number,
  house_number_type, orientation_number, orientation_letter, postal_code, location, label, search)
SELECT s.id, s.municipality_code, s.municipality, s.district, s.city_part, s.street, s.house_number,
  s.house_number_type, s.orientation_number, s.orientation_letter, s.postal_code,
  ST_Transform(ST_SetSRID(ST_MakePoint(-s.sjtsk_y, -s.sjtsk_x), 5514), 4326)::geography,
  l.label, lower(unaccent(l.label))
FROM ruian_staging s
CROSS JOIN LATERAL (SELECT
  coalesce(s.street, coalesce(s.city_part, s.municipality)) || ' ' ||
  CASE WHEN s.house_number_type = 'ce' THEN 'č. ev. ' ELSE '' END || s.house_number::text ||
  coalesce('/' || s.orientation_number::text || coalesce(s.orientation_letter, ''), '') || ', ' ||
  substr(s.postal_code, 1, 3) || ' ' || substr(s.postal_code, 4) || ' ' || s.municipality ||
  CASE WHEN s.district IS NOT NULL AND s.district <> s.municipality THEN ' - ' || s.district
       WHEN s.city_part IS NOT NULL AND s.city_part <> s.municipality THEN ' - ' || s.city_part ELSE '' END AS label) l
ON CONFLICT (id) DO UPDATE SET municipality = EXCLUDED.municipality, district = EXCLUDED.district,
  city_part = EXCLUDED.city_part, street = EXCLUDED.street, house_number = EXCLUDED.house_number,
  house_number_type = EXCLUDED.house_number_type, orientation_number = EXCLUDED.orientation_number,
  orientation_letter = EXCLUDED.orientation_letter, postal_code = EXCLUDED.postal_code,
  location = EXCLUDED.location, label = EXCLUDED.label, search = EXCLUDED.search;

-- name: TruncateRuianStaging :exec
TRUNCATE ruian_staging;

-- name: SearchRuian :many
SELECT id, label, municipality, district, city_part, street, house_number, orientation_number,
  orientation_letter, postal_code, ST_Y(location::geometry)::float8 AS lat, ST_X(location::geometry)::float8 AS lng
FROM ruian_places
WHERE lower(unaccent(sqlc.arg(q)::text)) <% search
ORDER BY word_similarity(lower(unaccent(sqlc.arg(q)::text)), search) DESC, label
LIMIT sqlc.arg(lim);

-- name: GetRuianPlace :one
SELECT id, label, municipality, district, city_part, street, house_number, house_number_type, orientation_number,
  orientation_letter, postal_code, ST_Y(location::geometry)::float8 AS lat, ST_X(location::geometry)::float8 AS lng
FROM ruian_places WHERE id = $1;

-- name: CountRuianPlaces :one
SELECT count(*) FROM ruian_places;

-- name: CountRuianSamplePlaces :one
-- Addresses of the embedded dev sample (synthetic ids 99000000-99999999).
SELECT count(*) FROM ruian_places WHERE id BETWEEN 99000000 AND 99999999;
