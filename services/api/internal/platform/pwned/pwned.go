// Package pwned checks passwords against breached-password corpora (ASVS
// V2.1.7). The production adapter queries the Have I Been Pwned range API with
// k-anonymity: only the first five hex characters of the SHA-1 hash leave the
// process, responses are padded, and an unreachable service never blocks a
// user (fail-open with a log line). The offline adapter matches a small
// embedded list of the most common passwords so `make dev` works without
// network access.
package pwned

import (
	"bufio"
	"context"
	"crypto/sha1" //nolint:gosec // SHA-1 is what the HIBP range API is keyed by; not used for security of stored data
	_ "embed"
	"encoding/hex"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"strings"
	"time"
)

// Checker reports whether a password appears in a breach corpus.
type Checker interface {
	Breached(ctx context.Context, password string) bool
}

// New returns the checker for mode: "hibp" (production), "local" (offline
// list, dev/test default) or "off".
func New(mode string, log *slog.Logger) (Checker, error) {
	switch mode {
	case "hibp":
		return &HIBP{Log: log}, nil
	case "local":
		return Local(), nil
	case "off":
		return Off{}, nil
	default:
		return nil, fmt.Errorf("PWNED_PASSWORDS must be hibp|local|off, got %q", mode)
	}
}

// Off never reports a breach.
type Off struct{}

// Breached implements Checker.
func (Off) Breached(context.Context, string) bool { return false }

//go:embed common.txt
var commonList string

// LocalList matches the embedded list of common passwords, case-insensitively.
type LocalList map[string]struct{}

// Local returns the offline checker.
func Local() LocalList {
	m := LocalList{}
	for _, l := range strings.Split(commonList, "\n") {
		l = strings.TrimSpace(l)
		if l != "" && !strings.HasPrefix(l, "#") {
			m[strings.ToLower(l)] = struct{}{}
		}
	}
	return m
}

// Breached implements Checker.
func (l LocalList) Breached(_ context.Context, password string) bool {
	_, ok := l[strings.ToLower(password)]
	return ok
}

// DefaultHIBPURL is the public Pwned Passwords range endpoint.
const DefaultHIBPURL = "https://api.pwnedpasswords.com/range/"

// HIBP queries the Pwned Passwords range API.
type HIBP struct {
	BaseURL string        // default DefaultHIBPURL
	Timeout time.Duration // default 2s
	Client  *http.Client  // default http.DefaultClient
	Log     *slog.Logger
}

// Breached implements Checker. Errors are logged and treated as "not
// breached" so an outage of the external service never blocks sign-up.
func (h *HIBP) Breached(ctx context.Context, password string) bool {
	found, err := h.lookup(ctx, password)
	if err != nil {
		if h.Log != nil {
			h.Log.Warn("pwned passwords check skipped (fail-open)", "err", err)
		}
		return false
	}
	return found
}

func (h *HIBP) lookup(ctx context.Context, password string) (bool, error) {
	sum := sha1.Sum([]byte(password)) //nolint:gosec // see import
	hash := strings.ToUpper(hex.EncodeToString(sum[:]))
	prefix, suffix := hash[:5], hash[5:]
	timeout := h.Timeout
	if timeout <= 0 {
		timeout = 2 * time.Second
	}
	ctx, cancel := context.WithTimeout(ctx, timeout)
	defer cancel()
	base := h.BaseURL
	if base == "" {
		base = DefaultHIBPURL
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, base+prefix, nil)
	if err != nil {
		return false, err
	}
	req.Header.Set("Add-Padding", "true")
	req.Header.Set("User-Agent", "TerraReality-API")
	client := h.Client
	if client == nil {
		client = http.DefaultClient
	}
	resp, err := client.Do(req)
	if err != nil {
		return false, err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		_, _ = io.Copy(io.Discard, io.LimitReader(resp.Body, 4096))
		return false, fmt.Errorf("pwned passwords: status %d", resp.StatusCode)
	}
	sc := bufio.NewScanner(io.LimitReader(resp.Body, 4<<20))
	for sc.Scan() {
		s, count, ok := strings.Cut(strings.TrimSpace(sc.Text()), ":")
		// Padding entries have a count of 0.
		if ok && strings.EqualFold(s, suffix) && strings.TrimSpace(count) != "0" {
			return true, nil
		}
	}
	return false, sc.Err()
}
