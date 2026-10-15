# ADR 0004: Identity, sessions and row-level security

Status: accepted (M1, 2026-10-14)

## Context

M1 needs accounts for private owners and agencies, a mobile app, social login, BankID
verification and strict separation of organizations' data.

## Decisions

1. **Opaque bearer sessions, not JWT.** The api issues a random 256-bit token and stores only its
   SHA-256 (`sessions`). Revocation is immediate (logout, password reset, erasure), lifetime is
   sliding (web 30 days, mobile 90 days). The api accepts only `Authorization: Bearer`.
   - Web: the SvelteKit server keeps the token in an `HttpOnly; SameSite=Lax` cookie on its own
     origin and calls the api server-side (BFF). The browser never sees the token, CSRF is handled
     by SvelteKit's origin check on form actions, and the api needs no cookies or CORS credentials.
   - Mobile: the token lives in secure storage.
2. **Passwords** use argon2id (m=19 MiB, t=2, p=1, OWASP minimum) to stay cheap on a small VM.
   Unknown e-mails burn the same CPU (no timing enumeration); magic link and password reset always
   answer 202.
3. **Second factor** is TOTP (RFC 6238) with replay protection (`totp_last_step`) and ten one-time
   recovery codes (HMAC-hashed). Secrets are sealed with AES-256-GCM under `APP_SECRET_KEY`.
   WebAuthn comes later.
4. **Identity providers** sit behind one adapter (`internal/identity`): generic OIDC for Google,
   Apple (form_post) and BankID (claims from userinfo), plus a mock IdP served by the api in
   dev/test, so `make dev` and E2E tests run offline. The redirect URI must match an allowlist; state
   and nonce are single-use (`auth_tokens`).
5. **Verification level** is a generated column: `none → email → phone → identity`. Features check
   the level instead of individual flags.
6. **Every user owns a personal organization.** A private owner never has to create a company;
   agencies create company organizations and invite members by e-mail. Roles: owner, admin, agent,
   accountant, maintenance, viewer; permissions are a matrix in `internal/org/roles.go`.
7. **Row-level security** protects org-scoped tables. Request handlers read and write org data in a
   transaction that runs `SET LOCAL ROLE terra_app` and sets `app.current_user`; policies limit rows
   to the user's organizations through the `SECURITY DEFINER` function `app_user_org_ids()`.
   The app role cannot read credentials at all (`sessions`, `auth_tokens`, password and TOTP
   columns). Auth flows, jobs and backoffice run as the owner role and authorize in code. Every new
   org-scoped table in later milestones must enable RLS with the same policy.
8. **Impersonation** creates a separate one-hour session that records the staff member
   (`impersonator_id`), requires a reason, is audited on start and end, and cannot change
   credentials, MFA, consents or request erasure. Staff rights never carry into it.
9. **Messages** (e-mail, SMS) are rendered from `internal/notify/messages/{cs,en}.json` and enqueued as
   River jobs in the same transaction (outbox). In dev SMTP goes to Mailpit and the SMS mock is
   delivered there as an e-mail. Completed jobs are kept one hour because they contain one-time links.
10. **GDPR**: export is a JSON file in object storage with a 15-minute presigned link; erasure is
    scheduled after a grace period (default 30 days), pseudonymizes the user and keeps identity
    verification records for contracts (see `docs/legal-questions.md`).

## Consequences

- Sessions need one indexed lookup per request; fine for the expected load.
- The in-process rate limiter is per api instance. A shared limiter is needed with more instances.
- Apple's client secret is a JWT that expires after six months; it is configured as an env value
  and must be rotated (runbook in M8).

## Notes (later changes, 2026-10-16)

- Point 1: the sliding lifetimes (web 30 days, mobile 90 days) are capped by the absolute
  `SESSION_MAX_AGE` (ASVS V3.3.2). It defaults to the longer of the two TTLs; production sets
  `2160h` (90 days), so the mobile lifetime is kept and no session lives longer than that
  regardless of activity.
- Point 7: "auth flows, jobs and backoffice run as the owner role" is superseded by ADR 0012
  point 5: they run as the login role `terra_api` (member of `terra_service`, no superuser, no
  BYPASSRLS) with an explicit `system_all` policy per RLS table; only migrations run as the owner.
  Per-user RLS through `db.AsUser` is unchanged.
