# Observability (production, app VM)

Prometheus + Alertmanager + blackbox exporter + node_exporter, Loki (logs via Grafana Alloy),
Tempo (traces) and Grafana with provisioned datasources and the `TerraReality` dashboard.
Nothing listens publicly: Grafana `127.0.0.1:3001`, Prometheus `127.0.0.1:9091`,
Alertmanager `127.0.0.1:9093` (use `ssh -L 3001:localhost:3001 app`).

## Wiring the app compose

- Include this file (`include: [../observability/docker-compose.yml]`) and attach `api`, `worker`
  (and `web` if desired) to the `observability` network (`name: terra-observability`).
- api and worker env:
  - `METRICS_ADDR=:9090`: internal Prometheus listener (unset = off, the dev default). Do not publish it.
  - `OTEL_EXPORTER_OTLP_ENDPOINT=http://tempo:4318/v1/traces`, `OTEL_TRACES_SAMPLER_ARG=0.2`
    (parent-based ratio, default 1).
- web env: `SENTRY_DSN`, `PUBLIC_SENTRY_DSN`, `PUBLIC_SENTRY_ENVIRONMENT=prod`,
  `PUBLIC_SENTRY_RELEASE=<git sha>` (all optional; empty disables Sentry).
- Logs: services keep logging slog JSON to stdout; Alloy reads them from the Docker socket and
  labels them with `service` (compose service name) and `level`.
- Secrets: `observability.env` from `observability.env.example`; Alertmanager reads
  `smtp_password` and `page_webhook_url` (one line each) from the directory `ALERT_SECRETS_DIR`
  (default `/etc/terrareality/secrets/alertmanager`, mounted read-only at `/run/alertmanager-secrets`).
  A missing file does not stop the stack (this file is `include`d by the app compose); the send
  fails and `AlertmanagerNotificationsFailing` shows it on Grafana.
- Paging: `severity=page` goes to e-mail **and** the webhook in `page_webhook_url` (e.g. an ntfy
  topic or an SMS/phone gateway accepting Alertmanager webhooks). LLM job alerts
  (`component="llm"`) are muted 07:00–13:00 Europe/Prague (`time_intervals: spark-comfyui-window`).
- Log retention (Loki): application logs 30 days, Caddy access logs 14 days (`retention_stream`).

## DB VM

Runs `node_exporter` (port 9100 on the private IP 10.10.1.20) with
`--collector.textfile.directory=/var/lib/node_exporter/textfile` and `postgres_exporter` (9187),
both from `compose/docker-compose.db.yml`. The single metric writer is `scripts/backup-metrics.sh` in the repo root (stanza `terra`,
systemd timer `infra/hetzner/db/systemd/terra-backup-metrics.timer` every 10 min and after each
backup); `scripts/pgbackrest-textfile.sh` here is only a wrapper around it. It writes
`/var/lib/node_exporter/textfile/pgbackrest.prom` atomically (temp file + rename) and emits
`pgbackrest_last_backup_timestamp_seconds{stanza,type}`, `pgbackrest_last_backup_size_bytes`,
`pgbackrest_last_archive_timestamp_seconds`, `pgbackrest_archive_failing` and
`pgbackrest_archive_failed_count` (from `pg_stat_archiver`), `pgbackrest_backup_ok` and
`pgbackrest_textfile_updated_timestamp_seconds`. Needs Docker + `jq`.

## Uptime targets

`prometheus/targets/{uptime,healthz}.yml` use placeholder hosts (`terrareality.cz`,
`app.terrareality.cz`, `api.terrareality.cz`); adjust to the final DNS. The healthz probe requires
HTTP 200 and `"worker":{..."status":"ok"}` in the body (worker heartbeat).

## Alerts

`prometheus/rules/slo.yml` (availability 99.9 % multi-window burn rate, search p95 > 300 ms,
uptime probes, TLS expiry) and `prometheus/rules/platform.yml` (healthz, scrape targets incl.
postgres and alertmanager, worker, job backlog/failures, LLM job failures, Alertmanager delivery,
DB pool, disk, PostgreSQL (`pg_up`, connections, long transactions, deadlocks), pgBackRest
age/WAL archive age/archive failures/backup status, media replica). Validate with
`docker run --rm -v $PWD/prometheus:/etc/prometheus:ro --entrypoint promtool prom/prometheus:v3.5.0 check config /etc/prometheus/prometheus.yml`
(also checks the rule files) and `... check rules /etc/prometheus/rules/*.yml`; Alertmanager with
`docker run --rm -v $PWD/alertmanager:/c:ro --entrypoint amtool prom/alertmanager:v0.28.1 check-config /c/alertmanager.yml`.
