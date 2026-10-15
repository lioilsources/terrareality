#!/bin/bash
# docker-entrypoint-initdb.d hook (runs once, on an empty data directory, as
# postgres while the temporary init server is up). Creating the pgBackRest
# stanza here means WAL archiving works from the very first segment instead
# of failing until someone runs stanza-create by hand.
# If the repository already holds a stanza from another cluster (different
# system id), this fails on purpose: see docs/runbooks/backup.md.
set -euo pipefail
pgbackrest --stanza=terra --log-level-console=warn stanza-create
