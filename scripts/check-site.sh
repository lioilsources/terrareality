#!/usr/bin/env bash
# M3 acceptance: the static site has a page for every municipality with at
# least one listing of each kind. Needs a running api (make dev).
set -euo pipefail
API_URL="${API_URL:-http://localhost:8080}"
cd "$(dirname "$0")/../apps/site"
env -u AI_AGENT -u CLAUDECODE npx astro build >/dev/null
missing=0
for pair in "apartment:pronajem-bytu" "room:pronajem-pokoje"; do
  kind="${pair%%:*}"; dir="${pair##*:}"
  for slug in $(curl -sf "$API_URL/v1/seo/municipalities?kind=$kind" | python3 -c 'import json,sys; print(" ".join(m["slug"] for m in json.load(sys.stdin)))'); do
    if [ ! -f "dist/$dir/$slug/index.html" ]; then echo "missing dist/$dir/$slug"; missing=1; fi
  done
done
[ "$missing" = 0 ] && echo "site: locality pages complete"
exit "$missing"
