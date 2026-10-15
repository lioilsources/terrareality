# ADR 0011: Paid promotion, invoices and Revolut payment links

Status: accepted (M7, 2026-10-15)

## Context

TerraReality earns money by selling services to owners, first paid promotion of listings: top placement
(topování), a visual highlight (zvýraznění) and a bundle of both, for 7 or 30 days. The platform must take
card payments for its own services and issue Czech tax documents, without ever touching rent or deposits
(ADR 0002). Owners also asked for a card payment option for rent next to the SPAYD QR code; that money must
go straight to the landlord. Search ranking changes must stay transparent to tenants, and the backoffice
needs tools to run all this (flags, catalog, metrics) while AI output stays a suggestion (ADR 0003).

## Decisions

1. **Stripe Checkout only for platform services.** The owner pays promotions by card in Stripe Checkout.
   Stripe never sees tenants' money; rent, deposits and service charges keep going tenant → landlord
   (ADR 0002). Stripe sits behind the adapter `billing.StripeClient` (`CreateCheckout`, `ParseWebhook`)
   with `NewStripeHTTP` for live and `NewMockStripe` for dev and tests (a hosted mock checkout page served by
   the API that delivers a signed webhook). `STRIPE_MODE` is `mock` by default without a key and is refused
   in prod.
2. **The signed webhook is the only source of payment truth.** `POST /v1/webhooks/stripe` verifies the
   `Stripe-Signature` (`STRIPE_WEBHOOK_SECRET`); the success redirect is cosmetic. An order stays `pending`
   until `checkout.session.completed` arrives; `checkout.session.expired` marks it `failed`.
3. **Idempotency.** Every event ID is inserted into `stripe_events` first (a duplicate inserts 0 rows and
   is acknowledged). Order transitions only run from `pending` (`MarkOrderPaidBySession` returns no row on
   repeat) and `CreatePromotion` is a no-op on repeat.
4. **One transaction for the paid flow.** Marking the order paid, creating the promotion rows, updating the
   search row and issuing the invoice (number and record) run in one system transaction (`db.InTx`, no
   user, RLS bypass as for other background work). Any failure rolls back everything including the
   `stripe_events` row, so Stripe's retry processes the event again.
5. **Promotions are time windows.** A purchase may start now or at a scheduled `starts_at`; the `promotions`
   rows hold `[starts_at, ends_at)` per kind (`top`, `highlight`; a bundle creates both). The current
   effect is denormalized to `listing_search.boosted_until` / `highlighted_until` so search needs no join.
   A worker job every 5 minutes (`PromoRecomputeArgs`, `RecomputeAllListingPromos`) refreshes these columns so
   scheduled promotions start and expired ones end without a request.
6. **Ordering rule and transparency.** The default and relevance sorts put currently boosted listings first
   (`boosted_until > now()` DESC), then the existing order. Explicit sorts chosen by the user (price,
   newest, ...) are kept as they are; promotion never overrides what the user asked for. Every boosted card
   carries `promoted: true` and the web always shows the label „Topováno“ / „Promoted“, in every sort;
   highlighted cards carry `highlighted: true`.
7. **Invoices are full tax documents (daňový doklad).** Numbers are gapless per calendar year,
   `TR-YYYY-NNNNNN`, taken from `invoice_counters` in the same transaction that inserts the invoice, so a
   rollback never burns a number. Catalog prices are net minor units in CZK; VAT 21 % (`vat_rate_bp = 2100`)
   is computed per line with half-up rounding (`billing.ComputeVAT`). Supplier particulars come from config
   (`PLATFORM_LEGAL_NAME`, `PLATFORM_ICO`, `PLATFORM_DIC`, `PLATFORM_ADDRESS`, `PLATFORM_IBAN`).
8. **Invoice PDF and delivery are asynchronous.** After commit a job renders the PDF with Typst
   (`InvoiceRenderer`, `TYPST_BIN`), stores it in object storage and sends the buyer an e-mail through the
   notify outbox with a link to `GET /v1/orgs/{orgId}/invoices/{invoiceId}/pdf` (the outbox has no
   attachments yet). A rendering failure never undoes the payment.
9. **Revolut payment links are landlord-direct.** The landlord connects their own Revolut Business merchant
   API key (`org_revolut_accounts`, encrypted with secretbox like other secrets, `sandbox` or `live`). For
   one obligation share the owner or the tenant of that share creates a payment link, which is an order in
   the landlord's own merchant account; money never passes the platform. It is the second option after the
   SPAYD QR code. Adapter `billing.RevolutMerchant` with `NewRevolutHTTP` and `NewMockRevolut` (a mock pay page
   served by the API); gated by the feature flag `payments.revolut`.
10. **Feature flags live in a table.** `feature_flags` replaces `Config.Flags` as the source; `flags.Store`
    caches the rows in process for 30 s and drops the cache on write, so other processes see a change within
    the TTL. Keys without a row fall back to the config defaults and `FEATURE_FLAGS`. Flags are edited in the
    backoffice and every change is audited.
11. **Backoffice additions.** Metrics dashboard, feature flags,
    promo product catalog (create, edit, deactivate; orders copy price, kind and duration so later changes do
    not alter paid orders), contract template overview with preview, and an AI attribute suggestion queue:
    new attribute keys the AI proposes are stored in `attribute_suggestions`; approve or reject records the
    decision only and never changes the catalog or filter schema by itself (ADR 0003).

## Consequences

- Revolut payment status is not synced yet; a paid link is recognised through bank matching from M6 like
  any other transfer (OQ-27).
- A Stripe session that fails to be created leaves its order `pending`; stale pending orders are not yet
  cleaned up (OQ-28).
- The order's listing title is shown in Czech; invoices are Czech only (OQ-29).
- Refunds and credit notes (opravný daňový doklad) are not implemented (OQ-30).
- Every invoice charges Czech VAT 21 %; reverse charge for EU VAT payers and OSS for EU consumers are not
  handled until Q-BILL-1..3 are answered.
