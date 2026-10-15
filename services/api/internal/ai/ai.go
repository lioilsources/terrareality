// Package ai turns listing facts into suggestions: attribute extraction from
// the owner's text and photo tags, and listing text drafts in Czech and
// English. The real implementation calls the OpenAI-compatible AiStack
// gateway on the DGX Spark; the mock is deterministic and offline. Results
// are never applied directly: callers store them as suggestions for a human
// (ADR 0003).
package ai

import (
	"context"

	"github.com/terrareality/terrareality/services/api/internal/catalog"
)

// ExtractRequest is the input for attribute extraction.
type ExtractRequest struct {
	Text      string              // owner's free text (description, notes)
	PhotoTags []string            // tags from the vision service
	UnitKind  string              // apartment | house | room | ...
	Attrs     []catalog.Attribute // attributes applicable to the unit kind
}

// NewOption is an enum/set value the model found that the schema lacks.
type NewOption struct {
	Key   string       `json:"key"`
	Value string       `json:"value"`
	Label catalog.I18n `json:"label"`
}

// NewAttribute is an attribute the model found that the catalog lacks. It is
// queued for staff (attribute_suggestions); nothing changes the catalog
// until a developer adds an approved one to packages/attributes (ADR 0003).
type NewAttribute struct {
	Key     string           `json:"key"`
	Type    string           `json:"type"` // bool | int | enum | set
	Group   string           `json:"group"`
	Label   catalog.I18n     `json:"label"`
	Options []catalog.Option `json:"options,omitempty"`
}

// ExtractResult holds suggested attribute values.
type ExtractResult struct {
	Values        map[string]any `json:"values"`
	NewOptions    []NewOption    `json:"new_options,omitempty"`
	NewAttributes []NewAttribute `json:"new_attributes,omitempty"`
	Model         string         `json:"model"`
}

// DraftRequest carries structured facts for a listing text.
type DraftRequest struct {
	UnitKind   string            `json:"unit_kind"`
	Layout     string            `json:"layout,omitempty"`
	FloorArea  float64           `json:"floor_area,omitempty"`
	Floor      *int32            `json:"floor,omitempty"`
	Location   string            `json:"location"` // city part, city
	Rent       int64             `json:"rent,omitempty"`
	Currency   string            `json:"currency,omitempty"`
	Features   map[string]string `json:"features"`              // attribute label -> value label (Czech)
	FeaturesEN map[string]string `json:"features_en"`           // same in English
	OwnerNotes string            `json:"owner_notes,omitempty"` // free text the owner wrote
}

// Texts is a Czech/English pair.
type Texts struct {
	CS string `json:"cs"`
	EN string `json:"en"`
}

// DraftResult is a suggested title and description.
type DraftResult struct {
	Title       Texts  `json:"title"`
	Description Texts  `json:"description"`
	Model       string `json:"model"`
}

// Assistant is implemented by the LLM client and the mock.
type Assistant interface {
	ExtractAttributes(ctx context.Context, req ExtractRequest) (ExtractResult, error)
	DraftText(ctx context.Context, req DraftRequest) (DraftResult, error)
}
