# Staging on the NAS

Pilot/staging only. Production runs on Hetzner from milestone M8 (see `docs/02-plan.md`).

1. Create `.env` next to `docker-compose.yml` with:
   `POSTGRES_PASSWORD`, `CENTRIFUGO_API_KEY`, `CENTRIFUGO_TOKEN_SECRET`,
   `APP_DOMAIN`, `API_DOMAIN`, `SITE_DOMAIN`, optionally `LLM_BASE_URL`
   (AiStack gateway on the Spark over LAN, e.g. `http://192.168.88.66:8080/v1`).
2. Build the Astro site and copy it: `npm run build -w site && cp -r apps/site/dist infra/nas/site-dist`.
3. `docker compose up -d --build`. The `migrate` service runs goose + River migrations once before api/worker start.
4. Check `https://$API_DOMAIN/healthz`.
