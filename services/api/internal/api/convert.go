package api

import (
	"context"
	"encoding/json"

	"github.com/google/uuid"
	openapi_types "github.com/oapi-codegen/runtime/types"

	"github.com/terrareality/terrareality/services/api/internal/account"
	"github.com/terrareality/terrareality/services/api/internal/api/gen"
	"github.com/terrareality/terrareality/services/api/internal/auth"
	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/org"
	"github.com/terrareality/terrareality/services/api/internal/platform/apperr"
)

// principal returns the caller or 401.
func principal(ctx context.Context) (*auth.Principal, error) {
	p := auth.FromContext(ctx)
	if p == nil {
		return nil, apperr.ErrUnauthenticated
	}
	return p, nil
}

func clientOf(c *gen.ClientKind) string {
	if c == nil {
		return "web"
	}
	return string(*c)
}

func authResult(r account.Result) gen.AuthResult {
	if r.Authenticated() {
		return gen.AuthResult{Status: gen.Authenticated, Session: &gen.SessionToken{Token: r.Token, ExpiresAt: r.ExpiresAt}}
	}
	t := r.MFAToken
	return gen.AuthResult{Status: gen.MfaRequired, MfaToken: &t}
}

func level(v *string) gen.VerificationLevel {
	if v == nil {
		return gen.VerificationLevelNone
	}
	return gen.VerificationLevel(*v)
}

func orgDTO(o db.Organization) gen.Organization {
	return gen.Organization{Id: o.ID, Kind: gen.OrganizationKind(o.Kind), Name: o.Name, RegistrationNo: o.RegistrationNo,
		VatNo: o.VatNo, JurisdictionCode: o.JurisdictionCode, CreatedAt: o.CreatedAt}
}

func membershipDTO(m org.Membership) gen.OrgMembership {
	return gen.OrgMembership{Organization: orgDTO(m.Org), Role: gen.Role(m.Role)}
}

func myOrgRows(rows []db.ListMyOrganizationsRow) []gen.OrgMembership {
	out := make([]gen.OrgMembership, 0, len(rows))
	for _, r := range rows {
		out = append(out, gen.OrgMembership{Role: gen.Role(r.Role), Organization: gen.Organization{
			Id: r.ID, Kind: gen.OrganizationKind(r.Kind), Name: r.Name, RegistrationNo: r.RegistrationNo,
			VatNo: r.VatNo, JurisdictionCode: r.JurisdictionCode, CreatedAt: r.CreatedAt}})
	}
	return out
}

func meDTO(v account.MeView) gen.Me {
	u := v.User
	hasPw := u.PasswordHash != nil
	me := gen.Me{
		Id: u.ID, Email: u.Email, EmailVerified: u.EmailVerifiedAt != nil, DisplayName: u.DisplayName,
		Locale: gen.Locale(u.Locale), Phone: u.Phone, PhoneVerified: u.PhoneVerifiedAt != nil,
		VerificationLevel: level(u.VerificationLevel), MfaEnabled: u.TotpEnabledAt != nil, HasPassword: &hasPw,
		IsStaff: u.IsStaff, CreatedAt: u.CreatedAt, Organizations: myOrgRows(v.Orgs),
	}
	if u.TotpEnabledAt != nil {
		n := int(v.RecoveryLeft)
		me.RecoveryCodesLeft = &n
	}
	if iv := v.Identity; iv != nil {
		id := &gen.VerifiedIdentity{Provider: iv.Provider, GivenName: iv.GivenName, FamilyName: iv.FamilyName, VerifiedAt: iv.VerifiedAt}
		if iv.Birthdate.Valid {
			id.Birthdate = &openapi_types.Date{Time: iv.Birthdate.Time}
		}
		me.Identity = id
	}
	if imp := v.Impersonator; imp != nil {
		name := imp.DisplayName
		me.Impersonator = &gen.UserRef{Id: imp.ID, Email: imp.Email, DisplayName: &name}
	}
	return me
}

func auditDTO(id uuid.UUID, at gen.AuditEvent) gen.AuditEvent { at.Id = id; return at }

func auditRows(rows []db.ListAuditEventsRow, limit int32) gen.AuditPage {
	page := gen.AuditPage{Items: make([]gen.AuditEvent, 0, len(rows))}
	for _, r := range rows {
		var diff map[string]any
		_ = json.Unmarshal(r.Diff, &diff)
		if diff == nil {
			diff = map[string]any{}
		}
		e := r.ActorEmail
		page.Items = append(page.Items, auditDTO(r.ID, gen.AuditEvent{OccurredAt: r.OccurredAt, ActorId: r.ActorID,
			ActorEmail: &e, ImpersonatorId: r.ImpersonatorID, OrgId: r.OrgID, Entity: r.Entity, EntityId: r.EntityID,
			Action: r.Action, Diff: diff}))
	}
	if int32(len(rows)) == limit && len(rows) > 0 {
		last := rows[len(rows)-1].ID
		page.NextBefore = &last
	}
	return page
}

func adminUserDTO(u db.User) gen.AdminUser {
	ps := u.PseudonymizedAt != nil
	return gen.AdminUser{Id: u.ID, Email: u.Email, DisplayName: u.DisplayName, VerificationLevel: level(u.VerificationLevel),
		MfaEnabled: u.TotpEnabledAt != nil, IsStaff: u.IsStaff, Pseudonymized: &ps, CreatedAt: u.CreatedAt}
}

func gdprDTO(r db.GdprRequest) gen.GdprRequest {
	return gen.GdprRequest{Id: r.ID, Kind: gen.GdprRequestKind(r.Kind), Status: gen.GdprRequestStatus(r.Status),
		ScheduledAt: r.ScheduledAt, Detail: r.Detail, CreatedAt: r.CreatedAt, CompletedAt: r.CompletedAt}
}

func limitOf(l *gen.Limit) int32 {
	if l == nil {
		return 50
	}
	return int32(*l)
}
