-- +goose Up
-- Least-privilege database role for the api and worker (ADR 0012 point 5,
-- ASVS V1.2). terra_service is NOLOGIN NOSUPERUSER NOBYPASSRLS; the actual
-- login role (terra_api in production) is created outside migrations with a
-- password and IN ROLE terra_service (infra/hetzner/db/initdb/13-api-role.sh).
-- Migrations keep running as the schema owner (MIGRATE_DATABASE_URL).
--
-- System code (auth, jobs, backoffice) needs every row, so instead of
-- bypassing RLS the role gets an explicit permissive policy `system_all` on
-- each table with RLS enabled. A new RLS table without that policy is closed
-- to the service role until a migration adds it; the integration test
-- TestServiceRolePolicies enumerates pg_class so that cannot go unnoticed.
-- +goose StatementBegin
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'terra_service') THEN
    CREATE ROLE terra_service NOLOGIN NOSUPERUSER NOBYPASSRLS NOCREATEDB NOCREATEROLE NOREPLICATION;
  ELSE
    ALTER ROLE terra_service NOLOGIN NOSUPERUSER NOBYPASSRLS NOCREATEDB NOCREATEROLE NOREPLICATION;
  END IF;
END
$$;
-- +goose StatementEnd

-- db.AsUser runs SET LOCAL ROLE terra_app; the login role reaches it through
-- terra_service.
GRANT terra_app TO terra_service;

-- PostgreSQL 15+ default, made explicit for clusters created earlier: only
-- the owner creates objects in public.
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
GRANT USAGE ON SCHEMA public TO terra_service;

-- Data access on every table, including the ones withheld from terra_app
-- (sessions, auth_tokens, user_recovery_codes, oauth_identities, users,
-- stripe_events, invoice_counters, feature_flags, ...). No TRUNCATE,
-- REFERENCES or TRIGGER.
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO terra_service;
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA public TO terra_service;
-- Tables created later by the migration owner (River's tables, new migrations).
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO terra_service;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO terra_service;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT EXECUTE ON FUNCTIONS TO terra_service;

-- The RÚIAN import empties its staging table.
GRANT TRUNCATE ON ruian_staging TO terra_service;

-- Append-only tables lose UPDATE/DELETE again in 00013 (review S-L4).

-- The schema version is the migration owner's business; the api only reads
-- it (health/version).
-- +goose StatementBegin
DO $$
BEGIN
  IF to_regclass('public.goose_db_version') IS NOT NULL THEN
    REVOKE INSERT, UPDATE, DELETE ON goose_db_version FROM terra_service;
  END IF;
END
$$;
-- +goose StatementEnd

-- Application functions (not the ones installed by extensions; those keep
-- their PUBLIC execute grant).
-- +goose StatementBegin
DO $$
DECLARE
  f regprocedure;
BEGIN
  FOR f IN
    SELECT p.oid::regprocedure
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.prokind IN ('f', 'p')
      AND NOT EXISTS (SELECT 1 FROM pg_depend d
                      WHERE d.classid = 'pg_proc'::regclass AND d.objid = p.oid AND d.deptype = 'e')
  LOOP
    EXECUTE format('GRANT EXECUTE ON %s TO terra_service', f);
  END LOOP;
END
$$;
-- +goose StatementEnd

-- REFRESH MATERIALIZED VIEW requires ownership (jobs.RefreshAggregatesWorker).
-- A migration that recreates the view must hand it to terra_service again.
-- The view's query then runs as terra_service and sees all rows through the
-- system_all policies below. Changing the owner to a role requires being able
-- to SET ROLE to it: without superuser (managed PostgreSQL) the migration
-- owner must be a member of terra_service first.
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

-- One permissive policy per RLS table. Policies are OR-ed, so the existing
-- per-user policies keep restricting terra_app (db.AsUser) unchanged: after
-- SET ROLE terra_app the session is no longer terra_service.
-- +goose StatementBegin
DO $$
DECLARE
  t regclass;
BEGIN
  FOR t IN
    SELECT c.oid::regclass
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relkind IN ('r', 'p') AND c.relrowsecurity
  LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_policy WHERE polrelid = t AND polname = 'system_all') THEN
      EXECUTE format('CREATE POLICY system_all ON %s TO terra_service USING (true) WITH CHECK (true)', t);
    END IF;
  END LOOP;
END
$$;
-- +goose StatementEnd

-- Every later migration that enables row-level security on a table calls
--   SELECT app_enable_rls('<table>');
-- which enables RLS and adds the system_all policy, then creates the per-user
-- policies (review S-F10c; TestServiceRolePolicies fails otherwise).
-- ALTER DEFAULT PRIVILEGES above applies to objects created by the role that
-- ran this migration: migrations must keep running as that same owner role.
-- +goose StatementBegin
CREATE FUNCTION app_enable_rls(t regclass) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE format('ALTER TABLE %s ENABLE ROW LEVEL SECURITY', t);
  IF NOT EXISTS (SELECT 1 FROM pg_policy WHERE polrelid = t AND polname = 'system_all') THEN
    EXECUTE format('CREATE POLICY system_all ON %s TO terra_service USING (true) WITH CHECK (true)', t);
  END IF;
END
$$;
-- +goose StatementEnd
-- Schema helper for migrations only.
REVOKE EXECUTE ON FUNCTION app_enable_rls(regclass) FROM PUBLIC, terra_service;

-- +goose Down
DROP FUNCTION IF EXISTS app_enable_rls(regclass);
-- +goose StatementBegin
DO $$
DECLARE
  t regclass;
BEGIN
  FOR t IN
    SELECT p.polrelid::regclass
    FROM pg_policy p
    JOIN pg_class c ON c.oid = p.polrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND p.polname = 'system_all'
  LOOP
    EXECUTE format('DROP POLICY system_all ON %s', t);
  END LOOP;
END
$$;
-- +goose StatementEnd
-- +goose StatementBegin
DO $$
BEGIN
  EXECUTE format('ALTER MATERIALIZED VIEW listing_aggregates OWNER TO %I', current_user);
END
$$;
-- +goose StatementEnd
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON TABLES FROM terra_service;
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON SEQUENCES FROM terra_service;
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON FUNCTIONS FROM terra_service;
-- Revokes the remaining grants in this database (DROP OWNED needs the
-- membership granted above, so it is not revoked separately; dropping the
-- role removes it). The role itself is
-- cluster-wide: it is dropped only when no other database (e.g. terra_test
-- next to terra in dev) and no login role still depend on it.
DROP OWNED BY terra_service;
-- +goose StatementBegin
DO $$
BEGIN
  DROP ROLE terra_service;
EXCEPTION WHEN dependent_objects_still_exist THEN
  RAISE NOTICE 'terra_service kept: still referenced in another database';
END
$$;
-- +goose StatementEnd
