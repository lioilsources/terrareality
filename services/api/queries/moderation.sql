-- M8: DSA notice-and-action for listings (system context; staff and the
-- anonymous reporter path never run as an org member).

-- name: CreateListingReport :one
INSERT INTO moderation_cases (kind, source, listing_id, reporter_id, reason, note,
  reporter_contact_email, reporter_contact_name, reporter_locale, ai_status)
VALUES ('listing', 'report', $1, $2, $3, $4, $5, $6, $7, 'disabled')
RETURNING id;

-- name: ListingOwnerRecipients :many
-- Owners and admins of the organization behind a listing (DSA art. 17
-- statement of reasons on unpublish or a change request).
SELECT u.id, u.email, u.locale
FROM memberships m JOIN users u ON u.id = m.user_id
WHERE m.org_id = $1 AND m.role IN ('owner', 'admin') AND u.pseudonymized_at IS NULL
ORDER BY m.role DESC, u.id;

-- name: ListingForReport :one
SELECT l.id, l.org_id, l.status, coalesce(s.title, l.title, '{}'::jsonb)::jsonb AS title
FROM listings l LEFT JOIN listing_search s ON s.listing_id = l.id
WHERE l.id = $1 AND l.deleted_at IS NULL;

-- name: WithdrawPendingVersionsForModeration :exec
-- Unpublished after a report: pending versions go back to the owner so a
-- resubmission is reviewed from scratch.
UPDATE listing_versions SET status = 'withdrawn' WHERE listing_id = $1 AND status = 'pending';
