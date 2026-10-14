package api

import (
	"errors"
	"net/http"
	"strings"

	"github.com/getkin/kin-openapi/openapi3"
	"github.com/getkin/kin-openapi/openapi3filter"
	"github.com/getkin/kin-openapi/routers/legacy"

	"github.com/terrareality/terrareality/services/api/internal/api/gen"
	"github.com/terrareality/terrareality/services/api/internal/platform/httpx"
)

func init() {
	openapi3.DefineStringFormatValidator("email", openapi3.NewRegexpFormatValidator(`^[^@\s]+@[^@\s]+\.[^@\s]+$`))
}

// requestValidator checks requests against the OpenAPI document (types,
// lengths, patterns, enums, formats) before handlers run.
func requestValidator() (func(http.Handler) http.Handler, error) {
	spec, err := gen.GetSpec()
	if err != nil {
		return nil, err
	}
	spec.Servers = nil // match any host
	router, err := legacy.NewRouter(spec)
	if err != nil {
		return nil, err
	}
	opts := &openapi3filter.Options{AuthenticationFunc: openapi3filter.NoopAuthenticationFunc}
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			route, params, err := router.FindRoute(r)
			if err != nil {
				next.ServeHTTP(w, r) // unknown routes fall through to 404/405
				return
			}
			in := &openapi3filter.RequestValidationInput{Request: r, PathParams: params, Route: route, Options: opts}
			if err := openapi3filter.ValidateRequest(r.Context(), in); err != nil {
				httpx.WriteProblem(w, httpx.Problem{Status: http.StatusBadRequest, Code: "validation_failed",
					Detail: validationDetail(err), Instance: r.URL.Path})
				return
			}
			next.ServeHTTP(w, r)
		})
	}, nil
}

// validationDetail keeps the useful first line (field and reason).
func validationDetail(err error) string {
	var re *openapi3filter.RequestError
	if errors.As(err, &re) {
		msg := re.Error()
		if i := strings.Index(msg, "\n"); i > 0 {
			msg = msg[:i]
		}
		return msg
	}
	return err.Error()
}
