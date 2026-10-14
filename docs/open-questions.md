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
