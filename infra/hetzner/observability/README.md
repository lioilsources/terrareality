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
- Secrets: `observability.env` from `observability.env.example`; the Alertmanager SMTP password
  is a one-line file at `ALERT_SMTP_PASSWORD_FILE` (Docker secret).

## DB VM

Runs `node_exporter` (port 9100 on the private IP 10.10.1.20) with
`--collector.textfile.directory=/var/lib/node_exporter/textfile`, optionally `postgres_exporter`
(9187). The single metric writer is `scripts/backup-metrics.sh` in the repo root (stanza `terra`,
systemd timer `infra/hetzner/db/systemd/terra-backup-metrics.timer` every 10 min and after each
backup); `scripts/pgbackrest-textfile.sh` here is only a wrapper around it. It writes
`/var/lib/node_exporter/textfile/pgbackrest.prom` atomically (temp file + rename) and emits
`pgbackrest_last_backup_timestamp_seconds{stanza,type}`, `pgbackrest_last_backup_size_bytes`,
`pgbackrest_last_archive_timestamp_seconds` (from `pg_stat_archiver`), `pgbackrest_backup_ok` and
`pgbackrest_textfile_updated_timestamp_seconds`. Needs Docker + `jq`.

## Uptime targets

`prometheus/targets/{uptime,healthz}.yml` use placeholder hosts (`terrareality.cz`,
`app.terrareality.cz`, `api.terrareality.cz`); adjust to the final DNS. The healthz probe requires
HTTP 200 and `"worker":{..."status":"ok"}` in the body (worker heartbeat).

## Alerts

`prometheus/rules/slo.yml` (availability 99.9 % multi-window burn rate, search p95 > 300 ms,
uptime probes, TLS expiry) and `prometheus/rules/platform.yml` (healthz, scrape targets, worker,
job backlog/failures, DB pool, disk, pgBackRest age/WAL archive/failures). Validate with
`docker run --rm -v $PWD/prometheus:/etc/prometheus:ro --entrypoint promtool prom/prometheus:v3.5.0 check config /etc/prometheus/prometheus.yml`
(also checks the rule files) and `... check rules /etc/prometheus/rules/*.yml`.
