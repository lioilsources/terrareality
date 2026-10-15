# ADR 0010: Portfolio across municipalities and lease risk

Status: accepted (M6b, 2026-10-15)

## Context

In Czechia one owner (a person, a family, a small company) often has several leases in different
municipalities, each with a different risk. They need one view of the whole portfolio and early warning
where income may drop. The score must be explainable and must never decide about a tenant (ADR 0003,
GDPR art. 22, Q-RISK-1).

## Decisions

1. **Portfolio = organization.** No new tenant of data. A lease knows its place: `leases.admin_path`
   (deepest administrative unit), `lat/lng` and `unit_id`, taken from the listing's address, an optional
   RÚIAN address (`ruian_id` on the lease input) or the municipality named in the free-text address.
   Older leases are located when they are next scored.
2. **Groups** (`portfolio_groups`, `portfolio_group_items`) tag properties (all their units and leases)
   or single leases, e.g. "Brno – investiční". Filters in the dashboard and rent roll use them.
3. **Rules per municipality or group** (`portfolio_rules`) override the jurisdiction defaults: reminder
   days (D-3, D+1, escalation D+7), suggested deposit months (capped by the jurisdiction) and the notice
   period. Group rules win over municipality rules. Resolved rules are copied into `leases.terms.rules`
   when a lease is created or edited; the Temporal workflow reads its reminder stages from the lease
   (`Info.Stages`), so later rule changes never alter signed leases and running workflows replay
   deterministically. Contractual penalties are not part of v0 (OQ-24).
4. **Lease risk v0 is deterministic** (`internal/portfolio/risk.go`, `model_version = risk-v0.1`).
   Ten factors with default weights summing to 100: debt (15), escalations in 12 months (12), days
   overdue (8), debt covered by the paid deposit (15), Tenant Passport (15), fixed term ending within 90
   days (8), notice (8), joint tenancy with a non-payer (4), rent vs. the municipality median from our
   own search data (8) and time on market in the municipality (7). Each factor stores its value 0..1,
   points and the numbers behind it (`lease_risk.factors`). Bands: < 25 low, < 50 medium, else high.
   Organizations may change the weights (normalized to 100; 0 switches a factor off). Missing data
   counts as 0 and is marked `known: false`. Protected characteristics are never inputs (they are not
   collected).
5. **Recompute by polling, not by hooks.** The worker job `lease_risk` runs every minute and rescores
   leases with a new event (payment, escalation, notice …), without a score, older than a day or scored by
   an older model. One snapshot per lease and month (`lease_risk_history`) feeds the 12-month trend. The
   leasing code stays unaware of scoring; an escalation shows in the portfolio within minutes.
6. **Portfolio aggregates** are computed in Go from the rent roll: rent-weighted risk, concentration
   (top municipality, top tenant, the month with most fixed terms ending, HHI over municipalities),
   expected vs. received income this month and per municipality, and an attention list (escalation in
   30 days, debt, ending within 90 days, notice, vacancy, high risk).
7. **Rent roll** lists running leases and vacant units with billed, paid and debt from the leases'
   ledgers as of today (receivable postings), so the CSV/XLSX export reconciles with every ledger.
8. **Roles.** New role `investor` (co-owner, bank, external accountant) has only `portfolio.read`: it
   sees the dashboard and rent roll with tenant initials instead of names, and cannot read leases or
   change anything. Owners and admins have `portfolio.write` (groups, rules, weights); agents,
   accountants and viewers read.
9. **Transparency.** Tenants read the risk row of their own lease (RLS) but the API returns only the
   payment factors (debt, escalations, days overdue, deposit coverage) without score, weights or the
   location and passport factors.
10. **AI summary is a suggestion.** The summary gets aggregates only (no names, addresses or single
    scores), says what changed and suggests steps; it never proposes sanctions or decisions about
    tenants. Without a model (or on error) a rules-based summary is used. Summaries are stored with the
    model and input for audit.

## Consequences

- Currency is the organization's jurisdiction currency; mixed-currency portfolios need conversion
  later (SK uses EUR).
- The market factors are as good as our listing data in the municipality; with fewer than three
  listings they are unknown.
- Q-RISK-1 (profiling, information duties, DPIA) must be answered before scores are shown to
  customers outside the pilot.
