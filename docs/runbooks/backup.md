# Runbook: backups

| What | How | Where | Retention | Objective |
|---|---|---|---|---|
| PostgreSQL (all DBs: terra, temporal, temporal_visibility) | pgBackRest full weekly (Sun 02:30 UTC), differential daily (Mon–Sat 02:30), continuous WAL archiving (`archive_timeout=60`) | Hetzner Object Storage bucket `terrareality-pgbackrest`, client-side AES-256 | 4 full backups (~4 weeks) + their diffs + WAL → PITR anywhere in that window | RPO ≤ 1 h (≈ 1 min in practice), RTO ≤ 4 h |
| Servers (OS, config, Docker volumes incl. Caddy certs, Grafana) | Hetzner automated backups (`backups = true` in Terraform), daily | Hetzner | 7 days | rebuild in < 1 h |
| Ad-hoc server state before risky changes | `hcloud server create-image --type snapshot` | Hetzner | until deleted (cost) | |
| Media (photos, documents) | Object Storage bucket `terrareality-media` (redundant storage at Hetzner) | Hetzner | | no second copy yet, see open points |
| Secrets (`.env`, cipher pass, FCM JSON, WireGuard keys) | Password manager + sealed offline envelope (owner) | | | |

Configuration: `infra/hetzner/db/pgbackrest.conf`, `infra/hetzner/db/postgresql.conf`,
`infra/hetzner/db/systemd/`. Scripts: `scripts/backup-run.sh`, `scripts/backup-check.sh`,
`scripts/backup-metrics.sh` (all on the DB VM, need Docker + jq). Alerts come from the
observability stack (`pgbackrest_*` metrics: backup age, archive age, status).

**The pgBackRest cipher passphrase (`PGBACKREST_CIPHER_PASS`) is the single point of failure:
without it no backup can be read.** Keep it in the password manager and in the owner's offline
envelope; verify both copies quarterly.

## Install (DB VM, once)

    sudo cp /opt/terra/infra/hetzner/db/systemd/terra-backup-* /etc/systemd/system/
    sudo install -m 0755 /opt/terra/infra/hetzner/db/pgbackrest-host-shim /usr/local/bin/pgbackrest
    sudo apt-get install -y jq
    sudo chown deploy /var/lib/node_exporter/textfile
    sudo systemctl daemon-reload
    sudo systemctl enable --now terra-backup-full.timer terra-backup-diff.timer terra-backup-metrics.timer
    systemctl list-timers 'terra-backup-*'

The stanza `terra` is created automatically on the first start of an empty cluster
(`infra/hetzner/db/initdb/20-pgbackrest-stanza.sh`). If you deliberately start a *new* cluster
against a repository that already holds the old one (e.g. after a major upgrade), run
`pgbackrest --stanza=terra stanza-upgrade` (major upgrade) or move the old repo path aside first.
Never `stanza-delete` without the owner's approval.

## Daily / weekly operation

- Daily (automated): timers run the backup, `backup-metrics.sh` every 10 min; alerts fire on
  age > 26 h or WAL archive age > 15 min.
- Weekly (on-call, 5 min): `/opt/terra/scripts/backup-check.sh` → all `ok`; skim
  `pgbackrest info` for the expected set of full/diff backups.
- Monthly: restore drill (below). Quarterly: restore drill **from production Object Storage** onto
  a throwaway VM (`restore.md`, scenario C), record duration (RTO evidence).

## Manual backups

    /opt/terra/scripts/backup-run.sh incr     # before risky migrations / manual data fixes
    /opt/terra/scripts/backup-run.sh full     # after a major upgrade or a restore

## Restore drill

- Local, offline, every change of `infra/hetzner/db/**`: `make restore-test` (throwaway containers,
  production `pgbackrest.conf` + `postgresql.conf`, posix repo instead of S3; full backup → more
  writes → PITR to a timestamp → row counts verified). Takes about 2–3 min after the first image
  build (needs the network once for `apt-get install pgbackrest`).
- Production: `restore.md`, scenario C.

## Troubleshooting

| Symptom | Check | Fix |
|---|---|---|
| `archive command failed` in PostgreSQL logs | `docker exec -u postgres terra-db pgbackrest --stanza=terra check` | S3 credentials/endpoint in `.env`; Object Storage status page; spool queue max is 4 GiB (`archive-push-queue-max`), beyond that WAL is dropped and PITR has a gap → take a full backup when fixed |
| `pg_wal` grows / disk full | `SELECT * FROM pg_stat_archiver` | same as above; never delete files in `pg_wal` by hand |
| Backup timer did not run | `systemctl status terra-backup-diff.timer`, `journalctl -u terra-backup-diff` | Docker down? `docker ps`; rerun `backup-run.sh diff` |
| Backup slow / load on the DB | `process-max`, run time in `pgbackrest info` | move the window, raise `process-max` on bigger VMs |
