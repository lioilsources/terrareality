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
4. **Observability: self-hosted Grafana stack plus Sentry.** Prometheus, Alertmanager, blackbox and node
   exporters, Loki (via Alloy, slog JSON from stdout), Tempo (OTLP, 20 % parent-based sampling) and
   Grafana with a provisioned dashboard, all on the app VM and bound to localhost
   (`infra/hetzner/observability`). Alerts: multi-window burn rate for 99.9 % availability, search p95,
   uptime and TLS expiry probes, `/healthz` including the worker heartbeat, job backlog, DB pool, disk
   and backup age/WAL archive/status. LLM alerts are silenced 07:00–13:00 when the Spark serves
   ComfyUI. Sentry (web, Flutter) is optional: an empty DSN disables it, so `make dev` stays offline.
5. **Database roles.** The api and worker currently connect as `terra`, the superuser that owns the
   schema and runs migrations. Owner-facing code reads and writes through `db.AsUser`, which runs
   `SET LOCAL ROLE terra_app` (non-owner, `NOLOGIN`) and sets `app.current_user`, so the
   `org_id IN (SELECT app_user_org_ids())` policies apply (ADR 0004). Code outside `AsUser` (workers,
   backoffice, system jobs) runs as the superuser and bypasses RLS by design; a bug there, or a
   missing `AsUser`, is not caught by the database. **Launch item:** production gets a dedicated login
   role for the api and worker (`NOSUPERUSER NOBYPASSRLS`, member of `terra_app`, explicit grants for
   system paths), while migrations keep running as the schema owner; until then this is recorded as
   ASVS V1.2 partial.
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
- The superuser connection keeps M1–M7 code working but leaves RLS as defence only inside `AsUser`;
  the dedicated role is a launch item, not a refactor deferred to phase 2.
- Mobile releases (TestFlight, Play internal track) depend on native MapLibre and Sentry setup that was
  not verified on the development Mac; they are tracked in the launch checklist.
- The cloud fallback adds a second AI provider and a cross-border transfer; it is opt-in per
  environment and visible in the stored suggestion metadata.
