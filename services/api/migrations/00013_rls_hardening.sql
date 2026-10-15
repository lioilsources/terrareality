-- +goose Up
-- M8b hardening of privileges, row-level security and constraints
-- (docs/05-review-implementation.md: B-2, V-3, V-4, S-F5, S-F6, S-F9, S-F11
-- and the SQL-only items of section 4). Request code keeps working through
-- db.AsUser; what changes is that the database itself enforces who may write
-- which rows, so RLS is a real last line of defence (ADR 0004, ADR 0009).
--
-- Conventions used below:
--   * "<table>_read"  FOR SELECT  who may see a row (members and parties);
--   * "<table>_member" / "_insert" / "_update" / "_delete"  who may change it;
--   * column-level UPDATE grants where users may only touch a few columns.
-- Rows that fail a USING clause are skipped silently (0 rows affected); rows
-- that fail WITH CHECK raise "new row violates row-level security policy".

-- ---------------------------------------------------------------------------
-- Helpers (SECURITY DEFINER: they read memberships/groups without recursing
-- into the policies that call them).

-- +goose StatementBegin
-- The caller's role in an organization (NULL when not a member).
CREATE FUNCTION app_user_role(p_org uuid) RETURNS text
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT m.role FROM memberships m
  JOIN organizations o ON o.id = m.org_id AND o.deleted_at IS NULL
  WHERE m.org_id = p_org AND m.user_id = app_current_user()
$$;

-- B-2: an invitation addressed to an e-mail counts only once the caller has
-- proved they own that address. Unverified registrants see nothing.
CREATE OR REPLACE FUNCTION app_user_group_ids() RETURNS SETOF uuid
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT m.group_id FROM group_members m
  WHERE m.user_id = app_current_user()
     OR (m.user_id IS NULL AND m.invited_email = (
           SELECT u.email FROM users u
           WHERE u.id = app_current_user() AND u.email_verified_at IS NOT NULL))
$$;

-- Groups the caller has joined (user_id is set only on joining).
CREATE FUNCTION app_user_member_group_ids() RETURNS SETOF uuid
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT m.group_id FROM group_members m WHERE m.user_id = app_current_user()
$$;

-- The caller's verified e-mail (NULL when unverified or in system context).
CREATE FUNCTION app_user_verified_email() RETURNS citext
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT u.email FROM users u WHERE u.id = app_current_user() AND u.email_verified_at IS NOT NULL
$$;

-- S-F11: names of organizations and groups only for callers related to them
-- (member, seeker in a conversation, applicant, lease party; for groups:
-- members, verified invitees, the creator and organizations the group applied
-- to). System context (no app.current_user) is trusted. Personal
-- organizations carry a person's name, so an unrelated caller gets NULL.
CREATE OR REPLACE FUNCTION org_display_name(p_org uuid) RETURNS text
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT o.name FROM organizations o
  WHERE o.id = p_org AND (
    app_current_user() IS NULL
    OR o.id IN (SELECT app_user_org_ids())
    OR EXISTS (SELECT 1 FROM conversations c WHERE c.org_id = o.id AND c.seeker_id = app_current_user())
    OR EXISTS (SELECT 1 FROM applications a WHERE a.org_id = o.id AND (a.applicant_id = app_current_user()
                 OR a.group_id IN (SELECT app_user_member_group_ids())))
    OR EXISTS (SELECT 1 FROM lease_parties p WHERE p.org_id = o.id AND p.user_id = app_current_user()))
$$;

CREATE OR REPLACE FUNCTION group_display_name(p_group uuid) RETURNS text
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT g.name FROM tenant_groups g
  WHERE g.id = p_group AND (
    app_current_user() IS NULL
    OR g.created_by = app_current_user()
    OR g.id IN (SELECT app_user_group_ids())
    OR EXISTS (SELECT 1 FROM applications a WHERE a.group_id = g.id AND a.org_id IN (SELECT app_user_org_ids())))
$$;

-- group_members under the app role: joining binds only the caller's own
-- account to an invitation; nothing else about a member row changes (role,
-- group, address, someone else's account). System context is unrestricted.
CREATE FUNCTION group_members_guard() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF current_user <> 'terra_app' THEN
    RETURN NEW;
  END IF;
  IF NEW.group_id <> OLD.group_id OR NEW.role <> OLD.role OR NEW.invited_email <> OLD.invited_email THEN
    RAISE EXCEPTION 'group member rows are immutable' USING ERRCODE = '42501';
  END IF;
  IF NEW.user_id IS DISTINCT FROM OLD.user_id OR NEW.joined_at IS DISTINCT FROM OLD.joined_at THEN
    IF OLD.user_id IS NOT NULL OR NEW.user_id IS DISTINCT FROM app_current_user() OR NEW.joined_at IS NULL THEN
      RAISE EXCEPTION 'only the invitee can join' USING ERRCODE = '42501';
    END IF;
  END IF;
  RETURN NEW;
END
$$;
-- +goose StatementEnd

CREATE TRIGGER group_members_guard BEFORE UPDATE ON group_members
  FOR EACH ROW EXECUTE FUNCTION group_members_guard();

-- ---------------------------------------------------------------------------
-- V-3: global tables without RLS are written only in system context. The app
-- role keeps SELECT (and River's job tables, which request transactions
-- enqueue into, keep their grants).
REVOKE INSERT, UPDATE, DELETE ON app_meta, jurisdictions, filter_schemas, filter_schema_groups,
  filter_schema_proposals, admin_units, ruian_places, ruian_staging FROM terra_app;
-- +goose StatementBegin
DO $$
DECLARE t text;
BEGIN
  -- Created outside the numbered migrations (goose, PostGIS); 00002's blanket
  -- GRANT ON ALL TABLES reached them.
  FOREACH t IN ARRAY ARRAY['goose_db_version', 'spatial_ref_sys']
  LOOP
    IF to_regclass('public.' || t) IS NOT NULL THEN
      EXECUTE format('REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON %I FROM terra_app', t);
    END IF;
  END LOOP;
END
$$;
-- +goose StatementEnd

-- listing_search is public data but carries org_id, and owners change the
-- visibility of their own listings inside db.AsUser (pause/resume re-indexes).
-- RLS: everyone reads; the app role writes only its organizations' rows.
-- (Spelled out instead of app_enable_rls() so this migration also applies on
-- databases that ran an earlier draft of 00012.)
ALTER TABLE listing_search ENABLE ROW LEVEL SECURITY;
CREATE POLICY system_all ON listing_search TO terra_service USING (true) WITH CHECK (true);
CREATE POLICY listing_search_read ON listing_search FOR SELECT USING (true);
CREATE POLICY listing_search_member ON listing_search
  USING (org_id IN (SELECT app_user_org_ids())) WITH CHECK (org_id IN (SELECT app_user_org_ids()));

-- ---------------------------------------------------------------------------
-- S-L4: append-only records stay append-only for the role the api and worker
-- really run as (ADR 0009 point 5); 00012 granted it DML on every table.
-- Nothing in system code updates or deletes them (cascades from leases and
-- organizations run as the table owner). Invoices only get their rendered
-- PDF key and the sent stamp; orders change status but are never deleted.
REVOKE UPDATE, DELETE ON lease_events, ledger_entries, stripe_events, invoices FROM terra_service;
GRANT UPDATE (pdf_key, sent_at) ON invoices TO terra_service;
REVOKE DELETE ON orders FROM terra_service;

-- ---------------------------------------------------------------------------
-- V-4: append-only, financial and identity records.
REVOKE UPDATE, DELETE ON audit_events, consents FROM terra_app;
REVOKE INSERT, UPDATE, DELETE ON invoices, lease_risk_history, identity_verifications FROM terra_app;
REVOKE UPDATE, DELETE ON gdpr_requests FROM terra_app;
-- Orders: created by members at checkout, which also stores the Stripe
-- session id; status and payment are set by the webhook (system).
REVOKE UPDATE, DELETE ON orders FROM terra_app;
GRANT UPDATE (stripe_session_id) ON orders TO terra_app;

-- ---------------------------------------------------------------------------
-- S-F6: memberships. Joining an organization (invitation, new org) is system
-- work; members see the roster; owners and admins change roles; only owners
-- grant, change or remove ownership; everyone may leave.
DROP POLICY memberships_member ON memberships;
CREATE POLICY memberships_read ON memberships FOR SELECT
  USING (org_id IN (SELECT app_user_org_ids()));
CREATE POLICY memberships_update ON memberships FOR UPDATE
  USING (app_user_role(org_id) IN ('owner', 'admin') AND (role <> 'owner' OR app_user_role(org_id) = 'owner'))
  WITH CHECK (app_user_role(org_id) IN ('owner', 'admin') AND (role <> 'owner' OR app_user_role(org_id) = 'owner'));
CREATE POLICY memberships_delete ON memberships FOR DELETE
  USING (user_id = app_current_user()
    OR (app_user_role(org_id) IN ('owner', 'admin') AND (role <> 'owner' OR app_user_role(org_id) = 'owner')));
REVOKE UPDATE ON memberships FROM terra_app;
GRANT UPDATE (role) ON memberships TO terra_app;

-- Invitations: owners and admins invite and revoke. Owner invitations exist
-- only for pilot onboarding (terractl, system context; 00010).
DROP POLICY invitations_member ON invitations;
CREATE POLICY invitations_read ON invitations FOR SELECT
  USING (org_id IN (SELECT app_user_org_ids()));
CREATE POLICY invitations_insert ON invitations FOR INSERT
  WITH CHECK (app_user_role(org_id) IN ('owner', 'admin') AND role <> 'owner');
CREATE POLICY invitations_update ON invitations FOR UPDATE
  USING (app_user_role(org_id) IN ('owner', 'admin'))
  WITH CHECK (app_user_role(org_id) IN ('owner', 'admin'));
CREATE POLICY invitations_delete ON invitations FOR DELETE
  USING (app_user_role(org_id) IN ('owner', 'admin'));
REVOKE UPDATE ON invitations FROM terra_app;
GRANT UPDATE (revoked_at) ON invitations TO terra_app;

-- ---------------------------------------------------------------------------
-- B-2 + S-F5: tenant groups.
DROP POLICY tenant_groups_member ON tenant_groups;
CREATE POLICY tenant_groups_read ON tenant_groups FOR SELECT
  USING (id IN (SELECT app_user_group_ids()) OR created_by = app_current_user());
CREATE POLICY tenant_groups_insert ON tenant_groups FOR INSERT
  WITH CHECK (created_by = app_current_user());

DROP POLICY group_members_member ON group_members;
CREATE POLICY group_members_read ON group_members FOR SELECT
  USING (user_id = app_current_user() OR group_id IN (SELECT app_user_group_ids()));
-- Members invite (pending rows) and the creator adds themselves first.
CREATE POLICY group_members_insert ON group_members FOR INSERT
  WITH CHECK ((user_id IS NULL OR user_id = app_current_user())
    AND (group_id IN (SELECT app_user_member_group_ids())
      OR group_id IN (SELECT g.id FROM tenant_groups g WHERE g.created_by = app_current_user())));
-- Joining (verified invitee) and the no-op upsert of a repeated invitation;
-- group_members_guard limits which columns may change.
CREATE POLICY group_members_update ON group_members FOR UPDATE
  USING (group_id IN (SELECT app_user_member_group_ids())
    OR (user_id IS NULL AND invited_email = app_user_verified_email()))
  WITH CHECK (user_id = app_current_user() OR group_id IN (SELECT app_user_member_group_ids()));
-- Leaving, and members withdrawing pending invitations.
CREATE POLICY group_members_delete ON group_members FOR DELETE
  USING (user_id = app_current_user()
    OR (user_id IS NULL AND group_id IN (SELECT app_user_member_group_ids())));

-- ---------------------------------------------------------------------------
-- S-F5: applications. Applicants and joined group members see and file them;
-- only the landlord's organization moves them to invited/accepted/rejected.
DROP POLICY applications_party ON applications;
CREATE POLICY applications_read ON applications FOR SELECT
  USING (applicant_id = app_current_user() OR org_id IN (SELECT app_user_org_ids())
    OR group_id IN (SELECT app_user_member_group_ids()));
CREATE POLICY applications_insert ON applications FOR INSERT
  WITH CHECK (applicant_id = app_current_user() AND status IN ('pending_consent', 'submitted')
    AND (group_id IS NULL OR group_id IN (SELECT app_user_member_group_ids())));
CREATE POLICY applications_update ON applications FOR UPDATE
  USING (applicant_id = app_current_user() OR org_id IN (SELECT app_user_org_ids())
    OR group_id IN (SELECT app_user_member_group_ids()))
  WITH CHECK (org_id IN (SELECT app_user_org_ids())
    OR ((applicant_id = app_current_user() OR group_id IN (SELECT app_user_member_group_ids()))
        AND status IN ('pending_consent', 'submitted', 'withdrawn')));

-- Consents: the applicant creates the rows (their own already given); each
-- member gives only their own consent.
DROP POLICY application_consents_party ON application_consents;
CREATE POLICY application_consents_read ON application_consents FOR SELECT
  USING (application_id IN (SELECT app_user_application_ids()));
CREATE POLICY application_consents_insert ON application_consents FOR INSERT
  WITH CHECK ((user_id = app_current_user() OR consented_at IS NULL)
    AND application_id IN (SELECT a.id FROM applications a WHERE a.applicant_id = app_current_user()));
CREATE POLICY application_consents_update ON application_consents FOR UPDATE
  USING (user_id = app_current_user()) WITH CHECK (user_id = app_current_user());
REVOKE UPDATE ON application_consents FROM terra_app;
GRANT UPDATE (consented_at) ON application_consents TO terra_app;

-- Viewing bookings: parties of the application cancel; booking is system work
-- (capacity check across applicants), but an own booking is allowed.
DROP POLICY viewing_bookings_party ON viewing_bookings;
CREATE POLICY viewing_bookings_read ON viewing_bookings FOR SELECT
  USING (application_id IN (SELECT app_user_application_ids()));
CREATE POLICY viewing_bookings_insert ON viewing_bookings FOR INSERT
  WITH CHECK (booked_by = app_current_user()
    AND application_id IN (SELECT a.id FROM applications a
      WHERE a.applicant_id = app_current_user() OR a.group_id IN (SELECT app_user_member_group_ids())));
CREATE POLICY viewing_bookings_update ON viewing_bookings FOR UPDATE
  USING (application_id IN (SELECT app_user_application_ids()))
  WITH CHECK (application_id IN (SELECT app_user_application_ids()));
REVOKE UPDATE ON viewing_bookings FROM terra_app;
GRANT UPDATE (cancelled_at) ON viewing_bookings TO terra_app;

-- ---------------------------------------------------------------------------
-- S-F5: conversations and attachments.
DROP POLICY conversations_party ON conversations;
CREATE POLICY conversations_read ON conversations FOR SELECT
  USING (seeker_id = app_current_user() OR org_id IN (SELECT app_user_org_ids()));
CREATE POLICY conversations_insert ON conversations FOR INSERT
  WITH CHECK (seeker_id = app_current_user());
CREATE POLICY conversations_update ON conversations FOR UPDATE
  USING (seeker_id = app_current_user() OR org_id IN (SELECT app_user_org_ids()))
  WITH CHECK (seeker_id = app_current_user() OR org_id IN (SELECT app_user_org_ids()));
REVOKE UPDATE ON conversations FROM terra_app;
GRANT UPDATE (last_message_at, blocked_by, blocked_at) ON conversations TO terra_app;

DROP POLICY message_attachments_party ON message_attachments;
CREATE POLICY message_attachments_read ON message_attachments FOR SELECT
  USING (conversation_id IN (SELECT app_user_conversation_ids()));
CREATE POLICY message_attachments_insert ON message_attachments FOR INSERT
  WITH CHECK (uploaded_by = app_current_user() AND conversation_id IN (SELECT app_user_conversation_ids()));
CREATE POLICY message_attachments_update ON message_attachments FOR UPDATE
  USING (uploaded_by = app_current_user() AND conversation_id IN (SELECT app_user_conversation_ids()))
  WITH CHECK (uploaded_by = app_current_user() AND conversation_id IN (SELECT app_user_conversation_ids()));
REVOKE UPDATE ON message_attachments FROM terra_app;
GRANT UPDATE (message_id, av_status) ON message_attachments TO terra_app;

-- ---------------------------------------------------------------------------
-- S-F5: lease records. Parties (tenants, guarantors) read; only the landlord's
-- organization writes under RLS. Party actions (sign, give notice, confirm the
-- settlement) run in system context after the handler checked the party.
-- +goose StatementBegin
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['lease_parties', 'lease_events', 'lease_documents', 'signatures',
                           'payment_obligations', 'obligation_splits', 'ledger_entries']
  LOOP
    EXECUTE format('DROP POLICY %I ON %I', t || '_party', t);
    EXECUTE format('CREATE POLICY %I ON %I FOR SELECT USING (org_id IN (SELECT app_user_org_ids()) OR lease_id IN (SELECT app_user_lease_ids()))', t || '_read', t);
    EXECUTE format('CREATE POLICY %I ON %I USING (org_id IN (SELECT app_user_org_ids())) WITH CHECK (org_id IN (SELECT app_user_org_ids()))', t || '_member', t);
  END LOOP;
END
$$;
-- +goose StatementEnd

-- ---------------------------------------------------------------------------
-- S-F9: indexes on hot predicates (RLS functions, claims, joins, FKs).
CREATE INDEX group_members_user_id ON group_members (user_id) WHERE user_id IS NOT NULL;
CREATE INDEX lease_parties_email_open ON lease_parties (email) WHERE user_id IS NULL;
CREATE INDEX auth_tokens_user_purpose ON auth_tokens (user_id, purpose);
CREATE INDEX tenant_groups_created_by ON tenant_groups (created_by);
CREATE INDEX applications_group ON applications (group_id) WHERE group_id IS NOT NULL;
CREATE INDEX applications_org ON applications (org_id, created_at DESC);
CREATE INDEX application_consents_user ON application_consents (user_id);
CREATE INDEX units_parent ON units (parent_id) WHERE parent_id IS NOT NULL;
CREATE INDEX units_org ON units (org_id);
CREATE INDEX listings_unit ON listings (unit_id);
CREATE INDEX properties_address ON properties (address_id);
CREATE INDEX ledger_entries_party ON ledger_entries (party_id) WHERE party_id IS NOT NULL;
CREATE INDEX ledger_entries_posting ON ledger_entries (posting_id);
CREATE INDEX obligation_splits_party ON obligation_splits (party_id);
CREATE INDEX signatures_lease ON signatures (lease_id);
CREATE INDEX message_attachments_conversation ON message_attachments (conversation_id);
CREATE INDEX moderation_cases_conversation ON moderation_cases (conversation_id) WHERE conversation_id IS NOT NULL;
CREATE INDEX moderation_cases_reporter ON moderation_cases (reporter_id) WHERE reporter_id IS NOT NULL;
CREATE INDEX bank_transactions_split ON bank_transactions (split_id) WHERE split_id IS NOT NULL;
CREATE INDEX payment_links_lease ON payment_links (lease_id);
-- pgvector >= 0.5 (HNSW); SimilarByEmbedding orders by cosine distance (<=>).
CREATE INDEX listing_search_embedding ON listing_search USING hnsw (embedding vector_cosine_ops);

-- ---------------------------------------------------------------------------
-- Integrity needed by the application and leasing fixes: at most one
-- accepted application per listing (accepting is the hand-over to a lease).
CREATE UNIQUE INDEX applications_accepted_per_listing ON applications (listing_id) WHERE status = 'accepted';

-- The first publication of a listing ("new since"), unlike published_at which
-- moves with every approved version. Set once by PublishListingVersion.
ALTER TABLE listings ADD COLUMN first_published_at timestamptz;
UPDATE listings l SET first_published_at = coalesce(
  (SELECT min(v.reviewed_at) FROM listing_versions v WHERE v.listing_id = l.id AND v.status = 'approved'),
  l.published_at)
WHERE l.published_at IS NOT NULL;

-- ---------------------------------------------------------------------------
-- Section 4 CHECK constraints.
ALTER TABLE invoices ADD CONSTRAINT invoices_amounts
  CHECK (net_amount >= 0 AND vat_amount >= 0 AND gross_amount = net_amount + vat_amount);
ALTER TABLE lease_risk_history ADD CONSTRAINT lease_risk_history_score CHECK (score BETWEEN 0 AND 100);
ALTER TABLE lease_risk_history ADD CONSTRAINT lease_risk_history_band CHECK (band IN ('low', 'medium', 'high'));
ALTER TABLE lease_risk_history ADD CONSTRAINT lease_risk_history_monthly CHECK (monthly >= 0);
ALTER TABLE moderation_cases ADD CONSTRAINT moderation_cases_decision_kind
  CHECK (decision IS NULL
    OR (kind = 'conversation' AND decision IN ('dismiss', 'warn', 'remove_message', 'suspend_user'))
    OR (kind = 'listing' AND decision IN ('keep', 'unpublish', 'request_change')));
ALTER TABLE addresses ADD CONSTRAINT addresses_country_format CHECK (country ~ '^[A-Z]{2}$');
-- +goose StatementBegin
DO $$
DECLARE t text;
BEGIN
  -- ISO 4217 codes (char(3) also accepts 'cz ' or '1 2').
  FOREACH t IN ARRAY ARRAY['jurisdictions', 'listings', 'listing_search', 'leases', 'payment_obligations',
                           'bank_transactions', 'promo_products', 'orders', 'invoices', 'payment_links']
  LOOP
    EXECUTE format('ALTER TABLE %I ADD CONSTRAINT %I CHECK (currency ~ ''^[A-Z]{3}$'')', t, t || '_currency_format');
  END LOOP;
END
$$;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['jurisdictions', 'listings', 'listing_search', 'leases', 'payment_obligations',
                           'bank_transactions', 'promo_products', 'orders', 'invoices', 'payment_links']
  LOOP
    EXECUTE format('ALTER TABLE %I DROP CONSTRAINT IF EXISTS %I', t, t || '_currency_format');
  END LOOP;
END
$$;
-- +goose StatementEnd
ALTER TABLE addresses DROP CONSTRAINT IF EXISTS addresses_country_format;
ALTER TABLE moderation_cases DROP CONSTRAINT IF EXISTS moderation_cases_decision_kind;
ALTER TABLE lease_risk_history DROP CONSTRAINT IF EXISTS lease_risk_history_monthly;
ALTER TABLE lease_risk_history DROP CONSTRAINT IF EXISTS lease_risk_history_band;
ALTER TABLE lease_risk_history DROP CONSTRAINT IF EXISTS lease_risk_history_score;
ALTER TABLE invoices DROP CONSTRAINT IF EXISTS invoices_amounts;

ALTER TABLE listings DROP COLUMN IF EXISTS first_published_at;
DROP INDEX IF EXISTS applications_accepted_per_listing;

DROP INDEX IF EXISTS listing_search_embedding;
DROP INDEX IF EXISTS payment_links_lease;
DROP INDEX IF EXISTS bank_transactions_split;
DROP INDEX IF EXISTS moderation_cases_reporter;
DROP INDEX IF EXISTS moderation_cases_conversation;
DROP INDEX IF EXISTS message_attachments_conversation;
DROP INDEX IF EXISTS signatures_lease;
DROP INDEX IF EXISTS obligation_splits_party;
DROP INDEX IF EXISTS ledger_entries_posting;
DROP INDEX IF EXISTS ledger_entries_party;
DROP INDEX IF EXISTS properties_address;
DROP INDEX IF EXISTS listings_unit;
DROP INDEX IF EXISTS units_org;
DROP INDEX IF EXISTS units_parent;
DROP INDEX IF EXISTS application_consents_user;
DROP INDEX IF EXISTS applications_org;
DROP INDEX IF EXISTS applications_group;
DROP INDEX IF EXISTS tenant_groups_created_by;
DROP INDEX IF EXISTS auth_tokens_user_purpose;
DROP INDEX IF EXISTS lease_parties_email_open;
DROP INDEX IF EXISTS group_members_user_id;

-- Lease records: back to one ALL policy per table (org or party).
-- +goose StatementBegin
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['lease_parties', 'lease_events', 'lease_documents', 'signatures',
                           'payment_obligations', 'obligation_splits', 'ledger_entries']
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I', t || '_read', t);
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I', t || '_member', t);
    EXECUTE format('CREATE POLICY %I ON %I USING (org_id IN (SELECT app_user_org_ids()) OR lease_id IN (SELECT app_user_lease_ids()))', t || '_party', t);
  END LOOP;
END
$$;
-- +goose StatementEnd

GRANT UPDATE ON message_attachments TO terra_app;
DROP POLICY IF EXISTS message_attachments_update ON message_attachments;
DROP POLICY IF EXISTS message_attachments_insert ON message_attachments;
DROP POLICY IF EXISTS message_attachments_read ON message_attachments;
CREATE POLICY message_attachments_party ON message_attachments
  USING (conversation_id IN (SELECT app_user_conversation_ids()));

GRANT UPDATE ON conversations TO terra_app;
DROP POLICY IF EXISTS conversations_update ON conversations;
DROP POLICY IF EXISTS conversations_insert ON conversations;
DROP POLICY IF EXISTS conversations_read ON conversations;
CREATE POLICY conversations_party ON conversations
  USING (seeker_id = app_current_user() OR org_id IN (SELECT app_user_org_ids()));

GRANT UPDATE ON viewing_bookings TO terra_app;
DROP POLICY IF EXISTS viewing_bookings_update ON viewing_bookings;
DROP POLICY IF EXISTS viewing_bookings_insert ON viewing_bookings;
DROP POLICY IF EXISTS viewing_bookings_read ON viewing_bookings;
CREATE POLICY viewing_bookings_party ON viewing_bookings USING (application_id IN (SELECT app_user_application_ids()));

GRANT UPDATE ON application_consents TO terra_app;
DROP POLICY IF EXISTS application_consents_update ON application_consents;
DROP POLICY IF EXISTS application_consents_insert ON application_consents;
DROP POLICY IF EXISTS application_consents_read ON application_consents;
CREATE POLICY application_consents_party ON application_consents
  USING (application_id IN (SELECT app_user_application_ids()));

DROP POLICY IF EXISTS applications_update ON applications;
DROP POLICY IF EXISTS applications_insert ON applications;
DROP POLICY IF EXISTS applications_read ON applications;
CREATE POLICY applications_party ON applications
  USING (applicant_id = app_current_user() OR org_id IN (SELECT app_user_org_ids())
    OR group_id IN (SELECT m.group_id FROM group_members m WHERE m.user_id = app_current_user()));

DROP POLICY IF EXISTS group_members_delete ON group_members;
DROP POLICY IF EXISTS group_members_update ON group_members;
DROP POLICY IF EXISTS group_members_insert ON group_members;
DROP POLICY IF EXISTS group_members_read ON group_members;
CREATE POLICY group_members_member ON group_members
  USING (user_id = app_current_user() OR group_id IN (SELECT app_user_group_ids()))
  WITH CHECK (group_id IN (SELECT app_user_group_ids())
    OR group_id IN (SELECT g.id FROM tenant_groups g WHERE g.created_by = app_current_user()));

DROP POLICY IF EXISTS tenant_groups_insert ON tenant_groups;
DROP POLICY IF EXISTS tenant_groups_read ON tenant_groups;
CREATE POLICY tenant_groups_member ON tenant_groups
  USING (id IN (SELECT app_user_group_ids()) OR created_by = app_current_user());

GRANT UPDATE ON invitations TO terra_app;
DROP POLICY IF EXISTS invitations_delete ON invitations;
DROP POLICY IF EXISTS invitations_update ON invitations;
DROP POLICY IF EXISTS invitations_insert ON invitations;
DROP POLICY IF EXISTS invitations_read ON invitations;
CREATE POLICY invitations_member ON invitations
  USING (org_id IN (SELECT app_user_org_ids()));

GRANT UPDATE ON memberships TO terra_app;
DROP POLICY IF EXISTS memberships_delete ON memberships;
DROP POLICY IF EXISTS memberships_update ON memberships;
DROP POLICY IF EXISTS memberships_read ON memberships;
CREATE POLICY memberships_member ON memberships
  USING (org_id IN (SELECT app_user_org_ids()));

GRANT DELETE ON orders TO terra_service;
GRANT UPDATE, DELETE ON lease_events, ledger_entries, stripe_events, invoices TO terra_service;

GRANT UPDATE, DELETE ON orders TO terra_app;
GRANT UPDATE, DELETE ON gdpr_requests TO terra_app;
GRANT INSERT, UPDATE, DELETE ON invoices, lease_risk_history, identity_verifications TO terra_app;
GRANT UPDATE, DELETE ON audit_events, consents TO terra_app;

DROP POLICY IF EXISTS listing_search_member ON listing_search;
DROP POLICY IF EXISTS listing_search_read ON listing_search;
DROP POLICY IF EXISTS system_all ON listing_search;
ALTER TABLE listing_search DISABLE ROW LEVEL SECURITY;

GRANT INSERT, UPDATE, DELETE ON app_meta, jurisdictions, filter_schemas, filter_schema_groups,
  filter_schema_proposals, admin_units, ruian_places, ruian_staging TO terra_app;
-- +goose StatementBegin
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['goose_db_version', 'spatial_ref_sys']
  LOOP
    IF to_regclass('public.' || t) IS NOT NULL THEN
      EXECUTE format('GRANT INSERT, UPDATE, DELETE ON %I TO terra_app', t);
    END IF;
  END LOOP;
END
$$;
-- +goose StatementEnd

DROP TRIGGER IF EXISTS group_members_guard ON group_members;
DROP FUNCTION IF EXISTS group_members_guard();

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION group_display_name(p_group uuid) RETURNS text
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT name FROM tenant_groups WHERE id = p_group
$$;

CREATE OR REPLACE FUNCTION org_display_name(p_org uuid) RETURNS text
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT name FROM organizations WHERE id = p_org
$$;

CREATE OR REPLACE FUNCTION app_user_group_ids() RETURNS SETOF uuid
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT m.group_id FROM group_members m
  WHERE m.user_id = app_current_user()
     OR (m.user_id IS NULL AND m.invited_email = (SELECT email FROM users WHERE id = app_current_user()))
$$;
-- +goose StatementEnd
DROP FUNCTION IF EXISTS app_user_verified_email();
DROP FUNCTION IF EXISTS app_user_member_group_ids();
DROP FUNCTION IF EXISTS app_user_role(uuid);
