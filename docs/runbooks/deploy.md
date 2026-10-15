# Runbook: deploy (production, Hetzner)

Layout: `infra/hetzner/README.md`. Two VMs on the private network `10.10.1.0/24`:
app `10.10.1.10` (Caddy, web, api, worker, vision, Centrifugo, Temporal, imgproxy, ClamAV,
observability) and db `10.10.1.20` (PostgreSQL 17 + PostGIS + pgvector, pgBackRest, exporters).
Repository checkout on both VMs: `/opt/terra` (user `deploy`). Secrets: `infra/hetzner/compose/.env`
(`chmod 600`), never in git, **one file per VM** (review V-16): the app VM from `.env.example`, the DB
VM from `db.env.example`. The app VM faces the internet and never holds the pgBackRest keys, the
cipher passphrase, the media replica keys or the monitoring password.

Shorthand used below (on the VM):

    cd /opt/terra/infra/hetzner/compose
    app() { docker compose -f docker-compose.app.yml "$@"; }
    db()  { docker compose -f docker-compose.db.yml "$@"; }

## 1. First deploy

### 1.1 Accounts and infrastructure (owner + operator, once)
1. Hetzner Cloud project `terrareality` (servers, network, media bucket); API token (read/write);
   Object Storage S3 keys of this project (media: `S3_ACCESS_KEY` on the app VM).
   A **second Hetzner project** `terrareality-backup` with its own S3 keys only (no servers): it
   holds the pgBackRest bucket and the media replica (`backup_access_key`/`backup_secret_key` in
   Terraform, `PGBACKREST_S3_KEY*` and `MEDIA_REPLICA_*_KEY` in the DB VM `.env`). Nobody stores
   these keys on the app VM or in CI. Terraform enables versioning with noncurrent-version expiry
   (`backup_noncurrent_days`, 30) on the backup bucket; check it once in the console after apply
   (bucket → Versioning: enabled; Lifecycle: 2 rules). If the provider call fails on your account,
   enable both by hand there (same values) and note it in `launch.md`.
2. Remote state bucket `terrareality-tfstate` by hand; `cp backend.hcl.example backend.hcl`.
3. `cd infra/hetzner/terraform && cp terraform.tfvars.example terraform.tfvars` and fill in
   (admin CIDRs, SSH keys, Spark egress IP for WireGuard — required, no default; backup project keys).
4. `terraform init -backend-config=backend.hcl && terraform plan -out tf.plan` → review →
   `terraform apply tf.plan`. Note the outputs (`terraform output`).
5. DNS (TTL 300 for launch week): A/AAAA for `terrareality.cz`, `www`, `app`, `api`, `img`
   → `app_public_ipv4/ipv6`. CAA `0 issue "letsencrypt.org"` (+ `zerossl.com` fallback).

### 1.2 DB VM
1. `ssh deploy@<db_public_ipv4>`; `git clone <repo> /opt/terra` (deploy key, read only).
2. `cp db.env.example .env` (DB VM template) and fill in: database passwords (the same values go into
   the app VM `.env`), pgBackRest section with the **backup project** keys and Terraform outputs
   `backup_bucket`/`backup_endpoint`, media + replica section (cipher pass: also into the password
   manager and the offline envelope, see `backup.md`).
3. TLS for PostgreSQL (review S-I12): `DB_HOST=10.10.1.20 /opt/terra/scripts/pg-tls-init.sh`. It
   writes `/srv/pgtls` (server certificate for the private IP, `ssl.conf` included by
   `postgresql.conf`) and the CA key to `/srv/pgtls-ca/ca.key`: copy `/srv/pgtls/ca.crt` to the app
   VM (§1.3 step 2), put `ca.key` into the password manager and delete it from the VM.
   Build the image: `docker build -t terra/postgres:17-postgis-pgvector /opt/terra/infra/dev/postgres && db build`.
4. `db up -d` — the first start runs initdb, creates the Temporal databases, the monitoring role,
   the api login role `terra_api` (§1.4) and the pgBackRest stanza (fails loudly if the bucket is unreachable or a stanza from another
   cluster exists).
5. Backup timers and the metrics shim: `backup.md` §Install. Take the first full backup now:
   `/opt/terra/scripts/backup-run.sh full`, then `/opt/terra/scripts/backup-check.sh`.
6. Media replica (second copy of `S3_BUCKET` in another location): `.env` media + `MEDIA_REPLICA_*`
   section, first sync and timer per `backup.md` §Media replica.

### 1.3 App VM
1. `ssh deploy@<app_public_ipv4>`; clone to `/opt/terra`; `.env` from `.env.example` (app VM
   template, `IMAGE_TAG` = the git SHA built by CI). Observability:
   `infra/hetzner/observability/observability.env` from its example.
   The web container gets its browser-facing origins from compose (refuses to start in production
   without them, review B-3): `API_PUBLIC_URL=https://$API_DOMAIN`,
   `CSP_MEDIA_ORIGINS=https://$IMG_DOMAIN https://$S3_ENDPOINT https://$S3_BUCKET.$S3_ENDPOINT`
   (photos via imgproxy, presigned downloads), `CSP_FORM_ACTION_ORIGINS` (Stripe Checkout,
   `https://checkout.revolut.com`, GoCardless bank consent `https://ob.gocardless.com`, BankID),
   `CSP_REALTIME_ORIGIN=wss://$APP_DOMAIN`, `CSP_MAP_ORIGINS` (empty for OpenFreeMap). Set them in
   `.env` only when a host differs. Uploads go through SvelteKit form actions:
   `BODY_SIZE_LIMIT=$WEB_BODY_SIZE_LIMIT` (default `60M`, review B-4) and Caddy `max_size 64MB`
   on the app domain; keep both in line with the largest upload (photos 20 MiB each).
2. Secrets files **before the first `app up`** (missing files otherwise turn into empty
   directories created by Docker):
   - `/etc/terrareality/secrets/fcm.json` (root:deploy 0640);
   - `/etc/terrareality/secrets/pg-ca.crt` = `ca.crt` from the DB VM (§1.2 step 3), 0644
     (`DB_SSLMODE=verify-full`; `disable` only while the DB VM has no certificate yet);
   - Alertmanager (review S-I13): directory `/etc/terrareality/secrets/alertmanager`
     (root:deploy 0750) with `smtp_password` and `page_webhook_url` (one line each, 0640, no
     trailing newline: `printf %s '...' > file`). The stack starts without them, but alert mail
     and paging fail (`AlertmanagerNotificationsFailing`, visible in Grafana only).
3. Static site: build `apps/site` with both URLs of the production stack, then sync:

       API_URL=https://api.terrareality.cz PUBLIC_APP_URL=https://app.terrareality.cz \
         SITE_ENV=production npm run build -w site
       rsync -a --delete apps/site/dist/ deploy@app:/srv/site/

   `API_URL` must be reachable (locality pages list offers); `PUBLIC_APP_URL` is where every CTA,
   footer link and listing link points (the build fails without it, review V-11).
4. WireGuard: `infra/hetzner/wireguard/README.md` (request to the AiStack operator). Until the
   tunnel is up keep `LLM_BASE_URL=` empty and `FEATURE_FLAGS=-ai.attributes,-ai.text,-ai.vision`.
5. Registry login: `echo $TOKEN | docker login ghcr.io -u <user> --password-stdin` (read-only token).
6. `app pull && app up -d`. Order is enforced by compose: `temporal-schema` → `temporal` →
   `temporal-namespace`; `migrate` (one-shot, goose + River) → `api`, `worker`.
7. Checks:
   - `app ps` (one-shots `Exited (0)`), `app logs migrate | tail`.
   - `app ps`: api, worker, web, vision, centrifugo, imgproxy, clamav `(healthy)`; temporal
     `(healthy)` within a minute.
   - `curl -fsS https://api.terrareality.cz/healthz` (worker heartbeat `ok`).
   - `https://app.terrareality.cz` login, `https://terrareality.cz`, a listing photo on `/hledat`
     (browser console without CSP errors), a download (`?/download`), a 10 MB photo upload.
   - `make smoke BASE_URL=… API_URL=… SITE_URL=…` (includes "a listing photo loads").
   - Stripe dashboard → webhook endpoint `https://api.terrareality.cz/v1/webhooks/stripe`,
     events `checkout.session.completed` and `checkout.session.expired`; "Send test webhook" → 2xx.
   - Grafana (`ssh -L 3001:localhost:3001 deploy@app`) dashboard `TerraReality`, targets up.
8. Seed: `app run --rm --no-deps migrate /app/terractl ...` (Praha data, staff accounts with MFA) per the launch
   checklist (`launch.md`).

### 1.4 Database roles (ADR 0012 point 5)

| Role | Login | Used by | Can |
| --- | --- | --- | --- |
| `terra` (`POSTGRES_USER`) | yes, `POSTGRES_PASSWORD` | `migrate` one-shot only (`MIGRATE_DATABASE_URL`) | everything (superuser, schema owner) |
| `terra_service` | no | group role, migration `00012_service_role.sql` | DML on all tables, `system_all` RLS policy per RLS table, no DDL |
| `terra_api` | yes, `TERRA_API_DB_PASSWORD` | api, worker, terractl (`DATABASE_URL`) | member of `terra_service` (and through it `terra_app` for `db.AsUser`) |
| `terra_app` | no | `SET LOCAL ROLE` inside `db.AsUser` | per-user RLS (ADR 0004) |

The app VM `.env` needs both passwords: compose builds `DATABASE_URL` (terra_api) for api and worker and
adds `MIGRATE_DATABASE_URL` (owner) only to the `migrate` service. Without `MIGRATE_DATABASE_URL` the
migrate command falls back to `DATABASE_URL` (dev, tests).

`initdb/13-api-role.sh` creates `terra_api` on a fresh data directory. On a cluster that already exists
(initdb hooks do not run again), create it once, before deploying the release with migration 00012:

    set -a; . ./.env; set +a
    docker exec -i terra-db psql -X -v ON_ERROR_STOP=1 -U terra -d postgres -v pw="$TERRA_API_DB_PASSWORD" <<'SQL'
    SELECT 'CREATE ROLE terra_service NOLOGIN NOSUPERUSER NOBYPASSRLS NOCREATEDB NOCREATEROLE NOREPLICATION'
    WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'terra_service')\gexec
    CREATE ROLE terra_api LOGIN NOSUPERUSER NOBYPASSRLS NOCREATEDB NOCREATEROLE NOREPLICATION
      CONNECTION LIMIT 100 PASSWORD :'pw' IN ROLE terra_service;
    SQL

Then `app run --rm --no-deps migrate` (applies 00012: grants and policies) and `app up -d`.
Staging (`infra/nas`) uses the same `terra_api` role (its README).
Check: `docker exec terra-db psql -U terra -d terra -c "SELECT usename FROM pg_stat_activity WHERE datname='terra'"`
shows `terra_api` for the api/worker connections.

Password rotation: `ALTER ROLE terra_api PASSWORD '...'` as `terra`, update `TERRA_API_DB_PASSWORD` in the
app VM `.env`, `app up -d --no-deps api worker`. Old connections keep working until the restart.

A new table with row-level security calls `SELECT app_enable_rls('<t>');` in its migration (enables RLS
and adds `system_all ... TO terra_service USING (true) WITH CHECK (true)`), then creates its per-user
policies: separate `FOR SELECT` (members and parties) and write policies with `WITH CHECK` (migration
00013 shows the pattern). `TestServiceRolePolicies` fails without `system_all`, and in production
system code would see no rows of that table. Migrations always run as the same owner role (`terra`):
`ALTER DEFAULT PRIVILEGES` in 00002/00012 covers only objects that role creates.

## 2. Rolling update (normal release)

Zero-downtime is not guaranteed for the api (single replica); a restart is ~2 s and clients retry.

1. CI green on `main`, images pushed with tag `<sha>`. Read the migration diff: destructive or long
   migrations (table rewrites, index without `CONCURRENTLY`) need a maintenance note and an
   incremental backup first: `ssh db /opt/terra/scripts/backup-run.sh incr`.
2. On the app VM:

        cd /opt/terra && git fetch && git checkout <sha>      # compose/Caddy changes
        cd infra/hetzner/compose
        sed -i "s/^IMAGE_TAG=.*/IMAGE_TAG=<sha>/" .env
        app pull
        app run --rm --no-deps migrate                      # fails -> stop here, nothing changed yet
        app up -d --no-deps api worker web vision
        app up -d                                           # anything else that changed (Caddy reloads config)

3. Verify: `app ps` (all long-running services `healthy`), `/healthz`, error rate and p95 in Grafana
   for 15 min, `app logs -f --since 5m api worker`. During the api restart Caddy holds requests up
   to 10 s (`lb_try_duration`) instead of answering 502.
4. Static site: rsync the new `dist/` (atomic enough; Caddy serves files directly).
5. Record the deploy (sha, time, who) in the release log / channel.

Caddyfile-only change: `app exec caddy caddy reload --config /etc/caddy/Caddyfile`.
DB VM changes (postgresql.conf, pgbackrest.conf, image): `db build && db up -d` restarts PostgreSQL
(~10–30 s outage, api reconnects). Announce it; run `backup-check.sh` afterwards.

## 3. Rollback

1. App only (no schema change in the release): set `IMAGE_TAG=<previous sha>` and
   `app up -d --no-deps api worker web vision`. Done in < 2 min.
2. Release with migrations: goose migrations are forward-only in production. Prefer a fix-forward.
   Never run a Down that deletes data after launch: `00007`/`00009` drop financial tables with
   `CASCADE`, `00008` deletes investor memberships, `00010` owner invitations and `00011` the DSA
   listing reports (a legal record). These Downs exist for development only.
   If the old code is incompatible with the new schema:
   - small, reversible migration: `app run --rm --no-deps migrate /app/migrate down` (one step, check the
     migration's `-- +goose Down`), then roll back the images;
   - data damaged or no safe Down: point-in-time restore to just before the migration
     (`restore.md`, scenario B). This loses writes after the target: decide with the owner.
3. Infrastructure (Terraform): revert the commit, `terraform plan` → `apply`. Servers have
   delete/rebuild protection; a broken VM is restored from the Hetzner backup/snapshot
   (`restore.md`, scenario D).

Before risky infra work take a server snapshot: `hcloud server create-image --type snapshot --description "pre-<change>" terra-prod-<app|db>`.

## 4. Health checks and Caddy upstream

- Compose healthchecks (review S-I4): api `/v1/version` (static `probe` binary in the distroless
  image), worker `:9090/metrics`, web `/robots.txt`, vision `/healthz`, Centrifugo `/health`,
  imgproxy `imgproxy health`, ClamAV its built-in `clamdcheck.sh`, Temporal frontend port 7233.
  Caddy starts only after api, web, Centrifugo and imgproxy are healthy. Memory limits:
  clamav 3g, temporal 1.5g, api/worker/vision/imgproxy 1g, web 768m, centrifugo 512m.
- Caddy's active health check on the api uses `/v1/version` (liveness), never `/healthz`
  (review B-5): `/healthz` turns 503 when vision or the worker heartbeat is degraded and Caddy
  would then drop every route. `/healthz` stays the readiness signal for the blackbox probe and
  `ApiHealthzDown`.
- Security headers: Caddy fills in only headers the upstream did not send (`?` + `defer`), so the
  api's own HSTS/`Referrer-Policy: no-referrer`/Permissions-Policy and the web's headers win and
  no response carries duplicates.
