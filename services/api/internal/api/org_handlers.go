package api

import (
	"context"

	"github.com/terrareality/terrareality/services/api/internal/api/gen"
	"github.com/terrareality/terrareality/services/api/internal/org"
	"github.com/terrareality/terrareality/services/api/internal/platform/apperr"
)

func orgInput(b *gen.OrgInput) org.Input {
	return org.Input{Name: &b.Name, RegistrationNo: b.RegistrationNo, VatNo: b.VatNo, Jurisdiction: b.JurisdictionCode}
}

// ListMyOrgs implements GET /v1/orgs.
func (s *Server) ListMyOrgs(ctx context.Context, _ gen.ListMyOrgsRequestObject) (gen.ListMyOrgsResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	list, err := s.Orgs.List(ctx, p)
	if err != nil {
		return nil, err
	}
	out := gen.ListMyOrgs200JSONResponse{}
	for _, m := range list {
		out = append(out, membershipDTO(m))
	}
	return out, nil
}

// CreateOrg implements POST /v1/orgs.
func (s *Server) CreateOrg(ctx context.Context, r gen.CreateOrgRequestObject) (gen.CreateOrgResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	m, err := s.Orgs.Create(ctx, p, orgInput(r.Body))
	if err != nil {
		return nil, err
	}
	return gen.CreateOrg201JSONResponse(membershipDTO(m)), nil
}

// GetOrg implements GET /v1/orgs/{orgId}.
func (s *Server) GetOrg(ctx context.Context, r gen.GetOrgRequestObject) (gen.GetOrgResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	m, err := s.Orgs.Get(ctx, p, r.OrgId)
	if err != nil {
		return nil, err
	}
	return gen.GetOrg200JSONResponse(membershipDTO(m)), nil
}

// UpdateOrg implements PATCH /v1/orgs/{orgId}.
func (s *Server) UpdateOrg(ctx context.Context, r gen.UpdateOrgRequestObject) (gen.UpdateOrgResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	m, err := s.Orgs.Update(ctx, p, r.OrgId, orgInput(r.Body))
	if err != nil {
		return nil, err
	}
	return gen.UpdateOrg200JSONResponse(membershipDTO(m)), nil
}

// ListOrgMembers implements GET /v1/orgs/{orgId}/members.
func (s *Server) ListOrgMembers(ctx context.Context, r gen.ListOrgMembersRequestObject) (gen.ListOrgMembersResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	rows, role, err := s.Orgs.Members(ctx, p, r.OrgId)
	if err != nil {
		return nil, err
	}
	// Read-only outsiders (viewer, investor) see names and roles, not the
	// team's e-mail addresses.
	hide := role == org.Viewer || role == org.Investor
	out := gen.ListOrgMembers200JSONResponse{}
	for _, m := range rows {
		mem := gen.Member{UserId: m.UserID, DisplayName: m.DisplayName, Role: gen.Role(m.Role),
			VerificationLevel: level(m.VerificationLevel), JoinedAt: m.CreatedAt}
		if !hide || m.UserID == p.UserID {
			e := m.Email
			mem.Email = &e
		}
		out = append(out, mem)
	}
	return out, nil
}

// UpdateOrgMember implements PATCH /v1/orgs/{orgId}/members/{userId}.
func (s *Server) UpdateOrgMember(ctx context.Context, r gen.UpdateOrgMemberRequestObject) (gen.UpdateOrgMemberResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	if err := s.Orgs.UpdateMemberRole(ctx, p, r.OrgId, r.UserId, string(r.Body.Role)); err != nil {
		return nil, err
	}
	return gen.UpdateOrgMember204Response{}, nil
}

// RemoveOrgMember implements DELETE /v1/orgs/{orgId}/members/{userId}.
func (s *Server) RemoveOrgMember(ctx context.Context, r gen.RemoveOrgMemberRequestObject) (gen.RemoveOrgMemberResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	if err := s.Orgs.RemoveMember(ctx, p, r.OrgId, r.UserId); err != nil {
		return nil, err
	}
	return gen.RemoveOrgMember204Response{}, nil
}

// ListOrgInvitations implements GET /v1/orgs/{orgId}/invitations.
func (s *Server) ListOrgInvitations(ctx context.Context, r gen.ListOrgInvitationsRequestObject) (gen.ListOrgInvitationsResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	list, err := s.Orgs.Invitations(ctx, p, r.OrgId)
	if err != nil {
		return nil, err
	}
	out := gen.ListOrgInvitations200JSONResponse{}
	for _, i := range list {
		out = append(out, gen.Invitation{Id: i.ID, Email: i.Email, Role: gen.Role(i.Role), ExpiresAt: i.ExpiresAt, CreatedAt: i.CreatedAt})
	}
	return out, nil
}

// CreateOrgInvitation implements POST /v1/orgs/{orgId}/invitations.
func (s *Server) CreateOrgInvitation(ctx context.Context, r gen.CreateOrgInvitationRequestObject) (gen.CreateOrgInvitationResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	if err := s.requireVerifiedEmail(ctx); err != nil {
		return nil, err
	}
	if err := s.limit(ctx, string(r.Body.Email)); err != nil {
		return nil, err
	}
	i, err := s.Orgs.Invite(ctx, p, r.OrgId, string(r.Body.Email), string(r.Body.Role), localeOf(r.Body.Locale))
	if err != nil {
		return nil, err
	}
	return gen.CreateOrgInvitation201JSONResponse{Id: i.ID, Email: i.Email, Role: gen.Role(i.Role), ExpiresAt: i.ExpiresAt, CreatedAt: i.CreatedAt}, nil
}

func (s *Server) requireVerifiedEmail(ctx context.Context) error {
	me, err := s.me(ctx)
	if err != nil {
		return err
	}
	if !me.EmailVerified {
		return apperr.Forbidden("email_not_verified", "verify your e-mail first")
	}
	return nil
}

// RevokeOrgInvitation implements DELETE /v1/orgs/{orgId}/invitations/{invitationId}.
func (s *Server) RevokeOrgInvitation(ctx context.Context, r gen.RevokeOrgInvitationRequestObject) (gen.RevokeOrgInvitationResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	if err := s.Orgs.RevokeInvitation(ctx, p, r.OrgId, r.InvitationId); err != nil {
		return nil, err
	}
	return gen.RevokeOrgInvitation204Response{}, nil
}

// ListOrgAudit implements GET /v1/orgs/{orgId}/audit.
func (s *Server) ListOrgAudit(ctx context.Context, r gen.ListOrgAuditRequestObject) (gen.ListOrgAuditResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	lim := limitOf(r.Params.Limit)
	rows, role, err := s.Orgs.Audit(ctx, p, r.OrgId, r.Params.Before, lim)
	if err != nil {
		return nil, err
	}
	page := auditRows(rows, lim)
	// Changed values are for owners and admins only (today only they may
	// read the log; the guard keeps it so if audit.read is ever widened).
	if role != org.Owner && role != org.Admin {
		for i := range page.Items {
			page.Items[i].Diff = map[string]any{}
		}
	}
	return gen.ListOrgAudit200JSONResponse(page), nil
}

// LookupInvitation implements POST /v1/invitations/lookup.
func (s *Server) LookupInvitation(ctx context.Context, r gen.LookupInvitationRequestObject) (gen.LookupInvitationResponseObject, error) {
	if err := s.limit(ctx, ""); err != nil {
		return nil, err
	}
	i, err := s.Orgs.Preview(ctx, r.Body.Token)
	if err != nil {
		return nil, err
	}
	return gen.LookupInvitation200JSONResponse{OrgName: i.OrgName, Role: gen.Role(i.Role), Email: i.Email,
		InviterName: i.InviterName, ExpiresAt: i.ExpiresAt, Status: gen.InvitationPreviewStatus(org.InvitationStatus(i))}, nil
}

// AcceptInvitation implements POST /v1/invitations/accept.
func (s *Server) AcceptInvitation(ctx context.Context, r gen.AcceptInvitationRequestObject) (gen.AcceptInvitationResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	m, err := s.Orgs.Accept(ctx, p, r.Body.Token)
	if err != nil {
		return nil, err
	}
	return gen.AcceptInvitation200JSONResponse(membershipDTO(m)), nil
}
