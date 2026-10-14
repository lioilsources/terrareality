-- +goose Up
-- M1: identity, sessions, organizations, row-level security, jurisdictions,
-- audit log and GDPR bookkeeping.

-- ---------------------------------------------------------------------------
-- Jurisdictions: country rules read by services instead of hardcoded values.
-- Legal values are drafts until confirmed (docs/legal-questions.md).
CREATE TABLE jurisdictions (
  code                 text PRIMARY KEY CHECK (code ~ '^[A-Z]{2}$'),
  name                 jsonb NOT NULL,            -- {"cs": "...", "en": "..."}
  currency             char(3) NOT NULL,
  default_locale       text NOT NULL,
  deposit_max_months   int NOT NULL CHECK (deposit_max_months >= 0),
  notice_period_months int NOT NULL CHECK (notice_period_months >= 0),
  signature_provider   text NOT NULL,
  identity_provider    text NOT NULL,
  address_format       jsonb NOT NULL,            -- ordered field list + postal code pattern
  rules                jsonb NOT NULL DEFAULT '{}'::jsonb,
  active               boolean NOT NULL DEFAULT true,
  created_at           timestamptz NOT NULL DEFAULT now(),
  updated_at           timestamptz NOT NULL DEFAULT now()
);
CREATE TRIGGER jurisdictions_updated_at BEFORE UPDATE ON jurisdictions
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

INSERT INTO jurisdictions (code, name, currency, default_locale, deposit_max_months,
  notice_period_months, signature_provider, identity_provider, address_format, rules)
VALUES ('CZ', '{"cs": "Česko", "en": "Czechia"}', 'CZK', 'cs', 3, 3, 'bankid_sign', 'bankid',
  '{"fields": ["street", "house_number", "orientation_number", "city", "city_part", "postal_code"], "postal_code_pattern": "^[0-9]{3} ?[0-9]{2}$", "registry": "ruian"}',
  '{"legal_basis": "zákon č. 89/2012 Sb., § 2235 an.", "deposit_return_days": 30, "payment_reference": "variable_symbol", "qr_payment_format": "spayd", "status": "draft_pending_legal_review"}');

-- ---------------------------------------------------------------------------
-- Users. verification_level is derived from the verified_at columns.
CREATE TABLE users (
  id                    uuid PRIMARY KEY DEFAULT uuid_v7(),
  email                 citext NOT NULL UNIQUE,
  email_verified_at     timestamptz,
  password_hash         text,
  display_name          text NOT NULL DEFAULT '' CHECK (length(display_name) <= 120),
  locale                text NOT NULL DEFAULT 'cs' CHECK (locale IN ('cs', 'en')),
  phone                 text,
  phone_verified_at     timestamptz,
  identity_verified_at  timestamptz,
  totp_secret           bytea,                    -- AES-GCM sealed, see internal/platform/secretbox
  totp_pending_secret   bytea,
  totp_enabled_at       timestamptz,
  totp_last_step        bigint NOT NULL DEFAULT 0, -- replay protection
  is_staff              boolean NOT NULL DEFAULT false,
  pseudonymized_at      timestamptz,
  created_at            timestamptz NOT NULL DEFAULT now(),
  updated_at            timestamptz NOT NULL DEFAULT now(),
  verification_level    text GENERATED ALWAYS AS (
    CASE
      WHEN identity_verified_at IS NOT NULL THEN 'identity'
      WHEN phone_verified_at IS NOT NULL AND email_verified_at IS NOT NULL THEN 'phone'
      WHEN email_verified_at IS NOT NULL THEN 'email'
      ELSE 'none'
    END) STORED
);
CREATE TRIGGER users_updated_at BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE user_recovery_codes (
  id         uuid PRIMARY KEY DEFAULT uuid_v7(),
  user_id    uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  code_hash  bytea NOT NULL,
  used_at    timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX user_recovery_codes_user ON user_recovery_codes (user_id);

-- Social logins (Google, Apple). One row per provider account.
CREATE TABLE oauth_identities (
  id         uuid PRIMARY KEY DEFAULT uuid_v7(),
  user_id    uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  provider   text NOT NULL,
  subject    text NOT NULL,
  email      citext,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (provider, subject)
);
CREATE INDEX oauth_identities_user ON oauth_identities (user_id);

-- Verified identity (BankID or mock). Minimal claim set, kept for contracts.
CREATE TABLE identity_verifications (
  id          uuid PRIMARY KEY DEFAULT uuid_v7(),
  user_id     uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  provider    text NOT NULL,
  subject     text NOT NULL,
  given_name  text,
  family_name text,
  birthdate   date,
  address     jsonb,
  verified_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (provider, subject)
);
CREATE INDEX identity_verifications_user ON identity_verifications (user_id);

-- Opaque session tokens; only the SHA-256 is stored.
CREATE TABLE sessions (
  id              uuid PRIMARY KEY DEFAULT uuid_v7(),
  user_id         uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash      bytea NOT NULL UNIQUE,
  client          text NOT NULL CHECK (client IN ('web', 'mobile', 'api')),
  impersonator_id uuid REFERENCES users(id) ON DELETE CASCADE,
  ip              inet,
  user_agent      text,
  created_at      timestamptz NOT NULL DEFAULT now(),
  last_seen_at    timestamptz NOT NULL DEFAULT now(),
  expires_at      timestamptz NOT NULL,
  revoked_at      timestamptz
);
CREATE INDEX sessions_user ON sessions (user_id) WHERE revoked_at IS NULL;

-- One-time tokens: magic links, e-mail verification, phone codes, MFA
-- challenges, OIDC state. Only hashes are stored.
CREATE TABLE auth_tokens (
  id         uuid PRIMARY KEY DEFAULT uuid_v7(),
  purpose    text NOT NULL CHECK (purpose IN ('magic_link', 'email_verify', 'phone_verify',
               'mfa_challenge', 'oidc_state', 'password_reset')),
  user_id    uuid REFERENCES users(id) ON DELETE CASCADE,
  email      citext,
  token_hash bytea NOT NULL UNIQUE,
  data       jsonb NOT NULL DEFAULT '{}'::jsonb,
  attempts   int NOT NULL DEFAULT 0,
  expires_at timestamptz NOT NULL,
  used_at    timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX auth_tokens_expiry ON auth_tokens (expires_at);

-- ---------------------------------------------------------------------------
-- Organizations. Every user owns an implicit personal organization.
CREATE TABLE organizations (
  id                uuid PRIMARY KEY DEFAULT uuid_v7(),
  kind              text NOT NULL CHECK (kind IN ('personal', 'company')),
  name              text NOT NULL CHECK (length(name) BETWEEN 1 AND 200),
  registration_no   text,                         -- IČO
  vat_no            text,                         -- DIČ
  jurisdiction_code text NOT NULL DEFAULT 'CZ' REFERENCES jurisdictions(code),
  personal_owner_id uuid UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),
  deleted_at        timestamptz,
  CHECK ((kind = 'personal') = (personal_owner_id IS NOT NULL))
);
CREATE TRIGGER organizations_updated_at BEFORE UPDATE ON organizations
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE memberships (
  org_id     uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id    uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role       text NOT NULL CHECK (role IN ('owner', 'admin', 'agent', 'accountant', 'maintenance', 'viewer')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (org_id, user_id)
);
CREATE INDEX memberships_user ON memberships (user_id);
CREATE TRIGGER memberships_updated_at BEFORE UPDATE ON memberships
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE invitations (
  id          uuid PRIMARY KEY DEFAULT uuid_v7(),
  org_id      uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  email       citext NOT NULL,
  role        text NOT NULL CHECK (role IN ('admin', 'agent', 'accountant', 'maintenance', 'viewer')),
  token_hash  bytea NOT NULL UNIQUE,
  invited_by  uuid REFERENCES users(id) ON DELETE SET NULL,
  expires_at  timestamptz NOT NULL,
  accepted_at timestamptz,
  accepted_by uuid REFERENCES users(id) ON DELETE SET NULL,
  revoked_at  timestamptz,
  created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX invitations_org ON invitations (org_id);
CREATE UNIQUE INDEX invitations_open_per_email ON invitations (org_id, email)
  WHERE accepted_at IS NULL AND revoked_at IS NULL;

-- ---------------------------------------------------------------------------
-- Audit log: every mutation of a domain object (plan, section 5).
CREATE TABLE audit_events (
  id              uuid PRIMARY KEY DEFAULT uuid_v7(),
  occurred_at     timestamptz NOT NULL DEFAULT now(),
  actor_id        uuid REFERENCES users(id) ON DELETE SET NULL,
  impersonator_id uuid REFERENCES users(id) ON DELETE SET NULL,
  org_id          uuid REFERENCES organizations(id) ON DELETE SET NULL,
  entity          text NOT NULL,
  entity_id       uuid,
  action          text NOT NULL,
  diff            jsonb NOT NULL DEFAULT '{}'::jsonb,
  ip              inet,
  request_id      text
);
CREATE INDEX audit_events_org ON audit_events (org_id, occurred_at DESC);
CREATE INDEX audit_events_actor ON audit_events (actor_id, occurred_at DESC);
CREATE INDEX audit_events_entity ON audit_events (entity, entity_id);

-- ---------------------------------------------------------------------------
-- GDPR: append-only consent log and data subject requests.
CREATE TABLE consents (
  id         uuid PRIMARY KEY DEFAULT uuid_v7(),
  user_id    uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  kind       text NOT NULL CHECK (kind IN ('terms', 'privacy', 'marketing')),
  version    text NOT NULL,
  granted    boolean NOT NULL,
  ip         inet,
  user_agent text,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX consents_user ON consents (user_id, kind, created_at DESC);

CREATE TABLE gdpr_requests (
  id           uuid PRIMARY KEY DEFAULT uuid_v7(),
  user_id      uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  kind         text NOT NULL CHECK (kind IN ('export', 'erasure')),
  status       text NOT NULL DEFAULT 'pending'
                 CHECK (status IN ('pending', 'processing', 'done', 'failed', 'cancelled', 'rejected')),
  scheduled_at timestamptz NOT NULL DEFAULT now(),
  object_key   text,
  detail       text,
  created_at   timestamptz NOT NULL DEFAULT now(),
  completed_at timestamptz
);
CREATE INDEX gdpr_requests_user ON gdpr_requests (user_id, created_at DESC);

-- ---------------------------------------------------------------------------
-- Row-level security. Request handlers run org data access inside a
-- transaction that switches to the non-owner role terra_app and sets
-- app.current_user; policies then limit rows to the user's organizations.
-- System work (auth, jobs, backoffice) runs as the owner role and is
-- authorized in code.
-- +goose StatementBegin
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'terra_app') THEN
    CREATE ROLE terra_app NOLOGIN;
  END IF;
END
$$;
-- +goose StatementEnd
-- +goose StatementBegin
DO $$
BEGIN
  EXECUTE format('GRANT terra_app TO %I', current_user);
END
$$;
-- +goose StatementEnd
GRANT USAGE ON SCHEMA public TO terra_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO terra_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO terra_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO terra_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO terra_app;
-- Secrets never leave system context.
REVOKE ALL ON sessions, auth_tokens, user_recovery_codes, oauth_identities FROM terra_app;
-- Org-scoped code may join users for names, never read credentials.
REVOKE ALL ON users FROM terra_app;
GRANT SELECT (id, email, display_name, locale, verification_level, created_at) ON users TO terra_app;

CREATE FUNCTION app_current_user() RETURNS uuid
LANGUAGE sql STABLE AS $$
  SELECT nullif(current_setting('app.current_user', true), '')::uuid
$$;

-- SECURITY DEFINER so the policy on memberships can call it without recursion.
CREATE FUNCTION app_user_org_ids() RETURNS SETOF uuid
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT m.org_id FROM memberships m
  JOIN organizations o ON o.id = m.org_id AND o.deleted_at IS NULL
  WHERE m.user_id = app_current_user()
$$;

ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
CREATE POLICY organizations_member ON organizations
  USING (id IN (SELECT app_user_org_ids()));

ALTER TABLE memberships ENABLE ROW LEVEL SECURITY;
CREATE POLICY memberships_member ON memberships
  USING (org_id IN (SELECT app_user_org_ids()));

ALTER TABLE invitations ENABLE ROW LEVEL SECURITY;
CREATE POLICY invitations_member ON invitations
  USING (org_id IN (SELECT app_user_org_ids()));

ALTER TABLE audit_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY audit_events_member ON audit_events
  USING (org_id IN (SELECT app_user_org_ids()) OR actor_id = app_current_user());

ALTER TABLE consents ENABLE ROW LEVEL SECURITY;
CREATE POLICY consents_self ON consents USING (user_id = app_current_user());

ALTER TABLE gdpr_requests ENABLE ROW LEVEL SECURITY;
CREATE POLICY gdpr_requests_self ON gdpr_requests USING (user_id = app_current_user());

ALTER TABLE identity_verifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY identity_verifications_self ON identity_verifications USING (user_id = app_current_user());

-- +goose Down
DROP TABLE IF EXISTS gdpr_requests, consents, audit_events, invitations, memberships,
  organizations, auth_tokens, sessions, identity_verifications, oauth_identities,
  user_recovery_codes, users, jurisdictions CASCADE;
DROP FUNCTION IF EXISTS app_user_org_ids();
DROP FUNCTION IF EXISTS app_current_user();
REVOKE ALL ON SCHEMA public FROM terra_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON TABLES FROM terra_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON SEQUENCES FROM terra_app;
