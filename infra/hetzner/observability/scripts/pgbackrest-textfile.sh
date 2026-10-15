#!/usr/bin/env bash
# Thin wrapper kept for the observability docs: the only pgBackRest metric writer is
# scripts/backup-metrics.sh (stanza `terra`, wired via infra/hetzner/db/systemd/terra-backup-metrics.timer).
# It writes /var/lib/node_exporter/textfile/pgbackrest.prom with the metric names used by
# prometheus/rules/platform.yml (terra-backup group).
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
exec "$here/../../../../scripts/backup-metrics.sh" "$@"
