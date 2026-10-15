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
// Activity slides the expiry by ttl, but never past created_at + maxAge
// (absolute session lifetime, ASVS V3.3.2; 0 disables the cap). The lookup
// itself refuses sessions older than maxAge, whatever expiry they store.
func Middleware(q db.Querier, ttl SessionTTL, maxAge time.Duration, log *slog.Logger) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			ctx := WithMeta(r.Context(), RequestMeta{
				IP:        httpx.ClientIP(r.Context()),
				UserAgent: truncate(r.UserAgent(), 400),
				RequestID: middleware.GetReqID(r.Context()),
			})
			if tok := bearer(r); tok != "" {
				var createdAfter time.Time // zero: no absolute cap
				if maxAge > 0 {
					createdAfter = time.Now().Add(-maxAge)
				}
				s, err := q.GetActiveSession(ctx, db.GetActiveSessionParams{TokenHash: tokens.Hash(tok), CreatedAfter: createdAfter})
				switch {
				case err == nil && s.PseudonymizedAt == nil:
					p := &Principal{UserID: s.UserID, SessionID: s.ID, Client: s.Client,
						IsStaff: s.IsStaff && s.ImpersonatorID == nil, ImpersonatorID: s.ImpersonatorID,
						MFA: s.TotpEnabledAt != nil && s.CreatedAt.After(*s.TotpEnabledAt)}
					ctx = WithPrincipal(ctx, p)
					// Impersonation sessions have a fixed lifetime.
					exp := s.ExpiresAt
					if s.ImpersonatorID == nil {
						exp = SlidingExpiry(time.Now(), s.CreatedAt, ttl(s.Client), maxAge)
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

// SlidingExpiry is now+ttl capped at created+maxAge (maxAge 0 = no cap).
func SlidingExpiry(now, created time.Time, ttl, maxAge time.Duration) time.Time {
	exp := now.Add(ttl)
	if maxAge > 0 {
		if hard := created.Add(maxAge); exp.After(hard) {
			exp = hard
		}
	}
	return exp
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
