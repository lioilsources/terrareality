#!/usr/bin/env bash
# Verifies the backup chain on the DB VM. Exit code != 0 when something is off:
#   - pgbackrest check fails (archive_command broken, repository unreachable)
#   - newest backup older than MAX_BACKUP_AGE_H (default 26 h)
#   - newest archived WAL older than MAX_WAL_AGE_S (default 900 s; archive_timeout is 60 s)
#   - the archiver reports failures newer than the last success
# Run by hand after changes and from monitoring (alerts also come from the textfile metrics).
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
# shellcheck source-path=SCRIPTDIR source=backup-lib.sh
. "$here/backup-lib.sh"

MAX_BACKUP_AGE_H="${MAX_BACKUP_AGE_H:-26}"
MAX_WAL_AGE_S="${MAX_WAL_AGE_S:-900}"
rc=0

blog "pgbackrest check"
pgbr check || { blog "FAIL: pgbackrest check"; rc=1; }

info=$(pgbr --output=json info)
last_stop=$(jq -r '[.[0].backup[]?.timestamp.stop] | max // 0' <<<"$info")
now=$(date +%s)
age_h=$(( (now - last_stop) / 3600 ))
if [ "$last_stop" -eq 0 ]; then
  blog "FAIL: no backup in the repository"; rc=1
elif [ "$age_h" -ge "$MAX_BACKUP_AGE_H" ]; then
  blog "FAIL: newest backup is ${age_h} h old (max $MAX_BACKUP_AGE_H h)"; rc=1
else
  blog "ok: newest backup $(jq -r '[.[0].backup[]] | max_by(.timestamp.stop) | "\(.label) (\(.type))"' <<<"$info"), ${age_h} h old"
fi

read -r wal_age failed_after_ok < <(db_sql "SELECT coalesce(extract(epoch FROM now() - last_archived_time)::int, -1),
  (coalesce(last_failed_time, '-infinity') > coalesce(last_archived_time, '-infinity'))::int FROM pg_stat_archiver" | tr '|' ' ')
if [ "$wal_age" -lt 0 ] || [ "$wal_age" -gt "$MAX_WAL_AGE_S" ]; then
  blog "FAIL: last archived WAL is ${wal_age} s old (max $MAX_WAL_AGE_S s)"; rc=1
else
  blog "ok: last archived WAL ${wal_age} s ago"
fi
[ "$failed_after_ok" = 0 ] || { blog "FAIL: archiver has failures after its last success"; rc=1; }

exit $rc
