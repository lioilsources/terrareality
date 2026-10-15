---
title: Privacy policy
version: 2026-10
draft: true
---

> **DRAFT for legal review.** This text is not binding until the operator's lawyer and data protection officer approve it. Values in square brackets must be filled in. The Czech version prevails.

## 1. Controller

The controller is [company name], ID No. [fill in], registered office [address] (the "operator"), e-mail [privacy@terrareality.cz].

Data protection officer (DPO): [name / external DPO], e-mail [dpo@terrareality.cz]. [To confirm whether a DPO is mandatory, see Q-GDPR-6.]

A landlord who manages leases on the platform is a separate controller for their tenants' data; to that extent the operator is the landlord's processor under the data processing agreement that forms part of the landlord terms. [Roles to be confirmed.]

## 2. What we process and why

- **Account:** e-mail, name, password (hash only), language, phone (optional). Purpose: providing the service. Legal basis: contract (Art. 6(1)(b) GDPR).
- **Identity verification via BankID:** name, date of birth, address, verification level. Purpose: trust between parties and concluding a lease. Legal basis: contract and legitimate interest in fraud prevention.
- **Listings, photos, messages, applications, viewings, leases:** content created by users. Purpose: providing the service. Legal basis: contract.
- **Payments and the landlord's bank transactions (read through GoCardless):** counterparty, amount, reference, date. Purpose: matching payments to obligations. Legal basis: contract with the landlord and the landlord's legitimate interest.
- **Lease risk score:** payment behaviour, Tenant Passport facts, location. Purpose: information for the landlord; **it never decides automatically**. Legal basis: the landlord's legitimate interest. [Profiling to be confirmed, see Q-RISK-1.]
- **Billing of paid services:** billing details, card payments (cards are processed by Stripe; the operator never sees card numbers). Legal basis: contract and legal obligation (accounting, VAT).
- **Security and operations:** IP address, browser, sign-in records, audit records, error diagnostics. Legal basis: legitimate interest in security.
- **Consents:** the version of the terms and the policy the user accepted and when. Legal basis: legal obligation to demonstrate consent.

## 3. Artificial intelligence

AI suggestions (texts, attributes from photos, summaries, moderation hints) are computed primarily on the operator's own server (DGX Spark) in the Czech Republic; the data does not leave the operator's infrastructure. If that server is unavailable and the operator enables the fallback mode, individual requests may be processed by a cloud language model provider (Anthropic Claude, through a cloud gateway [fill in gateway operator]) [processing location and third-country transfer to be confirmed, see Q-AI-1]. AI outputs are always suggestions approved by a human.

## 4. Recipients and processors

| Recipient | Role | Purpose | Location |
| --- | --- | --- | --- |
| Hetzner Online GmbH | processor | hosting, database, backups, photo storage | EU (DE/FI) |
| Operator's own DGX Spark server | operator itself | AI computation | CZ |
| Bankovní identita, a.s. (BankID) | separate controller / processor [confirm] | identity verification, signing | CZ |
| GoCardless (Bank Account Data) | processor | reading landlord transactions (AIS) | EU/UK [confirm] |
| Stripe Payments Europe, Ltd. | separate controller / processor | card payments for promotion, subscriptions | EU, USA (SCC) |
| Revolut Bank UAB | separate controller | payment links on the landlord's account | EU |
| E-mail provider [fill in] | processor | sending e-mails | [fill in] |
| Google, Apple | separate controllers | sign-in with Google/Apple, push notifications (Firebase) | EU, USA (DPF/SCC) |
| Sentry [fill in if SaaS] | processor | application error diagnostics | [fill in] |
| Anthropic (AI fallback only) | processor | fallback AI computation | USA (SCC/DPF) [confirm] |
| OpenFreeMap | — | map tiles (receives the browser's IP address) | EU [confirm] |
| Public authorities | separate controllers | where required by law | CZ/EU |

Listing data is public. Applicant data is visible to the landlord of the listing only to the extent the applicant shares it.

## 5. Retention

- Account: while the account exists; erasure runs 30 days after the request (can be cancelled), followed by pseudonymization. [Q-GDPR-2]
- Identity verification data: deleted on erasure unless a lease exists; otherwise kept for the limitation period (3 years after the lease ends). [Q-GDPR-1]
- Messages: 24 months after the last message if they did not lead to a lease. [Q-MSG-1]
- Leases and invoices: 10 years (accounting and tax law).
- Audit and security records: 3 years. [Q-GDPR-5]
- Backups: [fill in, e.g. 30 days], then overwritten.

## 6. Your rights

You have the right of access, rectification, erasure, restriction, data portability (data export in the account settings), the right to object to processing based on legitimate interest and the right not to be subject to a decision based solely on automated processing. Consent can be withdrawn at any time. We handle requests within one month at [privacy@terrareality.cz] or directly in the account settings (export and erasure).

You may lodge a complaint with the Czech Office for Personal Data Protection (www.uoou.cz).

## 7. Security

Data is encrypted in transit (TLS) and sensitive data also at rest; staff access is role-based and audited; backups are encrypted and regularly tested.

## 8. Cookies

We only use strictly necessary cookies, see the [Cookie policy](/cookies).

Effective from: [fill in].
