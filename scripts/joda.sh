#!/usr/bin/env bash
# Docker runs on JODA, not on the Mac. Everything that needs it goes through here:
#   joda.sh dev <compose args>     dependencies for `make dev` (project terra-dev, infra/dev, LAN ports)
#   joda.sh deploy qa|prod         full stack from infra/nas (project terra-<profile>, env file
#                                  .env.<profile> next to the compose file on JODA)
#   joda.sh compose qa|prod <args> docker compose of that stack (ps, logs -f api, exec db psql ...)
#   joda.sh images                 build terra/{api,web,vision} on JODA
#   joda.sh restore-test           scripts/restore-test.sh on JODA
#   joda.sh sync                   only mirror the checkout
# The checkout is mirrored to ~/deploy/terrareality with rsync. Secrets (.env.*), data, tunnel
# credentials and site builds exist only on JODA and are never deleted by the mirror.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
JODA=${JODA:-joda}
DIR=deploy/terrareality

# No git, no build output, no mobile app, nothing that lives only on JODA. Excluded paths are not
# deleted on the receiver (rsync --delete leaves excluded files alone).
sync() {
  rsync -a --delete \
    --include '.env.example' --exclude '.env' --exclude '.env.*' \
    --exclude .git --exclude node_modules --exclude .venv --exclude .svelte-kit --exclude .astro \
    --exclude dist --exclude build --exclude __pycache__ --exclude '*.pyc' \
    --exclude /apps/mobile --exclude /docs --exclude /services/api/bin \
    --exclude test-results --exclude playwright-report \
    --exclude /infra/dev/data --exclude /infra/nas/data --exclude /infra/nas/cloudflared \
    --exclude '/infra/nas/site-dist*' \
    "$ROOT"/ "$JODA":$DIR/
}

# A terminal here gets one there (psql, logs -f). Plain strings, not arrays: an empty array
# trips `set -u` in the macOS bash 3.2.
tty_flag() { if [ -t 0 ] && [ -t 1 ]; then echo -t; fi; }

# Runs a command in the mirrored checkout.
remote() {
  # shellcheck disable=SC2046
  ssh $(tty_flag) "$JODA" "cd $DIR && $(printf '%q ' "$@")"
}

profile() {
  case ${1:-} in
    qa|prod) ;;
    *) echo "profile must be qa or prod, got '${1:-}'" >&2; exit 2 ;;
  esac
}

dev() {
  ssh "$JODA" "mkdir -p $DIR/infra"
  rsync -a --delete --exclude data "$ROOT"/infra/dev/ "$JODA":$DIR/infra/dev/
  remote docker compose -p terra-dev -f infra/dev/docker-compose.yml "$@"
}

# docker compose of one full stack: its env file provides COMPOSE_FILE (tunnel) and the values.
compose() {
  local p=$1; shift
  profile "$p"
  # shellcheck disable=SC2046
  ssh $(tty_flag) "$JODA" "cd $DIR/infra/nas && set -a && . ./.env.$p && set +a \
    && SITE_DIST=./site-dist-$p docker compose -p terra-$p --env-file .env.$p $(printf '%q ' "$@")"
}

deploy() {
  local p=$1
  profile "$p"
  sync
  if ! ssh "$JODA" "test -f $DIR/infra/nas/.env.$p"; then
    echo "missing ~/$DIR/infra/nas/.env.$p on $JODA: start from infra/nas/.env.example (infra/nas/README.md)" >&2
    exit 1
  fi
  # The site is built here (Node) for this stack's domains and copied next to the compose file.
  local app api
  read -r app api < <(ssh "$JODA" "set -a; . $DIR/infra/nas/.env.$p; set +a; echo \"\$APP_DOMAIN \$API_DOMAIN\"")
  [ -n "$app" ] && [ -n "$api" ] || { echo "APP_DOMAIN / API_DOMAIN missing in .env.$p" >&2; exit 1; }
  local site_env=
  [ "$p" = prod ] && site_env=SITE_ENV=production
  # shellcheck disable=SC2086
  (cd "$ROOT" && env API_URL="https://$api" PUBLIC_APP_URL="https://$app" $site_env npm run build -w site)
  rsync -a --delete "$ROOT"/apps/site/dist/ "$JODA":$DIR/infra/nas/site-dist-$p/
  ssh "$JODA" bash -s -- "$p" <<'REMOTE'
set -euo pipefail
p=$1
cd ~/deploy/terrareality/infra/nas
# Both stacks on one box must keep their data apart.
other=$([ "$p" = qa ] && echo prod || echo qa)
if [ -f ".env.$other" ]; then
  mine=$(set -a; . "./.env.$p"; echo "${TERRA_DB_DIR:-./data}")
  theirs=$(set -a; . "./.env.$other"; echo "${TERRA_DB_DIR:-./data}")
  [ "$mine" != "$theirs" ] || { echo "TERRA_DB_DIR is '$mine' in both .env.$p and .env.$other" >&2; exit 1; }
fi
set -a; . "./.env.$p"; set +a
export SITE_DIST=./site-dist-$p
docker compose -p "terra-$p" --env-file ".env.$p" up -d --build --remove-orphans
docker compose -p "terra-$p" --env-file ".env.$p" ps --format 'table {{.Name}}\t{{.Status}}'
REMOTE
  echo "deployed terra-$p: https://$api/healthz"
}

images() {
  sync
  local version commit built
  version=$(git -C "$ROOT" describe --tags --always --dirty)
  commit=$(git -C "$ROOT" rev-parse HEAD)
  built=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  remote docker build -f services/api/Dockerfile -t terra/api \
    --build-arg "VERSION=$version" --build-arg "COMMIT=$commit" --build-arg "BUILT_AT=$built" services/api
  remote docker build -f apps/web/Dockerfile -t terra/web .
  remote docker build -t terra/vision services/vision
}

restore_test() {
  sync
  remote scripts/restore-test.sh
}

cmd=${1:-}; shift || true
case $cmd in
  dev) dev "$@" ;;
  deploy) deploy "${1:?profile qa|prod}" ;;
  compose) compose "${1:?profile qa|prod}" "${@:2}" ;;
  images) images ;;
  restore-test) restore_test ;;
  sync) sync ;;
  *) sed -n '2,11p' "$0" >&2; exit 2 ;;
esac
