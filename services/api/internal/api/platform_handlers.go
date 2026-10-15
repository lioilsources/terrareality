package api

import (
	"context"
	"encoding/json"
	"errors"

	"github.com/jackc/pgx/v5"

	"github.com/terrareality/terrareality/services/api/internal/api/gen"
	"github.com/terrareality/terrareality/services/api/internal/auth"
	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/platform/apperr"
)

func jurisdictionDTO(j db.Jurisdiction) gen.Jurisdiction {
	out := gen.Jurisdiction{Code: j.Code, Currency: j.Currency, DefaultLocale: j.DefaultLocale,
		DepositMaxMonths: int(j.DepositMaxMonths), NoticePeriodMonths: int(j.NoticePeriodMonths),
		SignatureProvider: j.SignatureProvider, IdentityProvider: j.IdentityProvider}
	_ = json.Unmarshal(j.Name, &out.Name)
	_ = json.Unmarshal(j.AddressFormat, &out.AddressFormat)
	_ = json.Unmarshal(j.Rules, &out.Rules)
	return out
}

// ListJurisdictions implements GET /v1/jurisdictions.
func (s *Server) ListJurisdictions(ctx context.Context, _ gen.ListJurisdictionsRequestObject) (gen.ListJurisdictionsResponseObject, error) {
	list, err := db.New(s.pool).ListJurisdictions(ctx)
	if err != nil {
		return nil, err
	}
	out := gen.ListJurisdictions200JSONResponse{}
	for _, j := range list {
		out = append(out, jurisdictionDTO(j))
	}
	return out, nil
}

// GetJurisdiction implements GET /v1/jurisdictions/{code}.
func (s *Server) GetJurisdiction(ctx context.Context, r gen.GetJurisdictionRequestObject) (gen.GetJurisdictionResponseObject, error) {
	j, err := db.New(s.pool).GetJurisdiction(ctx, r.Code)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, apperr.NotFound("jurisdiction_not_found", "unknown jurisdiction")
	}
	if err != nil {
		return nil, err
	}
	return gen.GetJurisdiction200JSONResponse(jurisdictionDTO(j)), nil
}

// staff returns the principal when it is a staff member. With
// StaffRequireMFA the session itself must have passed the second factor
// (opened after TOTP was enabled), not merely belong to a user who has it.
func (s *Server) staff(ctx context.Context) (*auth.Principal, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	if !p.IsStaff {
		return nil, apperr.ErrForbidden
	}
	if s.StaffRequireMFA && !p.MFA {
		return nil, apperr.Forbidden("staff_mfa_required",
			"staff accounts must enable two-factor authentication and sign in again with the code")
	}
	return p, nil
}

// BackofficeListUsers implements GET /v1/backoffice/users.
func (s *Server) BackofficeListUsers(ctx context.Context, r gen.BackofficeListUsersRequestObject) (gen.BackofficeListUsersResponseObject, error) {
	if _, err := s.staff(ctx); err != nil {
		return nil, err
	}
	lim := limitOf(r.Params.Limit)
	var q *string
	if r.Params.Q != nil && *r.Params.Q != "" {
		q = r.Params.Q
	}
	rows, err := db.New(s.pool).SearchUsers(ctx, db.SearchUsersParams{Q: q, Before: r.Params.Before, Lim: lim})
	if err != nil {
		return nil, err
	}
	page := gen.AdminUserPage{Items: make([]gen.AdminUser, 0, len(rows))}
	for _, u := range rows {
		page.Items = append(page.Items, adminUserDTO(u))
	}
	if int32(len(rows)) == lim && len(rows) > 0 {
		last := rows[len(rows)-1].ID
		page.NextBefore = &last
	}
	return gen.BackofficeListUsers200JSONResponse(page), nil
}

// BackofficeGetUser implements GET /v1/backoffice/users/{userId}.
func (s *Server) BackofficeGetUser(ctx context.Context, r gen.BackofficeGetUserRequestObject) (gen.BackofficeGetUserResponseObject, error) {
	if _, err := s.staff(ctx); err != nil {
		return nil, err
	}
	q := db.New(s.pool)
	u, err := q.GetUser(ctx, r.UserId)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, apperr.NotFound("user_not_found", "user not found")
	}
	if err != nil {
		return nil, err
	}
	orgs, err := q.ListMyOrganizations(ctx, u.ID)
	if err != nil {
		return nil, err
	}
	return gen.BackofficeGetUser200JSONResponse{User: adminUserDTO(u), Organizations: myOrgRows(orgs)}, nil
}

// BackofficeImpersonate implements POST /v1/backoffice/users/{userId}/impersonate.
func (s *Server) BackofficeImpersonate(ctx context.Context, r gen.BackofficeImpersonateRequestObject) (gen.BackofficeImpersonateResponseObject, error) {
	p, err := s.staff(ctx)
	if err != nil {
		return nil, err
	}
	res, err := s.Account.Impersonate(ctx, p, r.UserId, r.Body.Reason)
	if err != nil {
		return nil, err
	}
	return gen.BackofficeImpersonate200JSONResponse{AuthResultJSONResponse: gen.AuthResultJSONResponse(authResult(res))}, nil
}

// BackofficeListAudit implements GET /v1/backoffice/audit.
func (s *Server) BackofficeListAudit(ctx context.Context, r gen.BackofficeListAuditRequestObject) (gen.BackofficeListAuditResponseObject, error) {
	if _, err := s.staff(ctx); err != nil {
		return nil, err
	}
	lim := limitOf(r.Params.Limit)
	rows, err := db.New(s.pool).ListAuditEvents(ctx, db.ListAuditEventsParams{OrgID: r.Params.OrgId, ActorID: r.Params.ActorId,
		Entity: r.Params.Entity, Before: r.Params.Before, Lim: lim})
	if err != nil {
		return nil, err
	}
	return gen.BackofficeListAudit200JSONResponse(auditRows(rows, lim)), nil
}
