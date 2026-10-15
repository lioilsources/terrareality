# Production on Hetzner (milestone M8)

Nothing here is applied automatically; runbooks: `docs/runbooks/{deploy,backup,restore,incident}.md`.

```
                    Internet (80/443 tcp+udp)            Spark (owner LAN, NAT)
                              │                                   │ WireGuard 51820/udp
┌─────────────── app VM 10.10.1.10 ───────────────┐              │ 10.66.0.2 -> 10.66.0.1
│ caddy ─ web, api (/v1/webhooks/stripe),          │◄─────────────┘
│         centrifugo (/connection), imgproxy (img.)│  LLM_BASE_URL=http://10.66.0.2:8080/v1
│ worker, vision, temporal, clamav, observability  │
└──────────────┬───────────────────────────────────┘
               │ private network 10.10.1.0/24 (5432, 9100, 9187)
┌──────────────┴─── db VM 10.10.1.20 ──────────────┐      Hetzner Object Storage (S3)
│ PostgreSQL 17 + PostGIS + pgvector               │───►  terrareality-pgbackrest (WAL + backups)
│ pgBackRest, node_exporter, postgres_exporter     │      terrareality-media (photos, via imgproxy)
└──────────────────────────────────────────────────┘
```

| Path | What |
|---|---|
| `terraform/` | hcloud: 2 servers (Ubuntu 24.04, cloud-init: Docker, WireGuard, fail2ban, `deploy` user), private network, firewalls (app: 80/443, 51820/udp from `wireguard_peer_cidrs`; db: nothing public; SSH only from `admin_cidrs`), block volumes mounted at `/srv` (Docker data, pgdata), automated server backups, delete protection. Object Storage buckets via the `aminueza/minio` provider (Hetzner has no bucket API in hcloud; S3 credentials are created in the console). |
| `compose/docker-compose.app.yml` | app VM: Caddy, web, api, worker, vision, Centrifugo, imgproxy, ClamAV, Temporal (PostgreSQL persistence on the DB VM, schema + namespace one-shots), `migrate` one-shot before api/worker; includes `observability/docker-compose.yml`. Images `${IMAGE_REGISTRY}/terra/{api,web,vision}:${IMAGE_TAG}` from CI. |
| `compose/docker-compose.db.yml` | DB VM: PostgreSQL (`db/` image) on the private IP only, postgres_exporter, node_exporter. |
| `compose/Caddyfile` | Automatic HTTPS, HTTP/3, security header baseline (HSTS, nosniff, referrer, frame, permissions; CSP comes from the apps), `/metrics` blocked. Hosts: `terrareality.cz` (static site), `app.` (web + websocket), `api.`, `img.`. |
| `compose/.env.example` | Every production variable for both VMs (placeholders only). |
| `db/` | Image = `infra/dev/postgres` + pgBackRest; `postgresql.conf` (WAL archiving, `archive_timeout=60`), `pgbackrest.conf` (S3 repo, AES-256, 4 full backups retained), init hooks (Temporal DBs, monitoring role, stanza), systemd timers (full Sun, diff Mon–Sat, metrics every 10 min), host shim for monitoring. |
| `wireguard/` | `wg0.conf.example` (Hetzner side) and the request for the AiStack operator (Spark side is never touched by this project). |
| `observability/` | Grafana, Prometheus, Loki, Tempo, Alloy, Alertmanager (separate README). |

Checks that run offline:

```bash
make restore-test                                   # backup + PITR drill (scripts/restore-test.sh)
docker run --rm -v $PWD/infra/hetzner/terraform:/w -w /w hashicorp/terraform:1.13.4 fmt -check -recursive
docker run --rm -v $PWD/infra/hetzner/terraform:/w -w /w hashicorp/terraform:1.13.4 init -backend=false   # needs network
docker run --rm -v $PWD/infra/hetzner/terraform:/w -w /w hashicorp/terraform:1.13.4 validate
cd infra/hetzner/compose && cp .env.example .env && docker compose -f docker-compose.app.yml config -q   # needs observability.env
```

The provider lock file (`terraform/.terraform.lock.hcl`) has checksums for linux/darwin amd64+arm64.
