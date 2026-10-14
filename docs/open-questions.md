# Open questions

Questions that the scope and plan do not answer. Each has a proposed answer that the implementation
follows until decided otherwise.

## M1

- **OQ-1 BankID contract and scopes.** Real BankID needs a contract with Bankovní identita, a.s.
  and sandbox credentials. Implemented scopes: `openid profile.name profile.birthdate
  profile.addresses` via the userinfo endpoint; mapping verified only against the mock.
  Proposal: request sandbox access before M6 (signing).
- **OQ-2 Apple sign-in.** Needs an Apple Developer account, a Services ID and a key; the client
  secret JWT is configured as env and rotated every 6 months. Proposal: set up together with the
  App Store account in M8.
- **OQ-3 SMS provider.** Phone verification uses a mock that delivers to Mailpit. Proposal: a CZ
  provider (e.g. GoSMS or SMSbrána) behind `notify.Sender` before launch.
- **OQ-4 Transactional e-mail.** Proposal: Postmark or Amazon SES (EU region) via SMTP settings.
- **OQ-5 Staff MFA.** `STAFF_REQUIRE_MFA` defaults to true outside dev/test. Proposal: keep, and
  add WebAuthn for staff in phase 2.
- **OQ-6 Flutter sign-in screens.** The api supports bearer sessions for mobile; the Flutter login
  flow is scheduled with the other mobile screens (plan section 6.1: after the contract is stable).

## M2

- **OQ-7 Spark routes.** Resolved with the AiStack operator: chat/JSON uses `openclaw-default`
  (verified live 2026-10-14). Embeddings (`shop-embed`/bge-m3) and vision (`vl`) are not running;
  the owner decides whether to run them resident, as a CPU sidecar or in a time window. Until then
  embeddings and vision stay off/mock (infra/spark/README.md).
- **OQ-8 RÚIAN import.** Dev and tests use a 26-address synthetic sample. The full CZ data set
  (about 3 million address points, ZIP of per-municipality CSVs from ČÚZK) is imported with
  `terractl ruian import <file.zip>`; schedule a monthly refresh job in M3.
- **OQ-9 ClamAV.** Scanning is skipped when `CLAMAV_ADDR` is empty (a warning is logged in prod).
  Proposal: run clamd as a sidecar on the production VM (about 1 GB RAM for signatures).
- **OQ-10 Removed photos of published listings** stay in storage until the next approved version;
  a cleanup job comes with M3 search.
