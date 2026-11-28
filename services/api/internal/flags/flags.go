// Package flags serves feature flags through ol1n_platform_kit/flags: rows in
// the feature_flags table (edited in the backoffice, every change audited)
// win; keys without a row fall back to the process defaults (config.Config.Flags:
// built-in defaults plus the FEATURE_FLAGS env var).
package flags

import (
	"errors"

	"github.com/jackc/pgx/v5/pgxpool"
	kitflags "github.com/lioilsources/ol1n_platform_kit/flags"

	"github.com/terrareality/terrareality/services/api/internal/platform/apperr"
)

// DefaultTTL is how long a loaded flag set is served from memory.
const DefaultTTL = kitflags.DefaultTTL

// Sources of a flag value.
const (
	SourceDB      = kitflags.SourceDB
	SourceDefault = kitflags.SourceDefault
)

type (
	// Store resolves flags. The zero Pool serves defaults only.
	Store = kitflags.Store
	// Flag is the effective value of one flag.
	Flag = kitflags.Flag
)

// descriptions explain the built-in keys in the backoffice.
var descriptions = map[string]string{
	"ai.attributes":     "AI attribute extraction for listings (suggestions approved by the owner)",
	"ai.text":           "AI listing text drafts (suggestions approved by the owner)",
	"ai.vision":         "Photo analysis by the vision service",
	"ai.cloud_fallback": "Allow a cloud LLM when the own GPU server is unavailable",
	"ai.moderation":     "AI verdicts for message moderation (staff decide)",
	"ai.applications":   "AI summaries of rental applications (the landlord decides)",
	"payments.revolut":  "Revolut Business payment links for obligation shares (landlord-direct)",
}

// New creates a store over the feature_flags table with process defaults.
func New(pool *pgxpool.Pool, defaults map[string]bool) *Store {
	return kitflags.New(pool, defaults, descriptions)
}

// AppErr maps the kit's unknown-key error to the API error.
func AppErr(err error) error {
	if errors.Is(err, kitflags.ErrUnknown) {
		return apperr.NotFound("feature_flag_not_found", "unknown feature flag")
	}
	return err
}
