# Runbook: backups

| What | How | Where | Retention | Objective |
|---|---|---|---|---|
| PostgreSQL (all DBs: terra, temporal, temporal_visibility) | pgBackRest full weekly (Sun 02:30 UTC), differential daily (Mon–Sat 02:30), continuous WAL archiving (`archive_timeout=60`) | Hetzner Object Storage bucket `terrareality-pgbackrest` in the **separate backup project**, client-side AES-256, bucket versioning (deleted/overwritten objects kept 30 days as noncurrent versions) | 4 full backups (~4 weeks) + their diffs + WAL → PITR anywhere in that window | RPO ≤ 1 h (≈ 1 min in practice), RTO ≤ 4 h |
| Servers (OS, config, Docker volumes incl. Caddy certs, Grafana) | Hetzner automated backups (`backups = true` in Terraform), daily | Hetzner | 7 days | rebuild in < 1 h |
| Ad-hoc server state before risky changes | `hcloud server create-image --type snapshot` | Hetzner | until deleted (cost) | |
| Media (photos, documents) | Primary: Object Storage bucket `terrareality-media` (fsn1). Second copy: hourly `rclone sync` (`scripts/media-replicate.sh`, timer `terra-media-replicate` on the DB VM) into `terrareality-media-replica` in another location (default nbg1); deleted/overwritten objects move to `_replica-archive/<UTC stamp>/` instead of disappearing | Hetzner Object Storage, two locations; the replica lives in the separate backup project with its own keys | mirror = current state; archive runs 90 days (`MEDIA_REPLICA_RETENTION_DAYS`) | RPO ≤ 1 h (+ sync duration), RTO: switch the app to the replica in < 30 min, or copy back (`restore.md` scenario E) |
| Secrets (`.env`, cipher pass, FCM JSON, WireGuard keys) | Password manager + sealed offline envelope (owner) | | | |

Configuration: `infra/hetzner/db/pgbackrest.conf`, `infra/hetzner/db/postgresql.conf`,
`infra/hetzner/db/systemd/`. Scripts: `scripts/backup-run.sh`, `scripts/backup-check.sh`,
`scripts/backup-metrics.sh` (all on the DB VM, need Docker + jq). Alerts come from the
observability stack (`pgbackrest_*` metrics: backup age, archive age, status).
Media: `scripts/media-replicate.sh`, `scripts/media-restore.sh`, `scripts/media-lib.sh`
(DB VM, rclone in a container, `media_replica_*` metrics, alert group `terra-media-replica`).

**The pgBackRest cipher passphrase (`PGBACKREST_CIPHER_PASS`) is the single point of failure:
without it no backup can be read.** Keep it in the password manager and in the owner's offline
envelope; verify both copies quarterly.

## Credential isolation (review V-16)

| Secret | Where it lives | Never on |
|---|---|---|
| Media S3 keys (app project) | app VM `.env` (api, worker, imgproxy) and DB VM `.env` (source of the replication) | CI |
| Backup project S3 keys (`PGBACKREST_S3_KEY*`, `MEDIA_REPLICA_*_KEY`) | DB VM `.env` only (`compose/db.env.example`), password manager | app VM, CI, laptops |
| `PGBACKREST_CIPHER_PASS` | DB VM `.env`, password manager, offline envelope | app VM, CI |
| `MONITORING_DB_PASSWORD` | DB VM `.env` | app VM |

The app VM is the internet-facing machine; a compromise there yields the media keys and the DB
passwords, but no key that can read or delete a backup or the media replica. `media-replicate.sh`
refuses to run when the replica keys are empty or equal to the media keys
(`MEDIA_REPLICA_ALLOW_SHARED_KEYS=1` only for drills).

What protects the backups against a compromised **DB VM** (it holds the backup keys):
- bucket versioning on `terrareality-pgbackrest` with noncurrent-version expiry after
  `backup_noncurrent_days` (30): objects deleted or overwritten through the S3 API stay restorable
  as old versions for 30 days (Terraform `minio_s3_bucket_versioning` + `minio_ilm_policy`; verify
  in the console after apply, enable by hand if the provider call is not supported);
- the media replica keeps deleted/overwritten objects in `_replica-archive/` for 90 days.
A key holder can still delete object *versions* deliberately. Not done yet (follow-up, owner
decision): Object Lock in compliance mode (needs a new bucket, cannot be switched on later) or a
periodic offline copy (Storage Box pull from a machine outside both projects).

Restoring from an old version (repository damaged or files deleted): in the console, or with any
S3 client against the backup project, list versions of `pgbackrest/` and copy the version from
before the incident over the current object (or remove the delete marker); then
`pgbackrest --stanza=terra check` and `info` must show the expected backups.

## Install (DB VM, once)

    sudo cp /opt/terra/infra/hetzner/db/systemd/terra-backup-* /etc/systemd/system/
    sudo install -m 0755 /opt/terra/infra/hetzner/db/pgbackrest-host-shim /usr/local/bin/pgbackrest
    sudo apt-get install -y jq
    sudo chown deploy /var/lib/node_exporter/textfile
    sudo systemctl daemon-reload
    sudo systemctl enable --now terra-backup-full.timer terra-backup-diff.timer terra-backup-metrics.timer
    systemctl list-timers 'terra-backup-*'

## Media replica (DB VM, once)

The replica bucket comes from Terraform (`minio_s3_bucket.media_replica`, location
`media_replica_location`, default nbg1; it must differ from the primary location) and is created in
the **separate backup project** (provider `minio.replica` uses `backup_access_key` unless
`media_replica_access_key` is set). Its keys live only on the DB VM (`MEDIA_REPLICA_*` in the DB VM
`.env`), never on the app VM, so a leaked app key cannot delete the copy. Alternative target: a
Hetzner Storage Box over SFTP/WebDAV (change the `dst` remote in `scripts/media-lib.sh`; layout and
scripts stay the same).

1. `.env` on the DB VM (from `compose/db.env.example`): the media section (`S3_ENDPOINT`,
   `S3_REGION`, `S3_BUCKET`, `S3_ACCESS_KEY`, `S3_SECRET_KEY`) and the `MEDIA_REPLICA_*` section
   with the backup project keys.
2. Dry run, then the first sync by hand (the initial copy streams everything through the DB VM):

       docker pull rclone/rclone:1.71.0
       /opt/terra/scripts/media-replicate.sh --dry-run
       /opt/terra/scripts/media-replicate.sh
       /opt/terra/scripts/media-restore.sh check

3. Timer:

       sudo cp /opt/terra/infra/hetzner/db/systemd/terra-media-replicate.* /etc/systemd/system/
       sudo systemctl daemon-reload
       sudo systemctl enable --now terra-media-replicate.timer
       systemctl list-timers terra-media-replicate.timer

How the copy survives incidents on the primary:

- **Delete or overwrite** (bug, compromised owner account, ransomware rewriting objects): the next
  sync moves the old object to `_replica-archive/<run stamp>/<key>` (server-side move inside the
  replica), so every version that existed at a sync stays restorable for 90 days.
- **Mass delete / emptied bucket**: the sync aborts when the primary is empty, has shrunk by more than
  `MEDIA_REPLICA_MAX_SHRINK_PERCENT` (10 %) against the mirror, or more than `MEDIA_REPLICA_MAX_DELETE`
  (500) objects would be deleted; the run fails, `MediaReplicaFailing`/`MediaReplicaTooOld` fire, the
  mirror stays as it was. For a deliberate large cleanup, run once with the limits raised:
  `MEDIA_REPLICA_MAX_DELETE=100000 MEDIA_REPLICA_MAX_SHRINK_PERCENT=100 /opt/terra/scripts/media-replicate.sh`
  (approved by the owner).
- **Location outage** (fsn1 Object Storage down): the mirror in nbg1 is a complete bucket with the same
  keys; the app can be pointed at it directly (`restore.md` scenario E2).
- Objects uploaded after the last sync (≤ 1 h) exist only on the primary.

Metrics (`/var/lib/node_exporter/textfile/media_replica.prom`): `media_replica_last_success_timestamp_seconds`,
`media_replica_last_run_timestamp_seconds`, `media_replica_last_run_ok`,
`media_replica_last_run_duration_seconds`, `media_replica_objects`, `media_replica_bytes`. Alerts
(`terra-media-replica`): `MediaReplicaTooOld` (page, no success for 26 h), `MediaReplicaFailing`
(ticket, failing for 3 h), `MediaReplicaStale` (timer not running), `MediaReplicaMissing`.

The stanza `terra` is created automatically on the first start of an empty cluster
(`infra/hetzner/db/initdb/20-pgbackrest-stanza.sh`). If you deliberately start a *new* cluster
against a repository that already holds the old one (e.g. after a major upgrade), run
`pgbackrest --stanza=terra stanza-upgrade` (major upgrade) or move the old repo path aside first.
Never `stanza-delete` without the owner's approval.

## Daily / weekly operation

- Daily (automated): timers run the backup, `backup-metrics.sh` every 10 min; alerts fire on
  backup age > 26 h, WAL archive age > 1 h 15 min (`WalArchiveStale`) and on archive_command
  failing for 15 min (`WalArchiveFailing`, from `pg_stat_archiver`).
- Weekly (on-call, 5 min): `/opt/terra/scripts/backup-check.sh` → all `ok`; skim
  `pgbackrest info` for the expected set of full/diff backups.
  `/opt/terra/scripts/media-restore.sh check` → `ok`; mirror object count close to the primary
  (Grafana `media_replica_objects`).
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
- Media, quarterly: `restore.md` scenario E1 with `--prefix` of one listing into a scratch bucket
  (`--to`), open a few files; record the result in `launch.md` §Záznam.

## Troubleshooting

| Symptom | Check | Fix |
|---|---|---|
| `archive command failed` in PostgreSQL logs, `WalArchiveFailing` | `docker exec -u postgres terra-db pgbackrest --stanza=terra check`; `SELECT * FROM pg_stat_archiver` | S3 credentials/endpoint in the DB VM `.env`; Object Storage status page. The spool holds up to 12 GiB (`archive-push-queue-max`); beyond that pgBackRest drops WAL and PITR has a gap. **After every archive incident** (even if no WAL was dropped): `backup-run.sh full`, then `backup-check.sh`, and note it in the incident record |
| `pg_wal` grows / disk full | `SELECT * FROM pg_stat_archiver` | same as above; never delete files in `pg_wal` by hand |
| Backup timer did not run | `systemctl status terra-backup-diff.timer`, `journalctl -u terra-backup-diff` | Docker down? `docker ps`; rerun `backup-run.sh diff` |
| Backup slow / load on the DB | `process-max`, run time in `pgbackrest info` | move the window, raise `process-max` on bigger VMs |
| Media replica alert | `journalctl -u terra-media-replicate -n 100` | `refusing to sync` = mass-delete guard: find out why the primary lost objects (incident, `restore.md` E1) before raising the limits; `403`/`NoSuchBucket` = `MEDIA_REPLICA_*` keys/bucket; timeouts = Object Storage status page, the next hourly run catches up |
