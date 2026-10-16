# Staging on the NAS

Pilot/staging only. Production runs on Hetzner from milestone M8 (see `docs/02-plan.md`).

1. Create `.env` next to `docker-compose.yml` with:
   `POSTGRES_PASSWORD`, `TERRA_API_DB_PASSWORD`, `CENTRIFUGO_API_KEY`, `CENTRIFUGO_TOKEN_SECRET`,
   `APP_SECRET_KEY`, `APP_DOMAIN`, `API_DOMAIN`, `SITE_DOMAIN`, `CSP_MEDIA_ORIGINS` (imgproxy and S3
   origins the browser loads photos/downloads from), the media settings `S3_ENDPOINT`,
   `S3_ACCESS_KEY`, `S3_SECRET_KEY`, `IMGPROXY_URL`, `IMGPROXY_KEY`, `IMGPROXY_SALT` (the api refuses
   to start outside dev without S3), the app-link values `APPLE_TEAM_ID` and
   `ANDROID_CERT_SHA256` (see `docs/runbooks/launch.md` §8), optionally `SMTP_ADDR`/`SMTP_USERNAME`/
   `SMTP_PASSWORD` (empty = mails only logged; sign-in is by e-mail link, so testers need real mail), `IMGPROXY_URL_TTL`, `SESSION_MAX_AGE` (default 2160h),
   `PHONE_VERIFICATION` (default false), `LLM_BASE_URL`
   (AiStack gateway on the Spark over LAN, e.g. `http://192.168.88.66:8080/v1`).
   api and worker connect as `terra_api` (no superuser, no BYPASSRLS, same as production); only
   `migrate` uses the owner `terra`. A new volume gets the role from `initdb/13-api-role.sh`; on an
   existing volume create it once with the SQL in `docs/runbooks/deploy.md` §1.4
   (`docker compose exec -T db psql -U terra -d postgres ...`), then `docker compose up -d`.
   Media and image hosts: `IMG_DOMAIN`, `S3_DOMAIN` (Caddy), with `S3_ENDPOINT=$S3_DOMAIN`,
   `IMGPROXY_URL=https://$IMG_DOMAIN` and `CSP_MEDIA_ORIGINS="https://$IMG_DOMAIN https://$S3_DOMAIN"`.
   The api and web reach the bucket through the public `S3_DOMAIN` too (presigned URLs are signed
   for that host). Data locations: `TERRA_SSD_DIR` (PostgreSQL, Temporal) and `TERRA_POOL_DIR`
   (media bucket, daily dumps), both default `./data`.
2. Build the Astro site and copy it: `npm run build -w site && cp -r apps/site/dist infra/nas/site-dist`
   (with `API_URL=https://$API_DOMAIN PUBLIC_APP_URL=https://$APP_DOMAIN` once the api is up).
3. `docker compose up -d --build`. The `migrate` service runs goose + River migrations once before api/worker start.
   On a slow NAS build the images elsewhere instead (the Dockerfiles cross-compile):
   `docker buildx build --platform linux/amd64 -t terra/api:staging --load services/api` (likewise
   `terra/web` from the repo root with `-f apps/web/Dockerfile`, `terra/vision`, `terra/postgres` from
   `infra/dev/postgres`), then `docker save ... | ssh nas docker load` and `docker compose up -d`.
4. Check `https://$API_DOMAIN/healthz`.

## Behind a Cloudflare Tunnel (no open ports)

Set `COMPOSE_FILE=docker-compose.yml:docker-compose.tunnel.yml` and `SITE_SCHEME=http://` in `.env`.
Create the tunnel and one CNAME per host, then put the config next to the compose file:

    cloudflared tunnel create terra
    # An existing ~/.cloudflared/config.yml with `tunnel:` wins over the argument: pass an empty config.
    echo '{}' > /tmp/cf-empty.yml
    for h in $APP_DOMAIN $API_DOMAIN $SITE_DOMAIN $IMG_DOMAIN $S3_DOMAIN; do
      cloudflared --config /tmp/cf-empty.yml tunnel route dns --overwrite-dns <tunnel-id> $h
    done
    mkdir -p cloudflared && cp ~/.cloudflared/<tunnel-id>.json cloudflared/

`cloudflared/config.yml` sends every host to Caddy:

    tunnel: <tunnel-id>
    credentials-file: /etc/cloudflared/<tunnel-id>.json
    ingress:
      - service: http://caddy:80

Cloudflare's free certificate covers one level of subdomains only (`*.example.com`), so use names
like `terra-api.example.com`, not `api.terra.example.com`.

## Backups

The `backup` service writes `pg_dump -Fc` to `$TERRA_POOL_DIR/backups` once a day and keeps
`BACKUP_KEEP_DAYS` (14). The media bucket lives on the same disk; copy both off the NAS for a real
second copy. Restore into a scratch database:

    docker compose exec -T db createdb -U terra terra_restore
    docker compose exec -T db pg_restore -U terra -d terra_restore --no-owner < $TERRA_POOL_DIR/backups/<file>.dump

Differences from production, accepted for staging: Temporal is the single-binary dev server on
SQLite (no durability), PostgreSQL has no TLS (same Docker network) and no pgBackRest (daily
`pg_dump` instead), no ClamAV upload scanning (needs ~1.5 GB RAM), media on SeaweedFS instead of
Hetzner Object Storage. Caddy sets the
same header baseline and access-log redaction as production plus `X-Robots-Tag: noindex`, and
answers 404 on `/dev/*` (mock IdP, dev bank), so `MOCK_IDP` cannot be used from the internet.
