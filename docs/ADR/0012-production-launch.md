# ADR 0012: Production, observability, security hardening, cloud LLM fallback and launch

Status: accepted (M8, 2026-10-15)

## Context

M8 takes the platform from `make dev` to a first production launch in Prague with about 20 pilot
owners. The plan asks for Hetzner hosting, backups with a 1 h RPO and a verified restore, observability
with SLOs (availability 99.9 %, search p95 ≤ 300 ms), an OWASP ASVS L2 pass, a cloud LLM fallback behind
a flag, legal drafts and a launch checklist. The DGX Spark stays the owner's hardware (ADR 0001,
`infra/spark/README.md`); the platform still never holds money (ADR 0002) and AI output stays a
suggestion (ADR 0003). Nothing in the repository deploys itself.

## Decisions

1. **Hosting: two Hetzner VMs, Docker Compose, Caddy.** Terraform (`infra/hetzner/terraform`) creates an
   app VM (Caddy, web, api, worker, vision, Centrifugo, Temporal, imgproxy, ClamAV, observability) and a
   DB VM (PostgreSQL 17 + PostGIS + pgvector, pgBackRest, exporters) on a private network, firewalls (DB
   has no public port, SSH only from admin CIDRs), block volumes, automated server backups and delete
   protection; Object Storage buckets for media and backups. No Kubernetes: one replica per service is
   enough for the pilot and keeps operations in runbooks (`docs/runbooks/deploy.md`). Caddy terminates
   TLS (Let's Encrypt, ZeroSSL fallback), sets the transport-level header baseline (HSTS, nosniff,
   referrer, frame, permissions) and blocks `/metrics`; the apps set their own CSP.
2. **Images from CI.** The `images` job builds `terra/{api,web,vision}` on every run and, on push to
   `main` when the `REGISTRY_TOKEN` secret exists, pushes `$IMAGE_REGISTRY/terra/<name>:<git sha>` and
   `:latest` (default `ghcr.io/<repository owner>`). Production pins `IMAGE_TAG=<sha>`; `latest` is only
   a convenience. Rollback = previous sha (`deploy.md` §3). Migrations are forward-only; the `migrate`
   one-shot runs before api and worker.
3. **Backups: pgBackRest to Object Storage.** Stanza `terra`, weekly full, daily differential, continuous
   WAL archiving with `archive_timeout=60` (RPO ≤ 1 h, about 1 min in practice), client-side AES-256,
   4 full backups retained, systemd timers on the DB VM. One metric writer, `scripts/backup-metrics.sh`,
   produces the node_exporter textfile `pgbackrest_*` metrics that the `terra-backup` alert rules read
   (the observability script is a thin wrapper). `make restore-test` runs a backup + PITR drill offline;
   the same drill is repeated in production after the first backup (`restore.md` scenario C). The
   cipher passphrase is the single point of failure and is kept in the password manager and offline.
   Media (photos, documents) gets a second copy in another Object Storage location (default nbg1,
   primary fsn1): `scripts/media-replicate.sh` runs hourly from a DB VM timer, `rclone sync` with
   `--backup-dir`, so objects deleted or overwritten on the primary move to dated archive prefixes
   on the replica (90 days) instead of being lost; it refuses to mirror an emptied or strongly shrunk
   primary. `media_replica_*` textfile metrics feed the `terra-media-replica` alerts; restore is
   `scripts/media-restore.sh` (`restore.md` scenario E). We chose script-side archives over bucket
   versioning/object lock because they work the same on any S3 target or a Storage Box and need no
   lifecycle support; a separate Hetzner project for the replica keys is recommended so a leaked app
   key cannot delete the copy.
4. **Observability: self-hosted Grafana stack plus Sentry.** Prometheus, Alertmanager, blackbox and node
   exporters, Loki (via Alloy, slog JSON from stdout), Tempo (OTLP, 20 % parent-based sampling) and
   Grafana with a provisioned dashboard, all on the app VM and bound to localhost
   (`infra/hetzner/observability`). Alerts: multi-window burn rate for 99.9 % availability, search p95,
   uptime and TLS expiry probes, `/healthz` including the worker heartbeat, job backlog, DB pool, disk
   and backup age/WAL archive/status. LLM alerts are silenced 07:00–13:00 when the Spark serves
   ComfyUI. Sentry (web, Flutter) is optional: an empty DSN disables it, so `make dev` stays offline.
5. **Database roles.** Three roles separate schema ownership, system work and per-user work
   (migration `00012_service_role.sql`, `infra/hetzner/db/initdb/13-api-role.sh`):
   - `terra` (`POSTGRES_USER`) owns the schema and runs goose and River migrations only. Its
     password is given only to the `migrate` one-shot as `MIGRATE_DATABASE_URL` (falls back to
     `DATABASE_URL`, so `make dev` and tests keep one URL).
   - `terra_service` (`NOLOGIN NOSUPERUSER NOBYPASSRLS`) is the system role: DML on every table
     including credentials (`sessions`, `auth_tokens`, `users`, ...), sequences and application
     functions, default privileges for tables the owner creates later, `TRUNCATE` on
     `ruian_staging`, ownership of `listing_aggregates` (refresh requires it), read-only
     `goose_db_version`, no `CREATE` anywhere. Instead of bypassing RLS it has one explicit
     permissive policy `system_all ... TO terra_service USING (true) WITH CHECK (true)` per RLS
     table, generated by the migration from `pg_class.relrowsecurity`. A new RLS table without that
     policy is closed to system code (fails closed) and `TestServiceRolePolicies` enumerates
     `pg_class` to catch it in CI.
   - `terra_api` (production login, `IN ROLE terra_service`, created outside migrations with
     `TERRA_API_DB_PASSWORD`) is the `DATABASE_URL` of api, worker and terractl. `terra_service` is
     a member of `terra_app`, so `db.AsUser`'s `SET LOCAL ROLE terra_app` still works and the
     `org_id IN (SELECT app_user_org_ids())` policies apply there (ADR 0004); after the role switch
     `system_all` no longer applies.

   A SQL bug or a missing `AsUser` in system code can still read across orgs (that is what system
   code is for), but the runtime can no longer change the schema, roles or RLS settings, and every
   table it can see is listed explicitly. Dev keeps connecting as the owner `terra`;
   `TestServiceRole` creates a temporary login role in `terra_service` to exercise the production
   path on every `make test`.
6. **Security hardening to ASVS L2.** `docs/security/asvs-l2.md` is the checklist with evidence per
   requirement. Shipped in M8: per-route rate limits (`RATE_LIMIT_*`, search, chat, webhooks,
   applications, messages, auth), CSP with nonces in the web (`vite.config.ts` + runtime origins in
   `src/lib/server/csp.ts`) and a strict API CSP, HSTS in production, dependency scans in CI
   (govulncheck, npm audit, pip-audit, osv-scanner) and `terraform fmt`. The ten launch todos listed
   in that file (password policy, breached passwords, key rotation, `no-store`, ClamAV, session
   lifetime, log retention, Q-AI-1, pentest) gate the launch; the penetration test is commissioned by
   the customer.
7. **Cloud LLM fallback behind a flag.** The Spark gateway stays primary, reached over WireGuard from
   the app VM (`infra/hetzner/wireguard`; the Spark-side peer is a request to its operator). When a
   Spark call fails retryably and the backoffice flag `ai.cloud_fallback` is on (default off), the same
   request goes to an OpenAI-compatible gateway in front of Claude (`CLOUD_LLM_BASE_URL`,
   `CLOUD_LLM_MODEL`, default Claude Sonnet 5.5) (`internal/ai/fallback.go`). The answering model is
   recorded with the suggestion; outputs remain suggestions approved by a human (ADR 0003). The flag
   stays off in production until the Anthropic DPA is signed and Q-AI-1 (transfer of personal data to
   a US processor) is answered. Until the tunnel is up, AI features are switched off by flags.
8. **Legal texts are drafts.** Terms, privacy policy, cookie policy and the DSA contact point live in
   `packages/attributes/legal`, are rendered on the web marked as drafts, and only strictly necessary
   cookies are set (notice, not consent). DPAs are tracked in `docs/legal/dpa-checklist.md`; open points
   in `docs/legal-questions.md`. The customer's lawyer signs off; engineering signs nothing.
9. **Seed Praha by command, not migration.** `terractl import-ruian --region praha` loads addresses and
   boundaries, `terractl onboard-owner --csv` onboards the 20 pilot owners (CSV kept out of git), and
   the static Astro site generates Prague locality pages (`docs/runbooks/seed-praha.md`).
10. **Launch gate.** `docs/runbooks/launch.md` is the checklist with an owner per item (us, customer,
    Spark operator) and marks what is done in the repository versus pending outside. Go-live requires a
    green read-only production smoke test (`make smoke BASE_URL=… API_URL=… SITE_URL=…`, also the manual
    `smoke` workflow): site landing, Praha page and sitemap, web home, search with results and a listing
    detail, legal pages, `/healthz` including the worker, security headers and no console errors. The
    smoke test never logs in, writes or calls the LLM, so it is safe against production.

## Consequences

- One replica per service: deploys restart the api for a few seconds; scaling out later needs the rate
  limiter and sessions to move to shared state (noted in the ASVS file).
- Observability runs on the app VM it observes; an outage of that VM is detected by the external
  uptime probes and Sentry, not by Grafana. An off-site uptime check is a cheap follow-up.
- System code sees all rows through explicit `system_all` policies rather than per-user RLS; RLS is
  still the enforcement point only inside `AsUser`. Dev runs as the owner, so a privilege missing
  for `terra_service` shows up in `TestServiceRole`/`TestServiceRolePolicies`, not in `make dev`.
- Mobile releases (TestFlight, Play internal track) depend on native MapLibre and Sentry setup that was
  not verified on the development Mac; they are tracked in the launch checklist.
- The cloud fallback adds a second AI provider and a cross-border transfer; it is opt-in per
  environment and visible in the stored suggestion metadata.
- Media has two copies in two Object Storage locations, but the replica lags up to an hour behind and
  the initial copy and every sync stream through the DB VM (egress/traffic cost grows with the media
  volume). The pgBackRest repository is still in the primary location only; a second repository
  (`repo2`) in the replica location is a follow-up.

## Notes (M8b hardening, 2026-10-16; review `docs/05-review-implementation.md`)

- Point 1 (Caddy): the header baseline is applied only where the upstream sent no value (`?` with
  `defer`), so the api's own headers (HSTS 2 years, `Referrer-Policy: no-referrer`) win and no
  response carries duplicates. Caddy's active health check on the single api upstream uses
  `/v1/version` (liveness), not `/healthz`, which reports degraded dependencies with 503 and would
  take every route down; `lb_try_duration` covers api restarts. Compose healthchecks, `depends_on:
  service_healthy` for Caddy, memory limits and pinned image tags were added; the web container
  gets its CSP origins and `BODY_SIZE_LIMIT=60M` from compose. Access logs drop query strings and
  invitation tokens, truncate client IPs and are kept 14 days in Loki (application logs 30 days).
- Point 3 (backups): credentials are split per VM. The app VM `.env` (`compose/.env.example`) holds
  no backup key; the DB VM `.env` (`compose/db.env.example`) holds the keys of a **separate Hetzner
  backup project** that owns the pgBackRest bucket and the media replica. The pgBackRest bucket is
  versioned with noncurrent-version expiry (`backup_noncurrent_days`, 30) via Terraform; this
  replaces the earlier "no versioning" note for that bucket (pgBackRest works on versioned buckets).
  The media replica keeps its script-side archive; `media-replicate.sh` refuses to run with the
  media keys. Not done: Object Lock / an offline copy against a compromised DB VM. WAL archive
  failures alert (`WalArchiveFailing`) and the push queue is 12 GiB; after any archive incident a
  full backup is taken.
- Point 4 (observability): the LLM alert now exists (`LlmJobFailuresHigh`, `component="llm"`) and
  is muted 07:00–13:00 Europe/Prague by the Alertmanager time interval `spark-comfyui-window`;
  `severity=page` goes to e-mail plus a paging webhook (`page_webhook_url`). Alertmanager secrets are
  files in a mounted directory so a missing file no longer stops the whole app stack. PostgreSQL
  alerts (`PostgresDown`, connections, long transactions, deadlocks) and the `postgres` and
  `alertmanager` scrape jobs are covered by `ScrapeTargetDown`.
- Point 5 (database roles): api, worker and migrate connect over TLS (`sslmode=verify-full`, internal
  CA from `scripts/pg-tls-init.sh`); Temporal's connection is still plain on the private network.
- Point 6 (CI): Go is pinned to 1.26.9 (`go` + `toolchain` in `go.mod`, `golang:1.26.9-alpine`) with
  patched kin-openapi and excelize so govulncheck passes; CI runs `make gen-check-go` (catalog and
  lease templates included), `terraform validate`, has `permissions: contents: read`, job timeouts,
  build args for `/v1/version`, a sha256-verified typst download and Dependabot. Actions are still
  pinned by tag, not by commit SHA.
