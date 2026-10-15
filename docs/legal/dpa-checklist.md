# Data processing agreements (DPA) checklist

Status of the agreements needed before launch (plan M8, "DPA s partnery"). Nothing is signed by the
engineering team; the customer's legal owner signs and files the documents. The list mirrors the
recipients table in the privacy policy (`packages/attributes/legal/{cs,en}/privacy.md`); keep both in sync.

| Partner | Our role / their role | Document to obtain | Transfer outside EEA | Status |
| --- | --- | --- | --- | --- |
| Hetzner Online GmbH (hosting, object storage, backups) | controller / processor | Hetzner DPA (Art. 28, signed in Hetzner console) | no (DE/FI) | open |
| Bankovní identita, a.s. (BankID: identity, signing) | controller / processor or separate controller | BankID service agreement + DPA; confirm role | no | open |
| GoCardless Bank Account Data (AIS, landlord transactions) | controller / processor | GoCardless DPA + end-user agreement for AIS consent | check UK (adequacy) | open |
| Stripe Payments Europe (card payments, invoices) | separate controllers + processor for billing data | Stripe DPA (part of Stripe Services Agreement), SCC for US sub-processors | yes (US, SCC/DPF) | open |
| Revolut Business Merchant (payment links on landlord accounts) | separate controllers (landlord's merchant account) | Revolut merchant terms; confirm we act only via landlord's API key | no (LT) | open |
| E-mail delivery provider [to choose] | controller / processor | provider DPA | depends on provider | open |
| Google (Sign in with Google, Firebase Cloud Messaging) | separate controller (sign-in), processor (FCM) | Google Cloud / Firebase data processing terms | yes (US, DPF/SCC) | open |
| Apple (Sign in with Apple, APNs) | separate controller | Apple developer agreement (no separate DPA) | yes (US) | open |
| Sentry (error tracking, if SaaS rather than self-hosted) | controller / processor | Sentry DPA, EU data region | yes unless EU region | open |
| Anthropic (cloud LLM fallback behind `ai.cloud_fallback`, off by default) | controller / processor | Anthropic commercial terms + DPA, zero data retention option, SCC | yes (US) | open, required before the flag is enabled in production |
| DGX Spark (own hardware of the owner, AI inference) | controller (owner) / service agreement with the hardware owner if a separate legal entity | internal agreement or DPA if the owner is a different entity | no (CZ) | open |
| OpenFreeMap (map tiles, receives IP) | no personal data agreement offered | assess: self-host tiles or accept as independent recipient | check | open |
| Landlords using the platform for their leases | landlord = controller, operator = processor | DPA as an annex to the landlord terms (template to be drafted by counsel) | no | open |

Before launch:

- [ ] every row "signed" or consciously accepted by counsel with a note,
- [ ] record of processing activities (Art. 30 GDPR) updated with the same list,
- [ ] DPIA for the lease risk score (Q-RISK-1) and identity verification decided,
- [ ] sub-processor list published with the privacy policy.
