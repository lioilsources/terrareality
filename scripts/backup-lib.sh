# shellcheck shell=bash
# Shared helpers for scripts/backup-*.sh (sourced, not executed).
# pgBackRest runs inside the DB container (infra/hetzner/compose/docker-compose.db.yml),
# so every call goes through `docker exec` as the postgres user.
DB_CONTAINER="${DB_CONTAINER:-terra-db}"
STANZA="${PGBACKREST_STANZA:-terra}"

pgbr() {
  docker exec -u postgres "$DB_CONTAINER" pgbackrest --stanza="$STANZA" "$@"
}

db_sql() {
  docker exec -u postgres "$DB_CONTAINER" psql -X -U "${POSTGRES_USER:-terra}" -d terra -tAq -c "$1"
}

blog() { echo "[$(date -u +%FT%TZ)] $*"; }
