#!/usr/bin/env bash
# Starts the whole local stack: docker deps, Go api + worker, Python vision,
# SvelteKit web and Astro site. Ctrl+C stops everything.
# Offline: works without network once `make setup` ran and the Docker images (infra/dev) were
# pulled/built at least once; external services are mocks. Only the search map needs the network
# (MAP_STYLE defaults to OpenFreeMap tiles); offline the map stays empty, search still works.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

[ -f .env ] || cp .env.example .env
set -a; source .env; set +a

docker compose -f infra/dev/docker-compose.yml up -d --build --wait db centrifugo mailpit
docker compose -f infra/dev/docker-compose.yml up -d temporal s3 imgproxy

pids=()
cleanup() { echo; echo "stopping..."; kill "${pids[@]}" 2>/dev/null || true; wait 2>/dev/null || true; }
trap cleanup EXIT INT TERM

prefix() { local name=$1; shift; ( "$@" 2>&1 | sed -u "s/^/[$name] /" ) & pids+=($!); }

prefix api    bash -c "cd services/api && go run ./cmd/api"
prefix worker bash -c "cd services/api && go run ./cmd/worker"
if [ -x services/vision/.venv/bin/uvicorn ]; then
  prefix vision bash -c "cd services/vision && .venv/bin/uvicorn vision.main:app --port 8001 --reload"
else
  echo "[vision] skipped: run 'make setup' first"
fi
prefix web    npm run dev -w web -- --port 5173
# Astro 7 detaches into background mode when it detects an AI agent environment;
# keep it in the foreground so Ctrl+C stops it with everything else.
prefix site   env -u AI_AGENT -u CLAUDECODE npm run dev -w site -- --port 4321

echo "api http://localhost:8080/healthz | web http://localhost:5173 | site http://localhost:4321 | temporal http://localhost:8233 | mail http://localhost:8025"
wait
