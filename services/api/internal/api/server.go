// Package api implements the generated OpenAPI strict server interface and
// assembles the HTTP router.
package api

import (
	"context"
	"encoding/json"
	"errors"
	"log/slog"
	"net/http"
	"net/netip"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/jackc/pgx/v5/pgxpool"
	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"

	"github.com/terrareality/terrareality/services/api/internal/account"
	"github.com/terrareality/terrareality/services/api/internal/api/gen"
	"github.com/terrareality/terrareality/services/api/internal/auth"
	dbq "github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/health"
	"github.com/terrareality/terrareality/services/api/internal/identity"
	"github.com/terrareality/terrareality/services/api/internal/listing"
	"github.com/terrareality/terrareality/services/api/internal/org"
	"github.com/terrareality/terrareality/services/api/internal/platform/apperr"
	"github.com/terrareality/terrareality/services/api/internal/platform/buildinfo"
	"github.com/terrareality/terrareality/services/api/internal/platform/db"
	"github.com/terrareality/terrareality/services/api/internal/platform/httpx"
	"github.com/terrareality/terrareality/services/api/internal/platform/ratelimit"
)

// Services are the domain services behind the handlers.
type Services struct {
	Account         *account.Service
	Orgs            *org.Service
	IDP             *identity.Registry
	Listings        *listing.Service
	StaffRequireMFA bool
	// RateBurst is how many credential attempts per client IP pass before
	// throttling to one per 6 s (and three messages per address before one per
	// minute). Zero means the production default of 10.
	RateBurst int
}

// Server implements gen.StrictServerInterface.
type Server struct {
	pool    *pgxpool.Pool
	checker *health.Checker
	Services
	loginLimit *ratelimit.Limiter // per client IP
	emailLimit *ratelimit.Limiter // per target e-mail / phone
	addrLimit  *ratelimit.Limiter
}

var _ gen.StrictServerInterface = (*Server)(nil)

// NewServer creates the API implementation.
func NewServer(pool *pgxpool.Pool, checker *health.Checker, svc Services) *Server {
	burst := svc.RateBurst
	if burst <= 0 {
		burst = 10
	}
	return &Server{pool: pool, checker: checker, Services: svc,
		loginLimit: ratelimit.New(6*time.Second, burst),
		emailLimit: ratelimit.New(time.Minute, max(3, burst/3)),
		addrLimit:  ratelimit.New(100*time.Millisecond, 50)}
}

// GetHealth implements GET /healthz.
func (s *Server) GetHealth(ctx context.Context, _ gen.GetHealthRequestObject) (gen.GetHealthResponseObject, error) {
	results, healthy := s.checker.Run(ctx)
	body := gen.Health{Checks: make(map[string]gen.HealthCheck, len(results))}
	for name, r := range results {
		hc := gen.HealthCheck{Status: gen.HealthCheckStatus(r.Status)}
		if r.Status == health.OK {
			lat := r.LatencyMS
			hc.LatencyMs = &lat
		}
		if r.Err != "" {
			e := r.Err
			hc.Error = &e
		}
		body.Checks[name] = hc
	}
	if healthy {
		body.Status = gen.HealthStatusOk
		return gen.GetHealth200JSONResponse(body), nil
	}
	body.Status = gen.HealthStatusDegraded
	return gen.GetHealth503JSONResponse(body), nil
}

// GetVersion implements GET /v1/version.
func (s *Server) GetVersion(ctx context.Context, _ gen.GetVersionRequestObject) (gen.GetVersionResponseObject, error) {
	v, err := db.SchemaVersion(ctx, s.pool)
	if err != nil {
		return nil, err
	}
	return gen.GetVersion200JSONResponse{
		Version: buildinfo.Version, Commit: buildinfo.Commit,
		BuiltAt: buildinfo.BuiltAt, SchemaVersion: v,
	}, nil
}

// RouterConfig carries router dependencies.
type RouterConfig struct {
	Log            *slog.Logger
	CORSOrigins    []string
	TrustedProxies []netip.Prefix
	Sessions       dbq.Querier     // nil disables authentication (unit tests)
	SessionTTL     auth.SessionTTL // sliding session lifetime per client
	MockIdP        http.Handler    // dev/test mock identity provider pages
}

// NewRouter builds the chi router with the standard middleware chain.
func NewRouter(s *Server, rc RouterConfig) http.Handler {
	r := chi.NewRouter()
	r.Use(middleware.RequestID, httpx.TrustedProxies(rc.TrustedProxies),
		httpx.Recover(rc.Log), httpx.AccessLog(rc.Log),
		httpx.SecurityHeaders, httpx.CORS(rc.CORSOrigins),
		middleware.Timeout(30*time.Second))
	r.NotFound(httpx.NotFound)
	r.MethodNotAllowed(httpx.MethodNotAllowed)
	if rc.Sessions != nil {
		r.Use(auth.Middleware(rc.Sessions, rc.SessionTTL, rc.Log))
	}
	if rc.MockIdP != nil {
		r.Handle("/dev/idp/authorize", rc.MockIdP)
	}

	validate, err := requestValidator()
	if err != nil {
		panic(err) // the embedded spec is generated and always valid
	}
	strict := gen.NewStrictHandlerWithOptions(s, nil, gen.StrictHTTPServerOptions{
		RequestErrorHandlerFunc: func(w http.ResponseWriter, r *http.Request, err error) {
			httpx.WriteProblem(w, httpx.Problem{Status: http.StatusBadRequest, Code: "invalid_request", Detail: err.Error(), Instance: r.URL.Path})
		},
		ResponseErrorHandlerFunc: func(w http.ResponseWriter, r *http.Request, err error) {
			var fe *listing.FieldErrors
			if errors.As(err, &fe) {
				errs := make([]map[string]string, 0, len(fe.Errors))
				for _, x := range fe.Errors {
					errs = append(errs, map[string]string{"key": x.Key, "reason": x.Reason})
				}
				httpx.WriteProblem(w, httpx.Problem{Status: http.StatusUnprocessableEntity, Code: "invalid_fields",
					Detail: fe.Error(), Instance: r.URL.Path, Errors: errs})
				return
			}
			if e, ok := apperr.As(err); ok {
				httpx.WriteProblem(w, httpx.Problem{Status: e.Status, Code: e.Code, Detail: e.Detail, Instance: r.URL.Path})
				return
			}
			rc.Log.Error("handler error", "err", err, "path", r.URL.Path, "request_id", middleware.GetReqID(r.Context()))
			httpx.WriteProblem(w, httpx.Problem{Status: http.StatusInternalServerError, Instance: r.URL.Path})
		},
	})
	r.Group(func(r chi.Router) {
		r.Use(validate)
		gen.HandlerFromMux(strict, r)
	})

	// OpenAPI document for tooling and docs.
	r.Get("/openapi.json", func(w http.ResponseWriter, _ *http.Request) {
		spec, err := gen.GetSpec()
		if err != nil {
			httpx.WriteProblem(w, httpx.Problem{Status: http.StatusInternalServerError})
			return
		}
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(spec)
	})
	return otelhttp.NewHandler(r, "api")
}
