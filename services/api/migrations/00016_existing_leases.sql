-- +goose Up
-- M9: existing leases. A landlord joining the platform brings flats already
-- rented on paper contracts. Such a lease is imported straight into its
-- running state (no signing round, no rendered document): the platform
-- tracks payments only from the cutover date on, an unpaid balance at the
-- cutover becomes one opening-balance obligation, and a deposit the landlord
-- already holds is booked without a receivable. Existing tenants keep paying
-- with the variable symbol of their standing order.

-- origin: 'imported' = signed outside the platform (no signatures here).
-- cutover_on: the platform tracks payments from this date (imported only).
-- variable_symbol: the symbol tenants already use; payments, QR codes and
--   bank matching use it instead of code (Czech VS: up to 10 digits, stored
--   without leading zeros, which banks drop).
-- deposit_held: the deposit was collected before the cutover.
-- contract_media_id: the uploaded scan of the paper contract (a lease
--   document of kind 'scan').
ALTER TABLE leases
  ADD COLUMN origin text NOT NULL DEFAULT 'platform' CHECK (origin IN ('platform', 'imported')),
  ADD COLUMN cutover_on date,
  ADD COLUMN variable_symbol text CHECK (variable_symbol ~ '^[1-9][0-9]{0,9}$'),
  ADD COLUMN deposit_held boolean NOT NULL DEFAULT false,
  ADD COLUMN contract_media_id uuid REFERENCES lease_documents(id) ON DELETE SET NULL,
  ADD CONSTRAINT leases_imported_cutover CHECK ((origin = 'imported') = (cutover_on IS NOT NULL)),
  ADD CONSTRAINT leases_cutover_after_start CHECK (cutover_on IS NULL OR cutover_on >= starts_on);

-- A custom variable symbol identifies one running lease of the organization
-- (bank matching is scoped to the organization).
CREATE UNIQUE INDEX leases_org_variable_symbol ON leases (org_id, variable_symbol)
  WHERE variable_symbol IS NOT NULL AND state <> 'cancelled';

-- Tenants of an imported lease have no account and never agreed to the
-- platform: they are linked to an account (and receive tenant e-mails) only
-- after the landlord invited them (invited_at) and they signed in with the
-- invited, verified address (ClaimLeaseParties).
ALTER TABLE lease_parties ADD COLUMN invited_at timestamptz;

-- The debt a tenant owed when the platform started tracking the lease.
ALTER TABLE payment_obligations DROP CONSTRAINT payment_obligations_kind_check;
ALTER TABLE payment_obligations ADD CONSTRAINT payment_obligations_kind_check
  CHECK (kind IN ('rent', 'services', 'deposit', 'oneoff', 'opening_balance'));

-- +goose Down
DELETE FROM payment_obligations WHERE kind = 'opening_balance';
ALTER TABLE payment_obligations DROP CONSTRAINT payment_obligations_kind_check;
ALTER TABLE payment_obligations ADD CONSTRAINT payment_obligations_kind_check
  CHECK (kind IN ('rent', 'services', 'deposit', 'oneoff'));
ALTER TABLE lease_parties DROP COLUMN IF EXISTS invited_at;
DROP INDEX IF EXISTS leases_org_variable_symbol;
ALTER TABLE leases DROP CONSTRAINT IF EXISTS leases_cutover_after_start,
  DROP CONSTRAINT IF EXISTS leases_imported_cutover,
  DROP COLUMN IF EXISTS contract_media_id,
  DROP COLUMN IF EXISTS deposit_held,
  DROP COLUMN IF EXISTS variable_symbol,
  DROP COLUMN IF EXISTS cutover_on,
  DROP COLUMN IF EXISTS origin;
