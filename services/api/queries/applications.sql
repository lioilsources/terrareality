-- M5: groups, applications, roommate profiles, Tenant Passport, viewings.

-- ---------------------------------------------------------------------------
-- Groups (user context).

-- name: CreateGroup :one
INSERT INTO tenant_groups (name, created_by) VALUES ($1, $2) RETURNING *;

-- name: AddGroupMember :one
INSERT INTO group_members (group_id, user_id, invited_email, role, joined_at)
VALUES ($1, $2, $3, $4, $5)
ON CONFLICT (group_id, invited_email) DO UPDATE SET invited_email = excluded.invited_email
RETURNING *;

-- name: GetGroup :one
SELECT * FROM tenant_groups WHERE id = $1;

-- name: ListMyGroups :many
SELECT g.id, g.name, g.created_at, m.role, m.joined_at,
  (SELECT count(*) FROM group_members x WHERE x.group_id = g.id AND x.joined_at IS NOT NULL)::int AS members
FROM group_members m JOIN tenant_groups g ON g.id = m.group_id
WHERE m.user_id = sqlc.arg(user_id)::uuid OR (m.user_id IS NULL AND m.invited_email = sqlc.arg(email)::citext)
ORDER BY g.created_at DESC;

-- name: ListGroupMembers :many
SELECT m.id, m.group_id, m.user_id, m.invited_email, m.role, m.joined_at,
  coalesce(u.display_name, '')::text AS display_name, coalesce(u.verification_level, 'none')::text AS verification_level
FROM group_members m LEFT JOIN users u ON u.id = m.user_id
WHERE m.group_id = $1
ORDER BY m.created_at;

-- name: GetGroupMember :one
SELECT * FROM group_members WHERE group_id = $1 AND user_id = $2;

-- name: JoinGroup :execrows
UPDATE group_members SET user_id = sqlc.arg(user_id), joined_at = now()
WHERE group_id = sqlc.arg(group_id) AND invited_email = sqlc.arg(email)::citext AND user_id IS NULL;

-- name: LeaveGroup :execrows
DELETE FROM group_members WHERE group_id = $1 AND user_id = $2;

-- name: RemoveGroupInvite :execrows
DELETE FROM group_members WHERE id = $1 AND group_id = $2 AND joined_at IS NULL;

-- name: InsertGroupMessage :one
INSERT INTO group_messages (group_id, sender_id, body) VALUES ($1, $2, $3) RETURNING *;

-- name: ListGroupMessages :many
SELECT * FROM (
  SELECT gm.*, coalesce(u.display_name, '')::text AS sender_name
  FROM group_messages gm LEFT JOIN users u ON u.id = gm.sender_id
  WHERE gm.group_id = $1 ORDER BY gm.created_at DESC LIMIT 200
) t ORDER BY created_at;

-- name: GroupMemberUserIDs :many
-- Joined members (system context, realtime fan-out and notifications).
SELECT m.user_id::uuid AS user_id FROM group_members m WHERE m.group_id = $1 AND m.user_id IS NOT NULL AND m.joined_at IS NOT NULL;

-- ---------------------------------------------------------------------------
-- Applications.

-- name: InsertApplication :one
INSERT INTO applications (listing_id, org_id, applicant_id, group_id, status, message, answers, preferred_from,
  duration_months, household_size, submitted_at)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11) RETURNING *;

-- name: InsertApplicationConsent :exec
INSERT INTO application_consents (application_id, user_id, consented_at) VALUES ($1, $2, $3);

-- name: GiveConsent :execrows
UPDATE application_consents SET consented_at = now()
WHERE application_id = $1 AND user_id = $2 AND consented_at IS NULL;

-- name: CountMissingConsents :one
SELECT count(*)::int FROM application_consents WHERE application_id = $1 AND consented_at IS NULL;

-- name: SubmitApplication :execrows
UPDATE applications SET status = 'submitted', submitted_at = now() WHERE id = $1 AND status = 'pending_consent';

-- name: GetApplication :one
SELECT a.*, coalesce(s.title, l.title, '{}'::jsonb)::jsonb AS listing_title, g.name AS group_name,
  -- listing_search first: the applicant cannot read listings (RLS), the public index row carries the flag.
  coalesce(s.is_demo, l.is_demo, false)::boolean AS listing_is_demo
FROM applications a
LEFT JOIN listing_search s ON s.listing_id = a.listing_id
LEFT JOIN listings l ON l.id = a.listing_id
LEFT JOIN tenant_groups g ON g.id = a.group_id
WHERE a.id = $1;

-- name: ListMyApplications :many
SELECT a.*, coalesce(s.title, l.title, '{}'::jsonb)::jsonb AS listing_title, g.name AS group_name,
  c.consented_at AS my_consent_at, (c.user_id IS NOT NULL)::boolean AS consent_needed
FROM applications a
LEFT JOIN listing_search s ON s.listing_id = a.listing_id
LEFT JOIN listings l ON l.id = a.listing_id
LEFT JOIN tenant_groups g ON g.id = a.group_id
LEFT JOIN application_consents c ON c.application_id = a.id AND c.user_id = sqlc.arg(user_id)::uuid
WHERE a.applicant_id = sqlc.arg(user_id)::uuid
   OR a.group_id IN (SELECT m.group_id FROM group_members m WHERE m.user_id = sqlc.arg(user_id)::uuid)
ORDER BY a.created_at DESC;

-- name: ListApplicationConsents :many
SELECT c.application_id, c.user_id, c.consented_at, u.display_name
FROM application_consents c JOIN users u ON u.id = c.user_id
WHERE c.application_id = $1 ORDER BY u.display_name;

-- name: ListListingApplications :many
-- The landlord's applicant overview (RLS: organization members).
SELECT a.*, u.display_name AS applicant_name, coalesce(u.verification_level, 'none')::text AS verification_level,
  coalesce(group_display_name(a.group_id), '')::text AS group_name
FROM applications a
JOIN users u ON u.id = a.applicant_id
WHERE a.listing_id = $1 AND a.org_id = $2 AND a.status <> 'pending_consent'
ORDER BY CASE coalesce(u.verification_level, 'none') WHEN 'identity' THEN 0 WHEN 'phone' THEN 1 WHEN 'email' THEN 2 ELSE 3 END,
  a.submitted_at;

-- name: DecideApplication :execrows
UPDATE applications SET status = sqlc.arg(status), reject_reason = sqlc.narg(reject_reason), decided_at = now()
WHERE id = sqlc.arg(id) AND org_id = sqlc.arg(org_id) AND status = ANY(sqlc.arg(from_status)::text[]);

-- name: RejectOtherApplications :many
UPDATE applications SET status = 'rejected', reject_reason = 'other_applicant_chosen', decided_at = now()
WHERE listing_id = $1 AND id <> $2 AND status IN ('pending_consent', 'submitted', 'invited')
RETURNING id;

-- name: WithdrawApplication :execrows
UPDATE applications SET status = 'withdrawn', decided_at = now()
WHERE id = $1 AND status IN ('pending_consent', 'submitted', 'invited');

-- name: ApplicationPeople :many
-- Applicant and joined group members with their passport facts (system
-- context; callers check access first).
WITH a AS (SELECT * FROM applications WHERE applications.id = $1),
people AS (
  SELECT a.applicant_id AS user_id FROM a
  UNION
  SELECT m.user_id FROM group_members m JOIN a ON m.group_id = a.group_id WHERE m.user_id IS NOT NULL AND m.joined_at IS NOT NULL
)
SELECT u.id, u.display_name, u.email, u.locale, coalesce(u.verification_level, 'none')::text AS verification_level,
  p.income_key, p.income_filename, coalesce(p.isir_status, 'unchecked')::text AS isir_status, p.isir_checked_at
FROM people JOIN users u ON u.id = people.user_id
LEFT JOIN tenant_passports p ON p.user_id = u.id
WHERE u.pseudonymized_at IS NULL
ORDER BY u.display_name;

-- name: SystemGetApplication :one
SELECT a.*, coalesce(s.title, l.title, '{}'::jsonb)::jsonb AS listing_title, g.name AS group_name
FROM applications a
LEFT JOIN listing_search s ON s.listing_id = a.listing_id
LEFT JOIN listings l ON l.id = a.listing_id
LEFT JOIN tenant_groups g ON g.id = a.group_id
WHERE a.id = $1;

-- name: SetApplicationAI :exec
UPDATE applications SET ai_status = $2, ai_summary = $3, ai_model = $4 WHERE id = $1;

-- name: OrgMessagingMembers :many
SELECT u.id, u.email, u.locale, u.display_name FROM memberships m JOIN users u ON u.id = m.user_id
WHERE m.org_id = $1 AND m.role IN ('owner', 'admin', 'agent') AND u.pseudonymized_at IS NULL;

-- ---------------------------------------------------------------------------
-- Roommate profiles.

-- name: GetRoommateProfile :one
SELECT user_id, active, coalesce(admin_path::text, '')::text AS admin_path, area_label, budget_max, move_in, about,
  lifestyle, has_room, updated_at
FROM roommate_profiles WHERE user_id = $1;

-- name: UpsertRoommateProfile :one
INSERT INTO roommate_profiles (user_id, active, admin_path, area_label, budget_max, move_in, about, lifestyle, has_room)
VALUES ($1, $2, sqlc.narg(admin_path)::text::ltree, $3, $4, $5, $6, $7, $8)
ON CONFLICT (user_id) DO UPDATE SET active = excluded.active, admin_path = excluded.admin_path,
  area_label = excluded.area_label, budget_max = excluded.budget_max, move_in = excluded.move_in,
  about = excluded.about, lifestyle = excluded.lifestyle, has_room = excluded.has_room
RETURNING user_id;

-- name: ListRoommateProfiles :many
-- Active profiles in an area (or anywhere), with public user facts.
SELECT r.user_id, coalesce(r.admin_path::text, '')::text AS admin_path, r.area_label, r.budget_max, r.move_in, r.about, r.lifestyle,
  r.has_room, r.updated_at, u.display_name, coalesce(u.verification_level, 'none')::text AS verification_level
FROM roommate_profiles r JOIN users u ON u.id = r.user_id
WHERE r.active AND r.user_id <> sqlc.arg(exclude)::uuid
  AND (sqlc.narg(area)::text IS NULL OR r.admin_path IS NULL OR r.admin_path <@ sqlc.narg(area)::text::ltree
       OR sqlc.narg(area)::text::ltree <@ r.admin_path)
ORDER BY r.updated_at DESC
LIMIT 300;

-- name: ListingMatchFacts :one
-- What roommate matching needs about a listing (system context).
SELECT s.listing_id, s.unit_kind, s.rent_amount, s.attributes, coalesce(s.admin_path::text, '')::text AS admin_path
FROM listing_search s WHERE s.listing_id = $1;

-- ---------------------------------------------------------------------------
-- Tenant Passport.

-- name: GetPassport :one
SELECT * FROM tenant_passports WHERE user_id = $1;

-- name: SetPassportIncome :exec
INSERT INTO tenant_passports (user_id, income_key, income_filename, income_uploaded_at) VALUES ($1, $2, $3, now())
ON CONFLICT (user_id) DO UPDATE SET income_key = excluded.income_key, income_filename = excluded.income_filename,
  income_uploaded_at = now();

-- name: ClearPassportIncome :exec
UPDATE tenant_passports SET income_key = NULL, income_filename = NULL, income_uploaded_at = NULL WHERE user_id = $1;

-- name: SetPassportISIR :exec
INSERT INTO tenant_passports (user_id, isir_status, isir_checked_at) VALUES ($1, $2, now())
ON CONFLICT (user_id) DO UPDATE SET isir_status = excluded.isir_status, isir_checked_at = now();

-- ---------------------------------------------------------------------------
-- Viewings.

-- name: CreateViewingSlot :one
INSERT INTO viewing_slots (org_id, listing_id, starts_at, duration_min, capacity, note)
VALUES ($1, $2, $3, $4, $5, $6) RETURNING *;

-- name: DeleteViewingSlot :execrows
DELETE FROM viewing_slots WHERE id = $1 AND org_id = $2;

-- name: SlotsWithAvailability :many
-- Upcoming slots with the number of active bookings (system context: the
-- count must include other applicants' bookings).
SELECT s.*, (SELECT count(*) FROM viewing_bookings b WHERE b.slot_id = s.id AND b.cancelled_at IS NULL)::int AS booked
FROM viewing_slots s
WHERE s.listing_id = $1 AND s.starts_at > now()
  AND EXISTS (SELECT 1 FROM listings l WHERE l.id = s.listing_id AND l.deleted_at IS NULL)
ORDER BY s.starts_at;

-- name: ListSlotBookings :many
-- Bookings of a listing's slots for the landlord (RLS: organization members).
SELECT b.id, b.slot_id, b.application_id, b.created_at, u.display_name AS applicant_name, a.household_size
FROM viewing_bookings b
JOIN viewing_slots s ON s.id = b.slot_id
JOIN applications a ON a.id = b.application_id
JOIN users u ON u.id = a.applicant_id
WHERE s.listing_id = $1 AND b.cancelled_at IS NULL
  AND EXISTS (SELECT 1 FROM listings l WHERE l.id = s.listing_id AND l.deleted_at IS NULL)
ORDER BY s.starts_at;

-- name: LockSlot :one
SELECT * FROM viewing_slots WHERE id = $1 FOR UPDATE;

-- name: CountSlotBookings :one
SELECT count(*)::int FROM viewing_bookings WHERE slot_id = $1 AND cancelled_at IS NULL;

-- name: CancelApplicationBookings :exec
UPDATE viewing_bookings SET cancelled_at = now() WHERE application_id = $1 AND cancelled_at IS NULL;

-- name: InsertBooking :one
INSERT INTO viewing_bookings (slot_id, application_id, booked_by) VALUES ($1, $2, $3) RETURNING *;

-- name: CancelBooking :execrows
UPDATE viewing_bookings SET cancelled_at = now() WHERE id = $1 AND cancelled_at IS NULL;

-- name: MyViewings :many
SELECT b.id, b.slot_id, b.application_id, b.created_at, s.starts_at, s.duration_min, s.note, s.listing_id,
  coalesce(ls.title, '{}'::jsonb)::jsonb AS listing_title, ls.city, ls.city_part
FROM viewing_bookings b
JOIN viewing_slots s ON s.id = b.slot_id
JOIN applications a ON a.id = b.application_id
LEFT JOIN listing_search ls ON ls.listing_id = s.listing_id
WHERE b.cancelled_at IS NULL AND s.starts_at > now() - interval '1 day'
  AND (a.applicant_id = sqlc.arg(user_id)::uuid
       OR a.group_id IN (SELECT m.group_id FROM group_members m WHERE m.user_id = sqlc.arg(user_id)::uuid))
ORDER BY s.starts_at;

-- name: BookingForReminder :one
SELECT b.id, b.application_id, b.cancelled_at, s.starts_at, s.duration_min, s.note, s.listing_id,
  coalesce(ls.title, '{}'::jsonb)::jsonb AS listing_title, coalesce(ls.city, '')::text AS city
FROM viewing_bookings b
JOIN viewing_slots s ON s.id = b.slot_id
LEFT JOIN listing_search ls ON ls.listing_id = s.listing_id
WHERE b.id = $1;

-- ---------------------------------------------------------------------------
-- GDPR erasure (system context).

-- name: DeleteRoommateProfile :exec
DELETE FROM roommate_profiles WHERE user_id = $1;

-- name: DeletePassport :one
DELETE FROM tenant_passports WHERE user_id = $1 RETURNING income_key;

-- name: DeleteUserPushDevices :exec
DELETE FROM push_devices WHERE user_id = $1;

-- name: DeleteUserGroupMemberships :exec
DELETE FROM group_members WHERE user_id = $1;

-- ---------------------------------------------------------------------------
-- Concurrency guards and limits (review V-7, S-D9, S-D4, S-D5).

-- name: LockApplication :one
-- Serializes consents of one group application (RLS: parties).
SELECT id, status FROM applications WHERE id = $1 FOR UPDATE;

-- name: LockListingForDecision :one
-- Serializes decisions on a listing's applications (RLS: organization
-- members). NO KEY UPDATE leaves new applications (FK checks) unblocked.
SELECT id FROM listings WHERE id = $1 AND org_id = $2 FOR NO KEY UPDATE;

-- name: CountOtherAcceptedApplications :one
SELECT count(*)::int FROM applications WHERE listing_id = $1 AND id <> $2 AND status = 'accepted';

-- name: CancelSlotBookings :many
-- Cancels the active bookings of an organization's upcoming slot before it
-- is deleted and returns the applications to notify (RLS: organization
-- members).
UPDATE viewing_bookings b SET cancelled_at = now()
FROM viewing_slots s
WHERE s.id = b.slot_id AND b.slot_id = sqlc.arg(slot_id) AND s.org_id = sqlc.arg(org_id)
  AND b.cancelled_at IS NULL AND s.starts_at > now()
RETURNING b.id, b.application_id;

-- name: GetViewingSlot :one
SELECT * FROM viewing_slots WHERE id = $1 AND org_id = $2;

-- name: CountRecentActorActions :one
-- Rate limits backed by the audit log (system context).
SELECT count(*)::int FROM audit_events
WHERE actor_id = sqlc.arg(actor_id) AND action = sqlc.arg(action) AND occurred_at > sqlc.arg(since)::timestamptz;

-- name: ViewingReminderSent :one
-- Idempotency of reminder jobs: this reminder was already queued (audit
-- marker written in the same transaction as the e-mails). The two
-- reminders of a booking are 22 hours apart, so a 12 hour window tells a
-- retry from the next reminder.
SELECT EXISTS (SELECT 1 FROM audit_events
  WHERE entity = 'viewing_booking' AND entity_id = sqlc.arg(booking_id)::uuid AND action = 'viewing.reminded'
    AND occurred_at > now() - interval '12 hours')::boolean;
