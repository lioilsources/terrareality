# Runbook: restore PostgreSQL (pgBackRest, point-in-time)

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

    set -a; . ./.env; set +a
    BR=(-e PGBACKREST_REPO1_S3_BUCKET="$PGBACKREST_BUCKET" -e PGBACKREST_REPO1_S3_ENDPOINT="$S3_ENDPOINT"
        -e PGBACKREST_REPO1_S3_REGION="$S3_REGION" -e PGBACKREST_REPO1_S3_KEY="$PGBACKREST_S3_KEY"
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
`.env` with the pgBackRest variables) to prove the backup is usable without the DB VM. Record
duration and row counts of a few key tables (`listings`, `leases`, `payment_obligations`) compared to production.

## D. DB VM lost entirely

1. Either restore the Hetzner automated backup of the server (console → Backups → restore into a
   new server) and continue with A if data is stale, or
2. Recreate: `terraform apply` (the volume has delete protection; if the volume survives, attach it
   and start `db up -d` — PostgreSQL does crash recovery, then A only if that fails).
3. New empty volume: `deploy.md` §1.2 steps 1–3 **without** `db up` (an empty start would run initdb
   and try to create a new stanza), then A from step 4.
4. If the private IP changed, update `DB_HOST` on the app VM and `db_private_ip` for observability.

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
