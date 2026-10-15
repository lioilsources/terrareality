-- +goose Up
-- Pilot onboarding (terractl onboard-owner) invites the first owner of a new
-- organization. The public API still cannot invite owners: its contract enum
-- for InvitationInput.role excludes 'owner'.
ALTER TABLE invitations DROP CONSTRAINT invitations_role_check;
ALTER TABLE invitations ADD CONSTRAINT invitations_role_check
  CHECK (role IN ('owner', 'admin', 'agent', 'accountant', 'maintenance', 'viewer', 'investor'));

-- +goose Down
DELETE FROM invitations WHERE role = 'owner';
ALTER TABLE invitations DROP CONSTRAINT invitations_role_check;
ALTER TABLE invitations ADD CONSTRAINT invitations_role_check
  CHECK (role IN ('admin', 'agent', 'accountant', 'maintenance', 'viewer', 'investor'));
