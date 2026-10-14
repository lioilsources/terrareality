// Package httpx contains HTTP helpers shared by all modules: RFC 9457 problem
// responses and the middleware chain.
package httpx

import (
	"encoding/json"
	"net/http"
)

// Problem is an RFC 9457 problem details object.
type Problem struct {
	Type     string `json:"type"`
	Title    string `json:"title"`
	Status   int    `json:"status"`
	Detail   string `json:"detail,omitempty"`
	Instance string `json:"instance,omitempty"`
	Code     string `json:"code,omitempty"`
	Errors   any    `json:"errors,omitempty"`
}

// WriteProblem writes p as application/problem+json.
func WriteProblem(w http.ResponseWriter, p Problem) {
	if p.Type == "" {
		p.Type = "about:blank"
	}
	if p.Title == "" {
		p.Title = http.StatusText(p.Status)
	}
	w.Header().Set("Content-Type", "application/problem+json")
	w.WriteHeader(p.Status)
	_ = json.NewEncoder(w).Encode(p)
}

// NotFound is the router fallback.
func NotFound(w http.ResponseWriter, r *http.Request) {
	WriteProblem(w, Problem{Status: http.StatusNotFound, Instance: r.URL.Path})
}

// MethodNotAllowed is the router fallback for wrong verbs.
func MethodNotAllowed(w http.ResponseWriter, r *http.Request) {
	WriteProblem(w, Problem{Status: http.StatusMethodNotAllowed, Instance: r.URL.Path})
}
