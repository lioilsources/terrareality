package org

import (
	"context"
	"errors"
	"slices"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/terrareality/terrareality/services/api/internal/audit"
	"github.com/terrareality/terrareality/services/api/internal/auth"
	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/notify"
	"github.com/terrareality/terrareality/services/api/internal/platform/apperr"
	platformdb "github.com/terrareality/terrareality/services/api/internal/platform/db"
	"github.com/terrareality/terrareality/services/api/internal/platform/tokens"
)

const invitationTTL = 7 * 24 * time.Hour

var errNotFound = apperr.NotFound("org_not_found", "organization not found")

// Service manages organizations.
type Service struct {
	Pool       *pgxpool.Pool
	Outbox     notify.Outbox
	Render     *notify.Renderer
	WebBaseURL string
}

// Membership is an organization with the caller's role.
type Membership struct {
	Org  db.Organization
	Role string
}

// asUser runs fn with row-level security for the principal.
func (s *Service) asUser(ctx context.Context, p *auth.Principal, fn func(q *db.Queries, tx pgx.Tx) error) error {
	return platformdb.AsUser(ctx, s.Pool, p.UserID, func(tx pgx.Tx) error { return fn(db.New(tx), tx) })
}

// Access loads an organization and the caller's role, failing with 404 when
// the caller is not a member (row-level security hides the row) and 403 when
// the role lacks perm (empty perm = membership is enough).
func Access(ctx context.Context, q *db.Queries, userID, orgID uuid.UUID, perm Permission) (Membership, error) {
	o, err := q.GetOrganization(ctx, orgID)
	if errors.Is(err, pgx.ErrNoRows) {
		return Membership{}, errNotFound
	}
	if err != nil {
		return Membership{}, err
	}
	m, err := q.GetMembership(ctx, db.GetMembershipParams{OrgID: orgID, UserID: userID})
	if errors.Is(err, pgx.ErrNoRows) {
		return Membership{}, errNotFound
	}
	if err != nil {
		return Membership{}, err
	}
	if perm != "" && !Can(m.Role, perm) {
		return Membership{}, apperr.Forbidden("insufficient_role", "your role does not allow this")
	}
	return Membership{Org: o, Role: m.Role}, nil
}

// List returns the caller's organizations, personal first.
func (s *Service) List(ctx context.Context, p *auth.Principal) ([]Membership, error) {
	var out []Membership
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		rows, err := q.ListMyOrganizations(ctx, p.UserID)
		for _, r := range rows {
			out = append(out, Membership{Org: db.Organization{ID: r.ID, Kind: r.Kind, Name: r.Name,
				RegistrationNo: r.RegistrationNo, VatNo: r.VatNo, JurisdictionCode: r.JurisdictionCode,
				PersonalOwnerID: r.PersonalOwnerID, CreatedAt: r.CreatedAt, UpdatedAt: r.UpdatedAt}, Role: r.Role})
		}
		return err
	})
	return out, err
}

// Input is the editable part of an organization.
type Input struct {
	Name, RegistrationNo, VatNo, Jurisdiction *string
}

func trimPtr(s *string) *string {
	if s == nil {
		return nil
	}
	t := strings.TrimSpace(*s)
	if t == "" {
		return nil
	}
	return &t
}

// Create makes a company organization owned by the caller. A verified e-mail
// is required to keep throwaway accounts from creating organizations.
func (s *Service) Create(ctx context.Context, p *auth.Principal, in Input) (Membership, error) {
	var m Membership
	err := platformdb.InTx(ctx, s.Pool, func(tx pgx.Tx) error {
		q := db.New(tx)
		u, err := q.GetUser(ctx, p.UserID)
		if err != nil {
			return err
		}
		if u.EmailVerifiedAt == nil {
			return apperr.Forbidden("email_not_verified", "verify your e-mail first")
		}
		jur := "CZ"
		if j := trimPtr(in.Jurisdiction); j != nil {
			jur = *j
		}
		if _, err := q.GetJurisdiction(ctx, jur); err != nil {
			return apperr.Unprocessable("unknown_jurisdiction", "unknown jurisdiction")
		}
		o, err := q.CreateOrganization(ctx, db.CreateOrganizationParams{Kind: "company", Name: strings.TrimSpace(*in.Name),
			RegistrationNo: trimPtr(in.RegistrationNo), VatNo: trimPtr(in.VatNo), JurisdictionCode: jur})
		if err != nil {
			return err
		}
		if err := q.AddMembership(ctx, db.AddMembershipParams{OrgID: o.ID, UserID: u.ID, Role: Owner}); err != nil {
			return err
		}
		m = Membership{Org: o, Role: Owner}
		return audit.Record(ctx, q, audit.Event{OrgID: &o.ID, Entity: "organization", EntityID: &o.ID, Action: "org.created",
			Diff: map[string]any{"name": o.Name}})
	})
	return m, err
}

// Get returns one organization the caller belongs to.
func (s *Service) Get(ctx context.Context, p *auth.Principal, orgID uuid.UUID) (Membership, error) {
	var m Membership
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		var err error
		m, err = Access(ctx, q, p.UserID, orgID, "")
		return err
	})
	return m, err
}

// Update changes organization details (owner, admin).
func (s *Service) Update(ctx context.Context, p *auth.Principal, orgID uuid.UUID, in Input) (Membership, error) {
	var m Membership
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		var err error
		m, err = Access(ctx, q, p.UserID, orgID, PermOrgManage)
		if err != nil {
			return err
		}
		before := m.Org
		o, err := q.UpdateOrganization(ctx, db.UpdateOrganizationParams{ID: orgID, Name: strings.TrimSpace(*in.Name),
			RegistrationNo: trimPtr(in.RegistrationNo), VatNo: trimPtr(in.VatNo)})
		if err != nil {
			return err
		}
		m.Org = o
		return audit.Record(ctx, q, audit.Event{OrgID: &orgID, Entity: "organization", EntityID: &orgID, Action: "org.updated",
			Diff: map[string]any{"name": []string{before.Name, o.Name}}})
	})
	return m, err
}

// Members lists members and returns the caller's role.
func (s *Service) Members(ctx context.Context, p *auth.Principal, orgID uuid.UUID) ([]db.ListMembersRow, string, error) {
	var out []db.ListMembersRow
	var role string
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		m, err := Access(ctx, q, p.UserID, orgID, "")
		if err != nil {
			return err
		}
		role = m.Role
		out, err = q.ListMembers(ctx, orgID)
		return err
	})
	return out, role, err
}

// UpdateMemberRole changes a role. Only owners grant or revoke ownership, and
// the last owner cannot be demoted.
func (s *Service) UpdateMemberRole(ctx context.Context, p *auth.Principal, orgID, userID uuid.UUID, role string) error {
	return s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		me, err := Access(ctx, q, p.UserID, orgID, PermMembersManage)
		if err != nil {
			return err
		}
		if me.Org.Kind == "personal" && role == Owner {
			return apperr.Forbidden("personal_org_single_owner", "a personal organization has exactly one owner")
		}
		target, err := q.GetMembership(ctx, db.GetMembershipParams{OrgID: orgID, UserID: userID})
		if errors.Is(err, pgx.ErrNoRows) {
			return apperr.NotFound("member_not_found", "member not found")
		}
		if err != nil {
			return err
		}
		if (target.Role == Owner || role == Owner) && me.Role != Owner {
			return apperr.Forbidden("owner_required", "only an owner can change ownership")
		}
		if target.Role == Owner && role != Owner {
			if err := ensureAnotherOwner(ctx, q, orgID); err != nil {
				return err
			}
		}
		if _, err := q.UpdateMembershipRole(ctx, db.UpdateMembershipRoleParams{OrgID: orgID, UserID: userID, Role: role}); err != nil {
			return err
		}
		return audit.Record(ctx, q, audit.Event{OrgID: &orgID, Entity: "membership", EntityID: &userID, Action: "member.role_changed",
			Diff: map[string]any{"role": []string{target.Role, role}}})
	})
}

func ensureAnotherOwner(ctx context.Context, q *db.Queries, orgID uuid.UUID) error {
	n, err := q.CountOwners(ctx, orgID)
	if err != nil {
		return err
	}
	if n <= 1 {
		return apperr.Conflict("last_owner", "an organization needs at least one owner")
	}
	return nil
}

// RemoveMember removes a member; members may remove themselves (leave).
func (s *Service) RemoveMember(ctx context.Context, p *auth.Principal, orgID, userID uuid.UUID) error {
	return s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		perm := PermMembersManage
		if userID == p.UserID {
			perm = ""
		}
		me, err := Access(ctx, q, p.UserID, orgID, perm)
		if err != nil {
			return err
		}
		target, err := q.GetMembership(ctx, db.GetMembershipParams{OrgID: orgID, UserID: userID})
		if errors.Is(err, pgx.ErrNoRows) {
			return apperr.NotFound("member_not_found", "member not found")
		}
		if err != nil {
			return err
		}
		if me.Org.Kind == "personal" && target.Role == Owner {
			return apperr.Forbidden("personal_org_single_owner", "the owner cannot leave a personal organization")
		}
		if target.Role == Owner {
			if userID != p.UserID && me.Role != Owner {
				return apperr.Forbidden("owner_required", "only an owner can remove an owner")
			}
			if err := ensureAnotherOwner(ctx, q, orgID); err != nil {
				return err
			}
		}
		if _, err := q.DeleteMembership(ctx, db.DeleteMembershipParams{OrgID: orgID, UserID: userID}); err != nil {
			return err
		}
		return audit.Record(ctx, q, audit.Event{OrgID: &orgID, Entity: "membership", EntityID: &userID, Action: "member.removed",
			Diff: map[string]any{"role": target.Role}})
	})
}

// InvitableRoles are the roles an invitation through the API may carry.
// Ownership is never granted by invitation (owners promote members; pilot
// owner invitations are created by terractl in system context).
var InvitableRoles = []string{Admin, Agent, Accountant, Maintenance, Viewer, Investor}

// Invite e-mails an invitation (owner, admin).
func (s *Service) Invite(ctx context.Context, p *auth.Principal, orgID uuid.UUID, email, role, locale string) (db.Invitation, error) {
	if !slices.Contains(InvitableRoles, role) {
		return db.Invitation{}, apperr.Unprocessable("invalid_role", "invitations can carry the roles admin, agent, accountant, maintenance, viewer or investor")
	}
	email = strings.ToLower(strings.TrimSpace(email))
	var inv db.Invitation
	err := s.asUser(ctx, p, func(q *db.Queries, tx pgx.Tx) error {
		m, err := Access(ctx, q, p.UserID, orgID, PermMembersManage)
		if err != nil {
			return err
		}
		inviter, err := db.New(tx).ListMembers(ctx, orgID)
		if err != nil {
			return err
		}
		inviterName := ""
		for _, mem := range inviter {
			if strings.EqualFold(mem.Email, email) {
				return apperr.Conflict("already_member", "this person is already a member")
			}
			if mem.UserID == p.UserID {
				inviterName = mem.DisplayName
				if inviterName == "" {
					inviterName = mem.Email
				}
			}
		}
		if err := q.RevokeOpenInvitationsForEmail(ctx, db.RevokeOpenInvitationsForEmailParams{OrgID: orgID, Email: email}); err != nil {
			return err
		}
		tok := tokens.New()
		inv, err = q.CreateInvitation(ctx, db.CreateInvitationParams{OrgID: orgID, Email: email, Role: role,
			TokenHash: tokens.Hash(tok), InvitedBy: &p.UserID, ExpiresAt: time.Now().Add(invitationTTL)})
		if err != nil {
			return err
		}
		if locale != "en" {
			locale = "cs"
		}
		msg, err := s.Render.Render(notify.Email, email, locale, "invitation", map[string]any{
			"OrgName": m.Org.Name, "InviterName": inviterName, "Role": role, "Link": s.WebBaseURL + "/invite/" + tok})
		if err != nil {
			return err
		}
		if err := s.Outbox.Enqueue(ctx, tx, msg); err != nil {
			return err
		}
		return audit.Record(ctx, q, audit.Event{OrgID: &orgID, Entity: "invitation", EntityID: &inv.ID, Action: "invitation.created",
			Diff: map[string]any{"email": email, "role": role}})
	})
	return inv, err
}

// Invitations lists open invitations.
func (s *Service) Invitations(ctx context.Context, p *auth.Principal, orgID uuid.UUID) ([]db.Invitation, error) {
	var out []db.Invitation
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		if _, err := Access(ctx, q, p.UserID, orgID, PermMembersManage); err != nil {
			return err
		}
		var err error
		out, err = q.ListOpenInvitations(ctx, orgID)
		return err
	})
	return out, err
}

// RevokeInvitation revokes an open invitation.
func (s *Service) RevokeInvitation(ctx context.Context, p *auth.Principal, orgID, id uuid.UUID) error {
	return s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		if _, err := Access(ctx, q, p.UserID, orgID, PermMembersManage); err != nil {
			return err
		}
		n, err := q.RevokeInvitation(ctx, db.RevokeInvitationParams{ID: id, OrgID: orgID})
		if err != nil {
			return err
		}
		if n == 0 {
			return apperr.NotFound("invitation_not_found", "invitation not found")
		}
		return audit.Record(ctx, q, audit.Event{OrgID: &orgID, Entity: "invitation", EntityID: &id, Action: "invitation.revoked"})
	})
}

// InvitationStatus derives open/accepted/revoked/expired.
func InvitationStatus(i db.GetInvitationByTokenRow) string {
	switch {
	case i.AcceptedAt != nil:
		return "accepted"
	case i.RevokedAt != nil:
		return "revoked"
	case time.Now().After(i.ExpiresAt):
		return "expired"
	}
	return "open"
}

// Preview returns an invitation by token (no membership yet, system context).
func (s *Service) Preview(ctx context.Context, token string) (db.GetInvitationByTokenRow, error) {
	i, err := db.New(s.Pool).GetInvitationByToken(ctx, tokens.Hash(token))
	if errors.Is(err, pgx.ErrNoRows) {
		return i, apperr.NotFound("invitation_not_found", "invitation not found")
	}
	return i, err
}

// Accept joins the organization. The invitation e-mail must match the
// account; opening the link proves control of it, so it becomes verified.
func (s *Service) Accept(ctx context.Context, p *auth.Principal, token string) (Membership, error) {
	if p.Impersonated() {
		return Membership{}, apperr.ErrImpersonation
	}
	var m Membership
	err := platformdb.InTx(ctx, s.Pool, func(tx pgx.Tx) error {
		q := db.New(tx)
		i, err := q.GetInvitationByToken(ctx, tokens.Hash(token))
		if errors.Is(err, pgx.ErrNoRows) {
			return apperr.NotFound("invitation_not_found", "invitation not found")
		}
		if err != nil {
			return err
		}
		if st := InvitationStatus(i); st != "open" {
			return apperr.Conflict("invitation_"+st, "the invitation is "+st)
		}
		u, err := q.GetUser(ctx, p.UserID)
		if err != nil {
			return err
		}
		if !strings.EqualFold(u.Email, i.Email) {
			return apperr.Forbidden("invitation_email_mismatch", "the invitation was sent to a different e-mail address")
		}
		if n, err := q.AcceptInvitation(ctx, db.AcceptInvitationParams{ID: i.ID, AcceptedBy: &u.ID}); err != nil || n == 0 {
			if err == nil {
				err = apperr.Conflict("invitation_expired", "the invitation is no longer valid")
			}
			return err
		}
		role := i.Role
		if existing, err := q.GetMembership(ctx, db.GetMembershipParams{OrgID: i.OrgID, UserID: u.ID}); err == nil {
			role = existing.Role // never downgrade an existing member
		} else if errors.Is(err, pgx.ErrNoRows) {
			if err := q.AddMembership(ctx, db.AddMembershipParams{OrgID: i.OrgID, UserID: u.ID, Role: role}); err != nil {
				return err
			}
		} else {
			return err
		}
		if err := q.MarkEmailVerified(ctx, u.ID); err != nil {
			return err
		}
		o, err := q.GetOrganization(ctx, i.OrgID)
		if err != nil {
			return err
		}
		m = Membership{Org: o, Role: role}
		return audit.Record(ctx, q, audit.Event{OrgID: &i.OrgID, Entity: "invitation", EntityID: &i.ID, Action: "invitation.accepted",
			Diff: map[string]any{"role": role}})
	})
	return m, err
}

// Audit lists an organization's audit events (owner, admin) and returns the
// caller's role.
func (s *Service) Audit(ctx context.Context, p *auth.Principal, orgID uuid.UUID, before *uuid.UUID, limit int32) ([]db.ListAuditEventsRow, string, error) {
	var out []db.ListAuditEventsRow
	var role string
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		m, err := Access(ctx, q, p.UserID, orgID, PermAuditRead)
		if err != nil {
			return err
		}
		role = m.Role
		out, err = q.ListAuditEvents(ctx, db.ListAuditEventsParams{OrgID: &orgID, Before: before, Lim: limit})
		return err
	})
	return out, role, err
}
