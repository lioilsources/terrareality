-- M6: leases, signatures, schedule, ledger, bank matching.

-- name: CreateLease :one
INSERT INTO leases (org_id, listing_id, application_id, jurisdiction_code, currency, template, template_version,
  property_address, unit_label, starts_on, ends_on, rent_amount, services_amount, deposit_amount, due_day,
  notice_months, payee_iban, payee_name, clauses, terms, created_by)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21)
RETURNING *;

-- name: UpdateLeaseDraft :execrows
UPDATE leases SET template = $3, starts_on = $4, ends_on = $5, rent_amount = $6, services_amount = $7,
  deposit_amount = $8, due_day = $9, notice_months = $10, payee_iban = $11, payee_name = $12, clauses = $13,
  property_address = $14, unit_label = $15
WHERE id = $1 AND org_id = $2 AND state IN ('draft', 'negotiating');

-- name: GetLease :one
SELECT * FROM leases WHERE id = $1;

-- name: ListOrgLeases :many
SELECT l.*, (SELECT string_agg(p.name, ', ' ORDER BY p.position) FROM lease_parties p
  WHERE p.lease_id = l.id AND p.role <> 'landlord')::text AS tenant_names
FROM leases l WHERE l.org_id = $1 ORDER BY l.created_at DESC;

-- name: ListMyLeases :many
SELECT l.*, coalesce(org_display_name(l.org_id), '')::text AS org_name
FROM leases l
WHERE l.id IN (SELECT p.lease_id FROM lease_parties p WHERE p.user_id = $1)
ORDER BY l.created_at DESC;

-- name: SetLeaseState :execrows
UPDATE leases SET state = sqlc.arg(state), change_request = sqlc.narg(change_request)
WHERE id = sqlc.arg(id) AND state = ANY(sqlc.arg(from_states)::text[]);

-- name: MarkLeaseSigned :exec
UPDATE leases SET state = 'signed', signed_at = now(), workflow_id = $2 WHERE id = $1;

-- name: SetLeaseNotice :execrows
UPDATE leases SET state = 'notice_given', notice_on = $2 WHERE id = $1 AND state IN ('active', 'signed');

-- name: AddLeaseParty :one
INSERT INTO lease_parties (lease_id, org_id, role, user_id, name, email, share_bps, position)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *;

-- name: DeleteLeaseTenants :exec
DELETE FROM lease_parties WHERE lease_id = $1 AND role <> 'landlord';

-- name: ListLeaseParties :many
SELECT * FROM lease_parties WHERE lease_id = $1 ORDER BY position;

-- name: ConfirmSettlement :execrows
UPDATE lease_parties SET settlement_ok_at = now() WHERE lease_id = $1 AND user_id = $2 AND settlement_ok_at IS NULL;

-- name: LastLeaseEvent :one
SELECT seq, hash FROM lease_events WHERE lease_id = $1 ORDER BY seq DESC LIMIT 1;

-- name: InsertLeaseEvent :one
INSERT INTO lease_events (lease_id, org_id, seq, kind, payload, prev_hash, hash)
VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *;

-- name: ListLeaseEvents :many
SELECT * FROM lease_events WHERE lease_id = $1 ORDER BY seq;

-- name: InsertLeaseDocument :one
INSERT INTO lease_documents (lease_id, org_id, kind, version, object_key, filename, sha256)
VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *;

-- name: ListLeaseDocuments :many
SELECT * FROM lease_documents WHERE lease_id = $1 ORDER BY created_at;

-- name: LatestLeaseDocument :one
SELECT * FROM lease_documents WHERE lease_id = $1 AND kind = $2 ORDER BY version DESC LIMIT 1;

-- name: CountLeaseDocuments :one
SELECT count(*)::int FROM lease_documents WHERE lease_id = $1;

-- name: InsertSignature :one
INSERT INTO signatures (lease_id, org_id, document_id, party_id, provider) VALUES ($1, $2, $3, $4, $5)
ON CONFLICT (document_id, party_id) DO UPDATE SET provider = excluded.provider
RETURNING *;

-- name: CompleteSignature :execrows
UPDATE signatures SET status = 'signed', signed_at = now(), external_id = $3, evidence = $4, provider = $5
WHERE document_id = $1 AND party_id = $2 AND status = 'pending';

-- name: ListSignatures :many
SELECT s.*, p.name AS party_name, p.role AS party_role FROM signatures s JOIN lease_parties p ON p.id = s.party_id
WHERE s.document_id = $1 ORDER BY p.position;

-- name: CountPendingSignatures :one
SELECT count(*)::int FROM signatures WHERE document_id = $1 AND status <> 'signed';

-- ---------------------------------------------------------------------------
-- Schedule and ledger.

-- name: InsertObligation :one
INSERT INTO payment_obligations (lease_id, org_id, kind, period, due_on, amount, currency)
VALUES ($1, $2, $3, $4, $5, $6, $7)
ON CONFLICT (lease_id, kind, period) DO NOTHING
RETURNING *;

-- name: InsertSplit :one
INSERT INTO obligation_splits (obligation_id, lease_id, org_id, party_id, amount) VALUES ($1, $2, $3, $4, $5) RETURNING *;

-- name: ListObligations :many
SELECT o.id, o.kind, o.period, o.due_on, o.amount, o.currency, o.status,
  s.id AS split_id, s.party_id, s.amount AS split_amount, s.paid_amount, p.name AS party_name, p.position
FROM payment_obligations o
JOIN obligation_splits s ON s.obligation_id = o.id
JOIN lease_parties p ON p.id = s.party_id
WHERE o.lease_id = $1 AND o.status <> 'cancelled'
ORDER BY o.due_on, o.kind, p.position;

-- name: GetSplit :one
SELECT s.*, o.due_on, o.kind, o.period, o.currency, o.status AS obligation_status, l.code, l.payee_iban, l.payee_name,
  p.position, p.name AS party_name, p.user_id AS party_user_id
FROM obligation_splits s
JOIN payment_obligations o ON o.id = s.obligation_id
JOIN leases l ON l.id = s.lease_id
JOIN lease_parties p ON p.id = s.party_id
WHERE s.id = $1;

-- name: AddSplitPayment :one
UPDATE obligation_splits SET paid_amount = paid_amount + $2 WHERE id = $1 RETURNING *;

-- name: CloseObligationIfPaid :exec
UPDATE payment_obligations o SET status = 'paid'
WHERE o.id = $1 AND NOT EXISTS (SELECT 1 FROM obligation_splits s WHERE s.obligation_id = o.id AND s.paid_amount < s.amount);

-- name: InsertLedgerEntry :exec
INSERT INTO ledger_entries (lease_id, org_id, posting_id, account, party_id, split_id, amount, memo, booked_on)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9);

-- name: ListLedger :many
SELECT e.*, coalesce(p.name, '')::text AS party_name FROM ledger_entries e
LEFT JOIN lease_parties p ON p.id = e.party_id
WHERE e.lease_id = $1 ORDER BY e.booked_on, e.created_at, e.account;

-- name: DebtByParty :many
-- Receivable balance per party for items due by a date (the debt).
SELECT p.id AS party_id, p.name, coalesce(sum(e.amount), 0)::bigint AS debt
FROM lease_parties p
LEFT JOIN ledger_entries e ON e.party_id = p.id AND e.account = 'receivable' AND e.booked_on <= sqlc.arg(as_of)::date
WHERE p.lease_id = sqlc.arg(lease_id) AND p.role <> 'landlord'
GROUP BY p.id, p.name, p.position ORDER BY p.position;

-- name: LastRentPeriod :one
SELECT coalesce(max(period), '')::text FROM payment_obligations WHERE lease_id = $1 AND kind = 'rent';

-- name: OverdueSplitsForReminder :many
-- Open splits of a lease due on a given date (workflow reminders, system context).
SELECT s.id, s.amount, s.paid_amount, o.due_on, o.kind, o.period, p.user_id, p.name, p.email, u.locale
FROM obligation_splits s
JOIN payment_obligations o ON o.id = s.obligation_id
JOIN lease_parties p ON p.id = s.party_id
LEFT JOIN users u ON u.id = p.user_id
WHERE s.lease_id = $1 AND o.due_on = $2 AND s.paid_amount < s.amount AND o.status = 'open';

-- name: LeaseDueDates :many
SELECT DISTINCT due_on FROM payment_obligations WHERE lease_id = $1 AND status = 'open' AND due_on >= $2 ORDER BY due_on;

-- ---------------------------------------------------------------------------
-- Bank.

-- name: CreateBankConnection :one
INSERT INTO bank_connections (org_id, provider, institution_id, requisition_id, status, created_by)
VALUES ($1, $2, $3, $4, $5, $6) RETURNING *;

-- name: ListBankConnections :many
SELECT * FROM bank_connections WHERE org_id = $1 ORDER BY created_at;

-- name: GetBankConnection :one
SELECT * FROM bank_connections WHERE id = $1;

-- name: SetBankConnectionLinked :exec
UPDATE bank_connections SET status = $2, account_id = $3, iban = $4 WHERE id = $1;

-- name: TouchBankConnection :exec
UPDATE bank_connections SET last_synced_at = now() WHERE id = $1;

-- name: LinkedBankConnections :many
SELECT * FROM bank_connections WHERE status = 'linked' ORDER BY last_synced_at NULLS FIRST LIMIT 200;

-- name: InsertBankTransaction :one
INSERT INTO bank_transactions (org_id, connection_id, external_id, booked_on, amount, currency, variable_symbol,
  specific_symbol, counterparty_name, counterparty_account, remittance)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
ON CONFLICT (connection_id, external_id) DO NOTHING
RETURNING *;

-- name: ListBankTransactions :many
SELECT * FROM bank_transactions WHERE org_id = $1
  AND (sqlc.narg(status)::text IS NULL OR match_status = sqlc.narg(status)::text)
ORDER BY booked_on DESC, created_at DESC LIMIT 200;

-- name: GetBankTransaction :one
SELECT * FROM bank_transactions WHERE id = $1;

-- name: SetTransactionMatch :exec
UPDATE bank_transactions SET match_status = $2, split_id = $3, match_note = $4 WHERE id = $1;

-- name: OpenSplitsForCode :many
-- Unpaid splits of the organization's lease with this variable symbol, oldest first.
SELECT s.id, s.amount, s.paid_amount, o.due_on, p.position, p.name, l.id AS lease_id
FROM obligation_splits s
JOIN payment_obligations o ON o.id = s.obligation_id
JOIN leases l ON l.id = s.lease_id
JOIN lease_parties p ON p.id = s.party_id
WHERE l.org_id = $1 AND l.code = $2 AND s.paid_amount < s.amount AND o.status = 'open'
ORDER BY o.due_on, p.position;

-- name: OpenSplitsByAmount :many
-- Unpaid splits of the organization with this exact outstanding amount, due around a date.
SELECT s.id, s.amount, s.paid_amount, o.due_on, p.position, p.name, l.id AS lease_id
FROM obligation_splits s
JOIN payment_obligations o ON o.id = s.obligation_id
JOIN leases l ON l.id = s.lease_id
JOIN lease_parties p ON p.id = s.party_id
WHERE l.org_id = $1 AND s.amount - s.paid_amount = $2 AND o.status = 'open'
  AND o.due_on BETWEEN sqlc.arg(day)::date - 10 AND sqlc.arg(day)::date + 10
ORDER BY o.due_on;

-- name: LockLease :one
SELECT id FROM leases WHERE id = $1 FOR UPDATE;

-- name: ClaimLeaseParties :exec
-- Links parties invited by e-mail to the account with that address.
UPDATE lease_parties SET user_id = $1 WHERE user_id IS NULL AND email = $2::citext;

-- name: CancelObligationsAfter :exec
UPDATE payment_obligations SET status = 'cancelled' WHERE lease_id = $1 AND status = 'open' AND due_on > $2;

-- name: SetLeaseEnd :exec
UPDATE leases SET ends_on = $2 WHERE id = $1;

-- name: SystemSetLeaseState :exec
UPDATE leases SET state = $2 WHERE id = $1;

-- name: OldestOverdueDue :one
-- Dev: the oldest due date with an unpaid share (simulated escalation).
SELECT min(o.due_on)::date FROM payment_obligations o JOIN obligation_splits s ON s.obligation_id = o.id
WHERE o.lease_id = $1 AND o.status = 'open' AND s.paid_amount < s.amount AND o.due_on <= $2;
