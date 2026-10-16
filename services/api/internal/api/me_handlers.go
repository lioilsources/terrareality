package api

import (
	"context"

	"github.com/terrareality/terrareality/services/api/internal/api/gen"
)

func (s *Server) me(ctx context.Context) (gen.Me, error) {
	p, err := principal(ctx)
	if err != nil {
		return gen.Me{}, err
	}
	v, err := s.Account.Me(ctx, p)
	if err != nil {
		return gen.Me{}, err
	}
	return meDTO(v), nil
}

// GetMe implements GET /v1/me.
func (s *Server) GetMe(ctx context.Context, _ gen.GetMeRequestObject) (gen.GetMeResponseObject, error) {
	me, err := s.me(ctx)
	if err != nil {
		return nil, err
	}
	return gen.GetMe200JSONResponse{MeJSONResponse: gen.MeJSONResponse(me)}, nil
}

// UpdateMe implements PATCH /v1/me.
func (s *Server) UpdateMe(ctx context.Context, r gen.UpdateMeRequestObject) (gen.UpdateMeResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	var loc *string
	if r.Body.Locale != nil {
		l := string(*r.Body.Locale)
		loc = &l
	}
	if err := s.Account.UpdateProfile(ctx, p, r.Body.DisplayName, loc); err != nil {
		return nil, err
	}
	me, err := s.me(ctx)
	if err != nil {
		return nil, err
	}
	return gen.UpdateMe200JSONResponse{MeJSONResponse: gen.MeJSONResponse(me)}, nil
}

// ChangePassword implements POST /v1/me/password.
func (s *Server) ChangePassword(ctx context.Context, r gen.ChangePasswordRequestObject) (gen.ChangePasswordResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	if err := s.limit(ctx, ""); err != nil {
		return nil, err
	}
	if err := s.Account.ChangePassword(ctx, p, r.Body.CurrentPassword, r.Body.NewPassword); err != nil {
		return nil, err
	}
	return gen.ChangePassword204Response{}, nil
}

// ListMySessions implements GET /v1/me/sessions.
func (s *Server) ListMySessions(ctx context.Context, _ gen.ListMySessionsRequestObject) (gen.ListMySessionsResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	list, err := s.Account.Sessions(ctx, p)
	if err != nil {
		return nil, err
	}
	out := gen.ListMySessions200JSONResponse{}
	for _, x := range list {
		imp := x.ImpersonatorID != nil
		si := gen.SessionInfo{Id: x.ID, Client: x.Client, UserAgent: x.UserAgent, CreatedAt: x.CreatedAt,
			LastSeenAt: x.LastSeenAt, ExpiresAt: x.ExpiresAt, Current: x.ID == p.SessionID, Impersonated: &imp}
		if x.Ip != nil {
			ip := x.Ip.String()
			si.Ip = &ip
		}
		out = append(out, si)
	}
	return out, nil
}

// RevokeMySession implements DELETE /v1/me/sessions/{sessionId}.
func (s *Server) RevokeMySession(ctx context.Context, r gen.RevokeMySessionRequestObject) (gen.RevokeMySessionResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	if err := s.Account.RevokeSession(ctx, p, r.SessionId); err != nil {
		return nil, err
	}
	return gen.RevokeMySession204Response{}, nil
}

// SetupTotp implements POST /v1/me/mfa/totp/setup.
func (s *Server) SetupTotp(ctx context.Context, _ gen.SetupTotpRequestObject) (gen.SetupTotpResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	t, err := s.Account.SetupTOTP(ctx, p)
	if err != nil {
		return nil, err
	}
	return gen.SetupTotp200JSONResponse{Secret: t.Secret, OtpauthUri: t.URI}, nil
}

// EnableTotp implements POST /v1/me/mfa/totp/enable.
func (s *Server) EnableTotp(ctx context.Context, r gen.EnableTotpRequestObject) (gen.EnableTotpResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	if err := s.limit(ctx, ""); err != nil {
		return nil, err
	}
	codes, err := s.Account.EnableTOTP(ctx, p, r.Body.Code)
	if err != nil {
		return nil, err
	}
	return gen.EnableTotp200JSONResponse{RecoveryCodes: codes}, nil
}

// DisableTotp implements POST /v1/me/mfa/totp/disable.
func (s *Server) DisableTotp(ctx context.Context, r gen.DisableTotpRequestObject) (gen.DisableTotpResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	if err := s.limit(ctx, ""); err != nil {
		return nil, err
	}
	if err := s.Account.DisableTOTP(ctx, p, r.Body.Code); err != nil {
		return nil, err
	}
	return gen.DisableTotp204Response{}, nil
}

// StartPhoneVerification implements POST /v1/me/phone.
func (s *Server) StartPhoneVerification(ctx context.Context, r gen.StartPhoneVerificationRequestObject) (gen.StartPhoneVerificationResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	if err := s.limit(ctx, r.Body.Phone); err != nil {
		return nil, err
	}
	if err := s.Account.StartPhoneVerification(ctx, p, r.Body.Phone); err != nil {
		return nil, err
	}
	return gen.StartPhoneVerification202Response{}, nil
}

// VerifyPhone implements POST /v1/me/phone/verify.
func (s *Server) VerifyPhone(ctx context.Context, r gen.VerifyPhoneRequestObject) (gen.VerifyPhoneResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	if err := s.Account.VerifyPhone(ctx, p, r.Body.Code); err != nil {
		return nil, err
	}
	me, err := s.me(ctx)
	if err != nil {
		return nil, err
	}
	return gen.VerifyPhone200JSONResponse{MeJSONResponse: gen.MeJSONResponse(me)}, nil
}

// StartIdentityVerification implements POST /v1/me/identity/start.
func (s *Server) StartIdentityVerification(ctx context.Context, r gen.StartIdentityVerificationRequestObject) (gen.StartIdentityVerificationResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	u, err := s.Account.StartIdentityVerification(ctx, p, r.Body.RedirectUri)
	if err != nil {
		return nil, err
	}
	return gen.StartIdentityVerification200JSONResponse{OidcStartJSONResponse: gen.OidcStartJSONResponse{AuthorizationUrl: u}}, nil
}

// FinishIdentityVerification implements POST /v1/me/identity/callback.
func (s *Server) FinishIdentityVerification(ctx context.Context, r gen.FinishIdentityVerificationRequestObject) (gen.FinishIdentityVerificationResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	if err := s.Account.FinishIdentityVerification(ctx, p, r.Body.Code, r.Body.State, r.Body.RedirectUri); err != nil {
		return nil, err
	}
	me, err := s.me(ctx)
	if err != nil {
		return nil, err
	}
	return gen.FinishIdentityVerification200JSONResponse{MeJSONResponse: gen.MeJSONResponse(me)}, nil
}

// ListConsents implements GET /v1/me/consents.
func (s *Server) ListConsents(ctx context.Context, _ gen.ListConsentsRequestObject) (gen.ListConsentsResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	list, err := s.Account.Consents(ctx, p)
	if err != nil {
		return nil, err
	}
	out := gen.ListConsents200JSONResponse{}
	for _, c := range list {
		out = append(out, gen.Consent{Id: c.ID, Kind: gen.ConsentKind(c.Kind), Version: c.Version, Granted: c.Granted, CreatedAt: c.CreatedAt})
	}
	return out, nil
}

// RecordConsent implements POST /v1/me/consents.
func (s *Server) RecordConsent(ctx context.Context, r gen.RecordConsentRequestObject) (gen.RecordConsentResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	c, err := s.Account.RecordConsent(ctx, p, string(r.Body.Kind), r.Body.Version, r.Body.Granted)
	if err != nil {
		return nil, err
	}
	return gen.RecordConsent201JSONResponse{Id: c.ID, Kind: gen.ConsentKind(c.Kind), Version: c.Version, Granted: c.Granted, CreatedAt: c.CreatedAt}, nil
}

// ListGdprRequests implements GET /v1/me/gdpr-requests.
func (s *Server) ListGdprRequests(ctx context.Context, _ gen.ListGdprRequestsRequestObject) (gen.ListGdprRequestsResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	list, err := s.Account.GDPRRequests(ctx, p)
	if err != nil {
		return nil, err
	}
	out := gen.ListGdprRequests200JSONResponse{}
	for _, r := range list {
		out = append(out, gdprDTO(r))
	}
	return out, nil
}

// RequestDataExport implements POST /v1/me/data-exports.
func (s *Server) RequestDataExport(ctx context.Context, _ gen.RequestDataExportRequestObject) (gen.RequestDataExportResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	if err := s.limit(ctx, "export:"+p.UserID.String()); err != nil {
		return nil, err
	}
	r, err := s.Account.RequestExport(ctx, p)
	if err != nil {
		return nil, err
	}
	return gen.RequestDataExport202JSONResponse(gdprDTO(r)), nil
}

// GetDataExportDownload implements GET /v1/me/data-exports/{requestId}/download.
func (s *Server) GetDataExportDownload(ctx context.Context, r gen.GetDataExportDownloadRequestObject) (gen.GetDataExportDownloadResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	u, exp, err := s.Account.ExportLink(ctx, p, r.RequestId)
	if err != nil {
		return nil, err
	}
	return gen.GetDataExportDownload200JSONResponse{Url: u, ExpiresAt: exp}, nil
}

// RequestErasure implements POST /v1/me/erasure.
func (s *Server) RequestErasure(ctx context.Context, _ gen.RequestErasureRequestObject) (gen.RequestErasureResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	r, err := s.Account.RequestErasure(ctx, p)
	if err != nil {
		return nil, err
	}
	return gen.RequestErasure202JSONResponse(gdprDTO(r)), nil
}

// CancelErasure implements DELETE /v1/me/erasure.
func (s *Server) CancelErasure(ctx context.Context, _ gen.CancelErasureRequestObject) (gen.CancelErasureResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	if err := s.Account.CancelErasure(ctx, p); err != nil {
		return nil, err
	}
	return gen.CancelErasure204Response{}, nil
}
