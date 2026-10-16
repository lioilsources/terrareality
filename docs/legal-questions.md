# Legal questions for counsel

Implementation follows `jurisdictions` configuration and the proposals below until a lawyer
confirms them (plan, section 6.3). Each item: question, current implementation, owner of the answer.

## CZ jurisdiction seed (M1)

- **Q-CZ-1 Deposit cap.** Seed: `deposit_max_months = 3` (NOZ § 2254). Confirm, including whether
  utilities advances count.
- **Q-CZ-2 Notice period.** Seed: `notice_period_months = 3` (NOZ § 2286–2287, tenant notice for
  indefinite leases). Confirm the default for landlord notice and fixed-term leases.
- **Q-CZ-3 Deposit return.** Seed: `rules.deposit_return_days = 30`. Confirm.
- **Q-CZ-4 Signature.** Seed: `signature_provider = bankid_sign`. Is a qualified electronic signature
  required for a residential lease, or does an advanced signature suffice?

## GDPR (M1)

- **Q-GDPR-1 Retention of identity data after erasure.** On erasure we pseudonymize the account but
  keep `identity_verifications` (name, birthdate, address from BankID) because signed contracts may
  need to identify the parties. Which retention period applies when the user never signed a lease?
  Proposal: delete identity data on erasure unless a contract exists; keep it for the statutory
  limitation period (3 years after the lease ends) otherwise.
- **Q-GDPR-2 Erasure grace period.** We schedule erasure 30 days after the request and allow
  cancellation. Is this compatible with "without undue delay" (art. 17)?
- **Q-GDPR-3 Consent texts and versions.** Terms and privacy policy version `2026-10` are recorded
  in the consent log; the documents themselves are not written yet.
- **Q-GDPR-4 Social sign-up consent.** Users who sign up with Google/Apple accept terms by continuing
  (notice on the sign-in page), recorded with the current version. Is an explicit checkbox required?
- **Q-GDPR-5 Audit log retention.** Audit events keep IP addresses indefinitely. Proposal: 3 years.

## Impersonation (M1)

- **Q-IMP-1** Staff impersonation requires a reason and is audited, but the user is not notified.
  Must the user be informed (notification or entry in their activity)?

## Messaging (M4)

- **Q-MSG-1 Retention of messages.** Conversations are kept while both accounts exist; erasure of one
  party pseudonymizes the sender but keeps the other party's copy. What retention applies to
  conversations that never led to a lease? Proposal: delete 24 months after the last message.
- **Q-MSG-2 Contact masking.** We mask phone numbers, e-mails and bank accounts in messages before a
  lease is signed. Is processing message content for this purpose (and for scam detection) covered
  by legitimate interest, and how must it be described in the privacy policy?
- **Q-MSG-3 Moderation and sanctions.** Staff may remove a message or suspend messaging after a
  report, with an AI suggestion as input (DSA art. 16-17 notice and statement of reasons for
  hosting services?). Which information must the affected user receive?

## Applications and Tenant Passport (M5)

- **Q-APP-1 Insolvency check.** We query ISIR for the applicant themselves, with their consent, and
  show the landlord only "no record" / "record". Is this lawful processing, and must the result expire?
- **Q-APP-2 Income proof.** Landlords can download the uploaded file while an application is open.
  Retention after the application closes? Proposal: delete with the passport on request, and stop
  sharing when the application is closed.
- **Q-APP-3 Anti-discrimination.** Reject reasons come from a fixed list and protected data is not
  collected. Is that sufficient under the anti-discrimination act for the landlord's choice?

## Leases (M6)

- **Q-LEASE-1 Template review.** The four templates in `packages/attributes/templates/cz/` are drafts
  (watermarked) and must be reviewed before M6 acceptance: mandatory terms (sections 2235 et seq. of
  the Civil Code), the deposit clause and interest, joint tenancy (section 2270), house rules and the
  room lease.
- **Q-LEASE-2 Signature level.** Is a simple electronic signature with evidence (IP, time, document
  hash, audit chain) sufficient for a residential lease, or should we require Bank iD SIGN (qualified)?
- **Q-LEASE-3 Immutable event log vs. erasure.** Lease events and the ledger cannot be changed. After
  an erasure request they keep names inside past payloads. Is retention for the limitation period
  (3 years after the lease ends) the right basis, and must payloads avoid personal data?
- **Q-LEASE-4 Landlord's notice.** A landlord's notice (§ 2286 and § 2288–2290 of the Civil Code) must be
  in writing, state a statutory reason and inform the tenant of the right to object and to ask a court to
  review it; the notice period is at least three months. The platform only records the notice (reason,
  optional explanation, delivery date) and shows these requirements as a hint with a confirmation
  checkbox; it does not produce or deliver the written notice. The legal review must confirm the hint and
  reason texts (web `lease_notice_*` messages), whether the platform should generate the written notice
  with the instruction about the court review, and the allowed delivery-date window (30 days back, 7 ahead).

## Portfolio risk (M6b)

- **Q-RISK-1 Profiling.** The lease risk score combines payment behaviour, passport facts and location
  data. It informs the landlord and never decides automatically. Is it profiling under GDPR art. 4(4)
  and 22, which information must tenants get (art. 13–15), and is a DPIA required?

## Short-term stays (scope §5c.1)

- **Q-STR-1 Short-term accommodation rules.** Which obligations apply if hosts use us for stays of a few
  nights (guest registration, local accommodation fee, Prague rules for short-term rentals, consent of the
  owners' association), and do they change our role if we only sell cleaning and handover tools?
- **Q-STR-2 Non-discrimination in marketing.** We plan Arabic-language marketing through travel agencies
  for visitors from the Gulf states. Confirm that language and channel targeting is fine, and that nothing
  in the product may filter or rank guests by nationality or origin.

## Billing and invoices (M7)

- **Q-BILL-1 Invoice particulars.** Promo invoices are issued as a full tax document (§ 29 ZDPH) on the
  payment date (DUZP = card payment date, due date = issue date, "Platební karta – uhrazeno"). Confirm the
  particulars are complete, and whether a simplified tax document (§ 30, up to 10 000 Kč) would be enough for
  consumers who are not VAT payers.
- **Q-BILL-2 Buyers outside CZ.** Landlords in other EU states (SK, PL, ...) buy promotions too. For a buyer
  with a valid VAT ID the place of supply is the buyer's state (reverse charge, VIES check, wording "daň odvede
  zákazník"); for consumers OSS may apply. Until answered, every invoice charges Czech VAT 21 %.
- **Q-BILL-3 Electronic invoices and numbering.** Invoices are sent as a PDF link by e-mail (§ 26 odst. 3:
  buyer consent to electronic documents, e.g. in the terms) and numbered gaplessly per year
  (`TR-YYYY-000001`). Confirm consent in the terms is sufficient and that one series per year is fine.

## Cloud LLM fallback (M8)

- **Q-AI-1 Transfer to a cloud LLM provider.** When the Spark gateway is down and the backoffice flag
  `ai.cloud_fallback` is on (off by default), the API sends the same LLM request to a cloud
  OpenAI-compatible gateway in front of Anthropic Claude (`CLOUD_LLM_BASE_URL`, default model
  `claude-sonnet-5-5`). Payloads are listing texts and owner notes (attribute extraction, text drafts),
  free-text chat search queries, message reports (moderation), application facts (applicant summaries) and
  portfolio facts. There is no PII minimization yet: owner notes, chat queries, reported messages and
  application messages may contain names, phone numbers or other personal data. Questions: is a DPA with
  Anthropic (or the gateway operator) plus SCCs/EU–US DPF enough for this transfer, must the privacy policy
  and the record of processing name the provider, do applicant summaries and moderation need to be excluded
  from the fallback (special categories, Art. 22 GDPR context), and is zero-retention / no-training
  required contractually? Until answered the flag stays off in production; outputs remain suggestions
  approved by a person (ADR 0003) and the served model is recorded with each suggestion and logged.

## Legal texts, cookies and DSA (M8)

Drafts live in `packages/attributes/legal/{cs,en}/` (terms, privacy, cookies, dsa) and are served at
`/podminky`, `/soukromi`, `/cookies`, `/dsa` (+ `/en/...`), marked as drafts. DPAs: `docs/legal/dpa-checklist.md`.

- **Q-LEGAL-1 Review of the drafts.** All four texts need review and the operator's details (company, ID,
  addresses, e-mails, effective date). The Czech version is declared prevailing. The consumer withdrawal
  wording for paid promotion (terms 5.4: 14 days, express request to start performance, proportionate
  price) needs confirming, as does whether landlords using the platform for their leases need a separate
  landlord agreement with a DPA annex (landlord = controller, operator = processor).
- **Q-LEGAL-2 DSA obligations of a small platform.** We publish one single point of contact for authorities
  and users (Art. 11–12, Czech/English), a notice-and-action procedure by e-mail (Art. 16), statements of
  reasons for moderation (Art. 17), human-only removal decisions and an internal complaint route (Art. 20).
  Which of the online-platform obligations (Art. 20–28, 30 trader traceability) apply if we qualify as a
  micro or small enterprise (Art. 19), must we designate a legal representative or register with ČTÚ, and
  is e-mail enough as the Art. 16 mechanism? Since M8 every public listing has a "Nahlásit inzerát" button
  (`POST /v1/listings/{id}/reports`, anonymous allowed) with draft acknowledgement and statement-of-reasons e-mails.
- **Q-LEGAL-3 Re-consent on a new version.** Terms and privacy versions (`TERMS_VERSION`,
  `PRIVACY_VERSION`, currently `2026-10`) are stored in the consent log at sign-up only. When a version is
  bumped, existing users are not asked again; the terms say users are informed 15 days ahead and may leave.
  Is notice enough for B2C users, or do we need active re-acceptance (and for which kinds of change), and
  does the privacy policy need acceptance at all or only acknowledgement?
- **Q-LEGAL-4 Cookie banner scope.** The web sets only strictly necessary cookies (session, MFA, staff
  session, selected organization, post-login return, last order, language `PARAGLIDE_LOCALE`, and
  `terra_consent` recording that the notice was closed). We show an informational notice with a link and a
  dismiss button, no consent choice; analytics is designed to be off by default behind a future toggle.
  Is a notice required or advisable at all under § 89(3) ZEK, does the language cookie count as strictly
  necessary, and does loading map tiles from OpenFreeMap (IP address of the visitor, no cookies) need
  consent or only a mention in the privacy policy? The mobile apps set no cookies.
- **Q-LEGAL-5 Sign-off of the legal texts and consent versions (review V-10).** Before the pilot with real
  users, counsel signs off the four texts in `packages/attributes/legal/{cs,en}/` (terms, privacy, cookies,
  dsa) and the operator's managing director approves them. The sign-off names the version id of each text
  (front matter `version:`, today `2026-10` for all four, Czech and English kept identical) and is recorded
  here with date, reviewer and the git commit of the approved text. Only then is `draft: true` removed from
  the front matter (the web shows a draft banner and `noindex` while it is set). Consent records: the api
  stores `TERMS_VERSION` and `PRIVACY_VERSION` (config, default `2026-10`; set explicitly in the production
  `.env`) in the consent log, and the web takes the accepted version from the front matter, so both must be
  equal to the `version:` of `terms.md` and `privacy.md`. Every change of a text bumps its version in the
  markdown and the matching env variable in the same deploy (`docs/runbooks/deploy.md`), and goes through
  this sign-off again; whether existing users must re-accept is Q-LEGAL-3. Open: who signs off on the
  operator side (managing director or a delegated person), and whether cookies/dsa texts need versioned
  acknowledgement at all. Status: pending, no text is signed off yet.
- **Q-GDPR-6 Data protection officer.** The privacy policy has a DPO contact placeholder. Is a DPO
  mandatory (Art. 37: large-scale regular monitoring through the lease risk score and payment matching?),
  or is a privacy contact enough?
