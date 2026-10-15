# Runbook: deploy (production, Hetzner)

Layout: `infra/hetzner/README.md`. Two VMs on the private network `10.10.1.0/24`:
app `10.10.1.10` (Caddy, web, api, worker, vision, Centrifugo, Temporal, imgproxy, ClamAV,
observability) and db `10.10.1.20` (PostgreSQL 17 + PostGIS + pgvector, pgBackRest, exporters).
Repository checkout on both VMs: `/opt/terra` (user `deploy`). Secrets: `infra/hetzner/compose/.env`
(from `.env.example`, `chmod 600`), never in git.

Shorthand used below (on the VM):

    cd /opt/terra/infra/hetzner/compose
    app() { docker compose -f docker-compose.app.yml "$@"; }
    db()  { docker compose -f docker-compose.db.yml "$@"; }

## 1. First deploy

### 1.1 Accounts and infrastructure (owner + operator, once)
1. Hetzner Cloud project; API token (read/write). Object Storage credentials (console, S3 keys).
2. Remote state bucket `terrareality-tfstate` by hand; `cp backend.hcl.example backend.hcl`.
3. `cd infra/hetzner/terraform && cp terraform.tfvars.example terraform.tfvars` and fill in
   (admin CIDRs, SSH keys, Spark egress IP for WireGuard).
4. `terraform init -backend-config=backend.hcl && terraform plan -out tf.plan` → review →
   `terraform apply tf.plan`. Note the outputs (`terraform output`).
5. DNS (TTL 300 for launch week): A/AAAA for `terrareality.cz`, `www`, `app`, `api`, `img`
   → `app_public_ipv4/ipv6`. CAA `0 issue "letsencrypt.org"` (+ `zerossl.com` fallback).

### 1.2 DB VM
1. `ssh deploy@<db_public_ipv4>`; `git clone <repo> /opt/terra` (deploy key, read only).
2. `cp .env.example .env`, fill in the DB + pgBackRest section (cipher pass: also into the
   password manager and the offline envelope, see `backup.md`).
3. Build the image: `docker build -t terra/postgres:17-postgis-pgvector /opt/terra/infra/dev/postgres && db build`.
4. `db up -d` — the first start runs initdb, creates the Temporal databases, the monitoring role
   and the pgBackRest stanza (fails loudly if the bucket is unreachable or a stanza from another
   cluster exists).
5. Backup timers and the metrics shim: `backup.md` §Install. Take the first full backup now:
   `/opt/terra/scripts/backup-run.sh full`, then `/opt/terra/scripts/backup-check.sh`.

### 1.3 App VM
1. `ssh deploy@<app_public_ipv4>`; clone to `/opt/terra`; `.env` from `.env.example`
   (`IMAGE_TAG` = the git SHA built by CI). Observability: `infra/hetzner/observability/observability.env`
   from its example, Alertmanager SMTP password file, see that README.
2. Secrets files: `/etc/terrareality/secrets/fcm.json` (root:deploy 0640).
3. Static site: build `apps/site` (`npm run build -w site` with `API_URL=https://api...` reachable
   for locality pages) and `rsync -a --delete apps/site/dist/ deploy@app:/srv/site/`.
4. WireGuard: `infra/hetzner/wireguard/README.md` (request to the AiStack operator). Until the
   tunnel is up keep `LLM_BASE_URL=` empty and `FEATURE_FLAGS=-ai.attributes,-ai.text,-ai.vision`.
5. Registry login: `echo $TOKEN | docker login ghcr.io -u <user> --password-stdin` (read-only token).
6. `app pull && app up -d`. Order is enforced by compose: `temporal-schema` → `temporal` →
   `temporal-namespace`; `migrate` (one-shot, goose + River) → `api`, `worker`.
7. Checks:
   - `app ps` (one-shots `Exited (0)`), `app logs migrate | tail`.
   - `curl -fsS https://api.terrareality.cz/healthz` (worker heartbeat `ok`).
   - `https://app.terrareality.cz` login, `https://terrareality.cz`, an image via `img.`.
   - Stripe dashboard → webhook endpoint `https://api.terrareality.cz/v1/webhooks/stripe`,
     events `checkout.session.completed` and `checkout.session.expired`; "Send test webhook" → 2xx.
   - Grafana (`ssh -L 3001:localhost:3001 deploy@app`) dashboard `TerraReality`, targets up.
8. Seed: `app run --rm --no-deps migrate /app/terractl ...` (Praha data, staff accounts with MFA) per the launch
   checklist (`launch.md`).

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

3. Verify: `/healthz`, error rate and p95 in Grafana for 15 min, `app logs -f --since 5m api worker`.
4. Static site: rsync the new `dist/` (atomic enough; Caddy serves files directly).
5. Record the deploy (sha, time, who) in the release log / channel.

Caddyfile-only change: `app exec caddy caddy reload --config /etc/caddy/Caddyfile`.
DB VM changes (postgresql.conf, pgbackrest.conf, image): `db build && db up -d` restarts PostgreSQL
(~10–30 s outage, api reconnects). Announce it; run `backup-check.sh` afterwards.

## 3. Rollback

1. App only (no schema change in the release): set `IMAGE_TAG=<previous sha>` and
   `app up -d --no-deps api worker web vision`. Done in < 2 min.
2. Release with migrations: goose migrations are forward-only in production. Prefer a fix-forward.
   If the old code is incompatible with the new schema:
   - small, reversible migration: `app run --rm --no-deps migrate /app/migrate down` (one step, check the
     migration's `-- +goose Down`), then roll back the images;
   - data damaged or no safe Down: point-in-time restore to just before the migration
     (`restore.md`, scenario B). This loses writes after the target: decide with the owner.
3. Infrastructure (Terraform): revert the commit, `terraform plan` → `apply`. Servers have
   delete/rebuild protection; a broken VM is restored from the Hetzner backup/snapshot
   (`restore.md`, scenario D).

Before risky infra work take a server snapshot: `hcloud server create-image --type snapshot --description "pre-<change>" terra-prod-<app|db>`.
