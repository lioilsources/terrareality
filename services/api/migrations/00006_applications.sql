-- +goose Up
-- M5: tenant groups with consent, applications for listings, roommate
-- seeker profiles, Tenant Passport v0 and viewing slots.

-- ---------------------------------------------------------------------------
-- Groups of seekers who rent together (co-living). Members are invited by
-- e-mail and join explicitly; the group chat lives in group_messages.
CREATE TABLE tenant_groups (
  id         uuid PRIMARY KEY DEFAULT uuid_v7(),
  name       text NOT NULL CHECK (length(name) BETWEEN 1 AND 80),
  created_by uuid REFERENCES users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE group_members (
  id            uuid PRIMARY KEY DEFAULT uuid_v7(),
  group_id      uuid NOT NULL REFERENCES tenant_groups(id) ON DELETE CASCADE,
  user_id       uuid REFERENCES users(id) ON DELETE CASCADE,  -- null until the invitee joins
  invited_email citext NOT NULL,
  role          text NOT NULL DEFAULT 'member' CHECK (role IN ('admin', 'member')),
  joined_at     timestamptz,                                  -- consent to act as a group
  created_at    timestamptz NOT NULL DEFAULT now(),
  UNIQUE (group_id, invited_email)
);
CREATE UNIQUE INDEX group_members_user ON group_members (group_id, user_id) WHERE user_id IS NOT NULL;
CREATE INDEX group_members_email ON group_members (invited_email) WHERE user_id IS NULL;

CREATE TABLE group_messages (
  id         uuid PRIMARY KEY DEFAULT uuid_v7(),
  group_id   uuid NOT NULL REFERENCES tenant_groups(id) ON DELETE CASCADE,
  sender_id  uuid REFERENCES users(id) ON DELETE SET NULL,
  body       text NOT NULL CHECK (length(body) BETWEEN 1 AND 4000),
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX group_messages_group ON group_messages (group_id, created_at);

-- ---------------------------------------------------------------------------
-- Applications. A group application waits in pending_consent until every
-- joined member has consented; only then the landlord sees it.
CREATE TABLE applications (
  id              uuid PRIMARY KEY DEFAULT uuid_v7(),
  listing_id      uuid NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
  org_id          uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  applicant_id    uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,  -- who filed it
  group_id        uuid REFERENCES tenant_groups(id) ON DELETE SET NULL,
  status          text NOT NULL CHECK (status IN ('pending_consent', 'submitted', 'invited', 'accepted',
                                                  'rejected', 'withdrawn')),
  message         text NOT NULL DEFAULT '' CHECK (length(message) <= 4000),
  answers         jsonb NOT NULL DEFAULT '[]'::jsonb,
  preferred_from  date,
  duration_months int CHECK (duration_months BETWEEN 1 AND 120),
  household_size  int NOT NULL DEFAULT 1 CHECK (household_size BETWEEN 1 AND 20),
  reject_reason   text CHECK (reject_reason IN ('other_applicant_chosen', 'income_insufficient',
                    'move_in_mismatch', 'duration_mismatch', 'incomplete', 'listing_withdrawn', 'other')),
  ai_status       text NOT NULL DEFAULT 'pending' CHECK (ai_status IN ('pending', 'ready', 'failed', 'disabled')),
  ai_summary      jsonb,
  ai_model        text,
  created_at      timestamptz NOT NULL DEFAULT now(),
  submitted_at    timestamptz,
  decided_at      timestamptz,
  updated_at      timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX applications_listing ON applications (listing_id, status);
CREATE INDEX applications_applicant ON applications (applicant_id);
-- One open application per person (or group) and listing.
CREATE UNIQUE INDEX applications_open_user ON applications (listing_id, applicant_id)
  WHERE status IN ('pending_consent', 'submitted', 'invited') AND group_id IS NULL;
CREATE UNIQUE INDEX applications_open_group ON applications (listing_id, group_id)
  WHERE status IN ('pending_consent', 'submitted', 'invited') AND group_id IS NOT NULL;
CREATE TRIGGER applications_updated_at BEFORE UPDATE ON applications
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Per-application consent of each group member (and of the applicant).
CREATE TABLE application_consents (
  application_id uuid NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  user_id        uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  consented_at   timestamptz,
  PRIMARY KEY (application_id, user_id)
);

-- ---------------------------------------------------------------------------
-- "Looking for a flatmate" profiles. Protected characteristics (age, sex,
-- nationality, religion, health) are deliberately not collected.
CREATE TABLE roommate_profiles (
  user_id     uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  active      boolean NOT NULL DEFAULT true,
  admin_path  ltree,                         -- where (region..district)
  area_label  text NOT NULL DEFAULT '',
  budget_max  bigint NOT NULL CHECK (budget_max > 0), -- minor units, CZK
  move_in     date,
  about       text NOT NULL DEFAULT '' CHECK (length(about) <= 2000),
  lifestyle   text[] NOT NULL DEFAULT '{}',   -- tags from a fixed list (non_smoker, pets, quiet, ...)
  has_room    boolean NOT NULL DEFAULT false, -- offers a room in their flat
  updated_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX roommate_profiles_area ON roommate_profiles USING gist (admin_path) WHERE active;
CREATE TRIGGER roommate_profiles_updated_at BEFORE UPDATE ON roommate_profiles
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Tenant Passport v0: optional income proof (a file a person on the
-- landlord's side reads) and an insolvency register check.
CREATE TABLE tenant_passports (
  user_id           uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  income_key        text,
  income_filename   text,
  income_uploaded_at timestamptz,
  isir_status       text NOT NULL DEFAULT 'unchecked' CHECK (isir_status IN ('unchecked', 'clear', 'record', 'error')),
  isir_checked_at   timestamptz,
  updated_at        timestamptz NOT NULL DEFAULT now()
);
CREATE TRIGGER tenant_passports_updated_at BEFORE UPDATE ON tenant_passports
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ---------------------------------------------------------------------------
-- Viewing slots and bookings.
CREATE TABLE viewing_slots (
  id           uuid PRIMARY KEY DEFAULT uuid_v7(),
  org_id       uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  listing_id   uuid NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
  starts_at    timestamptz NOT NULL,
  duration_min int NOT NULL DEFAULT 20 CHECK (duration_min BETWEEN 5 AND 240),
  capacity     int NOT NULL DEFAULT 1 CHECK (capacity BETWEEN 1 AND 50),
  note         text NOT NULL DEFAULT '' CHECK (length(note) <= 500),
  created_at   timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX viewing_slots_listing ON viewing_slots (listing_id, starts_at);

CREATE TABLE viewing_bookings (
  id             uuid PRIMARY KEY DEFAULT uuid_v7(),
  slot_id        uuid NOT NULL REFERENCES viewing_slots(id) ON DELETE CASCADE,
  application_id uuid NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  booked_by      uuid REFERENCES users(id) ON DELETE SET NULL,
  cancelled_at   timestamptz,
  created_at     timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX viewing_bookings_active ON viewing_bookings (slot_id, application_id) WHERE cancelled_at IS NULL;
CREATE UNIQUE INDEX viewing_bookings_one_per_app ON viewing_bookings (application_id) WHERE cancelled_at IS NULL;

-- ---------------------------------------------------------------------------
-- Row-level security (ADR 0008).
-- +goose StatementBegin
CREATE FUNCTION app_user_group_ids() RETURNS SETOF uuid
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT m.group_id FROM group_members m
  WHERE m.user_id = app_current_user()
     OR (m.user_id IS NULL AND m.invited_email = (SELECT email FROM users WHERE id = app_current_user()))
$$;

-- The landlord sees the name of a group that applied (groups have
-- member-only RLS).
CREATE FUNCTION group_display_name(p_group uuid) RETURNS text
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT name FROM tenant_groups WHERE id = p_group
$$;

CREATE FUNCTION app_user_application_ids() RETURNS SETOF uuid
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT a.id FROM applications a
  WHERE a.applicant_id = app_current_user()
     OR a.org_id IN (SELECT app_user_org_ids())
     OR a.group_id IN (SELECT m.group_id FROM group_members m WHERE m.user_id = app_current_user())
$$;
-- +goose StatementEnd

ALTER TABLE tenant_groups ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_groups_member ON tenant_groups
  USING (id IN (SELECT app_user_group_ids()) OR created_by = app_current_user());

ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;
-- The creator adds the first member (themselves) before being one.
CREATE POLICY group_members_member ON group_members
  USING (user_id = app_current_user() OR group_id IN (SELECT app_user_group_ids()))
  WITH CHECK (group_id IN (SELECT app_user_group_ids())
    OR group_id IN (SELECT g.id FROM tenant_groups g WHERE g.created_by = app_current_user()));

ALTER TABLE group_messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY group_messages_member ON group_messages
  USING (group_id IN (SELECT m.group_id FROM group_members m WHERE m.user_id = app_current_user()))
  WITH CHECK (sender_id = app_current_user()
    AND group_id IN (SELECT m.group_id FROM group_members m WHERE m.user_id = app_current_user()));
REVOKE UPDATE, DELETE ON group_messages FROM terra_app;

ALTER TABLE applications ENABLE ROW LEVEL SECURITY;
-- Conditions inline (not app_user_application_ids()) so INSERT ... RETURNING sees the new row.
CREATE POLICY applications_party ON applications
  USING (applicant_id = app_current_user() OR org_id IN (SELECT app_user_org_ids())
    OR group_id IN (SELECT m.group_id FROM group_members m WHERE m.user_id = app_current_user()));

ALTER TABLE application_consents ENABLE ROW LEVEL SECURITY;
CREATE POLICY application_consents_party ON application_consents
  USING (application_id IN (SELECT app_user_application_ids()));

ALTER TABLE roommate_profiles ENABLE ROW LEVEL SECURITY;
-- Active profiles are visible to every signed-in user (that is their purpose).
CREATE POLICY roommate_profiles_read ON roommate_profiles FOR SELECT
  USING (user_id = app_current_user() OR (active AND app_current_user() IS NOT NULL));
CREATE POLICY roommate_profiles_write ON roommate_profiles FOR ALL
  USING (user_id = app_current_user()) WITH CHECK (user_id = app_current_user());

ALTER TABLE tenant_passports ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_passports_self ON tenant_passports USING (user_id = app_current_user());

ALTER TABLE viewing_slots ENABLE ROW LEVEL SECURITY;
-- Applicants of the listing see its slots; the organization manages them.
CREATE POLICY viewing_slots_read ON viewing_slots FOR SELECT
  USING (org_id IN (SELECT app_user_org_ids())
    OR listing_id IN (SELECT a.listing_id FROM applications a WHERE a.id IN (SELECT app_user_application_ids())));
CREATE POLICY viewing_slots_write ON viewing_slots FOR ALL
  USING (org_id IN (SELECT app_user_org_ids())) WITH CHECK (org_id IN (SELECT app_user_org_ids()));

ALTER TABLE viewing_bookings ENABLE ROW LEVEL SECURITY;
CREATE POLICY viewing_bookings_party ON viewing_bookings USING (application_id IN (SELECT app_user_application_ids()));

-- +goose Down
DROP TABLE IF EXISTS viewing_bookings, viewing_slots, tenant_passports, roommate_profiles, application_consents,
  applications, group_messages, group_members, tenant_groups CASCADE;
DROP FUNCTION IF EXISTS app_user_application_ids();
DROP FUNCTION IF EXISTS app_user_group_ids();
DROP FUNCTION IF EXISTS group_display_name(uuid);
