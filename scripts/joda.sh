#!/usr/bin/env bash
# Docker runs on JODA, not on the Mac. Everything that needs it goes through here:
#   joda.sh dev <compose args>     dependencies for `make dev` (project terra-dev, infra/dev, LAN ports)
#   joda.sh deploy qa|prod         full stack from infra/nas: qa = the terra-staging project that
#                                  already runs on JODA (its .env), prod = terra-prod (.env.prod)
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

# The full stacks (infra/nas). qa is the stack that has run on JODA as terra-staging since
# October, with its .env, cloudflared/config.yml and site-dist; prod gets suffixed files.
stack() {
  case ${1:-} in
    qa)   PROJECT=terra-staging; ENVF=.env;      SITE=site-dist ;;
    prod) PROJECT=terra-prod;    ENVF=.env.prod; SITE=site-dist-prod ;;
    *) echo "profile must be qa or prod, got '${1:-}'" >&2; exit 2 ;;
  esac
}

# One line per action in ~/deploy/events.jsonl on JODA (DevConventions infra-architektura.md),
# same keys as the other projects there.
event() {
  local json
  json=$(printf '{"ts":"%s","project":"terrareality","action":"%s","who":"%s@%s","commit":"%s"}' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" "$USER" "$(hostname -s)" "$(git -C "$ROOT" rev-parse --short HEAD)")
  ssh "$JODA" "mkdir -p ~/deploy && printf '%s\n' $(printf %q "$json") >> ~/deploy/events.jsonl"
}

# Ports only on JODA's LAN address; data on the pool dataset once Olin created it (DevConventions
# shared/infra.md: /home/oli/pool-terra), under the mirror until then.
dev() {
  ssh "$JODA" "mkdir -p $DIR/infra"
  rsync -a --delete --exclude data "$ROOT"/infra/dev/ "$JODA":$DIR/infra/dev/
  ssh "$JODA" bash -s -- "$@" <<'REMOTE'
set -euo pipefail
cd ~/deploy/terrareality
if [ -d "$HOME/pool-terra" ]; then
  data=$HOME/pool-terra/dev
else
  data=$PWD/infra/dev/data
  echo "dataset pool/terra is not mounted at $HOME/pool-terra: dev data stays in $data" >&2
fi
DEPS_BIND=$(hostname -I | cut -d' ' -f1) TERRA_DEV_DIR=$data \
  docker compose -p terra-dev -f infra/dev/docker-compose.yml "$@"
REMOTE
  [ "${1:-}" = up ] && event "dev up" || true
}

# docker compose of one full stack: its env file provides COMPOSE_FILE (tunnel) and the values.
compose() {
  local p=$1; shift
  stack "$p"
  # shellcheck disable=SC2046
  ssh $(tty_flag) "$JODA" "cd $DIR/infra/nas && set -a && . ./$ENVF && set +a \
    && SITE_DIST=./$SITE docker compose -p $PROJECT --env-file $ENVF $(printf '%q ' "$@")"
}

deploy() {
  local p=$1
  stack "$p"
  sync
  if ! ssh "$JODA" "test -f $DIR/infra/nas/$ENVF"; then
    echo "missing ~/$DIR/infra/nas/$ENVF on $JODA: start from infra/nas/.env.example (infra/nas/README.md)" >&2
    exit 1
  fi
  # The site is built here (Node) for this stack's domains and copied next to the compose file.
  local app api
  read -r app api < <(ssh "$JODA" "set -a; . $DIR/infra/nas/$ENVF; set +a; echo \"\$APP_DOMAIN \$API_DOMAIN\"")
  [ -n "$app" ] && [ -n "$api" ] || { echo "APP_DOMAIN / API_DOMAIN missing in $ENVF" >&2; exit 1; }
  local site_env=
  [ "$p" = prod ] && site_env=SITE_ENV=production
  # shellcheck disable=SC2086
  (cd "$ROOT" && env API_URL="https://$api" PUBLIC_APP_URL="https://$app" $site_env npm run build -w site)
  rsync -a --delete "$ROOT"/apps/site/dist/ "$JODA":$DIR/infra/nas/$SITE/
  ssh "$JODA" bash -s -- "$PROJECT" "$ENVF" "$SITE" <<'REMOTE'
set -euo pipefail
project=$1 envf=$2 site=$3
cd ~/deploy/terrareality/infra/nas
# Both stacks on one box must keep their data apart.
for other in .env .env.prod; do
  [ "$other" = "$envf" ] || [ ! -f "$other" ] && continue
  mine=$(set -a; . "./$envf"; echo "${TERRA_DB_DIR:-./data}")
  theirs=$(set -a; . "./$other"; echo "${TERRA_DB_DIR:-./data}")
  [ "$mine" != "$theirs" ] || { echo "TERRA_DB_DIR is '$mine' in both $envf and $other" >&2; exit 1; }
done
set -a; . "./$envf"; set +a
export SITE_DIST=./$site
docker compose -p "$project" --env-file "$envf" up -d --build --remove-orphans
docker compose -p "$project" --env-file "$envf" ps --format 'table {{.Name}}\t{{.Status}}'
REMOTE
  event "deploy $p ($PROJECT)"
  echo "deployed $PROJECT: https://$api/healthz"
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
  event "images $version"
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
