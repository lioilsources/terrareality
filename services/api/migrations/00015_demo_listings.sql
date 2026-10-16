-- +goose Up
-- Closed beta: clearly labelled demo listings ("ukázkové inzeráty") so the
-- map is not empty before real landlords add units (terractl demo seed,
-- docs/runbooks/seed-praha.md). Demo listings stay visible in search and on
-- the map with the flag, but nobody can contact, apply or book a viewing
-- (problem code demo_listing), and they never count as supply: SEO
-- municipality stats, the aggregate view, backoffice and portfolio market
-- statistics and saved-search digests leave them out.
--
-- No RLS change: the column lives on tables whose policies already cover it
-- (listings: org members; listing_search: public read, member write). Only
-- terractl (system context) sets it; no API writes it.
ALTER TABLE listings ADD COLUMN is_demo boolean NOT NULL DEFAULT false;
-- terractl demo list/remove scan only the (few) demo rows.
CREATE INDEX listings_demo ON listings (org_id, created_at) WHERE is_demo;

-- Denormalized onto the public index (search.Indexer copies it), so search
-- and statistics filter without joining listings.
ALTER TABLE listing_search ADD COLUMN is_demo boolean NOT NULL DEFAULT false;

-- The map aggregates count real supply only.
DROP MATERIALIZED VIEW listing_aggregates;
CREATE MATERIALIZED VIEW listing_aggregates AS
SELECT a.path, a.level, count(s.listing_id)::int AS listings,
  percentile_cont(0.5) WITHIN GROUP (ORDER BY s.rent_amount)::bigint AS median_rent,
  min(s.rent_amount) AS min_rent, max(s.rent_amount) AS max_rent
FROM admin_units a
JOIN listing_search s ON s.admin_path <@ a.path
WHERE NOT s.is_demo
GROUP BY a.path, a.level;
CREATE UNIQUE INDEX listing_aggregates_path ON listing_aggregates (path);
-- REFRESH needs ownership (00012): hand the recreated view to terra_service.
-- terra_app keeps SELECT through the default privileges (00002).
-- +goose StatementBegin
DO $$
BEGIN
  IF NOT pg_has_role(current_user, 'terra_service', 'MEMBER') THEN
    EXECUTE format('GRANT terra_service TO %I', current_user);
  END IF;
END
$$;
-- +goose StatementEnd
ALTER MATERIALIZED VIEW listing_aggregates OWNER TO terra_service;

-- +goose Down
DROP MATERIALIZED VIEW IF EXISTS listing_aggregates;
CREATE MATERIALIZED VIEW listing_aggregates AS
SELECT a.path, a.level, count(s.listing_id)::int AS listings,
  percentile_cont(0.5) WITHIN GROUP (ORDER BY s.rent_amount)::bigint AS median_rent,
  min(s.rent_amount) AS min_rent, max(s.rent_amount) AS max_rent
FROM admin_units a
JOIN listing_search s ON s.admin_path <@ a.path
GROUP BY a.path, a.level;
CREATE UNIQUE INDEX listing_aggregates_path ON listing_aggregates (path);
ALTER MATERIALIZED VIEW listing_aggregates OWNER TO terra_service;
ALTER TABLE listing_search DROP COLUMN IF EXISTS is_demo;
DROP INDEX IF EXISTS listings_demo;
ALTER TABLE listings DROP COLUMN IF EXISTS is_demo;
