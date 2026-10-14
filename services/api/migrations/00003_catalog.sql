-- +goose Up
-- M2: catalog. Properties contain units (apartments, houses, rooms inside an
-- apartment, parking, storage); listings offer a unit for rent. Listings are
-- edited as a working copy and published as immutable versions after human
-- review. Media, AI suggestions and filter schemas live here as well.

-- ---------------------------------------------------------------------------
-- Filter schemas: loaded from packages/attributes/catalog.json at startup and
-- extended only through approved proposals.
CREATE TABLE filter_schemas (
  key        text PRIMARY KEY CHECK (key ~ '^[a-z][a-z0-9_]*$'),
  type       text NOT NULL CHECK (type IN ('bool', 'int', 'range', 'enum', 'set', 'text')),
  group_key  text NOT NULL,
  label      jsonb NOT NULL,
  filter     boolean NOT NULL,
  unit       text,
  min_value  numeric,
  max_value  numeric,
  applies_to text[] NOT NULL DEFAULT '{}',
  options    jsonb NOT NULL DEFAULT '[]'::jsonb,   -- [{value, label{cs,en}, source}]
  keywords   jsonb NOT NULL DEFAULT '{}'::jsonb,
  position   int NOT NULL DEFAULT 0,
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TRIGGER filter_schemas_updated_at BEFORE UPDATE ON filter_schemas
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE filter_schema_groups (
  key      text PRIMARY KEY,
  label    jsonb NOT NULL,
  position int NOT NULL DEFAULT 0
);

-- New enum/set values found by AI ingest wait here for a human decision.
CREATE TABLE filter_schema_proposals (
  id                 uuid PRIMARY KEY DEFAULT uuid_v7(),
  attribute_key      text NOT NULL REFERENCES filter_schemas(key) ON DELETE CASCADE,
  value              text NOT NULL CHECK (value ~ '^[a-z0-9][a-z0-9_+-]*$'),
  label              jsonb NOT NULL,
  example_listing_id uuid,
  occurrences        int NOT NULL DEFAULT 1,
  status             text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  note               text,
  decided_by         uuid REFERENCES users(id) ON DELETE SET NULL,
  decided_at         timestamptz,
  created_at         timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX filter_schema_proposals_open ON filter_schema_proposals (attribute_key, value);

-- ---------------------------------------------------------------------------
-- RÚIAN address points (open data of ČÚZK), public reference data.
CREATE TABLE ruian_places (
  id                 bigint PRIMARY KEY,       -- kód adresního místa
  municipality_code  int NOT NULL,
  municipality       text NOT NULL,
  district           text,                     -- městský obvod / část (MOMC)
  city_part          text,
  street             text,
  house_number       int NOT NULL,
  house_number_type  text NOT NULL DEFAULT 'cp' CHECK (house_number_type IN ('cp', 'ce')),
  orientation_number int,
  orientation_letter text,
  postal_code        text NOT NULL,
  location           geography(Point, 4326) NOT NULL,
  label              text NOT NULL,            -- formatted single-line address
  search             text NOT NULL             -- lower(unaccent(label)) for trigram search
);
CREATE INDEX ruian_places_search ON ruian_places USING gin (search gin_trgm_ops);
CREATE INDEX ruian_places_municipality ON ruian_places (municipality_code);

-- Staging for bulk imports (COPY), merged into ruian_places by the importer.
CREATE UNLOGGED TABLE ruian_staging (
  id                 bigint NOT NULL,
  municipality_code  int NOT NULL,
  municipality       text NOT NULL,
  district           text,
  city_part          text,
  street             text,
  house_number       int NOT NULL,
  house_number_type  text NOT NULL,
  orientation_number int,
  orientation_letter text,
  postal_code        text NOT NULL,
  sjtsk_y            double precision NOT NULL,
  sjtsk_x            double precision NOT NULL
);

-- ---------------------------------------------------------------------------
-- Org-scoped catalog.
CREATE TABLE addresses (
  id                 uuid PRIMARY KEY DEFAULT uuid_v7(),
  org_id             uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  ruian_id           bigint REFERENCES ruian_places(id) ON DELETE SET NULL,
  street             text,
  house_number       text NOT NULL,
  orientation_number text,
  city               text NOT NULL,
  city_part          text,
  postal_code        text NOT NULL,
  country            char(2) NOT NULL DEFAULT 'CZ',
  location           geography(Point, 4326) NOT NULL,
  label              text NOT NULL,
  created_at         timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX addresses_org ON addresses (org_id);
CREATE INDEX addresses_location ON addresses USING gist (location);

CREATE TABLE properties (
  id         uuid PRIMARY KEY DEFAULT uuid_v7(),
  org_id     uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  address_id uuid NOT NULL REFERENCES addresses(id),
  kind       text NOT NULL CHECK (kind IN ('apartment_building', 'family_house', 'other')),
  name       text NOT NULL CHECK (length(name) BETWEEN 1 AND 200),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);
CREATE INDEX properties_org ON properties (org_id) WHERE deleted_at IS NULL;
CREATE TRIGGER properties_updated_at BEFORE UPDATE ON properties
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE units (
  id          uuid PRIMARY KEY DEFAULT uuid_v7(),
  org_id      uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  property_id uuid NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  parent_id   uuid REFERENCES units(id) ON DELETE CASCADE,
  kind        text NOT NULL CHECK (kind IN ('apartment', 'house', 'room', 'parking', 'storage', 'commercial')),
  label       text NOT NULL CHECK (length(label) BETWEEN 1 AND 120),
  floor       int,
  floor_area  numeric(8,2) CHECK (floor_area > 0),
  layout      text,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),
  deleted_at  timestamptz,
  CHECK ((kind = 'room') = (parent_id IS NOT NULL))
);
CREATE INDEX units_property ON units (property_id) WHERE deleted_at IS NULL;
CREATE TRIGGER units_updated_at BEFORE UPDATE ON units
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Listings: the row is the editable working copy; listing_versions keeps the
-- immutable snapshots that were submitted, reviewed and published.
CREATE TABLE listings (
  id                 uuid PRIMARY KEY DEFAULT uuid_v7(),
  org_id             uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  unit_id            uuid NOT NULL REFERENCES units(id),
  status             text NOT NULL DEFAULT 'draft'
                       CHECK (status IN ('draft', 'review', 'published', 'paused', 'rented', 'archived')),
  title              jsonb NOT NULL DEFAULT '{}'::jsonb,   -- {"cs": "...", "en": "..."}
  description        jsonb NOT NULL DEFAULT '{}'::jsonb,
  rent_amount        bigint CHECK (rent_amount >= 0),       -- minor units
  currency           char(3) NOT NULL DEFAULT 'CZK',
  deposit_amount     bigint CHECK (deposit_amount >= 0),
  utilities_amount   bigint CHECK (utilities_amount >= 0),
  available_from     date,
  min_term_months    int CHECK (min_term_months BETWEEN 0 AND 120),
  attributes         jsonb NOT NULL DEFAULT '{}'::jsonb,
  location_precision text NOT NULL DEFAULT 'approximate' CHECK (location_precision IN ('exact', 'approximate')),
  published_version  int,
  created_by         uuid REFERENCES users(id) ON DELETE SET NULL,
  created_at         timestamptz NOT NULL DEFAULT now(),
  updated_at         timestamptz NOT NULL DEFAULT now(),
  published_at       timestamptz,
  deleted_at         timestamptz
);
CREATE INDEX listings_org ON listings (org_id, updated_at DESC) WHERE deleted_at IS NULL;
CREATE INDEX listings_status ON listings (status) WHERE deleted_at IS NULL;
CREATE INDEX listings_attributes ON listings USING gin (attributes jsonb_path_ops);
CREATE TRIGGER listings_updated_at BEFORE UPDATE ON listings
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE listing_versions (
  id           uuid PRIMARY KEY DEFAULT uuid_v7(),
  listing_id   uuid NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
  org_id       uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  version      int NOT NULL,
  snapshot     jsonb NOT NULL,
  status       text NOT NULL DEFAULT 'pending'
                 CHECK (status IN ('pending', 'approved', 'rejected', 'withdrawn')),
  submitted_by uuid REFERENCES users(id) ON DELETE SET NULL,
  submitted_at timestamptz NOT NULL DEFAULT now(),
  reviewed_by  uuid REFERENCES users(id) ON DELETE SET NULL,
  reviewed_at  timestamptz,
  review_note  text,
  UNIQUE (listing_id, version)
);
CREATE INDEX listing_versions_pending ON listing_versions (submitted_at) WHERE status = 'pending';

CREATE TABLE media (
  id               uuid PRIMARY KEY DEFAULT uuid_v7(),
  org_id           uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  listing_id       uuid REFERENCES listings(id) ON DELETE CASCADE,
  kind             text NOT NULL DEFAULT 'photo' CHECK (kind IN ('photo', 'floor_plan')),
  object_key       text NOT NULL UNIQUE,
  filename         text NOT NULL,
  content_type     text NOT NULL,
  size_bytes       bigint,
  sha256           bytea,
  width            int,
  height           int,
  orientation      int NOT NULL DEFAULT 1,            -- EXIF orientation applied at render time
  status           text NOT NULL DEFAULT 'uploading'
                     CHECK (status IN ('uploading', 'processing', 'ready', 'rejected')),
  rejection_reason text,
  av_status        text NOT NULL DEFAULT 'pending' CHECK (av_status IN ('pending', 'clean', 'infected', 'skipped')),
  vision           jsonb,
  position         int NOT NULL DEFAULT 0,
  caption          jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_by       uuid REFERENCES users(id) ON DELETE SET NULL,
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX media_listing ON media (listing_id, position);
CREATE TRIGGER media_updated_at BEFORE UPDATE ON media
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- AI output is always a suggestion that a human accepts or rejects (ADR 0003).
CREATE TABLE ai_suggestions (
  id         uuid PRIMARY KEY DEFAULT uuid_v7(),
  org_id     uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  listing_id uuid NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
  media_id   uuid REFERENCES media(id) ON DELETE CASCADE,
  kind       text NOT NULL CHECK (kind IN ('attributes', 'text', 'photo_tags', 'privacy_blur')),
  status     text NOT NULL DEFAULT 'generating'
               CHECK (status IN ('generating', 'pending', 'accepted', 'partially_accepted', 'rejected', 'failed')),
  payload    jsonb NOT NULL DEFAULT '{}'::jsonb,
  decision   jsonb,
  model      text,
  error      text,
  created_by uuid REFERENCES users(id) ON DELETE SET NULL,
  decided_by uuid REFERENCES users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  decided_at timestamptz
);
CREATE INDEX ai_suggestions_listing ON ai_suggestions (listing_id, created_at DESC);

-- ---------------------------------------------------------------------------
-- Row-level security, same policy as M1 org tables.
-- +goose StatementBegin
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['addresses', 'properties', 'units', 'listings', 'listing_versions', 'media', 'ai_suggestions']
  LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('CREATE POLICY %I ON %I USING (org_id IN (SELECT app_user_org_ids()))', t || '_member', t);
  END LOOP;
END
$$;
-- +goose StatementEnd
-- Reviews are staff work (system context); the app role may only create pending versions.
REVOKE UPDATE, DELETE ON listing_versions FROM terra_app;

-- +goose StatementBegin
-- Owners withdraw their own pending versions (resubmission, archiving) without
-- being able to set any other review status.
CREATE FUNCTION withdraw_pending_versions(p_listing uuid) RETURNS void
LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  UPDATE listing_versions SET status = 'withdrawn'
  WHERE listing_id = p_listing AND status = 'pending' AND org_id IN (SELECT app_user_org_ids())
$$;
-- +goose StatementEnd

-- +goose Down
DROP FUNCTION IF EXISTS withdraw_pending_versions(uuid);
DROP TABLE IF EXISTS ai_suggestions, media, listing_versions, listings, units, properties, addresses,
  ruian_staging, ruian_places, filter_schema_proposals, filter_schema_groups, filter_schemas CASCADE;
