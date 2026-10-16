#!/usr/bin/env bash
# The single pgBackRest metric writer for Prometheus (node_exporter textfile collector).
# Wired via infra/hetzner/db/systemd/terra-backup-metrics.{service,timer} (every 10 min) and
# called by scripts/backup-run.sh after each backup. Runs on the DB VM as `deploy`; pgBackRest
# runs inside the DB container (backup-lib.sh: `docker exec`), stanza `terra`.
# infra/hetzner/observability/scripts/pgbackrest-textfile.sh is only a thin wrapper around this.
#
# Output: $TEXTFILE_DIR/pgbackrest.prom (default /var/lib/node_exporter/textfile), atomic rename.
# Metric names must match infra/hetzner/observability/prometheus/rules/platform.yml (terra-backup)
# and the Grafana dashboard terra-overview.json. All metrics carry the label stanza:
#   pgbackrest_backup_ok                            1 when `pgbackrest info` reports status ok (code 0)
#   pgbackrest_last_backup_timestamp_seconds{type}  stop time of the newest backup per type (full|diff|incr)
#   pgbackrest_last_backup_size_bytes{type}         database size of that backup
#   pgbackrest_last_archive_timestamp_seconds       last archived WAL (pg_stat_archiver; repo is on S3)
#   pgbackrest_archive_failing                      1 when the newest archive_command attempt failed
#                                                   (pg_stat_archiver.last_failed_time > last_archived_time)
#   pgbackrest_archive_failed_count                 pg_stat_archiver.failed_count (since stats reset)
#   pgbackrest_textfile_updated_timestamp_seconds   when this script last ran
# Needs Docker + jq on the host.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
# shellcheck source-path=SCRIPTDIR source=backup-lib.sh
. "$here/backup-lib.sh"

OUT_DIR="${TEXTFILE_DIR:-/var/lib/node_exporter/textfile}"
OUT="$OUT_DIR/pgbackrest.prom"
TMP="$(mktemp "$OUT_DIR/.pgbackrest.prom.XXXXXX")"
trap 'rm -f "$TMP"' EXIT

info="$(pgbr --output=json info 2>/dev/null || echo '[]')"
# pgBackRest info has no archive timestamp and the repo is on S3, so ask PostgreSQL.
archive_ts="${PGBACKREST_ARCHIVE_TS:-$(db_sql "SELECT coalesce(extract(epoch FROM last_archived_time)::bigint, 0) FROM pg_stat_archiver" 2>/dev/null || true)}"
# "<failing 0|1> <failed_count>"; empty when PostgreSQL is unreachable (metrics then omitted).
archive_fail="${PGBACKREST_ARCHIVE_FAIL:-$(db_sql "SELECT (coalesce(last_failed_time, 'epoch') > coalesce(last_archived_time, 'epoch'))::int || ' ' || failed_count FROM pg_stat_archiver" 2>/dev/null || true)}"

{
  echo "# HELP pgbackrest_backup_ok 1 when pgBackRest reports the stanza as ok."
  echo "# TYPE pgbackrest_backup_ok gauge"
  code="$(jq -r '.[0].status.code // 99' <<<"$info")"
  echo "pgbackrest_backup_ok{stanza=\"$STANZA\"} $([ "$code" = 0 ] && echo 1 || echo 0)"

  echo "# HELP pgbackrest_last_backup_timestamp_seconds Stop time of the newest backup per type."
  echo "# TYPE pgbackrest_last_backup_timestamp_seconds gauge"
  jq -r --arg s "$STANZA" '[.[0].backup // [] | group_by(.type)[] | max_by(.timestamp.stop)]
    | .[] | "pgbackrest_last_backup_timestamp_seconds{stanza=\"\($s)\",type=\"\(.type)\"} \(.timestamp.stop)"' <<<"$info"

  echo "# HELP pgbackrest_last_backup_size_bytes Database size of the newest backup per type."
  echo "# TYPE pgbackrest_last_backup_size_bytes gauge"
  jq -r --arg s "$STANZA" '[.[0].backup // [] | group_by(.type)[] | max_by(.timestamp.stop)]
    | .[] | "pgbackrest_last_backup_size_bytes{stanza=\"\($s)\",type=\"\(.type)\"} \(.info.size)"' <<<"$info"

  # 0 means "never archived": omit it so WalArchiveStale does not page on a fresh cluster
  # (BackupMetricsMissing/BackupTooOld still cover that case).
  if [ -n "$archive_ts" ] && [ "$archive_ts" != 0 ]; then
    echo "# HELP pgbackrest_last_archive_timestamp_seconds Time of the newest archived WAL segment."
    echo "# TYPE pgbackrest_last_archive_timestamp_seconds gauge"
    echo "pgbackrest_last_archive_timestamp_seconds{stanza=\"$STANZA\"} $archive_ts"
  fi

  if [ -n "$archive_fail" ]; then
    read -r failing failed_count <<<"$archive_fail"
    echo "# HELP pgbackrest_archive_failing 1 when the newest WAL archive attempt failed."
    echo "# TYPE pgbackrest_archive_failing gauge"
    echo "pgbackrest_archive_failing{stanza=\"$STANZA\"} ${failing:-0}"
    echo "# HELP pgbackrest_archive_failed_count Failed WAL archive attempts (pg_stat_archiver)."
    echo "# TYPE pgbackrest_archive_failed_count counter"
    echo "pgbackrest_archive_failed_count{stanza=\"$STANZA\"} ${failed_count:-0}"
  fi

  echo "# HELP pgbackrest_textfile_updated_timestamp_seconds When this file was written."
  echo "# TYPE pgbackrest_textfile_updated_timestamp_seconds gauge"
  echo "pgbackrest_textfile_updated_timestamp_seconds{stanza=\"$STANZA\"} $(date +%s)"
} >"$TMP"
chmod 0644 "$TMP"
mv "$TMP" "$OUT"
trap - EXIT
