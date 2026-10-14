# TerraReality

Rental platform for Central Europe: map search, chat, digital lease with BankID, payment matching.
Start market: Prague. Scope and plan: [docs/01-scope.md](docs/01-scope.md), [docs/02-plan.md](docs/02-plan.md).
Architecture decisions: [docs/ADR](docs/ADR).

## Layout

```
apps/web            SvelteKit 3: search, landlord admin, tenant portal, backoffice
apps/site           Astro 7: landing and SEO pages
apps/mobile         Flutter app
services/api        Go: api, worker (River + Temporal), migrate
services/vision     Python: photo tagging via the Spark LLM gateway (mock without GPU)
packages/contracts  openapi.yaml + generated TS and Dart clients
packages/ui         shared Svelte components and design tokens
infra/dev           docker compose for local dependencies
infra/nas           staging/pilot compose + Caddy
infra/spark         LLM routes for the AiStack gateway
```

## Quick start (macOS)

Requirements: Docker, Go 1.26, Node 24+, Python 3.12+, Flutter 3.44+, Java 17+ (Dart client generator), sqlc.

```bash
make setup   # npm, Go modules, Python venv, Flutter packages, .env
make dev     # docker deps + api :8080 + worker + vision :8001 + web :5173 + site :4321
```

Then open http://localhost:5173 (platform status), http://localhost:8080/healthz,
Temporal UI http://localhost:8233, Mailpit http://localhost:8025.

`make seed` creates dev accounts `staff@terra.local` (backoffice) and `owner@terra.local`, both with
password `terra-dev-password`. Verification e-mails, invitations and the SMS mock land in Mailpit.
Google, Apple and BankID run against a local mock IdP until real credentials are configured.

Mobile: `cd apps/mobile && flutter run` (iOS simulator reaches `localhost:8080`, Android emulator `10.0.2.2:8080`;
override with `--dart-define=API_URL=...`).
Live contract check of the Dart client against a running api:
`cd apps/mobile && flutter test test/live_api_test.dart --dart-define=LIVE_API_URL=http://localhost:8080`.

## Everyday commands

| Command | What it does |
|---|---|
| `make gen` | regenerate Go server stubs, sqlc, TS + Dart clients, Flutter l10n from contracts |
| `make test` | Go (incl. DB integration tests), web, site, Flutter, Python |
| `make lint` | go vet + staticcheck, prettier + eslint, ruff, flutter analyze |
| `make e2e` | Playwright against a running stack |
| `make migrate` | apply goose + River migrations |
| `make images` | build production images |

Without `LLM_BASE_URL` all AI features run in deterministic mock mode.
