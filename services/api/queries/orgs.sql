-- Queries on RLS tables run inside db.WithUser transactions unless noted.

-- name: CreateOrganization :one
INSERT INTO organizations (kind, name, registration_no, vat_no, jurisdiction_code, personal_owner_id)
VALUES ($1, $2, $3, $4, $5, $6)
RETURNING *;

-- name: GetOrganization :one
SELECT * FROM organizations WHERE id = $1 AND deleted_at IS NULL;

-- name: GetPersonalOrganization :one
SELECT * FROM organizations WHERE personal_owner_id = $1;

-- name: UpdateOrganization :one
UPDATE organizations SET name = $2, registration_no = $3, vat_no = $4
WHERE id = $1 AND deleted_at IS NULL
RETURNING *;

-- name: SoftDeleteOrganization :exec
UPDATE organizations SET deleted_at = now() WHERE id = $1;

-- name: ListMyOrganizations :many
SELECT o.*, m.role FROM organizations o
JOIN memberships m ON m.org_id = o.id
WHERE m.user_id = $1 AND o.deleted_at IS NULL
ORDER BY (o.kind = 'personal') DESC, o.name;

-- name: ListAllOrganizationIDs :many
-- System context: every organization (RLS tests and backoffice).
SELECT id FROM organizations ORDER BY id;

-- name: AddMembership :exec
INSERT INTO memberships (org_id, user_id, role) VALUES ($1, $2, $3)
ON CONFLICT (org_id, user_id) DO UPDATE SET role = EXCLUDED.role;

-- name: GetMembership :one
SELECT * FROM memberships WHERE org_id = $1 AND user_id = $2;

-- name: ListMembers :many
SELECT m.org_id, m.user_id, m.role, m.created_at, u.email, u.display_name, u.verification_level
FROM memberships m JOIN users u ON u.id = m.user_id
WHERE m.org_id = $1
ORDER BY m.created_at;

-- name: UpdateMembershipRole :execrows
UPDATE memberships SET role = $3 WHERE org_id = $1 AND user_id = $2;

-- name: DeleteMembership :execrows
DELETE FROM memberships WHERE org_id = $1 AND user_id = $2;

-- name: CountOwners :one
SELECT count(*) FROM memberships WHERE org_id = $1 AND role = 'owner';

-- name: ListUserMemberships :many
-- System context: used by GDPR erasure.
SELECT m.org_id, m.role, o.kind,
  (SELECT count(*) FROM memberships x WHERE x.org_id = m.org_id) AS member_count,
  (SELECT count(*) FROM memberships x WHERE x.org_id = m.org_id AND x.role = 'owner') AS owner_count
FROM memberships m JOIN organizations o ON o.id = m.org_id
WHERE m.user_id = $1 AND o.deleted_at IS NULL;

-- name: CreateInvitation :one
INSERT INTO invitations (org_id, email, role, token_hash, invited_by, expires_at)
VALUES ($1, $2, $3, $4, $5, $6)
RETURNING *;

-- name: ListOpenInvitations :many
SELECT * FROM invitations
WHERE org_id = $1 AND accepted_at IS NULL AND revoked_at IS NULL AND expires_at > now()
ORDER BY created_at DESC;

-- name: RevokeInvitation :execrows
UPDATE invitations SET revoked_at = now()
WHERE id = $1 AND org_id = $2 AND accepted_at IS NULL AND revoked_at IS NULL;

-- name: RevokeOpenInvitationsForEmail :exec
UPDATE invitations SET revoked_at = now()
WHERE org_id = $1 AND email = $2 AND accepted_at IS NULL AND revoked_at IS NULL;

-- name: GetInvitationByToken :one
-- System context: the invitee is not a member yet.
SELECT i.*, o.name AS org_name, coalesce(u.display_name, '') AS inviter_name
FROM invitations i
JOIN organizations o ON o.id = i.org_id AND o.deleted_at IS NULL
LEFT JOIN users u ON u.id = i.invited_by
WHERE i.token_hash = $1;

-- name: AcceptInvitation :execrows
UPDATE invitations SET accepted_at = now(), accepted_by = $2
WHERE id = $1 AND accepted_at IS NULL AND revoked_at IS NULL AND expires_at > now();
