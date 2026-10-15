// Package catalog holds the listing attribute catalog (packages/attributes/
// catalog.json, copied here by `make gen`), syncs it into filter_schemas and
// validates attribute values against the live schema, including option
// values added through approved ingest proposals.
package catalog

import (
	"context"
	_ "embed"
	"encoding/json"
	"fmt"
	"math"
	"slices"
	"sort"
	"strings"

	"github.com/terrareality/terrareality/services/api/internal/db"
)

//go:embed catalog.json
var catalogJSON []byte

// I18n is a Czech/English label.
type I18n struct {
	CS string `json:"cs"`
	EN string `json:"en"`
}

// Option is one value of an enum or set attribute.
type Option struct {
	Value  string `json:"value"`
	Label  I18n   `json:"label"`
	Source string `json:"source,omitempty"` // catalog | ingest
}

// Attribute describes one listing attribute.
type Attribute struct {
	Key       string              `json:"key"`
	Type      string              `json:"type"` // bool | int | range | enum | set | text
	Group     string              `json:"group"`
	Label     I18n                `json:"label"`
	Filter    bool                `json:"filter"`
	Unit      string              `json:"unit,omitempty"`
	Min       *float64            `json:"min,omitempty"`
	Max       *float64            `json:"max,omitempty"`
	AppliesTo []string            `json:"applies_to,omitempty"`
	Options   []Option            `json:"options,omitempty"`
	Keywords  map[string][]string `json:"keywords,omitempty"`
}

// Group is a heading for attributes.
type Group struct {
	Key   string `json:"key"`
	Label I18n   `json:"label"`
}

// Catalog is the parsed catalog file.
type Catalog struct {
	Version    int         `json:"version"`
	Groups     []Group     `json:"groups"`
	Attributes []Attribute `json:"attributes"`
}

// Embedded parses the catalog compiled into the binary.
func Embedded() (Catalog, error) {
	var c Catalog
	if err := json.Unmarshal(catalogJSON, &c); err != nil {
		return c, fmt.Errorf("catalog.json: %w", err)
	}
	return c, c.check()
}

func (c Catalog) check() error {
	groups := map[string]bool{}
	for _, g := range c.Groups {
		groups[g.Key] = true
	}
	seen := map[string]bool{}
	for _, a := range c.Attributes {
		if seen[a.Key] {
			return fmt.Errorf("duplicate attribute %q", a.Key)
		}
		seen[a.Key] = true
		if !groups[a.Group] {
			return fmt.Errorf("attribute %q: unknown group %q", a.Key, a.Group)
		}
		if (a.Type == "enum" || a.Type == "set") && len(a.Options) == 0 {
			return fmt.Errorf("attribute %q: %s without options", a.Key, a.Type)
		}
		if a.Label.CS == "" || a.Label.EN == "" {
			return fmt.Errorf("attribute %q: missing label", a.Key)
		}
	}
	return nil
}

// Sync upserts the catalog into filter_schemas (run at startup).
func Sync(ctx context.Context, q db.Querier) error {
	c, err := Embedded()
	if err != nil {
		return err
	}
	for i, g := range c.Groups {
		label, _ := json.Marshal(g.Label)
		if err := q.UpsertFilterGroup(ctx, db.UpsertFilterGroupParams{Key: g.Key, Label: label, Position: int32(i)}); err != nil {
			return err
		}
	}
	for i, a := range c.Attributes {
		for j := range a.Options {
			a.Options[j].Source = "catalog"
		}
		label, _ := json.Marshal(a.Label)
		opts, _ := json.Marshal(nonNil(a.Options))
		kw, _ := json.Marshal(a.Keywords)
		if a.Keywords == nil {
			kw = []byte("{}")
		}
		var unit *string
		if a.Unit != "" {
			unit = &a.Unit
		}
		applies := a.AppliesTo
		if applies == nil {
			applies = []string{}
		}
		if err := q.UpsertFilterSchema(ctx, db.UpsertFilterSchemaParams{Key: a.Key, Type: a.Type, GroupKey: a.Group,
			Label: label, Filter: a.Filter, Unit: unit, MinValue: a.Min, MaxValue: a.Max, AppliesTo: applies,
			Options: opts, Keywords: kw, Position: int32(i)}); err != nil {
			return fmt.Errorf("sync %s: %w", a.Key, err)
		}
	}
	return nil
}

func nonNil(o []Option) []Option {
	if o == nil {
		return []Option{}
	}
	return o
}

// Schema is the live attribute schema (catalog plus approved ingest options).
type Schema struct {
	Groups []Group
	Attrs  []Attribute
	byKey  map[string]*Attribute
}

// Load reads filter_schemas.
func Load(ctx context.Context, q db.Querier) (*Schema, error) {
	rows, err := q.ListFilterSchemas(ctx)
	if err != nil {
		return nil, err
	}
	groups, err := q.ListFilterGroups(ctx)
	if err != nil {
		return nil, err
	}
	s := &Schema{byKey: map[string]*Attribute{}}
	for _, g := range groups {
		var l I18n
		_ = json.Unmarshal(g.Label, &l)
		s.Groups = append(s.Groups, Group{Key: g.Key, Label: l})
	}
	for _, r := range rows {
		a := Attribute{Key: r.Key, Type: r.Type, Group: r.GroupKey, Filter: r.Filter, Min: r.MinValue, Max: r.MaxValue, AppliesTo: r.AppliesTo}
		if r.Unit != nil {
			a.Unit = *r.Unit
		}
		_ = json.Unmarshal(r.Label, &a.Label)
		_ = json.Unmarshal(r.Options, &a.Options)
		_ = json.Unmarshal(r.Keywords, &a.Keywords)
		s.Attrs = append(s.Attrs, a)
	}
	for i := range s.Attrs {
		s.byKey[s.Attrs[i].Key] = &s.Attrs[i]
	}
	return s, nil
}

// Schema returns the catalog as a schema without ingest options (tests and
// tools that run without a database).
func (c Catalog) Schema() *Schema {
	s := &Schema{Groups: c.Groups, Attrs: append([]Attribute(nil), c.Attributes...), byKey: map[string]*Attribute{}}
	for i := range s.Attrs {
		s.byKey[s.Attrs[i].Key] = &s.Attrs[i]
	}
	return s
}

// Get returns an attribute by key.
func (s *Schema) Get(key string) (*Attribute, bool) {
	a, ok := s.byKey[key]
	return a, ok
}

// For returns the attributes applicable to a unit kind.
func (s *Schema) For(unitKind string) []Attribute {
	var out []Attribute
	for _, a := range s.Attrs {
		if len(a.AppliesTo) == 0 || slices.Contains(a.AppliesTo, unitKind) {
			out = append(out, a)
		}
	}
	return out
}

// HasOption reports whether value is a known option of an enum/set attribute.
func (a *Attribute) HasOption(value string) bool {
	for _, o := range a.Options {
		if o.Value == value {
			return true
		}
	}
	return false
}

// FieldError is a validation problem of one attribute.
type FieldError struct {
	Key    string `json:"key"`
	Reason string `json:"reason"`
}

// Validate normalizes values and reports problems. Unknown keys, wrong types
// and unknown options are errors; nulls remove the attribute.
func (s *Schema) Validate(in map[string]any, unitKind string) (map[string]any, []FieldError) {
	out := map[string]any{}
	var errs []FieldError
	keys := make([]string, 0, len(in))
	for k := range in {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	for _, k := range keys {
		v := in[k]
		a, ok := s.byKey[k]
		if !ok {
			errs = append(errs, FieldError{k, "unknown attribute"})
			continue
		}
		if v == nil {
			continue
		}
		if len(a.AppliesTo) > 0 && !slices.Contains(a.AppliesTo, unitKind) {
			errs = append(errs, FieldError{k, "not applicable to " + unitKind})
			continue
		}
		norm, reason := a.normalize(v)
		if reason != "" {
			errs = append(errs, FieldError{k, reason})
			continue
		}
		out[k] = norm
	}
	return out, errs
}

func (a *Attribute) normalize(v any) (any, string) {
	switch a.Type {
	case "bool":
		b, ok := v.(bool)
		if !ok {
			return nil, "expected boolean"
		}
		return b, ""
	case "int", "range":
		f, ok := v.(float64)
		if !ok {
			if i, isInt := v.(int); isInt {
				f, ok = float64(i), true
			}
		}
		if !ok || math.IsNaN(f) {
			return nil, "expected number"
		}
		if a.Type == "int" && f != math.Trunc(f) {
			return nil, "expected whole number"
		}
		if (a.Min != nil && f < *a.Min) || (a.Max != nil && f > *a.Max) {
			return nil, "out of range"
		}
		return f, ""
	case "enum":
		sv, ok := v.(string)
		if !ok || !a.HasOption(sv) {
			return nil, "unknown option"
		}
		return sv, ""
	case "set":
		list, ok := v.([]any)
		if !ok {
			if ss, isStr := v.([]string); isStr {
				for _, x := range ss {
					list = append(list, x)
				}
				ok = true
			}
		}
		if !ok {
			return nil, "expected list"
		}
		var vals []string
		for _, x := range list {
			sv, ok := x.(string)
			if !ok || !a.HasOption(sv) {
				return nil, "unknown option"
			}
			if !slices.Contains(vals, sv) {
				vals = append(vals, sv)
			}
		}
		sort.Strings(vals)
		return vals, ""
	case "text":
		sv, ok := v.(string)
		if !ok || len(sv) > 2000 {
			return nil, "expected text up to 2000 characters"
		}
		return strings.TrimSpace(sv), ""
	}
	return nil, "unsupported type"
}
