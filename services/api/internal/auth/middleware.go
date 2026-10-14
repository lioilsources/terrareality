package auth

import (
	"errors"
	"log/slog"
	"net/http"
	"strings"
	"time"

	"github.com/go-chi/chi/v5/middleware"
	"github.com/jackc/pgx/v5"

	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/platform/httpx"
	"github.com/terrareality/terrareality/services/api/internal/platform/tokens"
)

// SessionTTL returns the sliding lifetime for a client kind.
type SessionTTL func(client string) time.Duration

// Middleware resolves the bearer token into a Principal. Invalid or expired
// tokens leave the request anonymous; handlers that need a user answer 401.
func Middleware(q db.Querier, ttl SessionTTL, log *slog.Logger) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			ctx := WithMeta(r.Context(), RequestMeta{
				IP:        httpx.ClientIP(r.Context()),
				UserAgent: truncate(r.UserAgent(), 400),
				RequestID: middleware.GetReqID(r.Context()),
			})
			if tok := bearer(r); tok != "" {
				s, err := q.GetActiveSession(ctx, tokens.Hash(tok))
				switch {
				case err == nil && s.PseudonymizedAt == nil:
					p := &Principal{UserID: s.UserID, SessionID: s.ID, Client: s.Client,
						IsStaff: s.IsStaff && s.ImpersonatorID == nil, ImpersonatorID: s.ImpersonatorID}
					ctx = WithPrincipal(ctx, p)
					// Impersonation sessions have a fixed lifetime.
					exp := s.ExpiresAt
					if s.ImpersonatorID == nil {
						exp = time.Now().Add(ttl(s.Client))
					}
					if err := q.TouchSession(ctx, db.TouchSessionParams{ID: s.ID, ExpiresAt: exp}); err != nil {
						log.Warn("touch session", "err", err)
					}
				case err != nil && !errors.Is(err, pgx.ErrNoRows):
					log.Error("session lookup", "err", err)
					httpx.WriteProblem(w, httpx.Problem{Status: http.StatusServiceUnavailable})
					return
				}
			}
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

func bearer(r *http.Request) string {
	h := r.Header.Get("Authorization")
	if len(h) > 7 && strings.EqualFold(h[:7], "bearer ") {
		return strings.TrimSpace(h[7:])
	}
	return ""
}

func truncate(s string, n int) string {
	if len(s) > n {
		return s[:n]
	}
	return s
}
