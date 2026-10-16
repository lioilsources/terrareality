-- +goose Up
-- M8b hardening, wave 2 (docs/05-review-implementation.md): persistent login
-- lockout (S-A1), MFA bound to the session (S-A3), failures of the risk
-- recompute (S-P1), payment shares that add up (N), organizations writable
-- only by owners and admins (N), and indexes for audit and lease event reads.

-- ---------------------------------------------------------------------------
-- S-A1: failed logins per account survive restarts and multiple API
-- instances. The in-memory limiter stays the first line (also for unknown
-- addresses); these columns lock real accounts with an exponential back-off.
-- Not readable by terra_app (00002 grants it a column list on users).
ALTER TABLE users
  ADD COLUMN failed_logins int NOT NULL DEFAULT 0 CHECK (failed_logins >= 0),
  ADD COLUMN locked_until  timestamptz;

-- ---------------------------------------------------------------------------
-- S-A3: a session that passed the second factor (CompleteMFA) carries mfa_at;
-- Server.staff() requires it instead of comparing the session's age with the
-- user's totp_enabled_at.
ALTER TABLE sessions ADD COLUMN mfa_at timestamptz;
-- Sessions opened after TOTP was enabled went through the second factor
-- (every login path asks for it then), so they keep their status.
UPDATE sessions s SET mfa_at = s.created_at
FROM users u
WHERE u.id = s.user_id AND u.totp_enabled_at IS NOT NULL AND s.created_at > u.totp_enabled_at
  AND s.impersonator_id IS NULL AND s.revoked_at IS NULL;

-- ---------------------------------------------------------------------------
-- S-P1: the last failed recompute of a lease's risk score. RecomputeStale
-- sets them (when a score row exists), skips such leases for an hour and a
-- successful recompute clears them.
ALTER TABLE lease_risk
  ADD COLUMN last_error text CHECK (length(last_error) <= 2000),
  ADD COLUMN failed_at  timestamptz;

-- ---------------------------------------------------------------------------
-- N: the payment shares of the tenant parties of a signed or active lease add
-- up to 100 % (10000 basis points). Checked at commit, so rewriting the
-- parties of a lease inside one transaction may pass through other sums.
-- +goose StatementBegin
-- SECURITY DEFINER: the check fires at commit, possibly still as terra_app,
-- and must see every party of the lease whatever the caller's policies.
CREATE FUNCTION lease_shares_check() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_lease uuid;
  v_state text;
  v_total bigint;
BEGIN
  IF TG_TABLE_NAME = 'leases' THEN
    v_lease := NEW.id;
  ELSIF TG_OP = 'DELETE' THEN
    v_lease := OLD.lease_id;
  ELSE
    v_lease := NEW.lease_id;
  END IF;
  SELECT state INTO v_state FROM leases WHERE id = v_lease;
  IF v_state IS NULL OR v_state NOT IN ('signed', 'active') THEN
    RETURN NULL;
  END IF;
  SELECT coalesce(sum(share_bps), 0) INTO v_total FROM lease_parties
  WHERE lease_id = v_lease AND role <> 'guarantor';
  IF v_total <> 10000 THEN
    RAISE EXCEPTION 'payment shares of lease % add up to % basis points, not 10000', v_lease, v_total
      USING ERRCODE = '23514', CONSTRAINT = 'lease_shares_total';
  END IF;
  RETURN NULL;
END
$$;
-- +goose StatementEnd

CREATE CONSTRAINT TRIGGER lease_parties_shares_total
  AFTER INSERT OR UPDATE OF share_bps, role, lease_id OR DELETE ON lease_parties
  DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW EXECUTE FUNCTION lease_shares_check();
CREATE CONSTRAINT TRIGGER leases_shares_total
  AFTER UPDATE OF state ON leases
  DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW WHEN (NEW.state IN ('signed', 'active') AND OLD.state IS DISTINCT FROM NEW.state)
  EXECUTE FUNCTION lease_shares_check();

-- ---------------------------------------------------------------------------
-- N: organizations. Members read their organizations; only owners and
-- admins change them (company details, soft delete). Creating organizations
-- is system work (registration, POST /v1/orgs) and nothing deletes rows under
-- the app role.
DROP POLICY organizations_member ON organizations;
CREATE POLICY organizations_read ON organizations FOR SELECT
  USING (id IN (SELECT app_user_org_ids()));
CREATE POLICY organizations_update ON organizations FOR UPDATE
  USING (app_user_role(id) IN ('owner', 'admin'))
  WITH CHECK (app_user_role(id) IN ('owner', 'admin'));
REVOKE INSERT, DELETE, TRUNCATE ON organizations FROM terra_app;

-- ---------------------------------------------------------------------------
-- Indexes for the audit views (entity history, actions over time) and the
-- lease event lookups by kind (notice, signatures).
CREATE INDEX audit_events_entity_time ON audit_events (entity, entity_id, occurred_at DESC);
CREATE INDEX audit_events_action_time ON audit_events (action, occurred_at);
CREATE INDEX lease_events_lease_kind ON lease_events (lease_id, kind);
-- Superseded by audit_events_entity_time (same leading columns).
DROP INDEX IF EXISTS audit_events_entity;

-- +goose Down
CREATE INDEX IF NOT EXISTS audit_events_entity ON audit_events (entity, entity_id);
DROP INDEX IF EXISTS lease_events_lease_kind;
DROP INDEX IF EXISTS audit_events_action_time;
DROP INDEX IF EXISTS audit_events_entity_time;

GRANT INSERT, DELETE ON organizations TO terra_app;
DROP POLICY IF EXISTS organizations_update ON organizations;
DROP POLICY IF EXISTS organizations_read ON organizations;
CREATE POLICY organizations_member ON organizations
  USING (id IN (SELECT app_user_org_ids()));

DROP TRIGGER IF EXISTS leases_shares_total ON leases;
DROP TRIGGER IF EXISTS lease_parties_shares_total ON lease_parties;
DROP FUNCTION IF EXISTS lease_shares_check();

ALTER TABLE lease_risk DROP COLUMN IF EXISTS failed_at, DROP COLUMN IF EXISTS last_error;
ALTER TABLE sessions DROP COLUMN IF EXISTS mfa_at;
ALTER TABLE users DROP COLUMN IF EXISTS locked_until, DROP COLUMN IF EXISTS failed_logins;
