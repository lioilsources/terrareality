# Full stack on JODA: profiles qa and prod

Two stacks from this one compose file, deployed from the Mac with `make deploy PROFILE=qa` and
`make deploy PROFILE=prod` (`scripts/joda.sh deploy`). Each is a compose project `terra-<profile>`
with its own env file `.env.<profile>`, domains, Cloudflare Tunnel, data directories and site
build. `prod` is the production for now; `infra/hetzner` stays the layout for a hosted production
later (`docs/02-plan.md`, M8).

What `make deploy PROFILE=<p>` does: mirrors the checkout to `~/deploy/terrareality` on JODA
(rsync; `.env.*`, `data`, `cloudflared` and site builds there are never touched), builds the Astro
site here for the stack's domains and copies it to `infra/nas/site-dist-<p>`, then runs
`docker compose -p terra-<p> --env-file .env.<p> up -d --build` there. The `migrate` service
runs goose + River migrations once before api/worker start. Afterwards: `make deploy-ps`,
`make deploy-logs`, or anything through `scripts/joda.sh compose <p> …`
(`exec db psql -U terra`, `logs -f caddy`, `down`).

## First deploy of a profile

1. On JODA create `~/deploy/terrareality/infra/nas/.env.<p>` from `.env.example` (`chmod 600`):
   secrets (`openssl rand -hex 32` each), the five domains, `TERRA_DB_DIR`/`TERRA_POOL_DIR`
   (different for qa and prod; the deploy refuses to start a stack whose `TERRA_DB_DIR` equals the
   other profile's), `TERRA_TAG`, optionally mail, `LLM_BASE_URL` (AiStack gateway on the Spark
   over LAN, e.g. `http://192.168.88.66:8080/v1`), `IMGPROXY_URL_TTL`, `SESSION_MAX_AGE`
   (default 2160h), `PHONE_VERIFICATION` (default false), the app-link values `APPLE_TEAM_ID` and
   `ANDROID_CERT_SHA256` (`docs/runbooks/launch.md` §8).
   api and worker connect as `terra_api` (no superuser, no BYPASSRLS, same as Hetzner); only
   `migrate` uses the owner `terra`. A new volume gets the role from `initdb/13-api-role.sh`; on an
   existing volume create it once with the SQL in `docs/runbooks/deploy.md` §1.4
   (`scripts/joda.sh compose <p> exec -T db psql -U terra -d postgres ...`), then deploy again.
   Media and image hosts: `IMG_DOMAIN`, `S3_DOMAIN` (Caddy), with `S3_ENDPOINT=$S3_DOMAIN`,
   `IMGPROXY_URL=https://$IMG_DOMAIN` and `CSP_MEDIA_ORIGINS="https://$IMG_DOMAIN https://$S3_DOMAIN"`.
   The api and web reach the bucket through the public `S3_DOMAIN` too (presigned URLs are signed
   for that host). Data go on the pool disk (DevConventions `shared/infra.md`): dataset `pool/terra`
   mounted at `/home/oli/pool-terra`, the database its own dataset (`recordsize=16k`,
   `compression=lz4`, `atime=off`), e.g. `pool/terra/qa-db` at `/home/oli/pool-terra/qa/db`.
   Olin creates datasets (sudo); until then the directories are plain folders on the pool. A
   snap-installed Docker only sees bind mounts under /home, /media and /mnt.
2. The tunnel for this profile (below): the credentials and `config-<p>.yml` go to
   `infra/nas/cloudflared/` on JODA. Two stacks on one box both need the tunnel (ports 80/443
   can only belong to one of them).
3. `make deploy PROFILE=<p>` from the Mac. Every deploy appends a line to `~/deploy/events.jsonl`.
4. Check `https://$API_DOMAIN/healthz`.

Memory: JODA has 2 cores and 3.8 GB RAM shared with everything else on it; this stack's limits
add up to about 2.6 GB. Run one full stack at a time next to `terra-dev` and stop the other
(`scripts/joda.sh compose <p> stop`; data stay on disk). An older `terra-staging` project may still
be running there: point `.env.qa` at its data directories and stop it before the first
`make deploy PROFILE=qa`.

Slow build on JODA: build the images elsewhere instead (the Dockerfiles cross-compile):
`docker buildx build --platform linux/amd64 -t terra/api:<TERRA_TAG> --load services/api` (likewise
`terra/web` from the repo root with `-f apps/web/Dockerfile`, `terra/vision`, `terra/postgres` from
`infra/dev/postgres`), then `docker save ... | ssh joda docker load` and deploy.

## Behind a Cloudflare Tunnel (no open ports)

`.env.<p>` has `COMPOSE_FILE=docker-compose.yml:docker-compose.tunnel.yml`,
`SITE_SCHEME=http://` and `CLOUDFLARED_CONFIG=config-<p>.yml` (the example does). The
`cloudflared/` directory is shared by both stacks, so each profile has its own tunnel and config
file there. Create the tunnel and one CNAME per host of the profile, then put its config next to
the compose file:

    cloudflared tunnel create terra-<p>
    # An existing ~/.cloudflared/config.yml with `tunnel:` wins over the argument: pass an empty config.
    echo '{}' > /tmp/cf-empty.yml
    for h in $APP_DOMAIN $API_DOMAIN $SITE_DOMAIN $IMG_DOMAIN $S3_DOMAIN; do
      cloudflared --config /tmp/cf-empty.yml tunnel route dns --overwrite-dns <tunnel-id> $h
    done
    mkdir -p cloudflared && cp ~/.cloudflared/<tunnel-id>.json cloudflared/

`cloudflared/config-<p>.yml` sends every host to that stack's Caddy (each stack has its own
compose network, so `caddy` resolves to the right one):

    tunnel: <tunnel-id>
    credentials-file: /etc/cloudflared/<tunnel-id>.json
    ingress:
      - service: http://caddy:80

Cloudflare's free certificate covers one level of subdomains only (`*.example.com`), so use names
like `terra-qa-api.example.com`, not `api.qa.example.com`.

## Backups

The `backup` service writes `pg_dump -Fc` to `$TERRA_POOL_DIR/backups` once a day and keeps
`BACKUP_KEEP_DAYS` (14). The media bucket lives on the same disk; copy both off JODA for a real
second copy. Restore into a scratch database (`scripts/joda.sh compose <p> exec -T db ...`):

    createdb -U terra terra_restore
    pg_restore -U terra -d terra_restore --no-owner < $TERRA_POOL_DIR/backups/<file>.dump

Differences from the Hetzner layout, accepted here: Temporal is the single-binary dev server on
SQLite (no durability), PostgreSQL has no TLS (same Docker network) and no pgBackRest (daily
`pg_dump` instead), no ClamAV upload scanning (needs ~1.5 GB RAM), media on SeaweedFS instead of
Hetzner Object Storage. Caddy sets the same header baseline and access-log redaction plus
`X-Robots-Tag: noindex`, and answers 404 on `/dev/*` (mock IdP, dev bank), so `MOCK_IDP` cannot be
used from the internet.
