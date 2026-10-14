# ADR 0001: Technology stack

- Status: accepted (2026-10-14)
- Context: scope v0.3, section 8; the owner's existing stack (ChatShop) and preference.

## Decision

| Layer | Choice |
|---|---|
| Backend | Go modular monolith (`services/api`): chi, pgx v5, sqlc, goose, oapi-codegen (strict server) |
| Background work | River (queue in PostgreSQL) for jobs, Temporal for long-running business workflows |
| ML side work | Python FastAPI worker (`services/vision`) only for vision and OCR |
| Database | PostgreSQL 17 + PostGIS + pgvector (one database: relational, geo, embeddings, fulltext) |
| Realtime | Centrifugo |
| Web app | SvelteKit 3 (adapter-node), Tailwind 4, Paraglide i18n |
| Marketing / SEO | Astro 7 with Svelte islands, shared `packages/ui` |
| Mobile | Flutter (Riverpod, go_router), generated Dart client |
| Contract | `packages/contracts/openapi.yaml` is the source of truth; Go server, TS and Dart clients are generated |
| LLM | AiStack gateway on DGX Spark (OpenAI-compatible); cloud fallback behind a flag |
| Edge | Caddy |

## Consequences and notes

- `api` and `worker` are two binaries of one Go module (`services/api/cmd/{api,worker,migrate}`), not two
  directories as sketched in the plan. They share all domain code; the plan's `services/worker` is this.
- No Redis at the start: River uses PostgreSQL. Redis may come for map aggregate caching (M3) if needed.
- MinIO no longer publishes container images, so local S3 is SeaweedFS. Production uses Hetzner Object Storage.
- `postgis/postgis` has no arm64 build; our image installs PostGIS and pgvector on `postgres:17` from PGDG.
- `chi/middleware.RealIP` is deprecated (IP spoofing); we resolve client IPs with `httpx.TrustedProxies`.
