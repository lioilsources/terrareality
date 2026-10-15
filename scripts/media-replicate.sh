#!/usr/bin/env bash
# Second copy of media: mirrors the primary media bucket (S3_BUCKET, e.g. fsn1) into the replica
# bucket in another location (MEDIA_REPLICA_BUCKET, e.g. nbg1) with rclone.
# Wired via infra/hetzner/db/systemd/terra-media-replicate.{service,timer} (hourly) on the DB VM,
# user `deploy`, next to the pgBackRest timers. Needs Docker; reads infra/hetzner/compose/.env.
#
# Protection against deletes and ransomware overwrites on the primary: an object that the primary
# deleted or changed is not lost on the replica but moved (server side) to
# _replica-archive/<run stamp>/<key>; archive runs older than MEDIA_REPLICA_RETENTION_DAYS (default 90)
# are purged after a successful sync. A sync that would delete/archive more than
# MEDIA_REPLICA_MAX_DELETE objects (default 500), or a primary that has shrunk by more than
# MEDIA_REPLICA_MAX_SHRINK_PERCENT (default 10) against the mirror, aborts and alerts instead
# (mass delete = incident, restore.md scenario E). An empty or unreadable primary never empties
# the replica. Deliberate mass deletes: rerun once with the limits raised in the environment.
#
#   scripts/media-replicate.sh            # sync + prune + metrics
#   scripts/media-replicate.sh --dry-run  # show what would change, no writes, no metrics
#
# Output: $TEXTFILE_DIR/media_replica.prom (node_exporter textfile collector), atomic rename.
# Metric names must match infra/hetzner/observability/prometheus/rules/platform.yml (terra-media-replica):
#   media_replica_last_success_timestamp_seconds  end of the last successful sync (kept across failures)
#   media_replica_last_run_timestamp_seconds      end of the last run, successful or not
#   media_replica_last_run_ok                     1 when the last run succeeded
#   media_replica_last_run_duration_seconds       duration of the last run
#   media_replica_objects / media_replica_bytes   size of the mirror after the last successful sync
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
# shellcheck source-path=SCRIPTDIR source=media-lib.sh
. "$here/media-lib.sh"

DRY_RUN=0
case "${1:-}" in
  "") ;;
  --dry-run) DRY_RUN=1 ;;
  *) echo "usage: $0 [--dry-run]" >&2; exit 2 ;;
esac

media_env
RETENTION_DAYS="${MEDIA_REPLICA_RETENTION_DAYS:-90}"
MAX_DELETE="${MEDIA_REPLICA_MAX_DELETE:-500}"
MAX_SHRINK="${MEDIA_REPLICA_MAX_SHRINK_PERCENT:-10}"
OUT_DIR="${TEXTFILE_DIR:-/var/lib/node_exporter/textfile}"
OUT="$OUT_DIR/media_replica.prom"
SRC="src:$S3_BUCKET"
DST="dst:$MEDIA_REPLICA_BUCKET"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
START=$(date +%s)
labels="bucket=\"$S3_BUCKET\",replica=\"$MEDIA_REPLICA_BUCKET\""

write_metrics() { # ok objects bytes
  local ok=$1 objects=$2 bytes=$3 now last_success tmp
  now=$(date +%s)
  last_success=0
  [ -r "$OUT" ] && last_success=$(awk '/^media_replica_last_success_timestamp_seconds/ {print $2}' "$OUT" | tail -1)
  last_success=${last_success:-0}
  if [ "$ok" = 1 ]; then last_success=$now; fi
  tmp="$(mktemp "$OUT_DIR/.media_replica.prom.XXXXXX")"
  {
    echo "# HELP media_replica_last_success_timestamp_seconds End of the last successful media replication."
    echo "# TYPE media_replica_last_success_timestamp_seconds gauge"
    # 0 = never succeeded: omit it so absent() / MediaReplicaMissing handles a fresh setup.
    [ "$last_success" != 0 ] && echo "media_replica_last_success_timestamp_seconds{$labels} $last_success"
    echo "# HELP media_replica_last_run_timestamp_seconds End of the last media replication run."
    echo "# TYPE media_replica_last_run_timestamp_seconds gauge"
    echo "media_replica_last_run_timestamp_seconds{$labels} $now"
    echo "# HELP media_replica_last_run_ok 1 when the last media replication run succeeded."
    echo "# TYPE media_replica_last_run_ok gauge"
    echo "media_replica_last_run_ok{$labels} $ok"
    echo "# HELP media_replica_last_run_duration_seconds Duration of the last media replication run."
    echo "# TYPE media_replica_last_run_duration_seconds gauge"
    echo "media_replica_last_run_duration_seconds{$labels} $((now - START))"
    if [ "$ok" = 1 ]; then
      echo "# HELP media_replica_objects Objects in the replica mirror (archive excluded)."
      echo "# TYPE media_replica_objects gauge"
      echo "media_replica_objects{$labels} $objects"
      echo "# HELP media_replica_bytes Bytes in the replica mirror (archive excluded)."
      echo "# TYPE media_replica_bytes gauge"
      echo "media_replica_bytes{$labels} $bytes"
    fi
  } >"$tmp"
  chmod 0644 "$tmp"
  mv "$tmp" "$OUT"
}

fail() {
  mlog "FAIL: $*"
  [ "$DRY_RUN" = 1 ] || write_metrics 0 0 0 || true
  exit 1
}

count() { # remote -> "objects bytes"
  rclone size --json --fast-list --exclude "/$ARCHIVE_PREFIX/**" "$1" | jq -r '"\(.count) \(.bytes)"'
}

mlog "media replication $SRC -> $DST (archive $ARCHIVE_PREFIX/$STAMP, dry-run=$DRY_RUN)"

# Guard: an empty primary (wrong bucket, wiped account, broken credentials that list nothing)
# must not turn the whole mirror into archive.
read -r src_objects _ < <(count "$SRC") || fail "cannot list primary $SRC"
read -r dst_objects _ < <(count "$DST") || fail "cannot list replica $DST"
if [ "${src_objects:-0}" -eq 0 ] && [ "${dst_objects:-0}" -gt 0 ]; then
  fail "primary is empty but the replica holds $dst_objects objects; refusing to sync (see restore.md scenario E)"
fi
if [ "${dst_objects:-0}" -gt 0 ] && [ $(( (dst_objects - src_objects) * 100 / dst_objects )) -gt "$MAX_SHRINK" ]; then
  fail "primary has $src_objects objects, mirror $dst_objects (> $MAX_SHRINK % fewer); refusing to sync"
fi

sync_args=(sync "$SRC" "$DST"
  --backup-dir "$DST/$ARCHIVE_PREFIX/$STAMP"
  --exclude "/$ARCHIVE_PREFIX/**"
  --checksum --fast-list --transfers 8 --checkers 16
  --max-delete "$MAX_DELETE"
  --retries 3 --low-level-retries 10
  --log-level INFO --stats 5m --stats-one-line)
[ "$DRY_RUN" = 1 ] && sync_args+=(--dry-run)
rclone "${sync_args[@]}" || fail "rclone sync failed (max-delete $MAX_DELETE may have been hit)"

if [ "$DRY_RUN" = 1 ]; then
  mlog "dry run done"
  exit 0
fi

# Retention of the archive: purge run directories older than RETENTION_DAYS (names sort by time).
cutoff="$(date -u -d "-$RETENTION_DAYS days" +%Y%m%dT%H%M%SZ)"
while read -r dir; do
  dir="${dir%/}"
  [ -n "$dir" ] || continue
  if [[ "$dir" < "$cutoff" ]]; then
    mlog "purging archive $ARCHIVE_PREFIX/$dir (older than $RETENTION_DAYS days)"
    rclone purge "$DST/$ARCHIVE_PREFIX/$dir" || mlog "warning: purge of $dir failed"
  fi
done < <(rclone lsf --dirs-only "$DST/$ARCHIVE_PREFIX/" 2>/dev/null || true)

read -r objects bytes < <(count "$DST") || fail "cannot size replica after sync"
write_metrics 1 "$objects" "$bytes"
mlog "ok: replica holds $objects objects, $bytes bytes (primary had $src_objects before the sync)"
