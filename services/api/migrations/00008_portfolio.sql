-- +goose Up
-- M6b: one portfolio (the organization) across municipalities and regions:
-- where each lease is, groups (tags) of properties and leases, rules per
-- municipality or group, a read-only investor role and a deterministic,
-- explainable risk score per lease (ADR 0010). The score informs people; it
-- never decides about a tenant (ADR 0003, GDPR art. 22).

ALTER TABLE memberships DROP CONSTRAINT memberships_role_check;
ALTER TABLE memberships ADD CONSTRAINT memberships_role_check
  CHECK (role IN ('owner', 'admin', 'agent', 'accountant', 'maintenance', 'viewer', 'investor'));
ALTER TABLE invitations DROP CONSTRAINT invitations_role_check;
ALTER TABLE invitations ADD CONSTRAINT invitations_role_check
  CHECK (role IN ('admin', 'agent', 'accountant', 'maintenance', 'viewer', 'investor'));

-- Where a lease is: from its listing's address, a RÚIAN address or the
-- municipality named in the free-text address. admin_path is the deepest
-- known administrative unit (cz.<region>.<municipality>[.<district>...]).
ALTER TABLE leases ADD COLUMN unit_id uuid REFERENCES units(id) ON DELETE SET NULL;
ALTER TABLE leases ADD COLUMN admin_path ltree;
ALTER TABLE leases ADD COLUMN lat double precision;
ALTER TABLE leases ADD COLUMN lng double precision;
CREATE INDEX leases_admin_path ON leases USING gist (admin_path);
CREATE INDEX leases_unit ON leases (unit_id);

UPDATE leases l SET unit_id = li.unit_id, admin_path = a.admin_path,
  lat = ST_Y(a.location::geometry), lng = ST_X(a.location::geometry)
FROM listings li JOIN units u ON u.id = li.unit_id JOIN properties p ON p.id = u.property_id
JOIN addresses a ON a.id = p.address_id
WHERE li.id = l.listing_id;

-- Groups ("Brno – investiční", "Praha – vlastní"): a property puts all its
-- units and leases into the group; a lease can also be tagged directly.
CREATE TABLE portfolio_groups (
  id         uuid PRIMARY KEY DEFAULT uuid_v7(),
  org_id     uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  name       text NOT NULL CHECK (length(name) BETWEEN 1 AND 80),
  color      text NOT NULL DEFAULT '#64748b' CHECK (color ~ '^#[0-9a-f]{6}$'),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (org_id, name)
);

CREATE TABLE portfolio_group_items (
  group_id    uuid NOT NULL REFERENCES portfolio_groups(id) ON DELETE CASCADE,
  org_id      uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  property_id uuid REFERENCES properties(id) ON DELETE CASCADE,
  lease_id    uuid REFERENCES leases(id) ON DELETE CASCADE,
  created_at  timestamptz NOT NULL DEFAULT now(),
  CHECK ((property_id IS NULL) <> (lease_id IS NULL))
);
CREATE UNIQUE INDEX portfolio_group_items_property ON portfolio_group_items (group_id, property_id) WHERE property_id IS NOT NULL;
CREATE UNIQUE INDEX portfolio_group_items_lease ON portfolio_group_items (group_id, lease_id) WHERE lease_id IS NOT NULL;

-- Overrides of the jurisdiction defaults for riskier places. A group rule
-- wins over a municipality rule. Resolved values are copied into the lease
-- terms when the lease is created, so the workflow reads them from the lease.
CREATE TABLE portfolio_rules (
  id          uuid PRIMARY KEY DEFAULT uuid_v7(),
  org_id      uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  scope       text NOT NULL CHECK (scope IN ('municipality', 'group')),
  admin_path  ltree,                                   -- municipality scope
  group_id    uuid REFERENCES portfolio_groups(id) ON DELETE CASCADE,
  rules       jsonb NOT NULL,                          -- see portfolio.Rules
  updated_at  timestamptz NOT NULL DEFAULT now(),
  CHECK ((scope = 'municipality') = (admin_path IS NOT NULL)),
  CHECK ((scope = 'group') = (group_id IS NOT NULL))
);
CREATE UNIQUE INDEX portfolio_rules_municipality ON portfolio_rules (org_id, admin_path) WHERE scope = 'municipality';
CREATE UNIQUE INDEX portfolio_rules_group ON portfolio_rules (org_id, group_id) WHERE scope = 'group';
CREATE TRIGGER portfolio_rules_updated_at BEFORE UPDATE ON portfolio_rules
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Factor weights per organization (missing keys use the model defaults).
CREATE TABLE risk_settings (
  org_id     uuid PRIMARY KEY REFERENCES organizations(id) ON DELETE CASCADE,
  weights    jsonb NOT NULL DEFAULT '{}'::jsonb,
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TRIGGER risk_settings_updated_at BEFORE UPDATE ON risk_settings
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Current risk of a lease and one snapshot per month for the trend.
CREATE TABLE lease_risk (
  lease_id      uuid PRIMARY KEY REFERENCES leases(id) ON DELETE CASCADE,
  org_id        uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  score         int NOT NULL CHECK (score BETWEEN 0 AND 100),
  band          text NOT NULL CHECK (band IN ('low', 'medium', 'high')),
  factors       jsonb NOT NULL,
  model_version text NOT NULL,
  computed_at   timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX lease_risk_org ON lease_risk (org_id, score DESC);

CREATE TABLE lease_risk_history (
  lease_id   uuid NOT NULL REFERENCES leases(id) ON DELETE CASCADE,
  org_id     uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  period     text NOT NULL CHECK (period ~ '^[0-9]{4}-[0-9]{2}$'),
  score      int NOT NULL,
  band       text NOT NULL,
  monthly    bigint NOT NULL,                          -- rent + services, the weight
  PRIMARY KEY (lease_id, period)
);
CREATE INDEX lease_risk_history_org ON lease_risk_history (org_id, period);

-- AI summaries of the portfolio are suggestions a person reads (ADR 0003).
CREATE TABLE portfolio_summaries (
  id         uuid PRIMARY KEY DEFAULT uuid_v7(),
  org_id     uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  body       text NOT NULL,
  model      text NOT NULL,
  input      jsonb NOT NULL,
  created_by uuid REFERENCES users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX portfolio_summaries_org ON portfolio_summaries (org_id, created_at DESC);

-- +goose StatementBegin
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['portfolio_groups', 'portfolio_group_items', 'portfolio_rules', 'risk_settings',
                           'lease_risk_history', 'portfolio_summaries']
  LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('CREATE POLICY %I ON %I USING (org_id IN (SELECT app_user_org_ids()))', t || '_member', t);
  END LOOP;
END
$$;
-- +goose StatementEnd

-- Tenants read the risk row of their own lease; the API shows them only the
-- payment factors, never the score, location factors or weights.
ALTER TABLE lease_risk ENABLE ROW LEVEL SECURITY;
CREATE POLICY lease_risk_party ON lease_risk
  USING (org_id IN (SELECT app_user_org_ids()) OR lease_id IN (SELECT app_user_lease_ids()))
  WITH CHECK (org_id IN (SELECT app_user_org_ids()));

-- +goose Down
DROP TABLE IF EXISTS portfolio_summaries, lease_risk_history, lease_risk, risk_settings, portfolio_rules,
  portfolio_group_items, portfolio_groups CASCADE;
ALTER TABLE leases DROP COLUMN IF EXISTS lat, DROP COLUMN IF EXISTS lng, DROP COLUMN IF EXISTS admin_path, DROP COLUMN IF EXISTS unit_id;
DELETE FROM memberships WHERE role = 'investor';
DELETE FROM invitations WHERE role = 'investor';
ALTER TABLE memberships DROP CONSTRAINT memberships_role_check;
ALTER TABLE memberships ADD CONSTRAINT memberships_role_check
  CHECK (role IN ('owner', 'admin', 'agent', 'accountant', 'maintenance', 'viewer'));
ALTER TABLE invitations DROP CONSTRAINT invitations_role_check;
ALTER TABLE invitations ADD CONSTRAINT invitations_role_check
  CHECK (role IN ('admin', 'agent', 'accountant', 'maintenance', 'viewer'));
