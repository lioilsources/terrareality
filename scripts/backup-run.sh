#!/usr/bin/env bash
# Takes a pgBackRest backup on the DB VM and refreshes the backup metrics.
#   scripts/backup-run.sh full   # weekly (terra-backup-full.timer, Sunday 02:30 UTC)
#   scripts/backup-run.sh diff   # daily  (terra-backup-diff.timer, Mon-Sat 02:30 UTC)
#   scripts/backup-run.sh incr   # ad hoc, e.g. before a risky migration
# Expiry of old backups/WAL runs automatically after each backup (retention in pgbackrest.conf).
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
# shellcheck source-path=SCRIPTDIR source=backup-lib.sh
. "$here/backup-lib.sh"

type="${1:-}"
case "$type" in full|diff|incr) ;; *) echo "usage: $0 full|diff|incr" >&2; exit 2 ;; esac

blog "pgbackrest $type backup start (stanza $STANZA, container $DB_CONTAINER)"
pgbr --type="$type" --log-level-console=info backup
blog "pgbackrest $type backup done"
pgbr --output=text info | sed -n '1,40p'

"$here/backup-metrics.sh" || blog "warning: metrics refresh failed"
