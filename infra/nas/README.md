# Staging on the NAS

Pilot/staging only. Production runs on Hetzner from milestone M8 (see `docs/02-plan.md`).

1. Create `.env` next to `docker-compose.yml` with:
   `POSTGRES_PASSWORD`, `TERRA_API_DB_PASSWORD`, `CENTRIFUGO_API_KEY`, `CENTRIFUGO_TOKEN_SECRET`,
   `APP_DOMAIN`, `API_DOMAIN`, `SITE_DOMAIN`, `CSP_MEDIA_ORIGINS` (imgproxy and S3 origins the
   browser loads photos/downloads from), optionally `LLM_BASE_URL`
   (AiStack gateway on the Spark over LAN, e.g. `http://192.168.88.66:8080/v1`).
   api and worker connect as `terra_api` (no superuser, no BYPASSRLS, same as production); only
   `migrate` uses the owner `terra`. A new volume gets the role from `initdb/13-api-role.sh`; on an
   existing volume create it once with the SQL in `docs/runbooks/deploy.md` §1.4
   (`docker compose exec -T db psql -U terra -d postgres ...`), then `docker compose up -d`.
2. Build the Astro site and copy it: `npm run build -w site && cp -r apps/site/dist infra/nas/site-dist`.
3. `docker compose up -d --build`. The `migrate` service runs goose + River migrations once before api/worker start.
4. Check `https://$API_DOMAIN/healthz`.

Differences from production, accepted for staging: Temporal is the single-binary dev server on
SQLite (no durability), PostgreSQL has no TLS (same Docker network) and no pgBackRest. Caddy sets the
same header baseline and access-log redaction as production plus `X-Robots-Tag: noindex`, and
answers 404 on `/dev/*` (mock IdP, dev bank), so `MOCK_IDP` cannot be used from the internet.
