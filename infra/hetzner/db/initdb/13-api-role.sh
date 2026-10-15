#!/bin/bash
# docker-entrypoint-initdb.d hook: login role for the api and worker (ADR 0012
# point 5). terra_api is NOSUPERUSER NOBYPASSRLS and gets its privileges only
# through terra_service, whose grants and system_all RLS policies come from
# migration 00012_service_role.sql. The NOLOGIN group role is created here
# (same attributes as in the migration) so the membership can exist before the
# first migration runs. Migrations keep running as the owner (POSTGRES_USER).
# Password from TERRA_API_DB_PASSWORD or the file named by
# TERRA_API_DB_PASSWORD_FILE (Docker secret).
set -euo pipefail
pw="${TERRA_API_DB_PASSWORD:-}"
if [ -z "$pw" ] && [ -n "${TERRA_API_DB_PASSWORD_FILE:-}" ]; then
  pw="$(cat "$TERRA_API_DB_PASSWORD_FILE")"
fi
if [ -z "$pw" ]; then
  echo "13-api-role: TERRA_API_DB_PASSWORD not set, skipping terra_api" >&2
  exit 0
fi
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres -v pw="$pw" <<'SQL'
SELECT 'CREATE ROLE terra_service NOLOGIN NOSUPERUSER NOBYPASSRLS NOCREATEDB NOCREATEROLE NOREPLICATION'
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'terra_service')\gexec
CREATE ROLE terra_api LOGIN NOSUPERUSER NOBYPASSRLS NOCREATEDB NOCREATEROLE NOREPLICATION
  CONNECTION LIMIT 100 PASSWORD :'pw' IN ROLE terra_service;
SQL
