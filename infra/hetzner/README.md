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
│ PostgreSQL 17 + PostGIS + pgvector (TLS)         │      app project:    terrareality-media (photos, via imgproxy)
│ pgBackRest, node_exporter, postgres_exporter     │───►  backup project: terrareality-pgbackrest (WAL + backups, versioned)
│ rclone (media replica, hourly)                   │───►  backup project: nbg1 terrareality-media-replica (2nd copy)
└──────────────────────────────────────────────────┘
```

Credentials are split per VM (review V-16): the internet-facing app VM has the media keys and the
DB passwords only; the keys of the separate backup project, the pgBackRest cipher pass and the
monitoring password exist only on the DB VM (`docs/runbooks/backup.md` §Credential isolation).

| Path | What |
|---|---|
| `terraform/` | hcloud: 2 servers (Ubuntu 24.04, cloud-init: Docker, WireGuard, fail2ban, `deploy` user), private network, firewalls (app: 80/443, 51820/udp from `wireguard_peer_cidrs`; db: nothing public; SSH only from `admin_cidrs`), block volumes mounted at `/srv` (Docker data, pgdata), automated server backups, delete protection. Object Storage buckets via the `aminueza/minio` provider (Hetzner has no bucket API in hcloud; S3 credentials are created in the console). |
| `compose/docker-compose.app.yml` | app VM: Caddy, web, api, worker, vision, Centrifugo, imgproxy, ClamAV, Temporal (PostgreSQL persistence on the DB VM, schema + namespace one-shots), `migrate` one-shot before api/worker; includes `observability/docker-compose.yml`. Images `${IMAGE_REGISTRY}/terra/{api,web,vision}:${IMAGE_TAG}` from CI. |
| `compose/docker-compose.db.yml` | DB VM: PostgreSQL (`db/` image) on the private IP only (TLS when `scripts/pg-tls-init.sh` ran), postgres_exporter, node_exporter. |
| `compose/Caddyfile` | Automatic HTTPS, HTTP/3, security header baseline set only where the upstream sent none (no duplicates; CSP comes from the apps), `/metrics`, `/debug`, `/dev` blocked, api health check on `/v1/version`, access logs without query strings and with truncated IPs. Hosts: `terrareality.cz` (static site), `app.` (web + websocket), `api.`, `img.`. |
| `compose/centrifugo.json` | Production Centrifugo config: namespaces only, no admin, no secrets (they come from env). |
| `compose/.env.example` | App VM variables (placeholders only). |
| `compose/db.env.example` | DB VM variables: database, pgBackRest (backup project keys, cipher pass), media replica. |
| `db/` | Image = `infra/dev/postgres` + pgBackRest; `postgresql.conf` (WAL archiving, `archive_timeout=60`), `pgbackrest.conf` (S3 repo, AES-256, 4 full backups retained), init hooks (Temporal DBs, monitoring role, api login role `terra_api` IN ROLE `terra_service`, stanza), systemd timers (full Sun, diff Mon–Sat, metrics every 10 min, media replica hourly via `scripts/media-replicate.sh`), host shim for monitoring. |
| `wireguard/` | `wg0.conf.example` (Hetzner side) and the request for the AiStack operator (Spark side is never touched by this project). |
| `observability/` | Grafana, Prometheus, Loki, Tempo, Alloy, Alertmanager (separate README). |

Checks that run offline:

```bash
make restore-test                                   # backup + PITR drill (scripts/restore-test.sh)
docker run --rm -v $PWD/infra/hetzner/terraform:/w -w /w hashicorp/terraform:1.13.4 fmt -check -recursive
docker run --rm -v $PWD/infra/hetzner/terraform:/w -w /w hashicorp/terraform:1.13.4 init -backend=false   # needs network (registry)
docker run --rm -v $PWD/infra/hetzner/terraform:/w -w /w hashicorp/terraform:1.13.4 validate
cd infra/hetzner/compose && cp .env.example .env && docker compose -f docker-compose.app.yml config -q   # needs observability.env
cp db.env.example .env && docker compose -f docker-compose.db.yml config -q
docker run --rm -v $PWD/infra/hetzner/compose/Caddyfile:/etc/caddy/Caddyfile:ro -e ACME_EMAIL=a@b.c \
  -e SITE_DOMAIN=terrareality.cz -e APP_DOMAIN=app.terrareality.cz -e API_DOMAIN=api.terrareality.cz \
  -e IMG_DOMAIN=img.terrareality.cz caddy:2.10.2 caddy validate --config /etc/caddy/Caddyfile
```

`terraform init -backend=false` writes `.terraform/` into the directory (git-ignored); CI runs the
same `fmt` + `init -backend=false` + `validate` in the `security` job.

The provider lock file (`terraform/.terraform.lock.hcl`) has checksums for linux/darwin amd64+arm64.
