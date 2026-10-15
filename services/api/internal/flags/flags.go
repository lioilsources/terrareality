// Package flags serves feature flags. Rows in the feature_flags table (edited
// in the backoffice, every change audited) win; keys without a row fall back
// to the process defaults (config.Config.Flags: built-in defaults plus the
// FEATURE_FLAGS env var). Reads hit an in-process cache that is refreshed
// every TTL and dropped on Set, so other processes see a change within TTL.
package flags

import (
	"context"
	"errors"
	"maps"
	"slices"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/terrareality/terrareality/services/api/internal/audit"
	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/platform/apperr"
	platformdb "github.com/terrareality/terrareality/services/api/internal/platform/db"
)

// DefaultTTL is how long a loaded flag set is served from memory.
const DefaultTTL = 30 * time.Second

// Sources of a flag value.
const (
	SourceDB      = "db"
	SourceDefault = "default"
)

// Flag is the effective value of one flag.
type Flag struct {
	Key         string
	Enabled     bool
	Description string
	Source      string     // SourceDB | SourceDefault
	UpdatedAt   *time.Time // set for SourceDB
}

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

// Store resolves flags. The zero Pool serves defaults only.
type Store struct {
	Pool     *pgxpool.Pool
	Defaults map[string]bool
	TTL      time.Duration
	Now      func() time.Time // tests

	mu       sync.Mutex
	rows     map[string]db.FeatureFlag
	loadedAt time.Time
}

// New creates a store over the feature_flags table with process defaults.
func New(pool *pgxpool.Pool, defaults map[string]bool) *Store {
	return &Store{Pool: pool, Defaults: maps.Clone(defaults), TTL: DefaultTTL}
}

func (s *Store) now() time.Time {
	if s.Now != nil {
		return s.Now()
	}
	return time.Now()
}

// load returns the cached rows, refreshing them after TTL. A failed refresh
// keeps the previous rows (or none), so flags degrade to the defaults instead
// of failing requests.
func (s *Store) load(ctx context.Context) (map[string]db.FeatureFlag, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	ttl := s.TTL
	if ttl <= 0 {
		ttl = DefaultTTL
	}
	if s.rows != nil && s.now().Sub(s.loadedAt) < ttl {
		return s.rows, nil
	}
	if s.Pool == nil {
		s.rows, s.loadedAt = map[string]db.FeatureFlag{}, s.now()
		return s.rows, nil
	}
	list, err := db.New(s.Pool).ListFeatureFlags(ctx)
	if err != nil {
		if s.rows == nil {
			return map[string]db.FeatureFlag{}, err
		}
		return s.rows, err
	}
	rows := make(map[string]db.FeatureFlag, len(list))
	for _, r := range list {
		rows[r.Key] = r
	}
	s.rows, s.loadedAt = rows, s.now()
	return rows, nil
}

// Invalidate drops the cache; the next read reloads from the database.
func (s *Store) Invalidate() {
	s.mu.Lock()
	s.rows = nil
	s.mu.Unlock()
}

// Enabled reports whether a flag is on. Unknown keys are off.
func (s *Store) Enabled(ctx context.Context, key string) bool {
	if s == nil {
		return false
	}
	rows, _ := s.load(ctx)
	if r, ok := rows[key]; ok {
		return r.Enabled
	}
	return s.Defaults[key]
}

func (s *Store) fromRow(r db.FeatureFlag) Flag {
	t := r.UpdatedAt
	d := r.Description
	if d == "" {
		d = descriptions[r.Key]
	}
	return Flag{Key: r.Key, Enabled: r.Enabled, Description: d, Source: SourceDB, UpdatedAt: &t}
}

// List returns every known flag (database rows merged with defaults), sorted by key.
func (s *Store) List(ctx context.Context) ([]Flag, error) {
	rows, err := s.load(ctx)
	if err != nil {
		return nil, err
	}
	keys := slices.Collect(maps.Keys(s.Defaults))
	for k := range rows {
		if _, ok := s.Defaults[k]; !ok {
			keys = append(keys, k)
		}
	}
	slices.Sort(keys)
	out := make([]Flag, 0, len(keys))
	for _, k := range keys {
		if r, ok := rows[k]; ok {
			out = append(out, s.fromRow(r))
		} else {
			out = append(out, Flag{Key: k, Enabled: s.Defaults[k], Description: descriptions[k], Source: SourceDefault})
		}
	}
	return out, nil
}

var errUnknown = apperr.NotFound("feature_flag_not_found", "unknown feature flag")

// Set stores an override for a known key (one with a default or an existing
// row) and audits the change. description nil keeps the stored one.
func (s *Store) Set(ctx context.Context, actor uuid.UUID, key string, enabled bool, description *string) (Flag, error) {
	if s.Pool == nil {
		return Flag{}, errors.New("flags: no database")
	}
	var out db.FeatureFlag
	err := platformdb.InTx(ctx, s.Pool, func(tx pgx.Tx) error {
		q := db.New(tx)
		before, err := q.GetFeatureFlag(ctx, key)
		var prev any
		switch {
		case errors.Is(err, pgx.ErrNoRows):
			def, known := s.Defaults[key]
			if !known {
				return errUnknown
			}
			prev = def
		case err != nil:
			return err
		default:
			prev = before.Enabled
		}
		var desc any // untyped nil keeps the stored description
		if description != nil {
			desc = *description
		}
		out, err = q.UpsertFeatureFlag(ctx, db.UpsertFeatureFlagParams{Key: key, Enabled: enabled,
			Description: desc, UpdatedBy: &actor})
		if err != nil {
			return err
		}
		return audit.Record(ctx, q, audit.Event{Entity: "feature_flag", Action: "feature_flag.set", ActorID: &actor,
			Diff: map[string]any{"key": key, "enabled": enabled, "before": prev}})
	})
	s.Invalidate()
	if err != nil {
		return Flag{}, err
	}
	return s.fromRow(out), nil
}
