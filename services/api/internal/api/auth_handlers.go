package api

import (
	"context"
	"strings"

	"github.com/terrareality/terrareality/services/api/internal/account"
	"github.com/terrareality/terrareality/services/api/internal/api/gen"
	"github.com/terrareality/terrareality/services/api/internal/auth"
	"github.com/terrareality/terrareality/services/api/internal/platform/apperr"
)

// limit applies the per-IP limiter and, when key is set, the per-target one.
func (s *Server) limit(ctx context.Context, key string) error {
	if !s.loginLimit.Allow(auth.Meta(ctx).IP) {
		return apperr.TooMany("too many attempts, try again later")
	}
	if key != "" && !s.emailLimit.Allow(strings.ToLower(key)) {
		return apperr.TooMany("too many messages to this address, try again later")
	}
	return nil
}

// searchLimit throttles public autocomplete per client IP.
func (s *Server) searchLimit(ctx context.Context) error {
	if !s.addrLimit.Allow(auth.Meta(ctx).IP) {
		return apperr.TooMany("too many requests, slow down")
	}
	return nil
}

func localeOf(l *gen.UserLocale) string {
	if l == nil {
		return ""
	}
	return string(*l)
}

// Register implements POST /v1/auth/register.
func (s *Server) Register(ctx context.Context, r gen.RegisterRequestObject) (gen.RegisterResponseObject, error) {
	b := r.Body
	if err := s.limit(ctx, ""); err != nil {
		return nil, err
	}
	res, err := s.Account.Register(ctx, account.RegisterInput{
		Email: string(b.Email), Password: b.Password, DisplayName: strings.TrimSpace(b.DisplayName), Locale: localeOf(b.Locale),
		TermsVersion: b.AcceptTermsVersion, PrivacyVersion: b.AcceptPrivacyVersion, Marketing: b.Marketing != nil && *b.Marketing,
		Client: clientOf(b.Client),
	})
	if err != nil {
		return nil, err
	}
	return gen.Register201JSONResponse{AuthResultJSONResponse: gen.AuthResultJSONResponse(authResult(res))}, nil
}

// Login implements POST /v1/auth/login.
func (s *Server) Login(ctx context.Context, r gen.LoginRequestObject) (gen.LoginResponseObject, error) {
	if err := s.limit(ctx, ""); err != nil {
		return nil, err
	}
	res, err := s.Account.Login(ctx, string(r.Body.Email), r.Body.Password, clientOf(r.Body.Client))
	if err != nil {
		return nil, err
	}
	return gen.Login200JSONResponse{AuthResultJSONResponse: gen.AuthResultJSONResponse(authResult(res))}, nil
}

// CompleteMfa implements POST /v1/auth/mfa.
func (s *Server) CompleteMfa(ctx context.Context, r gen.CompleteMfaRequestObject) (gen.CompleteMfaResponseObject, error) {
	if err := s.limit(ctx, ""); err != nil {
		return nil, err
	}
	res, err := s.Account.CompleteMFA(ctx, r.Body.MfaToken, r.Body.Code)
	if err != nil {
		return nil, err
	}
	return gen.CompleteMfa200JSONResponse{AuthResultJSONResponse: gen.AuthResultJSONResponse(authResult(res))}, nil
}

// RequestMagicLink implements POST /v1/auth/magic-link.
func (s *Server) RequestMagicLink(ctx context.Context, r gen.RequestMagicLinkRequestObject) (gen.RequestMagicLinkResponseObject, error) {
	if err := s.limit(ctx, string(r.Body.Email)); err != nil {
		return nil, err
	}
	if err := s.Account.RequestMagicLink(ctx, string(r.Body.Email), localeOf(r.Body.Locale)); err != nil {
		return nil, err
	}
	return gen.RequestMagicLink202Response{}, nil
}

// VerifyMagicLink implements POST /v1/auth/magic-link/verify.
func (s *Server) VerifyMagicLink(ctx context.Context, r gen.VerifyMagicLinkRequestObject) (gen.VerifyMagicLinkResponseObject, error) {
	if err := s.limit(ctx, ""); err != nil {
		return nil, err
	}
	res, err := s.Account.VerifyMagicLink(ctx, r.Body.Token, clientOf(r.Body.Client))
	if err != nil {
		return nil, err
	}
	return gen.VerifyMagicLink200JSONResponse{AuthResultJSONResponse: gen.AuthResultJSONResponse(authResult(res))}, nil
}

// VerifyEmail implements POST /v1/auth/email/verify.
func (s *Server) VerifyEmail(ctx context.Context, r gen.VerifyEmailRequestObject) (gen.VerifyEmailResponseObject, error) {
	if err := s.Account.VerifyEmail(ctx, r.Body.Token); err != nil {
		return nil, err
	}
	return gen.VerifyEmail204Response{}, nil
}

// ResendEmailVerification implements POST /v1/auth/email/resend.
func (s *Server) ResendEmailVerification(ctx context.Context, _ gen.ResendEmailVerificationRequestObject) (gen.ResendEmailVerificationResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	if err := s.limit(ctx, p.UserID.String()); err != nil {
		return nil, err
	}
	if err := s.Account.ResendVerification(ctx, p.UserID); err != nil {
		return nil, err
	}
	return gen.ResendEmailVerification202Response{}, nil
}

// ForgotPassword implements POST /v1/auth/password/forgot.
func (s *Server) ForgotPassword(ctx context.Context, r gen.ForgotPasswordRequestObject) (gen.ForgotPasswordResponseObject, error) {
	if err := s.limit(ctx, string(r.Body.Email)); err != nil {
		return nil, err
	}
	if err := s.Account.ForgotPassword(ctx, string(r.Body.Email), localeOf(r.Body.Locale)); err != nil {
		return nil, err
	}
	return gen.ForgotPassword202Response{}, nil
}

// ResetPassword implements POST /v1/auth/password/reset.
func (s *Server) ResetPassword(ctx context.Context, r gen.ResetPasswordRequestObject) (gen.ResetPasswordResponseObject, error) {
	if err := s.limit(ctx, ""); err != nil {
		return nil, err
	}
	if err := s.Account.ResetPassword(ctx, r.Body.Token, r.Body.Password); err != nil {
		return nil, err
	}
	return gen.ResetPassword204Response{}, nil
}

// ListAuthProviders implements GET /v1/auth/providers.
func (s *Server) ListAuthProviders(_ context.Context, _ gen.ListAuthProvidersRequestObject) (gen.ListAuthProvidersResponseObject, error) {
	out := gen.ListAuthProviders200JSONResponse{}
	for _, p := range s.IDP.SocialProviders() {
		out = append(out, gen.AuthProvider{Id: gen.AuthProviderId(p.ID()), Mock: p.Mock()})
	}
	return out, nil
}

// StartOidc implements POST /v1/auth/oidc/{provider}/start.
func (s *Server) StartOidc(ctx context.Context, r gen.StartOidcRequestObject) (gen.StartOidcResponseObject, error) {
	u, err := s.Account.StartSocialLogin(ctx, string(r.Provider), r.Body.RedirectUri)
	if err != nil {
		return nil, err
	}
	return gen.StartOidc200JSONResponse{OidcStartJSONResponse: gen.OidcStartJSONResponse{AuthorizationUrl: u}}, nil
}

// FinishOidc implements POST /v1/auth/oidc/{provider}/callback.
func (s *Server) FinishOidc(ctx context.Context, r gen.FinishOidcRequestObject) (gen.FinishOidcResponseObject, error) {
	if err := s.limit(ctx, ""); err != nil {
		return nil, err
	}
	b := r.Body
	res, err := s.Account.FinishSocialLogin(ctx, string(r.Provider), b.Code, b.State, b.RedirectUri, clientOf(b.Client))
	if err != nil {
		return nil, err
	}
	return gen.FinishOidc200JSONResponse{AuthResultJSONResponse: gen.AuthResultJSONResponse(authResult(res))}, nil
}

// Logout implements POST /v1/auth/logout.
func (s *Server) Logout(ctx context.Context, _ gen.LogoutRequestObject) (gen.LogoutResponseObject, error) {
	p, err := principal(ctx)
	if err != nil {
		return nil, err
	}
	if err := s.Account.Logout(ctx, p); err != nil {
		return nil, err
	}
	return gen.Logout204Response{}, nil
}
