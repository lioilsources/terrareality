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

