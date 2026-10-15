#!/usr/bin/env bash
# Offline restore drill for the production backup setup (pgBackRest).
#
# Spins up a throwaway PostgreSQL container from the production DB image
# (infra/hetzner/db: dev image + pgBackRest) with the production pgbackrest.conf
# and postgresql.conf, but with a local posix repository instead of S3. Then:
#   1. creates data (PostGIS + pgvector + a plain table), takes a full backup,
#   2. writes more rows, records a target timestamp, writes rows that must be lost,
#   3. destroys the container and its data volume,
#   4. restores to the target timestamp (PITR) into a fresh volume,
#   5. verifies row counts and extensions, then cleans everything up.
# Needs only Docker; after the first image build it runs offline.
# Usage: scripts/restore-test.sh   (or: make restore-test)
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
DB_DIR="$ROOT/infra/hetzner/db"
BASE_IMAGE=terra/postgres:17-postgis-pgvector
RUN_ID="terra-restore-$(date +%s)-$$"
DATA_VOL="$RUN_ID-data"
DATA2_VOL="$RUN_ID-data-restored"
REPO_VOL="$RUN_ID-repo"
SRC="$RUN_ID-src"
DST="$RUN_ID-dst"
STANZA=terra
CIPHER=restore-test-only-cipher-pass   # throwaway, not a secret
START=$SECONDS

log() { printf '\033[36m[restore-test +%3ss]\033[0m %s\n' "$((SECONDS - START))" "$*"; }
fail() { printf '\033[31m[restore-test] FAIL: %s\033[0m\n' "$*" >&2; exit 1; }

cleanup() {
  local rc=$?
  if [ $rc -ne 0 ] && docker inspect "$DST" >/dev/null 2>&1; then
    echo "--- last log lines of $DST ---" >&2; docker logs --tail 30 "$DST" >&2 || true
  elif [ $rc -ne 0 ] && docker inspect "$SRC" >/dev/null 2>&1; then
    echo "--- last log lines of $SRC ---" >&2; docker logs --tail 30 "$SRC" >&2 || true
  fi
  docker rm -f "$SRC" "$DST" >/dev/null 2>&1 || true
  docker volume rm -f "$DATA_VOL" "$DATA2_VOL" "$REPO_VOL" >/dev/null 2>&1 || true
  exit $rc
}
trap cleanup EXIT INT TERM

command -v docker >/dev/null || fail "docker is required"

log "building images (cached after the first run)"
docker image inspect "$BASE_IMAGE" >/dev/null 2>&1 || docker build -q -t "$BASE_IMAGE" "$ROOT/infra/dev/postgres" >/dev/null
# Tag by content hash of infra/hetzner/db so unchanged configs skip the build.
HASH=$( (cd "$DB_DIR" && find . -type f ! -path './systemd/*' | LC_ALL=C sort | xargs cat) | { shasum 2>/dev/null || sha1sum; } | cut -c1-12)
IMAGE=terra/postgres-backrest:test-$HASH
docker image inspect "$IMAGE" >/dev/null 2>&1 \
  || docker build -q --build-arg BASE_IMAGE="$BASE_IMAGE" -t "$IMAGE" "$DB_DIR" >/dev/null

# Production configs, repository switched to a local posix volume.
PG_ENV=(
  -e POSTGRES_USER=terra -e POSTGRES_PASSWORD=terra -e POSTGRES_DB=terra
  -e PGBACKREST_REPO1_TYPE=posix
  -e PGBACKREST_REPO1_PATH=/var/lib/pgbackrest
  -e PGBACKREST_REPO1_CIPHER_PASS="$CIPHER"
  -e PGBACKREST_ARCHIVE_ASYNC=n
)
for v in "$DATA_VOL" "$DATA2_VOL" "$REPO_VOL"; do docker volume create "$v" >/dev/null; done

wait_ready() { # container
  for _ in $(seq 1 300); do
    if docker exec "$1" pg_isready -h 127.0.0.1 -U terra -d terra >/dev/null 2>&1; then return 0; fi
    docker inspect -f '{{.State.Running}}' "$1" 2>/dev/null | grep -q true || fail "$1 exited"
    sleep 1
  done
  fail "$1 did not become ready"
}
psql_in() { # container sql
  docker exec -i "$1" psql -X -v ON_ERROR_STOP=1 -U terra -d terra -tAq -c "$2"
}
pgbr() { # container args...
  local c=$1; shift
  docker exec -u postgres "${PG_ENV[@]}" "$c" pgbackrest --stanza="$STANZA" "$@"
}

log "starting source database $SRC"
docker run -d --name "$SRC" "${PG_ENV[@]}" \
  -v "$DATA_VOL":/var/lib/postgresql/data -v "$REPO_VOL":/var/lib/pgbackrest \
  "$IMAGE" >/dev/null
wait_ready "$SRC"

log "check (stanza was created by the image's init hook)"
pgbr "$SRC" check >/dev/null

log "creating data: 1000 rows (batch 1)"
psql_in "$SRC" "
  CREATE EXTENSION IF NOT EXISTS postgis;
  CREATE EXTENSION IF NOT EXISTS vector;
  CREATE TABLE drill (id bigserial PRIMARY KEY, batch int NOT NULL, geom geometry(Point,4326), emb vector(3), at timestamptz DEFAULT clock_timestamp());
  INSERT INTO drill (batch, geom, emb) SELECT 1, ST_SetSRID(ST_MakePoint(14.42, 50.08), 4326), '[1,2,3]' FROM generate_series(1,1000);"

log "full backup"
pgbr "$SRC" --type=full backup >/dev/null

log "500 rows after the backup (batch 2, must survive via WAL replay)"
psql_in "$SRC" "INSERT INTO drill (batch) SELECT 2 FROM generate_series(1,500);"
sleep 1
TARGET=$(psql_in "$SRC" "SELECT to_char(clock_timestamp() AT TIME ZONE 'UTC', 'YYYY-MM-DD HH24:MI:SS.US') || '+00'")
sleep 1
log "target time $TARGET; 300 rows after it (batch 3, must be gone after PITR)"
psql_in "$SRC" "INSERT INTO drill (batch) SELECT 3 FROM generate_series(1,300);"
psql_in "$SRC" "SELECT pg_switch_wal();" >/dev/null
pgbr "$SRC" check >/dev/null   # waits until the switched segment is archived
EXPECT_TOTAL=$(psql_in "$SRC" "SELECT count(*) FROM drill")
[ "$EXPECT_TOTAL" = 1800 ] || fail "source has $EXPECT_TOTAL rows, expected 1800"

log "destroying source container and data volume"
docker rm -f "$SRC" >/dev/null
docker volume rm "$DATA_VOL" >/dev/null

log "restoring to $TARGET into a fresh volume"
docker run --rm -u postgres "${PG_ENV[@]}" \
  -v "$DATA2_VOL":/var/lib/postgresql/data -v "$REPO_VOL":/var/lib/pgbackrest \
  "$IMAGE" pgbackrest --stanza="$STANZA" --type=time "--target=$TARGET" \
  --target-action=promote --log-level-console=detail restore | sed -n 's/^/  /p' | grep -E 'restore (command|size)|recovery|ERROR|WARN' || true

log "starting restored database $DST"
docker run -d --name "$DST" "${PG_ENV[@]}" \
  -v "$DATA2_VOL":/var/lib/postgresql/data -v "$REPO_VOL":/var/lib/pgbackrest \
  "$IMAGE" >/dev/null
wait_ready "$DST"
for _ in $(seq 1 60); do
  [ "$(psql_in "$DST" 'SELECT pg_is_in_recovery()')" = f ] && break
  sleep 1
done
[ "$(psql_in "$DST" 'SELECT pg_is_in_recovery()')" = f ] || fail "restored database is still in recovery"

log "verifying"
B1=$(psql_in "$DST" "SELECT count(*) FROM drill WHERE batch = 1")
B2=$(psql_in "$DST" "SELECT count(*) FROM drill WHERE batch = 2")
B3=$(psql_in "$DST" "SELECT count(*) FROM drill WHERE batch = 3")
EXT=$(psql_in "$DST" "SELECT string_agg(extname, ',' ORDER BY extname) FROM pg_extension WHERE extname IN ('postgis','vector')")
GEO=$(psql_in "$DST" "SELECT count(*) FROM drill WHERE ST_DWithin(geom, ST_SetSRID(ST_MakePoint(14.42, 50.08), 4326), 0.001) AND emb = '[1,2,3]'")
echo "  batch1=$B1 (expect 1000) batch2=$B2 (expect 500) batch3=$B3 (expect 0) extensions=$EXT geo+vector rows=$GEO"
[ "$B1" = 1000 ] || fail "batch 1: $B1 rows"
[ "$B2" = 500 ] || fail "batch 2: $B2 rows (WAL replay incomplete)"
[ "$B3" = 0 ] || fail "batch 3: $B3 rows (PITR target not honoured)"
[ "$EXT" = "postgis,vector" ] || fail "extensions: $EXT"
[ "$GEO" = 1000 ] || fail "PostGIS/pgvector data: $GEO rows"
psql_in "$DST" "INSERT INTO drill (batch) VALUES (4)" || fail "restored database is not writable"

log "PASS: point-in-time restore verified in $((SECONDS - START)) s"
