-- +goose Up
-- M6: leases with parties, documents and signatures, a hash-chained event
-- log, the payment schedule (obligations split between co-tenants), bank
-- connections with transaction matching and a double-entry ledger. The
-- platform never holds money (ADR 0002): payments go straight to the
-- landlord's account; we only record and match them.

-- Variable symbol for payments of a lease (10 digits, never reused).
CREATE SEQUENCE lease_code_seq START 2600000001;

CREATE TABLE leases (
  id                uuid PRIMARY KEY DEFAULT uuid_v7(),
  org_id            uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  listing_id        uuid REFERENCES listings(id) ON DELETE SET NULL,
  application_id    uuid REFERENCES applications(id) ON DELETE SET NULL,
  code              bigint NOT NULL UNIQUE DEFAULT nextval('lease_code_seq'),
  jurisdiction_code text NOT NULL REFERENCES jurisdictions(code),
  currency          char(3) NOT NULL,
  state             text NOT NULL DEFAULT 'draft' CHECK (state IN ('draft', 'proposed', 'negotiating', 'signed',
                      'active', 'notice_given', 'terminated', 'settled', 'cancelled')),
  template          text NOT NULL CHECK (template IN ('byt_doba_urcita', 'byt_doba_neurcita', 'spolecny_najem', 'pokoj')),
  template_version  text NOT NULL,
  property_address  text NOT NULL,
  unit_label        text NOT NULL DEFAULT '',
  starts_on         date NOT NULL,
  ends_on           date,                       -- null = indefinite term
  rent_amount       bigint NOT NULL CHECK (rent_amount > 0),
  services_amount   bigint NOT NULL DEFAULT 0 CHECK (services_amount >= 0),
  deposit_amount    bigint NOT NULL DEFAULT 0 CHECK (deposit_amount >= 0),
  due_day           int NOT NULL DEFAULT 1 CHECK (due_day BETWEEN 1 AND 28),
  notice_months     int NOT NULL DEFAULT 3 CHECK (notice_months BETWEEN 1 AND 12),
  payee_iban        text NOT NULL,
  payee_name        text NOT NULL,
  clauses           text[] NOT NULL DEFAULT '{}',  -- optional clauses by key
  terms             jsonb NOT NULL DEFAULT '{}'::jsonb,
  change_request    text,                       -- last tenant comment in negotiation
  notice_on         date,
  workflow_id       text,
  created_by        uuid REFERENCES users(id) ON DELETE SET NULL,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),
  signed_at         timestamptz,
  CHECK (ends_on IS NULL OR ends_on > starts_on)
);
CREATE INDEX leases_org ON leases (org_id, created_at DESC);
CREATE TRIGGER leases_updated_at BEFORE UPDATE ON leases FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE lease_parties (
  id               uuid PRIMARY KEY DEFAULT uuid_v7(),
  lease_id         uuid NOT NULL REFERENCES leases(id) ON DELETE CASCADE,
  org_id           uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  role             text NOT NULL CHECK (role IN ('landlord', 'tenant', 'co_tenant', 'subtenant', 'guarantor')),
  user_id          uuid REFERENCES users(id) ON DELETE SET NULL,
  name             text NOT NULL,
  email            citext,
  share_bps        int NOT NULL DEFAULT 0 CHECK (share_bps BETWEEN 0 AND 10000), -- payment share, basis points
  position         int NOT NULL,                -- also the specific symbol on payments
  settlement_ok_at timestamptz,                 -- confirmed the deposit settlement
  created_at       timestamptz NOT NULL DEFAULT now(),
  UNIQUE (lease_id, position)
);
CREATE INDEX lease_parties_user ON lease_parties (user_id);

-- Append-only event log; each hash covers the previous one.
CREATE TABLE lease_events (
  id         uuid PRIMARY KEY DEFAULT uuid_v7(),
  lease_id   uuid NOT NULL REFERENCES leases(id) ON DELETE CASCADE,
  org_id     uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  seq        int NOT NULL,
  kind       text NOT NULL,
  payload    jsonb NOT NULL,                    -- canonical JSON that was hashed
  prev_hash  bytea NOT NULL,
  hash       bytea NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (lease_id, seq)
);

CREATE TABLE lease_documents (
  id           uuid PRIMARY KEY DEFAULT uuid_v7(),
  lease_id     uuid NOT NULL REFERENCES leases(id) ON DELETE CASCADE,
  org_id       uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  kind         text NOT NULL CHECK (kind IN ('draft', 'final', 'signed', 'scan', 'evidence')),
  version      int NOT NULL,
  object_key   text NOT NULL UNIQUE,
  filename     text NOT NULL,
  sha256       bytea NOT NULL,
  created_at   timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX lease_documents_lease ON lease_documents (lease_id, created_at);

CREATE TABLE signatures (
  id           uuid PRIMARY KEY DEFAULT uuid_v7(),
  lease_id     uuid NOT NULL REFERENCES leases(id) ON DELETE CASCADE,
  org_id       uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  document_id  uuid NOT NULL REFERENCES lease_documents(id) ON DELETE CASCADE,
  party_id     uuid NOT NULL REFERENCES lease_parties(id) ON DELETE CASCADE,
  provider     text NOT NULL CHECK (provider IN ('mock', 'bankid_sign', 'upload_scan')),
  status       text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'signed', 'declined')),
  external_id  text,
  evidence     jsonb NOT NULL DEFAULT '{}'::jsonb,
  signed_at    timestamptz,
  created_at   timestamptz NOT NULL DEFAULT now(),
  UNIQUE (document_id, party_id)
);

-- ---------------------------------------------------------------------------
-- Payment schedule.
CREATE TABLE payment_obligations (
  id         uuid PRIMARY KEY DEFAULT uuid_v7(),
  lease_id   uuid NOT NULL REFERENCES leases(id) ON DELETE CASCADE,
  org_id     uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  kind       text NOT NULL CHECK (kind IN ('rent', 'services', 'deposit', 'oneoff')),
  period     text NOT NULL DEFAULT '',          -- YYYY-MM for monthly items
  due_on     date NOT NULL,
  amount     bigint NOT NULL CHECK (amount > 0),
  currency   char(3) NOT NULL,
  status     text NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'paid', 'cancelled')),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (lease_id, kind, period)
);
CREATE INDEX payment_obligations_due ON payment_obligations (due_on) WHERE status = 'open';

CREATE TABLE obligation_splits (
  id            uuid PRIMARY KEY DEFAULT uuid_v7(),
  obligation_id uuid NOT NULL REFERENCES payment_obligations(id) ON DELETE CASCADE,
  lease_id      uuid NOT NULL REFERENCES leases(id) ON DELETE CASCADE,
  org_id        uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  party_id      uuid NOT NULL REFERENCES lease_parties(id) ON DELETE CASCADE,
  amount        bigint NOT NULL CHECK (amount > 0),
  paid_amount   bigint NOT NULL DEFAULT 0 CHECK (paid_amount >= 0),
  UNIQUE (obligation_id, party_id)
);
CREATE INDEX obligation_splits_lease ON obligation_splits (lease_id);

-- Double-entry ledger: every posting group sums to zero. Accounts:
-- receivable (per party), income, deposit_held, cash.
CREATE TABLE ledger_entries (
  id            uuid PRIMARY KEY DEFAULT uuid_v7(),
  lease_id      uuid NOT NULL REFERENCES leases(id) ON DELETE CASCADE,
  org_id        uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  posting_id    uuid NOT NULL,
  account       text NOT NULL CHECK (account IN ('receivable', 'income', 'deposit_held', 'cash')),
  party_id      uuid REFERENCES lease_parties(id) ON DELETE SET NULL,
  split_id      uuid REFERENCES obligation_splits(id) ON DELETE SET NULL,
  amount        bigint NOT NULL,                -- debit positive, credit negative
  memo          text NOT NULL DEFAULT '',
  booked_on     date NOT NULL,
  created_at    timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ledger_entries_lease ON ledger_entries (lease_id, booked_on);

-- ---------------------------------------------------------------------------
-- Open banking (AIS): the landlord links their own account; we read it.
CREATE TABLE bank_connections (
  id             uuid PRIMARY KEY DEFAULT uuid_v7(),
  org_id         uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  provider       text NOT NULL CHECK (provider IN ('gocardless', 'mock')),
  institution_id text NOT NULL DEFAULT '',
  requisition_id text NOT NULL DEFAULT '',
  account_id     text NOT NULL DEFAULT '',
  iban           text NOT NULL DEFAULT '',
  status         text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'linked', 'expired', 'error')),
  last_synced_at timestamptz,
  created_by     uuid REFERENCES users(id) ON DELETE SET NULL,
  created_at     timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX bank_connections_org ON bank_connections (org_id);

CREATE TABLE bank_transactions (
  id                   uuid PRIMARY KEY DEFAULT uuid_v7(),
  org_id               uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  connection_id        uuid NOT NULL REFERENCES bank_connections(id) ON DELETE CASCADE,
  external_id          text NOT NULL,
  booked_on            date NOT NULL,
  amount               bigint NOT NULL,         -- minor units, incoming positive
  currency             char(3) NOT NULL,
  variable_symbol      text NOT NULL DEFAULT '',
  specific_symbol      text NOT NULL DEFAULT '',
  counterparty_name    text NOT NULL DEFAULT '',
  counterparty_account text NOT NULL DEFAULT '',
  remittance           text NOT NULL DEFAULT '',
  match_status         text NOT NULL DEFAULT 'unmatched'
                         CHECK (match_status IN ('unmatched', 'matched', 'suggested', 'ignored')),
  split_id             uuid REFERENCES obligation_splits(id) ON DELETE SET NULL,
  match_note           text NOT NULL DEFAULT '',
  created_at           timestamptz NOT NULL DEFAULT now(),
  UNIQUE (connection_id, external_id)
);
CREATE INDEX bank_transactions_open ON bank_transactions (org_id, match_status);

-- ---------------------------------------------------------------------------
-- Row-level security (ADR 0009): organization members, plus parties for the
-- lease, its documents, events, schedule and ledger.
-- +goose StatementBegin
CREATE FUNCTION app_user_lease_ids() RETURNS SETOF uuid
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT p.lease_id FROM lease_parties p WHERE p.user_id = app_current_user()
  UNION
  SELECT l.id FROM leases l WHERE l.org_id IN (SELECT app_user_org_ids())
$$;
-- +goose StatementEnd

ALTER TABLE leases ENABLE ROW LEVEL SECURITY;
CREATE POLICY leases_party ON leases
  USING (org_id IN (SELECT app_user_org_ids()) OR id IN (SELECT app_user_lease_ids()))
  WITH CHECK (org_id IN (SELECT app_user_org_ids()));

-- +goose StatementBegin
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['lease_parties', 'lease_events', 'lease_documents', 'signatures',
                           'payment_obligations', 'obligation_splits', 'ledger_entries']
  LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('CREATE POLICY %I ON %I USING (org_id IN (SELECT app_user_org_ids()) OR lease_id IN (SELECT app_user_lease_ids()))', t || '_party', t);
  END LOOP;
  FOREACH t IN ARRAY ARRAY['bank_connections', 'bank_transactions']
  LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('CREATE POLICY %I ON %I USING (org_id IN (SELECT app_user_org_ids()))', t || '_member', t);
  END LOOP;
END
$$;
-- +goose StatementEnd

-- The event log and the ledger are append-only for everyone, including the app role.
REVOKE UPDATE, DELETE ON lease_events, ledger_entries FROM terra_app;

-- +goose Down
DROP TABLE IF EXISTS bank_transactions, bank_connections, ledger_entries, obligation_splits, payment_obligations,
  signatures, lease_documents, lease_events, lease_parties, leases CASCADE;
DROP FUNCTION IF EXISTS app_user_lease_ids();
DROP SEQUENCE IF EXISTS lease_code_seq;
