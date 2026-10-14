# ADR 0009: Leases, signatures, payment schedule and matching

Status: accepted (M6, 2026-10-15)

## Decisions

1. **Templates in Typst, rendered by the api.** `packages/attributes/templates/cz/*.typ` (fixed term,
   indefinite term, joint tenancy, room) share `_base.typ`; data arrives as JSON (`sys.inputs.data`).
   The output is one PDF with the Czech version first and the English translation after it ("the Czech
   version prevails"). The typst CLI runs with `--ignore-system-fonts`, so documents are identical on
   every machine; templates are embedded into the api by `make gen`. Until the customer's lawyer
   reviews them (`LEASE_TEMPLATES_REVIEWED=true`), every page carries a DRAFT watermark.
2. **Validation from the jurisdiction.** The deposit cap comes from `jurisdictions.deposit_max_months`
   (3 in CZ), fixed-term leases need an end, joint tenancy needs two tenants, the IBAN is checked with
   mod 97, shares add up to 100 % (equal by default).
3. **States and who writes them.** `draft → proposed ⇄ negotiating → signed → active → notice_given →
   terminated → settled` (and `cancelled`). Landlord actions run under RLS; tenant actions (sign,
   request changes, confirm the settlement) run in system context after an RLS access check, because
   lease rows belong to the landlord's organization. Parties invited by e-mail are linked to the
   account with that address when it first opens a lease.
4. **Signatures behind `SignatureProvider`.** Every party signs the latest document; the signature
   stores evidence (document SHA-256, IP, user agent, time) and its hash goes into the event log.
   `mock` is the simple electronic signature used in dev and tests. Bank iD SIGN (qualified signature)
   plugs into the same interface once there is a contract (OQ-19); `upload_scan` is reserved for leases
   signed on paper.
5. **Hash-chained event log.** `lease_events.hash = sha256(prev_hash || canonical_json(payload))` with
   sorted keys and no whitespace; the first `prev_hash` is 32 zero bytes. The app role cannot update or
   delete events (or ledger entries). `GET /v1/leases/{id}/events` returns the log with its
   verification, which is also the export for disputes.
6. **Schedule and ledger.** On the last signature the deposit and one monthly payment (rent plus
   service advances) per month are scheduled; an indefinite lease gets 12 months and the workflow
   extends it. Each item is split between paying parties by share (rounding to the first party). Every
   share is accrued in a double-entry ledger (receivable/income or receivable/deposit_held) on its due
   date; a payment books cash/receivable. The debt is the receivable balance up to today.
7. **QR Platba.** Each open share has an SPD 1.0 payload: landlord's IBAN, amount, `X-VS` = lease
   code (from a sequence, never reused) and `X-SS` = the party's position, so co-tenants' payments are
   told apart. The api also serves it as a PNG.
8. **Matching v0.** Transactions come from the landlord's own account through open banking (read only;
   GoCardless Bank Account Data adapter, mock in dev with `/dev/bank/transactions`). Variable symbol +
   specific symbol + exact amount match automatically; symbol with another amount, or amount and date
   alone, become suggestions the landlord confirms. The landlord can also confirm a payment by hand
   ("přišlo"). The platform never initiates or holds payments (ADR 0002).
9. **Temporal owns time, the database owns state.** `LeaseLifecycle` (one per lease, id `lease-<id>`,
   started by a River job enqueued in the signing transaction) activates the lease on the start date,
   sends reminders at D-3 and D+1 and escalates at D+7 while a share is unpaid, extends indefinite
   schedules and terminates the lease after its last day. It reads state through activities, so manual
   payments and notices need no signals.

## Deviations from the plan

- `payment_schedules` is not a separate table: the schedule is derived from the lease terms.
- Rent and service advances are one monthly payment; partial first and last months are charged in
  full (no proration in v0, OQ-20).
- The Flutter app signs with the mock; the Bank iD SIGN web view follows with the contract (OQ-19).
