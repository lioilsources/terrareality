# Working on TerraReality

Read first: `docs/02-plan.md` (milestones, acceptance criteria, rules), `docs/01-scope.md` (product scope),
`docs/ADR/` (binding decisions).

Hard rules (from the plan, section 0 and 6):
- The platform never holds or forwards money (ADR 0002). No escrow, no crypto, no on-chain code.
- Every AI output is a suggestion approved by a human (ADR 0003). Never auto-publish or auto-reject.
- `packages/contracts/openapi.yaml` is the source of truth. Change it first, then `make gen`. Never edit
  generated files (`services/api/internal/api/gen`, `services/api/internal/db`, `packages/contracts/ts/schema.d.ts`,
  `packages/contracts/dart`).
- Every org-scoped table enables row-level security with the `org_id IN (SELECT app_user_org_ids())`
  policy (ADR 0004); owner-facing code reads and writes through `db.AsUser`.
- Schema changes are new goose migrations in `services/api/migrations`; queries live in `services/api/queries` (sqlc).
- External services only behind adapters with a mock implementation; `make dev` must work offline.
- Legal questions go to `docs/legal-questions.md`, other open questions to `docs/open-questions.md`.
- Each milestone is a branch `m<N>-<slug>`; done means `make test`, `make lint`, `make gen-check` and `make e2e` pass.

Stack notes that differ from common defaults:
- SvelteKit 3: env vars are declared in `apps/web/src/env.ts` (`defineEnvVars`) and imported from
  `$app/env/private` / `$app/env/public`; internal imports use `#lib/...js`.
- Paraglide messages live in `apps/web/messages/{cs,en}.json`; run `npm run i18n -w web` after edits.
- Go money values are `bigint` minor units plus currency; IDs are UUID v7 (`uuid_v7()` in SQL).
