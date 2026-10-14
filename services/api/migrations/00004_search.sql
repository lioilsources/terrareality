-- +goose Up
-- M3: administrative hierarchy, the public search index of published
-- listings, aggregates for the map and saved searches.

-- Administrative units: region (kraj) > municipality (obec) > district
-- (městský obvod, e.g. Praha 6) > part (část obce, e.g. Dejvice).
CREATE TABLE admin_units (
  id          serial PRIMARY KEY,
  code        text NOT NULL UNIQUE,            -- RÚIAN / NUTS code or synthetic key
  level       smallint NOT NULL CHECK (level BETWEEN 1 AND 4),
  name        text NOT NULL,
  slug        text NOT NULL,                   -- URL slug, unique per parent
  path        ltree NOT NULL UNIQUE,
  geom        geometry(MultiPolygon, 4326) NOT NULL,
  centroid    geometry(Point, 4326) NOT NULL,
  search      text NOT NULL                    -- lower(unaccent(name)) for place lookup
);
CREATE INDEX admin_units_geom ON admin_units USING gist (geom);
CREATE INDEX admin_units_path ON admin_units USING gist (path);
CREATE INDEX admin_units_search ON admin_units USING gin (search gin_trgm_ops);

ALTER TABLE addresses ADD COLUMN admin_path ltree;
CREATE INDEX addresses_admin_path ON addresses USING gist (admin_path);

-- +goose StatementBegin
-- "key=value" tokens of boolean, enum and set attributes: fast facet counts
-- (unnest instead of expanding JSON) and GIN-indexed filters.
CREATE FUNCTION facet_tokens(attrs jsonb) RETURNS text[]
LANGUAGE sql IMMUTABLE PARALLEL SAFE AS $$
  SELECT coalesce(array_agg(e.key || '=' || x.val ORDER BY 1), '{}')
  FROM jsonb_each(attrs) e(key, v)
  CROSS JOIN LATERAL jsonb_array_elements_text(
    CASE WHEN jsonb_typeof(e.v) = 'array' THEN e.v ELSE jsonb_build_array(e.v) END) x(val)
  WHERE jsonb_typeof(e.v) IN ('boolean', 'string', 'array')
$$;
-- +goose StatementEnd

-- Search index: one row per published listing, built from the approved
-- snapshot (never from the working copy). Public data only.
CREATE TABLE listing_search (
  listing_id      uuid PRIMARY KEY REFERENCES listings(id) ON DELETE CASCADE,
  org_id          uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  version         int NOT NULL,
  unit_kind       text NOT NULL,
  layout          text,
  rent_amount     bigint NOT NULL,
  currency        char(3) NOT NULL,
  deposit_amount  bigint,
  floor_area      numeric(8,2),
  attributes      jsonb NOT NULL DEFAULT '{}'::jsonb,
  facets          text[] GENERATED ALWAYS AS (facet_tokens(attributes)) STORED,
  title           jsonb NOT NULL,
  location        geography(Point, 4326) NOT NULL,  -- jittered when precision is approximate
  admin_path      ltree,
  city            text NOT NULL,
  city_part       text,
  cover_key       text,
  cover_orientation int NOT NULL DEFAULT 1,
  tsv             tsvector NOT NULL,
  embedding       vector(1024),
  published_at    timestamptz NOT NULL
);
CREATE INDEX listing_search_location ON listing_search USING gist (location);
CREATE INDEX listing_search_admin ON listing_search USING gist (admin_path);
CREATE INDEX listing_search_attrs ON listing_search USING gin (attributes jsonb_path_ops);
CREATE INDEX listing_search_facets ON listing_search USING gin (facets);
CREATE INDEX listing_search_tsv ON listing_search USING gin (tsv);
CREATE INDEX listing_search_rent ON listing_search (rent_amount);
CREATE INDEX listing_search_kind ON listing_search (unit_kind, rent_amount);
CREATE INDEX listing_search_published ON listing_search (published_at DESC);

-- Aggregates without filters per admin unit (refreshed by a job); filtered
-- aggregates are computed online.
CREATE MATERIALIZED VIEW listing_aggregates AS
SELECT a.path, a.level, count(s.listing_id)::int AS listings,
  percentile_cont(0.5) WITHIN GROUP (ORDER BY s.rent_amount)::bigint AS median_rent,
  min(s.rent_amount) AS min_rent, max(s.rent_amount) AS max_rent
FROM admin_units a
JOIN listing_search s ON s.admin_path <@ a.path
GROUP BY a.path, a.level;
CREATE UNIQUE INDEX listing_aggregates_path ON listing_aggregates (path);

CREATE TABLE saved_searches (
  id               uuid PRIMARY KEY DEFAULT uuid_v7(),
  user_id          uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name             text NOT NULL CHECK (length(name) BETWEEN 1 AND 120),
  query            jsonb NOT NULL,
  notify           boolean NOT NULL DEFAULT true,
  last_notified_at timestamptz NOT NULL DEFAULT now(),
  created_at       timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX saved_searches_user ON saved_searches (user_id);
ALTER TABLE saved_searches ENABLE ROW LEVEL SECURITY;
CREATE POLICY saved_searches_self ON saved_searches USING (user_id = app_current_user());

-- +goose Down
DROP TABLE IF EXISTS saved_searches;
DROP MATERIALIZED VIEW IF EXISTS listing_aggregates;
DROP TABLE IF EXISTS listing_search;
DROP FUNCTION IF EXISTS facet_tokens(jsonb);
ALTER TABLE addresses DROP COLUMN IF EXISTS admin_path;
DROP TABLE IF EXISTS admin_units;
