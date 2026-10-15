-- +goose Up
-- M7: paid promotion of listings (topování, zvýraznění), orders paid by card
-- through Stripe Checkout, VAT invoices, landlord-direct Revolut payment links
-- for rent shares, feature flags in the database and the backoffice queue of
-- AI-proposed attributes.
--
-- The platform never holds or forwards tenants' money (ADR 0002): Stripe only
-- collects the platform's own fees for promotion; a Revolut payment link is an
-- order in the landlord's own merchant account.

-- ---------------------------------------------------------------------------
-- Promo catalog (global). Prices are net minor units; VAT is added on top.
CREATE TABLE promo_products (
  id            uuid PRIMARY KEY DEFAULT uuid_v7(),
  code          text NOT NULL UNIQUE CHECK (code ~ '^[a-z][a-z0-9_]*$'),
  kind          text NOT NULL CHECK (kind IN ('top', 'highlight', 'bundle')),
  duration_days int NOT NULL CHECK (duration_days BETWEEN 1 AND 365),
  net_amount    bigint NOT NULL CHECK (net_amount >= 0),
  currency      char(3) NOT NULL DEFAULT 'CZK',
  vat_rate_bp   int NOT NULL DEFAULT 2100 CHECK (vat_rate_bp BETWEEN 0 AND 10000),
  name          jsonb NOT NULL,                       -- {"cs": "...", "en": "..."}
  active        boolean NOT NULL DEFAULT true,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);
CREATE TRIGGER promo_products_updated_at BEFORE UPDATE ON promo_products
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

INSERT INTO promo_products (code, kind, duration_days, net_amount, name) VALUES
  ('top_7d', 'top', 7, 19900,
    '{"cs": "Topování na 7 dní", "en": "Top placement for 7 days"}'),
  ('top_30d', 'top', 30, 49900,
    '{"cs": "Topování na 30 dní", "en": "Top placement for 30 days"}'),
  ('highlight_30d', 'highlight', 30, 29900,
    '{"cs": "Zvýraznění na 30 dní", "en": "Highlight for 30 days"}'),
  ('bundle_top_highlight_30d', 'bundle', 30, 69900,
    '{"cs": "Balíček topování a zvýraznění na 30 dní", "en": "Top placement and highlight for 30 days"}');

-- ---------------------------------------------------------------------------
-- Orders: one purchase of a product for a listing. Kind, duration and amounts
-- are copied from the product at checkout so later catalog edits do not
-- change what was bought. Financial records: never cascaded away.
CREATE TABLE orders (
  id                uuid PRIMARY KEY DEFAULT uuid_v7(),
  org_id            uuid NOT NULL REFERENCES organizations(id) ON DELETE RESTRICT,
  listing_id        uuid NOT NULL REFERENCES listings(id) ON DELETE RESTRICT,
  product_id        uuid NOT NULL REFERENCES promo_products(id),
  kind              text NOT NULL CHECK (kind IN ('top', 'highlight', 'bundle')),
  duration_days     int NOT NULL CHECK (duration_days > 0),
  created_by        uuid REFERENCES users(id) ON DELETE SET NULL,
  status            text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'failed', 'canceled')),
  net_amount        bigint NOT NULL CHECK (net_amount >= 0),
  vat_amount        bigint NOT NULL CHECK (vat_amount >= 0),
  gross_amount      bigint NOT NULL CHECK (gross_amount = net_amount + vat_amount),
  currency          char(3) NOT NULL,
  vat_rate_bp       int NOT NULL,
  starts_at         timestamptz NOT NULL,
  stripe_session_id text UNIQUE,
  created_at        timestamptz NOT NULL DEFAULT now(),
  paid_at           timestamptz
);
CREATE INDEX orders_org ON orders (org_id, created_at DESC);
CREATE INDEX orders_listing ON orders (listing_id);
CREATE INDEX orders_paid ON orders (paid_at) WHERE status = 'paid';

-- Active periods. A bundle order creates one 'top' and one 'highlight' row.
CREATE TABLE promotions (
  id         uuid PRIMARY KEY DEFAULT uuid_v7(),
  org_id     uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  listing_id uuid NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
  order_id   uuid NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  kind       text NOT NULL CHECK (kind IN ('top', 'highlight')),
  starts_at  timestamptz NOT NULL,
  ends_at    timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  CHECK (ends_at > starts_at),
  UNIQUE (order_id, kind)
);
CREATE INDEX promotions_listing ON promotions (listing_id, kind, ends_at DESC);
CREATE INDEX promotions_window ON promotions (starts_at, ends_at);

-- ---------------------------------------------------------------------------
-- Invoices (daňový doklad) with gapless numbers TR-YYYY-000001 per year. The
-- counter is incremented in the same transaction that inserts the invoice.
CREATE TABLE invoice_counters (
  year int PRIMARY KEY,
  last int NOT NULL
);

CREATE TABLE invoices (
  id                uuid PRIMARY KEY DEFAULT uuid_v7(),
  org_id            uuid NOT NULL REFERENCES organizations(id) ON DELETE RESTRICT,
  order_id          uuid NOT NULL UNIQUE REFERENCES orders(id) ON DELETE RESTRICT,
  number            text NOT NULL UNIQUE,
  issued_on         date NOT NULL,
  taxable_supply_on date NOT NULL,
  net_amount        bigint NOT NULL,
  vat_amount        bigint NOT NULL,
  gross_amount      bigint NOT NULL,
  currency          char(3) NOT NULL,
  vat_rate_bp       int NOT NULL,
  buyer             jsonb NOT NULL,                   -- name, ico, dic, address, email at issue time
  supplier          jsonb NOT NULL,                   -- platform legal data at issue time
  pdf_key           text,                             -- storage key once rendered
  sent_at           timestamptz,
  created_at        timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX invoices_org ON invoices (org_id, issued_on DESC);

-- ---------------------------------------------------------------------------
-- Revolut Business merchant account of the landlord (its own API key,
-- encrypted with secretbox). Payment links are orders in that account.
CREATE TABLE org_revolut_accounts (
  org_id       uuid PRIMARY KEY REFERENCES organizations(id) ON DELETE CASCADE,
  api_key_enc  bytea NOT NULL,
  mode         text NOT NULL CHECK (mode IN ('sandbox', 'live')),
  connected_at timestamptz NOT NULL DEFAULT now(),
  connected_by uuid REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE payment_links (
  id          uuid PRIMARY KEY DEFAULT uuid_v7(),
  org_id      uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  lease_id    uuid NOT NULL REFERENCES leases(id) ON DELETE CASCADE,
  share_id    uuid NOT NULL REFERENCES obligation_splits(id) ON DELETE CASCADE,
  provider    text NOT NULL DEFAULT 'revolut' CHECK (provider IN ('revolut')),
  external_id text NOT NULL,
  url         text NOT NULL,
  amount      bigint NOT NULL CHECK (amount > 0),
  currency    char(3) NOT NULL,
  status      text NOT NULL DEFAULT 'created' CHECK (status IN ('created', 'paid', 'expired')),
  expires_at  timestamptz,
  created_by  uuid REFERENCES users(id) ON DELETE SET NULL,
  created_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (provider, external_id)
);
CREATE INDEX payment_links_share ON payment_links (share_id, created_at DESC);

-- ---------------------------------------------------------------------------
-- Stripe webhook idempotency: an event id is processed once.
CREATE TABLE stripe_events (
  id          text PRIMARY KEY,
  type        text NOT NULL,
  received_at timestamptz NOT NULL DEFAULT now()
);

-- Feature flags; keys without a row fall back to config defaults.
CREATE TABLE feature_flags (
  key         text PRIMARY KEY CHECK (key ~ '^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)*$'),
  enabled     boolean NOT NULL,
  description text NOT NULL DEFAULT '',
  updated_by  uuid REFERENCES users(id) ON DELETE SET NULL,
  updated_at  timestamptz NOT NULL DEFAULT now()
);

-- New attributes (keys missing from the catalog) proposed by AI ingest wait
-- here for a staff decision (ADR 0003); new options of existing attributes
-- stay in filter_schema_proposals.
CREATE TABLE attribute_suggestions (
  id                 uuid PRIMARY KEY DEFAULT uuid_v7(),
  key                text NOT NULL UNIQUE CHECK (key ~ '^[a-z][a-z0-9_]*$'),
  type               text NOT NULL CHECK (type IN ('bool', 'int', 'range', 'enum', 'set', 'text')),
  group_key          text NOT NULL,
  label              jsonb NOT NULL,
  options            jsonb NOT NULL DEFAULT '[]'::jsonb,
  example_listing_id uuid REFERENCES listings(id) ON DELETE SET NULL,
  occurrences        int NOT NULL DEFAULT 1,
  model              text,
  status             text NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'approved', 'rejected')),
  note               text CHECK (length(note) <= 2000),
  decided_by         uuid REFERENCES users(id) ON DELETE SET NULL,
  decided_at         timestamptz,
  created_at         timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX attribute_suggestions_open ON attribute_suggestions (occurrences DESC, created_at) WHERE status = 'open';

-- ---------------------------------------------------------------------------
-- Search: promotion windows denormalized onto the index row (recomputed from
-- promotions when an order is paid and by a periodic job for scheduled
-- starts and expiries).
ALTER TABLE listing_search ADD COLUMN boosted_until timestamptz;
ALTER TABLE listing_search ADD COLUMN highlighted_until timestamptz;
CREATE INDEX listing_search_boosted ON listing_search (boosted_until DESC) WHERE boosted_until IS NOT NULL;

-- ---------------------------------------------------------------------------
-- Row-level security (ADR 0004).
-- +goose StatementBegin
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['orders', 'promotions', 'invoices', 'org_revolut_accounts']
  LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('CREATE POLICY %I ON %I USING (org_id IN (SELECT app_user_org_ids()))', t || '_member', t);
  END LOOP;
END
$$;
-- +goose StatementEnd

-- Lease parties read the payment links of their lease; links are created in
-- system context after the handler checked who asks.
ALTER TABLE payment_links ENABLE ROW LEVEL SECURITY;
CREATE POLICY payment_links_party ON payment_links
  USING (org_id IN (SELECT app_user_org_ids()) OR lease_id IN (SELECT app_user_lease_ids()))
  WITH CHECK (org_id IN (SELECT app_user_org_ids()));

-- Global tables: the catalog is readable by the app role, written by staff in
-- system context; webhook, counter, flag and suggestion tables are system only.
REVOKE INSERT, UPDATE, DELETE ON promo_products FROM terra_app;
REVOKE ALL ON stripe_events, invoice_counters, feature_flags, attribute_suggestions FROM terra_app;

-- +goose Down
DROP INDEX IF EXISTS listing_search_boosted;
ALTER TABLE listing_search DROP COLUMN IF EXISTS highlighted_until, DROP COLUMN IF EXISTS boosted_until;
DROP TABLE IF EXISTS attribute_suggestions, feature_flags, stripe_events, payment_links, org_revolut_accounts,
  invoices, invoice_counters, promotions, orders, promo_products CASCADE;
