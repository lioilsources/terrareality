// Package health runs dependency checks for /healthz.
package health

import (
	"context"
	"net/http"
	"sync"
	"time"
)

// Status of a single check.
type Status string

const (
	OK       Status = "ok"
	Fail     Status = "fail"
	Disabled Status = "disabled"
)

// Result of a single check.
type Result struct {
	Status    Status
	LatencyMS int64
	Err       string
}

// CheckFunc probes one dependency. Returning ErrDisabled marks it optional-off.
type CheckFunc func(ctx context.Context) error

// ErrDisabled signals that a dependency is intentionally not configured.
var ErrDisabled = disabledErr{}

type disabledErr struct{}

func (disabledErr) Error() string { return "disabled" }

// Checker runs named checks concurrently with a shared timeout.
type Checker struct {
	checks  map[string]CheckFunc
	timeout time.Duration
}

// New creates a Checker.
func New(timeout time.Duration) *Checker {
	return &Checker{checks: map[string]CheckFunc{}, timeout: timeout}
}

// Add registers a check.
func (c *Checker) Add(name string, fn CheckFunc) { c.checks[name] = fn }

// Run executes all checks; healthy is false if any check failed.
func (c *Checker) Run(ctx context.Context) (results map[string]Result, healthy bool) {
	ctx, cancel := context.WithTimeout(ctx, c.timeout)
	defer cancel()
	results = make(map[string]Result, len(c.checks))
	var mu sync.Mutex
	var wg sync.WaitGroup
	for name, fn := range c.checks {
		wg.Add(1)
		go func() {
			defer wg.Done()
			start := time.Now()
			err := fn(ctx)
			r := Result{Status: OK, LatencyMS: time.Since(start).Milliseconds()}
			switch {
			case err == ErrDisabled:
				r = Result{Status: Disabled}
			case err != nil:
				r.Status, r.Err = Fail, err.Error()
			}
			mu.Lock()
			results[name] = r
			mu.Unlock()
		}()
	}
	wg.Wait()
	healthy = true
	for _, r := range results {
		if r.Status == Fail {
			healthy = false
		}
	}
	return results, healthy
}

// HTTPCheck returns a check that GETs url and expects a 2xx response.
// An empty url means the dependency is disabled.
func HTTPCheck(client *http.Client, url string) CheckFunc {
	return func(ctx context.Context) error {
		if url == "" {
			return ErrDisabled
		}
		req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
		if err != nil {
			return err
		}
		resp, err := client.Do(req)
		if err != nil {
			return err
		}
		resp.Body.Close()
		if resp.StatusCode/100 != 2 {
			return &statusErr{resp.StatusCode}
		}
		return nil
	}
}

type statusErr struct{ code int }

func (e *statusErr) Error() string { return "unexpected status " + http.StatusText(e.code) }
