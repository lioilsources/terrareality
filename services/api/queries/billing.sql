-- M7: promo catalog, orders, promotions, invoices, Revolut payment links and
-- Stripe webhook idempotency. Owner-facing reads and writes run through
-- db.AsUser; webhook processing runs in system context (db.InTx).

-- ---------------------------------------------------------------------------
-- Promo catalog.

-- name: ListPromoProducts :many
SELECT * FROM promo_products
WHERE active OR sqlc.arg(include_inactive)::boolean
ORDER BY active DESC, kind, duration_days, net_amount;

-- name: GetPromoProduct :one
SELECT * FROM promo_products WHERE id = $1;

-- name: GetActivePromoProductByCode :one
SELECT * FROM promo_products WHERE code = $1 AND active;

-- name: CreatePromoProduct :one
INSERT INTO promo_products (code, kind, duration_days, net_amount, currency, vat_rate_bp, name, active)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *;

-- name: UpdatePromoProduct :one
UPDATE promo_products SET
  net_amount = coalesce(sqlc.narg(net_amount), net_amount),
  active = coalesce(sqlc.narg(active), active),
  name = coalesce(sqlc.narg(name), name),
  duration_days = coalesce(sqlc.narg(duration_days), duration_days)
WHERE id = sqlc.arg(id) RETURNING *;

-- ---------------------------------------------------------------------------
-- Orders.

-- name: CreateOrder :one
INSERT INTO orders (org_id, listing_id, product_id, kind, duration_days, created_by, net_amount, vat_amount,
  gross_amount, currency, vat_rate_bp, starts_at)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12) RETURNING *;

-- name: SetOrderSession :exec
UPDATE orders SET stripe_session_id = $2 WHERE id = $1 AND status = 'pending';

-- name: GetOrder :one
SELECT o.*, p.code AS product_code, l.title AS listing_title, i.id AS invoice_id
FROM orders o
JOIN promo_products p ON p.id = o.product_id
JOIN listings l ON l.id = o.listing_id
LEFT JOIN invoices i ON i.order_id = o.id
WHERE o.id = $1 AND o.org_id = $2;

-- name: ListOrders :many
SELECT o.*, p.code AS product_code, l.title AS listing_title, i.id AS invoice_id
FROM orders o
JOIN promo_products p ON p.id = o.product_id
JOIN listings l ON l.id = o.listing_id
LEFT JOIN invoices i ON i.order_id = o.id
WHERE o.org_id = $1
ORDER BY o.created_at DESC
LIMIT 500;

-- name: SystemGetOrderBySession :one
SELECT * FROM orders WHERE stripe_session_id = $1;

-- name: MarkOrderPaidBySession :one
-- Idempotent: only a pending order flips to paid; a repeated webhook gets no
-- row (pgx.ErrNoRows) and must not create promotions or invoices again.
UPDATE orders SET status = 'paid', paid_at = now()
WHERE stripe_session_id = $1 AND status = 'pending'
RETURNING *;

-- name: SetOrderStatusBySession :execrows
-- Failed or canceled checkout; never touches a paid order.
UPDATE orders SET status = sqlc.arg(status)
WHERE stripe_session_id = sqlc.arg(stripe_session_id) AND status = 'pending';

-- ---------------------------------------------------------------------------
-- Promotions.

-- name: CreatePromotion :exec
INSERT INTO promotions (org_id, listing_id, order_id, kind, starts_at, ends_at)
VALUES ($1, $2, $3, $4, $5, $6)
ON CONFLICT (order_id, kind) DO NOTHING;

-- name: PromotionEndOf :one
-- Where a new period of this kind starts: after the latest one that is still
-- running or scheduled, or at the requested start (purchases extend, not overlap).
SELECT greatest(sqlc.arg(starts_at)::timestamptz,
  coalesce(max(ends_at), sqlc.arg(starts_at)::timestamptz))::timestamptz AS starts_at
FROM promotions WHERE listing_id = sqlc.arg(listing_id) AND kind = sqlc.arg(kind) AND ends_at > now();

-- name: ListListingPromotions :many
SELECT p.*, (p.starts_at <= now() AND p.ends_at > now())::boolean AS active
FROM promotions p
WHERE p.listing_id = $1 AND p.org_id = $2
ORDER BY p.starts_at DESC;

-- name: RecomputeListingPromo :exec
-- Denormalize the running promotion windows of one listing onto its search row.
-- @at is the caller's clock: now() is the transaction start, which can precede
-- a promotion that starts at payment time inside the same transaction.
UPDATE listing_search s SET
  boosted_until = (SELECT max(p.ends_at) FROM promotions p
    WHERE p.listing_id = s.listing_id AND p.kind = 'top' AND p.starts_at <= sqlc.arg(at)::timestamptz AND p.ends_at > sqlc.arg(at)::timestamptz),
  highlighted_until = (SELECT max(p.ends_at) FROM promotions p
    WHERE p.listing_id = s.listing_id AND p.kind = 'highlight' AND p.starts_at <= sqlc.arg(at)::timestamptz AND p.ends_at > sqlc.arg(at)::timestamptz)
WHERE s.listing_id = sqlc.arg(listing_id);

-- name: RecomputeAllListingPromos :execrows
-- Periodic job: starts scheduled promotions, clears expired ones. Touches only
-- rows whose value changes.
WITH w AS (
  SELECT s.listing_id,
    (SELECT max(p.ends_at) FROM promotions p
      WHERE p.listing_id = s.listing_id AND p.kind = 'top' AND p.starts_at <= now() AND p.ends_at > now()) AS boosted,
    (SELECT max(p.ends_at) FROM promotions p
      WHERE p.listing_id = s.listing_id AND p.kind = 'highlight' AND p.starts_at <= now() AND p.ends_at > now()) AS highlighted
  FROM listing_search s
  WHERE s.boosted_until IS NOT NULL OR s.highlighted_until IS NOT NULL
    OR EXISTS (SELECT 1 FROM promotions p WHERE p.listing_id = s.listing_id AND p.starts_at <= now() AND p.ends_at > now())
)
UPDATE listing_search s SET boosted_until = w.boosted, highlighted_until = w.highlighted
FROM w
WHERE s.listing_id = w.listing_id
  AND (s.boosted_until IS DISTINCT FROM w.boosted OR s.highlighted_until IS DISTINCT FROM w.highlighted);

-- ---------------------------------------------------------------------------
-- Invoices.

-- name: NextInvoiceNumber :one
-- Gapless per year when called in the same transaction as CreateInvoice.
INSERT INTO invoice_counters (year, last) VALUES ($1, 1)
ON CONFLICT (year) DO UPDATE SET last = invoice_counters.last + 1
RETURNING last;

-- name: CreateInvoice :one
INSERT INTO invoices (org_id, order_id, number, issued_on, taxable_supply_on, net_amount, vat_amount, gross_amount,
  currency, vat_rate_bp, buyer, supplier)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12) RETURNING *;

-- name: GetInvoice :one
SELECT * FROM invoices WHERE id = $1 AND org_id = $2;

-- name: SystemGetInvoice :one
SELECT * FROM invoices WHERE id = $1;

-- name: GetInvoiceByOrder :one
SELECT * FROM invoices WHERE order_id = $1;

-- name: ListInvoices :many
SELECT * FROM invoices WHERE org_id = $1 ORDER BY issued_on DESC, number DESC LIMIT 500;

-- name: SetInvoicePdfKey :exec
UPDATE invoices SET pdf_key = $2 WHERE id = $1;

-- name: MarkInvoiceSent :exec
UPDATE invoices SET sent_at = now() WHERE id = $1 AND sent_at IS NULL;

-- name: InvoiceBuyer :one
-- Buyer data for the invoice (system context): the organization and the
-- person who ordered.
SELECT o.id, o.kind, o.name, o.registration_no, o.vat_no, o.jurisdiction_code, coalesce(u.email, '')::text AS email,
  coalesce(u.locale, 'cs')::text AS locale, coalesce(u.display_name, '')::text AS display_name
FROM organizations o
LEFT JOIN users u ON u.id = sqlc.narg(user_id)
WHERE o.id = sqlc.arg(org_id);

-- ---------------------------------------------------------------------------
-- Revolut Business merchant account of the landlord.

-- name: UpsertRevolutAccount :one
INSERT INTO org_revolut_accounts (org_id, api_key_enc, mode, connected_by)
VALUES ($1, $2, $3, $4)
ON CONFLICT (org_id) DO UPDATE SET api_key_enc = EXCLUDED.api_key_enc, mode = EXCLUDED.mode,
  connected_at = now(), connected_by = EXCLUDED.connected_by
RETURNING *;

-- name: GetRevolutAccount :one
SELECT * FROM org_revolut_accounts WHERE org_id = $1;

-- name: DeleteRevolutAccount :execrows
DELETE FROM org_revolut_accounts WHERE org_id = $1;

-- ---------------------------------------------------------------------------
-- Payment links (landlord-direct).

-- name: GetShareForPaymentLink :one
-- The share with what a payment link needs; the caller checks who asks.
SELECT s.id, s.org_id, s.lease_id, s.party_id, s.amount, s.paid_amount, o.currency, o.kind, o.period, o.due_on,
  o.status AS obligation_status, p.user_id AS party_user_id, p.name AS party_name, p.position AS party_position
FROM obligation_splits s
JOIN payment_obligations o ON o.id = s.obligation_id
JOIN lease_parties p ON p.id = s.party_id
WHERE s.id = $1;

-- name: CreatePaymentLink :one
INSERT INTO payment_links (org_id, lease_id, share_id, provider, external_id, url, amount, currency, expires_at, created_by)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10) RETURNING *;

-- name: GetLatestPaymentLink :one
SELECT * FROM payment_links
WHERE share_id = $1 AND status <> 'expired' AND (expires_at IS NULL OR expires_at > now())
ORDER BY created_at DESC LIMIT 1;

-- name: SetPaymentLinkStatus :exec
UPDATE payment_links SET status = sqlc.arg(status)
WHERE provider = sqlc.arg(provider) AND external_id = sqlc.arg(external_id);

-- ---------------------------------------------------------------------------
-- Stripe webhook idempotency.

-- name: InsertStripeEvent :execrows
-- 0 rows: the event was already received and must be ignored.
INSERT INTO stripe_events (id, type) VALUES ($1, $2) ON CONFLICT (id) DO NOTHING;
