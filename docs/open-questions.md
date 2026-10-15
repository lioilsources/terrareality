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

## M3

- **OQ-11 Administrative boundaries source.** Overpass API was overloaded on 2026-10-14, so dev uses
  outlines derived from address points. Proposal: import RÚIAN VFR boundaries (official, CC-BY) for
  regions, municipalities, MOMC and parts of municipalities via `ogr2ogr` → GeoJSON with properties
  code/level/name/parent → `terractl admin import`. Needs a one-off conversion script (M8).
- **OQ-12 Basemap.** OpenFreeMap (free, no key, OSM data). For production traffic consider
  self-hosted PMTiles of CZ on our object storage. Decide before launch (M8).
- **OQ-13 Embeddings.** See OQ-7: bge-m3 location (Spark resident, CPU sidecar on the app VM, or a
  time window). Until decided, similar listings use the attribute fallback.

## M4

- **OQ-14 Firebase project for push.** Mobile push needs a Firebase project (Android
  `google-services.json`, iOS `GoogleService-Info.plist` plus an APNs key uploaded to Firebase) and a
  service account JSON for the api (`PUSH_PROVIDER=fcm`, `FCM_CREDENTIALS_FILE`). Owner: customer
  (developer accounts). Until then mobile users get e-mail.
- **OQ-15 Transactional e-mail provider** (follows OQ-4). Message notifications raise the volume;
  Postmark or SES via SMTP needs SPF/DKIM on the sending domain before launch.
- **OQ-16 Notification delay.** Push/e-mail wait `MESSAGE_NOTIFY_DELAY` (20 s) so that people who
  are chatting are not disturbed. Tune after launch with real response times.

## M5

- **OQ-17 ISIR usage terms.** The public ISIR_CUZK_WS service is queried by name and birth date
  (`ISIR_MODE=live` outside dev). Confirm that automated checks for a rental platform fit its terms and
  whether a rate limit applies; dev and tests use the mock.
- **OQ-18 Roommate profile visibility.** Profiles are visible to all signed-in users. Alternative:
  only to verified users (phone or BankID) to reduce scraping.

## M6

- **OQ-19 Bank iD SIGN.** Qualified e-signatures need a contract with Bank iD (SIGN product) and its
  API documentation; the `SignatureProvider` interface is ready. Until then leases are signed with the
  simple electronic signature (mock) or on paper. Is a simple signature with evidence acceptable for
  residential leases in the pilot (see Q-LEASE-2)?
- **OQ-20 Proration.** The first and last months are charged in full. Proposal: prorate by days and
  let the landlord override per lease.
- **OQ-21 Open banking provider.** GoCardless Bank Account Data is implemented; confirm the provider is
  still onboarding new customers in CZ (alternatives: Salt Edge, Finbricks) and that the landlord's
  consent flow fits our terms. The mock bank serves dev and E2E.
- **OQ-22 Variable symbol per lease.** One code per lease plus the party's position as the specific
  symbol. Some Czech banks do not pass the specific symbol through PSD2; such payments become
  suggestions.

## Target segments

- **OQ-23 Short-term stays with turnover cleaning (scope §5c.1).** Hosts in Prague serving weekend
  groups need fast cleaning and damage evidence. Validate in phase 0 with 5 short-term property managers:
  a cleaning and handover add-on for hosts, a separate short-term product, or out of scope? It must not
  weaken the long-term core and its relationship with owners' associations.

## Portfolio (M6b)

- **OQ-24 Late payment interest and penalties.** Rules per municipality cover reminders, deposit and
  notice. Statutory late interest (nařízení vlády 351/2013 Sb.) or a contractual penalty would need a
  clause in the templates and a computed ledger item. Wanted for v1?
- **OQ-25 Risk weights and bands.** Default weights and the 25/50 band thresholds are a first guess.
  Calibrate them with the pilot owners' real payment histories before showing scores widely.
- **OQ-26 Market factor quality.** The median rent compares a lease with all listings in the
  municipality regardless of size. Use rent per m² once units carry floor areas consistently?


## Promo and billing (M7)

- **OQ-27 Revolut payment status.** Payment links are created in the landlord's own Revolut merchant
  account, but their status is not synced back. Options: a Revolut webhook per connected merchant, or bank
  matching (M6), which already sees the transfer on the landlord's account. Proposal: rely on bank
  matching in the pilot and add the Revolut webhook in phase 2.
- **OQ-28 Stale pending orders.** An order stays `pending` when the owner abandons checkout or the Stripe
  session cannot be created. Proposal: a worker job marks orders pending longer than 24 h as `failed`
  (Stripe sessions expire within 24 h anyway).
- **OQ-29 Invoice language.** Invoices and the order's listing title are in Czech. Owners using English
  get Czech documents. Proposal: a bilingual (cs/en) invoice template, keeping Czech as the binding text.
- **OQ-30 Refunds and credit notes.** Refunds and opravný daňový doklad (§ 42 ZDPH) are not implemented.
  Proposal: phase 2, issued manually from the backoffice (refund in Stripe, credit note in the same
  numbering series, promotion ended).
