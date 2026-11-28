# ADR 0013: Shared platform kit (ol1n_platform_kit)

Status: accepted (K1a, 2026-11-27)

## Context

MegaJob, a second product with the same owner and stack, needs the same platform pieces as TerraReality:
- row-level security per organization (ADR 0004);
- the audit log;
- feature flags;
- notifications, storage, realtime, RÚIAN and Typst documents.

Copying them would fork two copies of security-relevant code. The pieces move to a separate Go module, `github.com/lioilsources/ol1n_platform_kit`, which both apps import. The kit's own ADR 0001 has the full design.

## Decision

- **Identity stays in TerraReality.** `users`, `organizations`, `memberships`, `uuid_v7()`, `app_current_user()` and `app_user_org_ids()` stay here. The kit only requires them, as a contract.
- **Kit tables keep their names and columns.** The kit carries its own goose history (`ol1n_kit_schema_version`) of idempotent migrations. `platform/db.Migrate` runs it after TerraReality's migrations. Here it is a no-op, because TerraReality's own history created `audit_events` and `feature_flags`. No data moves.
- **Changes to kit tables go through kit migrations only**, never through a TerraReality migration.
- **K1a moves four pieces to the kit:**
  - `platform/db`: `InTx`, `AsUser` and `Elevate` delegate to `tenancy` with role `terra_app`;
  - `audit`: event building;
  - `flags`;
  - the request principal and metadata (`auth.WithPrincipal` and `auth.WithMeta` also fill the kit's `principal` context).
- **Thin shims keep the call sites.** `internal/audit.Record` keeps its `db.Querier` signature, so its 95 callers are unchanged. It builds the row in the kit and inserts it through TerraReality's own sqlc query (the field sets are identical). `internal/flags` aliases the kit store and keeps the built-in descriptions and the API error mapping.
- **The kit version is pinned in `go.mod`.** For local development, `go.work` points at a kit checkout. `go.work` is not committed.

## Consequences

- Later cuts follow the same pattern, one PR each: K1b `notify`, K1c `storage` and `realtime`, K1d `ruian` and `typstdoc`. K2 (payments) and K3 (billing, scoring) come before MegaJob phase 4.
- A kit release must not raise TerraReality's dependency versions (pgx, goose, `golang.org/x/*`).
