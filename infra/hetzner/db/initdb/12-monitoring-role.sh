#!/bin/bash
# docker-entrypoint-initdb.d hook: read-only monitoring role for postgres_exporter.
set -euo pipefail
if [ -n "${MONITORING_DB_PASSWORD:-}" ]; then
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres \
    -v pw="$MONITORING_DB_PASSWORD" <<'SQL'
CREATE ROLE monitoring LOGIN PASSWORD :'pw' IN ROLE pg_monitor;
SQL
fi
