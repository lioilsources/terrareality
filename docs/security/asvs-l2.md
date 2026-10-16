# OWASP ASVS 4.0.3 Level 2: TerraReality self-assessment

Status as of M8b (branch `m8b-hardening`, 2026-10-16; M8 baseline on `m8-launch`). This is an engineering self-assessment that groups
the ASVS L2 requirements by chapter and points at evidence in the repository. It is **not** a
penetration test: the pentest before launch is commissioned by the customer (owner) from an external
firm, and its findings are tracked as issues against this document.

Status: **done** (implemented, with evidence) · **partial** (implemented in part or not verified) ·
**todo** (open for launch) · **n/a** (not applicable to this system).

Scope: Go API (`services/api`), SvelteKit web (`apps/web`), Astro site (`apps/site`), Flutter app
(`apps/mobile`), vision service (`services/vision`), Hetzner deployment (`infra/hetzner`). The DGX
Spark LLM gateway is operated by the owner and out of scope (see `infra/spark/README.md`).

## V1 Architecture, design and threat modeling

| Req.        | Topic                                                                   | Status  | Evidence / note                                                                                                                                                                                                                                                                                                                                             |
| ----------- | ----------------------------------------------------------------------- | ------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1.1.1–1.1.2 | Secure SDLC, threat model                                               | partial | Plan and ADRs (`docs/02-plan.md`, `docs/ADR/`); no written threat model yet                                                                                                                                                                                                                                                                                 |
| 1.1.4       | Trust boundaries documented                                             | partial | `docs/01-scope.md`, `infra/spark/README.md`; no data-flow diagram                                                                                                                                                                                                                                                                                           |
| 1.2.x       | Authentication architecture, least-privilege service accounts           | done    | Single API issues sessions (`internal/auth`). DB: owner `terra` only migrates (`MIGRATE_DATABASE_URL`); api/worker log in as `terra_api` IN ROLE `terra_service` (NOSUPERUSER NOBYPASSRLS, no CREATE, explicit `system_all` policy per RLS table, `00012_service_role.sql`); `db.AsUser` drops to `terra_app`; `TestServiceRole`, `TestServiceRolePolicies` |
| 1.4.x       | Access control architecture (single enforcement point, deny by default) | done    | Postgres RLS on every org-scoped table (ADR 0004, `services/api/migrations`), `db.AsUser`                                                                                                                                                                                                                                                                   |
| 1.5.x       | Input/output architecture                                               | done    | OpenAPI contract is the source of truth with request validation (`internal/api/validate.go`)                                                                                                                                                                                                                                                                |
| 1.6.x       | Key management                                                          | partial | `internal/platform/secretbox` keyring (field encryption, key from env), rotation in `docs/runbooks/key-rotation.md`; no KMS/HSM |
| 1.8.x       | Data classification                                                     | partial | GDPR export/erasure (`internal/account/gdpr.go`); no formal classification                                                                                                                                                                                                                                                                                  |
| 1.14.x      | Configuration, segregated components                                    | done    | Env-only config (`internal/platform/config/config.go`), adapters with mocks, separate worker                                                                                                                                                                                                                                                                |

## V2 Authentication

| Req.          | Topic                                            | Status   | Evidence / note                                                                                                                  |
| ------------- | ------------------------------------------------ | -------- | -------------------------------------------------------------------------------------------------------------------------------- |
| 2.1.1         | Password length ≥ 12                             | done     | `Password` schema `minLength: 12` (`packages/contracts/openapi.yaml`), enforced again in `internal/account/login.go` (`checkPassword`) |
| 2.1.2–2.1.6   | Max length ≥ 64, any characters, change password | done     | `maxLength: 200`, no composition rules                                                                                           |
| 2.1.7         | Breached password check                          | done     | Register, reset and change: `internal/platform/pwned` (HIBP range API with k-anonymity + `Add-Padding`, 2 s timeout, fail-open with a log line; embedded offline list for dev/test), `PWNED_PASSWORDS=hibp` in prod, error `password_breached` |
| 2.2.1         | Anti-automation on credential endpoints          | done     | Per-IP and per-address limiters (`internal/api/auth_handlers.go`, `internal/platform/ratelimit`)                                 |
| 2.2.3         | Notify on credential changes                     | partial  | Notification e-mails exist (`internal/notify`); verify coverage for MFA and e-mail change                                        |
| 2.4.1         | Password storage (argon2id)                      | done     | `internal/auth/password.go` (argon2id, PHC format, constant-time verify)                                                         |
| 2.5.x         | Credential recovery                              | done     | Magic link and reset tokens are single-use, hashed (`internal/platform/tokens`)                                                  |
| 2.7.x / 2.8.x | Out-of-band and TOTP MFA                         | done     | `internal/auth/totp.go`, `internal/account/mfa.go`; staff MFA enforced (`STAFF_REQUIRE_MFA`)                                     |
| 2.9.x         | Cryptographic authenticators                     | n/a      |                                                                                                                                  |
| 2.10.x        | Service authentication, no hard-coded secrets    | partial  | Secrets from env; dev defaults exist in `config.go` and must be overridden in prod (checked for Stripe, bank, Revolut, mock IdP) |

## V3 Session management

| Req.  | Topic                                                   | Status  | Evidence / note                                                                                                           |
| ----- | ------------------------------------------------------- | ------- | ------------------------------------------------------------------------------------------------------------------------- |
| 3.1.1 | No session tokens in URLs                               | done    | Opaque token in HttpOnly cookie (web) / secure storage (mobile)                                                           |
| 3.2.x | New token on login, ≥ 64 bits entropy, stored hashed    | done    | `internal/auth/middleware.go`, `internal/platform/tokens/tokens.go` (SHA-256 at rest)                                     |
| 3.3.x | Logout and idle/absolute timeout, revoke other sessions | done    | Sliding TTL (`SESSION_TTL_WEB`, `SESSION_TTL_MOBILE`) capped by absolute lifetime `SESSION_MAX_AGE` (default 30 days from login, `auth.SlidingExpiry` in `internal/auth/middleware.go`) |
| 3.4.x | Cookie attributes (Secure, HttpOnly, SameSite, __Host-) | partial | `apps/web/src/lib/server/session.ts` (HttpOnly, SameSite=Lax, Secure by SvelteKit outside localhost); no `__Host-` prefix |
| 3.5.x | Token-based sessions                                    | done    | Mobile bearer token, server-side revocable                                                                                |
| 3.7.1 | Re-authentication for sensitive operations              | done    | MFA challenge on login; password change requires the current password (`ChangePassword`, `internal/account/login.go`); there is no e-mail change endpoint (address fixed after registration). Setting a first password on a social-login-only account needs only the session |

## V4 Access control

| Req.  | Topic                                 | Status | Evidence / note                                                                                                                                  |
| ----- | ------------------------------------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| 4.1.x | Enforced server-side, deny by default | done   | RLS policies `org_id IN (SELECT app_user_org_ids())` (ADR 0004), `db.AsUser`                                                                     |
| 4.2.1 | IDOR protection                       | done   | RLS plus per-handler ownership checks; integration tests in `internal/integration`                                                               |
| 4.2.2 | CSRF                                  | done   | SvelteKit origin check on form posts; API uses bearer/cookie via server-side web only, CORS allow-list (`internal/platform/httpx/middleware.go`) |
| 4.3.1 | Admin interfaces with MFA             | done   | Backoffice requires staff + MFA (`STAFF_REQUIRE_MFA`)                                                                                            |
| 4.3.2 | Directory browsing, metadata          | done   | No static file serving from the API                                                                                                              |

## V5 Validation, sanitization and encoding

| Req.        | Topic                           | Status  | Evidence / note                                                                                                                            |
| ----------- | ------------------------------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| 5.1.x       | Input validation against schema | done    | OpenAPI request validator (`internal/api/validate.go`), attribute schema validation (`internal/catalog`)                                   |
| 5.2.x       | Sanitization, SSRF              | partial | Outbound URLs are configuration only; no user-supplied URL fetches. Verify imgproxy only serves signed URLs (`internal/media/imgproxy.go`) |
| 5.3.x       | Output encoding, XSS            | done    | Svelte auto-escaping, no `{@html}` in `apps/web/src`; CSP with nonces (see V14)                                                            |
| 5.3.4–5.3.5 | SQL injection                   | done    | sqlc-generated parameterized queries (`services/api/queries`)                                                                              |
| 5.5.x       | Deserialization                 | done    | JSON only, size-limited LLM responses (`internal/ai/fallback.go`)                                                                          |

## V6 Stored cryptography

| Req.  | Topic                                                | Status   | Evidence / note                                                                                                                                               |
| ----- | ---------------------------------------------------- | -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 6.1.x | Data classification and encryption of sensitive data | partial  | `internal/platform/secretbox` for secrets (TOTP, bank tokens); identity documents in S3 rely on bucket encryption, to be confirmed for Hetzner Object Storage |
| 6.2.x | Approved algorithms                                  | done     | argon2id, AES-GCM / NaCl secretbox, SHA-256, HMAC (Centrifugo, Stripe webhooks)                                                                               |
| 6.3.x | Random values                                        | done     | `crypto/rand` for tokens and salts; UUID v7 IDs are not used as secrets                                                                                       |
| 6.4.x | Secret management, key rotation                      | done     | `secretbox` keyring with key ids (`APP_SECRET_KEY` + `APP_SECRET_KEY_PREVIOUS`), `terractl rotate-secrets`, runbook `docs/runbooks/key-rotation.md` (all secrets); no KMS, keys in `.env` |

## V7 Error handling and logging

| Req.  | Topic                                        | Status  | Evidence / note                                                                                                              |
| ----- | -------------------------------------------- | ------- | ---------------------------------------------------------------------------------------------------------------------------- |
| 7.1.x | No sensitive data in logs                    | partial | Structured logs (`internal/platform/logx`, `httpx.AccessLog`) log path, not query or body; Caddy access logs redact query strings and invitation tokens, truncate client IPs to /24 (/48) and drop User-Agent/Referer (`infra/hetzner/compose/Caddyfile`, `(access_log)`); review job error messages for PII |
| 7.2.x | Log authentication and access-control events | done    | Audit events (`internal/account/login.go`, `internal/account/mfa.go`, backoffice actions)                                    |
| 7.3.x | Log protection, time sync                    | partial | Central log shipping in `infra/hetzner/observability`. Retention decided: application logs 30 days, Caddy access logs 14 days (`loki/loki.yml` `retention_stream`); audit trail in the database (`audit_events`). Tamper protection: none beyond host access control (Loki on the app VM) |
| 7.4.x | Generic error messages                       | done    | RFC 9457 problem+json without stack traces (`internal/platform/httpx/problem.go`, `Recover`)                                 |

## V8 Data protection

| Req.  | Topic                                                  | Status  | Evidence / note                                                                                              |
| ----- | ------------------------------------------------------ | ------- | ------------------------------------------------------------------------------------------------------------ |
| 8.1.x | Caching of sensitive data                              | done    | `httpx.NoStore` (`internal/platform/httpx/security.go`): `Cache-Control: no-store` for requests with `Authorization`, `/v1/auth/*` and all non-GET; anonymous public GETs (search, listings) stay cacheable |
| 8.2.x | Client-side data                                       | done    | No tokens in localStorage on web; mobile uses secure storage                                                 |
| 8.3.x | Sensitive private data, GDPR export/erasure, retention | done    | `internal/account/gdpr.go`, `GDPR_ERASURE_GRACE`; open retention questions in `docs/legal-questions.md`      |
| 8.3.x | Data sent to third parties                             | partial | Cloud LLM fallback is off by default and gated by flag `ai.cloud_fallback`; no PII minimization yet (Q-AI-1) |

## V9 Communication

| Req.  | Topic                                 | Status  | Evidence / note                                                                                                                                             |
| ----- | ------------------------------------- | ------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 9.1.x | TLS for all client connectivity, HSTS | done    | TLS termination in Caddy (`infra/hetzner/compose/Caddyfile`, automatic HTTPS, HTTP→HTTPS redirect); HSTS from the API itself (`internal/platform/httpx/security.go`) and from Caddy for web, site and img (`?Strict-Transport-Security`, only when the upstream sent none, so no duplicate headers); the production smoke test asserts HSTS on all three origins |
| 9.2.x | Server-to-server TLS                  | partial | Spark over WireGuard (`infra/hetzner/wireguard`); api, worker and migrate reach PostgreSQL over TLS with `sslmode=verify-full` against an internal CA (`scripts/pg-tls-init.sh`, `DB_SSLMODE`); Temporal → PostgreSQL and container-to-container traffic on the app VM are still plain |

## V10 Malicious code

| Req.   | Topic                            | Status | Evidence / note                                                                                                     |
| ------ | -------------------------------- | ------ | ------------------------------------------------------------------------------------------------------------------- |
| 10.2.x | No back doors, time bombs        | done   | Mock/dev handlers mounted only in dev/test; prod config refuses mock providers (`config.go`)                        |
| 10.3.x | Dependency integrity and updates | done   | `security` CI job: govulncheck, npm audit, pip-audit, osv-scanner (`.github/workflows/ci.yml`); lockfiles committed; Go pinned to `go`/`toolchain` 1.26.9 with patched modules so govulncheck is green; Dependabot for actions, Go, npm, pip, pub, Docker, Terraform (`.github/dependabot.yml`); typst download verified by sha256 (Dockerfile, CI). GitHub Actions are pinned by tag, not by commit SHA (open) |
| 10.3.2 | Subresource integrity            | n/a    | No third-party scripts loaded from CDNs                                                                             |

## V11 Business logic

| Req.   | Topic                                        | Status | Evidence / note                                                                                                          |
| ------ | -------------------------------------------- | ------ | ------------------------------------------------------------------------------------------------------------------------ |
| 11.1.x | Sequential flows, limits on business actions | done   | Rate limits on search, chat search (LLM), applications, messages, webhooks (`internal/api/ratelimit.go`, `RATE_LIMIT_*`) |
| 11.1.x | Anti-automation of costly operations         | done   | LLM work in River jobs, chat search limited per user/IP; AI outputs are suggestions approved by a human (ADR 0003)       |
| 11.1.x | Money                                        | n/a    | Platform never holds or forwards money (ADR 0002); Stripe only for platform services, webhooks signature-checked         |

## V12 Files and resources

| Req.            | Topic                                    | Status  | Evidence / note                                                                                                             |
| --------------- | ---------------------------------------- | ------- | --------------------------------------------------------------------------------------------------------------------------- |
| 12.1.x          | Upload size limits                       | done    | Presigned uploads with content-type allow-list (`openapi.yaml` enums), server-side processing (`internal/listing/media.go`) |
| 12.2.1          | File type validation                     | partial | Declared content type is validated; verify magic-byte sniffing for attachments                                              |
| 12.3.x / 12.4.x | Path traversal, storage outside web root | done    | Object keys generated server-side (UUIDs) in S3, served via presigned URLs or signed imgproxy URLs                          |
| 12.4.2          | Antivirus scanning                       | partial | ClamAV adapter (`internal/media`, `CLAMAV_ADDR`); warning if unset in prod, must be set for launch                          |

## V13 API and web service

| Req.   | Topic                                                       | Status | Evidence / note                                                    |
| ------ | ----------------------------------------------------------- | ------ | ------------------------------------------------------------------ |
| 13.1.x | Same encoding/parsers, admin endpoints protected            | done   | Single OpenAPI contract; backoffice routes require staff           |
| 13.2.x | RESTful method checks, Content-Type validation, JSON schema | done   | chi router with `MethodNotAllowed`, request validator              |
| 13.2.5 | CSRF on REST                                                | done   | Browser never calls the API with cookies directly; CORS allow-list |
| 13.2.6 | Rate limiting / 429                                         | done   | `internal/api/ratelimit.go` (problem+json + `Retry-After`)         |

## V14 Configuration

| Req.          | Topic                                                       | Status  | Evidence / note                                                                                                                                                                                                                                       |
| ------------- | ----------------------------------------------------------- | ------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 14.1.x        | Repeatable, hardened build and deploy                       | partial | Dockerfiles with `.dockerignore` (no `.env`, `node_modules`, local data in build contexts), pinned image tags, build args `VERSION/COMMIT/BUILT_AT` from CI, Terraform (`infra/hetzner/terraform`), CI `permissions: contents: read` and job timeouts; images not signed, no SBOM, actions not SHA-pinned. Hosts: key-only SSH from `admin_cidrs`, `PermitRootLogin no`; the `deploy` user has passwordless sudo and the docker group (effectively root; accepted, no password exists to phish) |
| 14.2.x        | Dependency checks                                           | done    | `security` CI job (govulncheck, npm audit, pip-audit, osv-scanner on `package-lock.json`, `go.mod`, `pubspec.lock`)                                                                                                                                   |
| 14.3.x        | No debug in prod, no version banners                        | done    | `/dev/*` and `/mock/*` only in dev/test; `/v1/version` exposes build info deliberately (review)                                                                                                                                                       |
| 14.4.1        | Content-Type with charset                                   | done    | JSON / problem+json responses                                                                                                                                                                                                                         |
| 14.4.3        | Content-Security-Policy                                     | done    | Web: SvelteKit CSP with nonces (`apps/web/vite.config.ts`) plus runtime origins (`apps/web/src/hooks.server.ts`, `apps/web/src/lib/server/csp.ts`); API: `default-src 'none'; frame-ancestors 'none'` on JSON (`internal/platform/httpx/security.go`) |
| 14.4.4–14.4.7 | nosniff, Referrer-Policy, frame-ancestors / X-Frame-Options | done    | Same files as 14.4.3                                                                                                                                                                                                                                  |
| 14.4.5        | HSTS                                                        | done    | API in prod (2 years, includeSubDomains); web, site and img via Caddy (1 year, includeSubDomains, preload), verified by the production smoke test                                                                                                     |
| 14.5.x        | HTTP request header validation, CORS                        | done    | CORS allow-list (`CORS_ORIGINS`), trusted proxies for client IP (`internal/platform/httpx/clientip.go`)                                                                                                                                               |

## Known deviations

- `style-src 'unsafe-inline'` on the web: Svelte style attributes/transitions and MapLibre require it.
  Scripts are nonce-only.
- Rate limiting is in-process per API instance (`internal/platform/ratelimit`); a shared limiter is
  needed when the API runs on more than one node.

## Launch todos

1. ~~Raise minimum password length to 12 (V2.1.1): contract change first, then `make gen`.~~ Done.
2. ~~Breached-password check on register/reset (V2.1.7).~~ Done: `internal/platform/pwned`, `PWNED_PASSWORDS`
   (also on password change).
3. ~~Key and secret rotation runbook (`APP_SECRET_KEY`, secretbox, webhook and Centrifugo secrets) (V6.4).~~
   Done: `docs/runbooks/key-rotation.md`, secretbox keyring, `terractl rotate-secrets`.
4. ~~`Cache-Control: no-store` on authenticated API responses (V8.1).~~ Done: `httpx.NoStore`.
5. ~~Confirm HSTS and TLS settings on the reverse proxy for web and site (V9.1, V14.4.5).~~ Done in the
   repository (Caddyfile); confirm on production with `make smoke` and SSL Labs (launch checklist).
6. Set `CLAMAV_ADDR` in production and verify magic-byte checks on attachments (V12.2, V12.4.2).
7. ~~Absolute session lifetime and step-up re-authentication for e-mail/password change (V3.3, V3.7).~~
   Done: `SESSION_MAX_AGE`; password change already required the current password; no e-mail change endpoint exists.
8. Log retention and tamper protection in the observability stack (V7.3). Retention done (30 days,
   access logs 14 days); tamper protection still open (owner decision: accept, or ship logs off the VM).
9. Answer Q-AI-1 before switching on `ai.cloud_fallback` in production (V8.3).
10. External penetration test (commissioned by the customer) and remediation of its findings.

Status counts: 0 **todo** rows, 16 partial; 10 launch todos above (6 done).
