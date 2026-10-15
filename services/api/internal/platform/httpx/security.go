package httpx

import (
	"net/http"
	"strings"
)

// APIContentSecurityPolicy locks down API responses: they are data, never
// documents a browser should render or frame.
const APIContentSecurityPolicy = "default-src 'none'; frame-ancestors 'none'"

// SecurityOptions configures Security.
type SecurityOptions struct {
	// HSTS sends Strict-Transport-Security (production only: dev runs on
	// plain http and a pinned HSTS entry for localhost breaks other projects).
	HSTS bool
	// DocumentPrefixes are paths that serve HTML pages (dev mock IdP, mock
	// Stripe/Revolut checkout); they get no API CSP so their forms work.
	DocumentPrefixes []string
}

// DefaultDocumentPrefixes are the dev/test HTML pages of the API.
var DefaultDocumentPrefixes = []string{"/mock/", "/dev/"}

// Security sets response security headers: nosniff, no referrer, a
// restrictive Permissions-Policy, no framing, HSTS in production and, for
// everything except HTML pages under DocumentPrefixes and PDF downloads
// (invoices, template previews: the browser PDF viewer needs to run), the
// API Content-Security-Policy.
func Security(o SecurityOptions) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			h := w.Header()
			h.Set("X-Content-Type-Options", "nosniff")
			h.Set("Referrer-Policy", "no-referrer")
			h.Set("X-Frame-Options", "DENY")
			h.Set("Permissions-Policy", "camera=(), microphone=(), geolocation=(), payment=(), usb=(), browsing-topics=()")
			h.Set("Cross-Origin-Opener-Policy", "same-origin")
			if o.HSTS {
				h.Set("Strict-Transport-Security", "max-age=63072000; includeSubDomains")
			}
			for _, p := range o.DocumentPrefixes {
				if strings.HasPrefix(r.URL.Path, p) {
					next.ServeHTTP(w, r)
					return
				}
			}
			next.ServeHTTP(&cspWriter{ResponseWriter: w}, r)
		})
	}
}

// cspWriter adds the API CSP when the handler writes its header, unless the
// response is a PDF.
type cspWriter struct {
	http.ResponseWriter
	done bool
}

func (c *cspWriter) decide() {
	if c.done {
		return
	}
	c.done = true
	h := c.ResponseWriter.Header()
	if strings.HasPrefix(h.Get("Content-Type"), "application/pdf") {
		return
	}
	if h.Get("Content-Security-Policy") == "" {
		h.Set("Content-Security-Policy", APIContentSecurityPolicy)
	}
}

func (c *cspWriter) WriteHeader(code int) {
	c.decide()
	c.ResponseWriter.WriteHeader(code)
}

func (c *cspWriter) Write(b []byte) (int, error) {
	c.decide()
	return c.ResponseWriter.Write(b)
}

// Flush supports streaming handlers.
func (c *cspWriter) Flush() {
	c.decide()
	if f, ok := c.ResponseWriter.(http.Flusher); ok {
		f.Flush()
	}
}

// Unwrap lets http.ResponseController reach the underlying writer.
func (c *cspWriter) Unwrap() http.ResponseWriter { return c.ResponseWriter }
