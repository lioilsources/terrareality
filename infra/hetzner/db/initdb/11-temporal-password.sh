#!/bin/bash
# docker-entrypoint-initdb.d hook: sets the Temporal role password from the
# environment so it never appears in a file.
set -euo pipefail
if [ -n "${TEMPORAL_DB_PASSWORD:-}" ]; then
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres \
    -v pw="$TEMPORAL_DB_PASSWORD" <<'SQL'
ALTER ROLE temporal PASSWORD :'pw';
SQL
fi
