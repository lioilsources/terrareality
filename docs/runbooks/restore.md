# Runbook: restore PostgreSQL (pgBackRest, point-in-time), the backup repository (F) and media (E)

Matches `scripts/restore-test.sh` (the same commands against a local posix repository) and the
production setup in `infra/hetzner/db/` + `infra/hetzner/compose/docker-compose.db.yml`.
Stanza `terra`; repository on Object Storage; all PostgreSQL databases (terra, temporal,
temporal_visibility) restore together. Target RTO: 4 h. Someone with the pgBackRest cipher
passphrase must be reachable (`backup.md`).

Decide first (incident lead + owner): **which scenario, which target time**, and accept that every
write after the target is lost (payments are not affected: the platform holds no money, but Stripe
invoices/webhooks after the target must be replayed, see `incident.md`).

Shorthand on the DB VM:

    cd /opt/terra/infra/hetzner/compose
    db()  { docker compose -f docker-compose.db.yml "$@"; }
    pgbr() { db run --rm --no-deps -u postgres db pgbackrest --stanza=terra "$@"; }   # container stopped
On the app VM: `app() { docker compose -f docker-compose.app.yml "$@"; }`.

## 0. Look before you touch anything

    docker exec -u postgres terra-db pgbackrest --stanza=terra info      # DB running
    pgbr info                                                            # DB stopped
Note the backup labels and the WAL range (`wal archive min/max`). A target time must lie after
the end of the oldest full backup and before the newest archived WAL.
Timestamps are UTC, format `2026-10-15 13:56:02+00`.

## A. Latest state (DB lost / corrupted, repository intact)

1. Stop writers on the app VM: `app stop api worker temporal` (web shows errors; put up the
   maintenance notice per `incident.md`).
2. DB VM: `db stop db`.
3. Keep the broken data if disk allows: `sudo mv /srv/pgdata /srv/pgdata.broken-$(date +%F) && sudo install -d -o 999 -g 999 -m 700 /srv/pgdata`.
   (No space: skip; `delta=y` in pgbackrest.conf then restores over the existing directory.)
4. `pgbr --log-level-console=info restore` (default type: replay all archived WAL).
5. `db up -d db`, watch `db logs -f db` until `database system is ready to accept connections`.
6. Verify (§Verify), then `app start temporal api worker`.
7. Take a full backup: `/opt/terra/scripts/backup-run.sh full`, then `backup-check.sh`.

## B. Point in time (bad migration, mass delete, compromised account)

Same as A, but step 4 restores to just before the incident:

    pgbr --type=time "--target=2026-10-15 13:56:02+00" --target-action=promote --log-level-console=info restore

- `--target-action=promote` opens the database read/write at the target. To inspect first, use
  `--target-action=pause`, check data with `psql`, then `SELECT pg_wal_replay_resume();` (moves on)
  or restore again with an earlier target.
- After a PITR the cluster is on a new timeline; pgBackRest handles it. Take a full backup
  immediately (step 7) so later PITRs do not depend on the old timeline.
- If the incident was a migration: deploy the previous image tag before starting api/worker
  (`deploy.md` §Rollback) or the migrate job re-applies it.

## C. Restore next to production (recover a few rows, drills, quarterly test)

Production keeps running; the copy runs on the DB VM on a different port, private only.

    set -a; . ./.env; set +a          # the DB VM .env (db.env.example): backup project keys
    BR=(-e PGBACKREST_REPO1_S3_BUCKET="$PGBACKREST_BUCKET" -e PGBACKREST_REPO1_S3_ENDPOINT="$PGBACKREST_S3_ENDPOINT"
        -e PGBACKREST_REPO1_S3_REGION="$PGBACKREST_S3_REGION" -e PGBACKREST_REPO1_S3_KEY="$PGBACKREST_S3_KEY"
        -e PGBACKREST_REPO1_S3_KEY_SECRET="$PGBACKREST_S3_KEY_SECRET" -e PGBACKREST_REPO1_CIPHER_PASS="$PGBACKREST_CIPHER_PASS")
    sudo install -d -o 999 -g 999 -m 700 /srv/pgrestore
    docker run --rm -u postgres "${BR[@]}" -v /srv/pgrestore:/var/lib/postgresql/data terra/postgres-backrest:17 \
      pgbackrest --stanza=terra --type=time "--target=<UTC time>" --target-action=promote \
      --archive-mode=off restore
    docker run -d --name terra-db-restore "${BR[@]}" -v /srv/pgrestore:/var/lib/postgresql/data \
      -p 127.0.0.1:5434:5432 terra/postgres-backrest:17 \
      postgres -c config_file=/etc/postgresql/postgresql.conf -c archive_mode=off
`--archive-mode=off` and `-c archive_mode=off` keep the copy from pushing WAL into the production
repository. Extract what you need (`pg_dump -h 127.0.0.1 -p 5434 -U terra -t <table> --data-only terra`),
apply it to production deliberately (review, transaction), then
`docker rm -f terra-db-restore && sudo rm -rf /srv/pgrestore`.

Quarterly drill: do the same on a fresh throwaway VM (`hcloud server create`, same image build,
`.env` with the pgBackRest variables of `db.env.example`, removed afterwards) to prove the backup is
usable without the DB VM. Record
duration and row counts of a few key tables (`listings`, `leases`, `payment_obligations`) compared to production.

## D. DB VM lost entirely

1. Either restore the Hetzner automated backup of the server (console → Backups → restore into a
   new server) and continue with A if data is stale, or
2. Recreate: `terraform apply` (the volume has delete protection; if the volume survives, attach it
   and start `db up -d` — PostgreSQL does crash recovery, then A only if that fails).
3. New empty volume: `deploy.md` §1.2 steps 1–3 **without** `db up` (an empty start would run initdb
   and try to create a new stanza), then A from step 4. The DB VM `.env` comes from the password
   manager (backup project keys, cipher pass); it was never on the app VM.
4. If the private IP changed, update `DB_HOST` on the app VM and `db_private_ip` for observability,
   and re-issue the server certificate for the new IP (`scripts/pg-tls-init.sh --renew` with the CA
   key from the password manager); the app VM keeps its `pg-ca.crt`.

## F. Backup repository damaged or deleted (compromised DB VM, operator error)

The backup bucket is versioned (`backup.md` §Credential isolation): objects deleted or overwritten
through the S3 API stay as noncurrent versions for 30 days.

1. Stop the writer: `sudo systemctl stop terra-backup-full.timer terra-backup-diff.timer` and rotate
   the backup project keys in the Hetzner console (the old ones may be in an attacker's hands).
2. With the new keys, list versions under `pgbackrest/` (console, `rclone --s3-versions`, or
   `aws s3api list-object-versions --endpoint-url https://<backup endpoint>`), pick the state from
   before the incident and restore it: remove delete markers / copy the old version over the current
   object. Restore `backup.info`, `archive.info` (and their `.copy`) first.
3. Update `PGBACKREST_S3_KEY*` in the DB VM `.env`, `db up -d db`, `pgbackrest --stanza=terra check`
   and `info`; then `backup-run.sh full` and the scenario C drill to prove the repository works.

## Verify

    docker exec terra-db psql -U terra -d terra -c "SELECT pg_is_in_recovery();"           # f
    docker exec terra-db psql -U terra -d terra -c "SELECT count(*) FROM listings;"
    docker exec terra-db psql -U terra -d terra -c "SELECT max(occurred_at) FROM audit_events;" # ~ target
    docker exec terra-db psql -U terra -d terra -c "SELECT extname, extversion FROM pg_extension;"
    curl -fsS https://api.terrareality.cz/healthz
Then: Stripe webhooks replay for the lost window (`incident.md`), notify affected users if data
was lost (GDPR breach assessment if personal data is affected: `incident.md`).

## Local drill

`make restore-test` runs scenario B end to end in throwaway containers (no network after the first
image build): full backup → writes → PITR target → writes that must disappear → restore into a new
volume → row counts and PostGIS/pgvector data verified.

## E. Media (photos, documents) from the replica

Media lives in `S3_BUCKET` (primary location) and, synced hourly, in `MEDIA_REPLICA_BUCKET` in a
second location (`backup.md` §Media replica). Replica layout: the same keys as the primary at the
bucket root (the mirror) plus `_replica-archive/<YYYYMMDDTHHMMSSZ>/<key>` for objects the primary
deleted or overwrote in that sync (kept 90 days). Database rows point to keys
(`orgs/<org>/media/<id>/original`, `leases/<id>/<doc>.pdf`, `invoices/…`, `passports/…`,
`conversations/…`), so restoring the object under the same key is enough; if the DB was restored
to a point in time too (scenario B), restore media to the same moment (archive run just before it).

All commands on the DB VM as `deploy`; the script never deletes on the target (`rclone copy`).
**Stop the replication first** so a damaged primary is not mirrored while you work:

    sudo systemctl stop terra-media-replicate.timer
    /opt/terra/scripts/media-restore.sh check          # replica listable, object counts, archive runs

### E1. Objects deleted or overwritten on the primary (bug, compromised account, ransomware)

1. Find the scope: keys from the audit log / support ticket, e.g. one org `orgs/<org id>/`.
2. Pick the source:
   - deleted after the last sync → still in the mirror: `--from mirror`;
   - deleted or overwritten and already synced → in the archive run of that sync:
     `media-restore.sh list-archive` (runs), `media-restore.sh list-archive orgs/<org id>/` (objects);
     choose the run right after the incident began (it holds the pre-incident versions).
3. Dry run, read the list, then for real:

       /opt/terra/scripts/media-restore.sh restore --from 20261015T131500Z --prefix orgs/<org id>/ --dry-run
       /opt/terra/scripts/media-restore.sh restore --from 20261015T131500Z --prefix orgs/<org id>/

   Ransomware that overwrote many keys across several syncs: restore the oldest affected archive run
   first, then newer ones only for keys not covered; the mirror itself holds the encrypted versions.
4. Check in the app (listing photos through imgproxy, a lease PDF). imgproxy caches by URL; purge its
   cache or wait for expiry if old renders are served.
5. `sudo systemctl start terra-media-replicate.timer`. If the primary shrank, the first run may hit the
   mass-delete guard: confirm the state is intended, then rerun once with the raised limits (`backup.md`).

### E2. Primary location or bucket lost

Fastest (RTO < 30 min): point the app at the replica, which is a complete bucket with the same keys.
On the app VM in `.env`: `S3_ENDPOINT=$MEDIA_REPLICA_ENDPOINT`, `S3_REGION=$MEDIA_REPLICA_REGION`,
`S3_BUCKET=$MEDIA_REPLICA_BUCKET` and replica keys, then `app up -d api worker imgproxy web` (web:
its CSP media origins follow `S3_ENDPOINT`/`S3_BUCKET`). Do **not** copy the backup project keys to
the app VM: create a new key pair for this emergency (console of the backup project) and delete it
once the primary is back, so the backup keys never sit on the internet-facing VM. Uploads
made in the last ≤ 1 h before the outage are missing. The replica is now the only copy and the
timer must stay stopped (it would sync from the dead primary): create a new primary/replica pair as
soon as possible —

1. New bucket in a healthy location (Terraform: change `object_storage_location`/`media_bucket`, or
   create it by hand), then copy everything into it. The scripts skip `.env` when `S3_BUCKET` and
   `MEDIA_REPLICA_BUCKET` are already in the environment, so load `.env` and override the primary:

       set -a; . /opt/terra/infra/hetzner/compose/.env; set +a     # DB VM .env (replica keys)
       export S3_ENDPOINT=hel1.your-objectstorage.com S3_REGION=hel1 S3_BUCKET=terrareality-media-2 \
              S3_ACCESS_KEY=<new primary key> S3_SECRET_KEY=<new primary secret>
       /opt/terra/scripts/media-restore.sh restore --dry-run
       /opt/terra/scripts/media-restore.sh restore

2. Switch the app `.env` to the new primary, update the DB VM `.env`, `media-replicate.sh --dry-run`,
   start the timer again.

### Drill (quarterly, and optional cheap check)

- `media-restore.sh check` is the cheap check (listing only); `scripts/restore-test.sh` covers the
  database only and stays offline.
- Quarterly: restore one listing's prefix into a scratch bucket
  (`restore --prefix orgs/<org id>/media/<id>/ --to <scratch bucket>`), compare with the primary
  (`rclone check` or open the files), delete the scratch bucket, note duration and result in `launch.md`.
