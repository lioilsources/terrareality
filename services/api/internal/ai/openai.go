package ai

import (
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"net/http"
	"regexp"
	"slices"
	"strings"
	"time"
	"unicode/utf8"
)

// Client calls an OpenAI-compatible chat completions endpoint (AiStack
// LiteLLM gateway on the Spark) with JSON-schema constrained output.
//
// Fallback, when set, is a cloud OpenAI-compatible gateway (Claude) used only
// when the Spark fails (unreachable, timeout, 5xx) and FallbackOn reports the
// flag ai.cloud_fallback on for the request. Listing texts and search queries
// then leave the EU-hosted stack; see docs/legal-questions.md.
type Client struct {
	BaseURL    string
	APIKey     string
	Model      string
	HTTP       *http.Client
	Fallback   *Endpoint
	FallbackOn func(context.Context) bool
	Log        *slog.Logger
}

// NewClient creates a client with a generous timeout for local inference.
func NewClient(baseURL, apiKey, model string) *Client {
	return &Client{BaseURL: strings.TrimRight(baseURL, "/"), APIKey: apiKey, Model: model,
		HTTP: &http.Client{Timeout: 120 * time.Second}}
}

type chatRequest struct {
	Model          string         `json:"model"`
	Messages       []chatMessage  `json:"messages"`
	Temperature    float64        `json:"temperature"`
	ResponseFormat map[string]any `json:"response_format,omitempty"`
}

type chatMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

// complete asks for JSON and returns the model that answered. With a schema the output is constrained by guided
// decoding; without one (nil) the model answers in JSON mode and the caller
// validates, which works better for wide, sparse objects.
func (c *Client) complete(ctx context.Context, system, user, schemaName string, schema map[string]any, out any) (string, error) {
	format := map[string]any{"type": "json_object"}
	if schema != nil {
		format = map[string]any{"type": "json_schema", "json_schema": map[string]any{
			"name": schemaName, "schema": schema, "strict": false}}
	}
	raw, model, err := c.post(ctx, func(model string) []byte {
		body, _ := json.Marshal(chatRequest{
			Model: model, Temperature: 0,
			Messages:       []chatMessage{{Role: "system", Content: system}, {Role: "user", Content: user}},
			ResponseFormat: format,
		})
		return body
	})
	if err != nil {
		return "", err
	}
	var cr struct {
		Choices []struct {
			Message struct {
				Content string `json:"content"`
			} `json:"message"`
		} `json:"choices"`
	}
	if err := json.Unmarshal(raw, &cr); err != nil || len(cr.Choices) == 0 {
		return "", fmt.Errorf("llm: unexpected response: %.300s", raw)
	}
	return model, json.Unmarshal([]byte(jsonObject(cr.Choices[0].Message.Content)), out)
}

var reThink = regexp.MustCompile(`(?s)<think>.*?</think>`)

// jsonObject extracts the outermost JSON object (models sometimes add prose
// or reasoning blocks even in JSON mode).
func jsonObject(s string) string {
	s = reThink.ReplaceAllString(s, "")
	i, j := strings.Index(s, "{"), strings.LastIndex(s, "}")
	if i < 0 || j < i {
		return s
	}
	return s[i : j+1]
}

const extractSystem = `You extract structured attributes of a rental property from the owner's text (usually Czech)
and from photo tags. Go through the attribute list one by one and include every attribute that the text states
or clearly implies, for example "s výtahem" -> "elevator": true, "balkon" -> "balcony": true,
"ve 3. patře" -> "floor": 3, "cihlový dům" -> "building_type": "brick", "pes po dohodě" -> "pets": ["dogs"].
"bez výtahu" means false. Omit attributes the text does not mention; never guess numbers and never output 0
for an unknown number. For enum and set attributes use only the listed option values. If the text clearly
states a value that is not among the options, add it to "new_options" with a short snake_case value and
Czech and English labels, and leave the attribute out of "values". If the text clearly states a property
feature that none of the listed attributes covers, add it to "new_attributes" with a snake_case key, a type
(bool, int, enum or set), a group (basic, building, equipment, location, outdoor, parking, room or rules) and
Czech and English labels. Answer with one JSON object only.`

// ExtractAttributes implements Assistant. A schema with 60+ optional
// properties makes guided decoding stop after a few keys, so extraction uses
// JSON mode and the caller validates the values against the catalog.
func (c *Client) ExtractAttributes(ctx context.Context, req ExtractRequest) (ExtractResult, error) {
	var lines []string
	for _, a := range req.Attrs {
		if a.Type == "text" {
			continue
		}
		line := fmt.Sprintf("- %s (%s): %s / %s", a.Key, a.Type, a.Label.CS, a.Label.EN)
		if a.Unit != "" {
			line += " [" + a.Unit + "]"
		}
		if len(a.Options) > 0 {
			vals := make([]string, 0, len(a.Options))
			for _, o := range a.Options {
				vals = append(vals, o.Value)
			}
			line += " options: " + strings.Join(vals, ", ")
		}
		if kw := append(a.Keywords["cs"], a.Keywords["en"]...); len(kw) > 0 {
			line += " (e.g. " + strings.Join(kw, ", ") + ")"
		}
		lines = append(lines, line)
	}
	user := fmt.Sprintf("Unit kind: %s\nAttributes:\n%s\n\nPhoto tags: %s\n\nOwner text:\n%s\n\n"+
		`Answer as {"values": {"<attribute key>": <value>, ...}, "new_options": [{"key": ..., "value": ..., "label": {"cs": ..., "en": ...}}], `+
		`"new_attributes": [{"key": ..., "type": ..., "group": ..., "label": {"cs": ..., "en": ...}}]}`,
		req.UnitKind, strings.Join(lines, "\n"), strings.Join(req.PhotoTags, ", "), req.Text)
	var out ExtractResult
	model, err := c.complete(ctx, extractSystem, user, "", nil, &out)
	if err != nil {
		return ExtractResult{}, err
	}
	if out.Values == nil {
		out.Values = map[string]any{}
	}
	// Keep only proposals for known enum/set attributes with a sane value.
	reValue := regexp.MustCompile(`^[a-z0-9][a-z0-9_+-]{0,40}$`)
	known := map[string]string{}
	for _, a := range req.Attrs {
		known[a.Key] = a.Type
	}
	out.NewOptions = slices.DeleteFunc(out.NewOptions, func(n NewOption) bool {
		t := known[n.Key]
		return (t != "enum" && t != "set") || !reValue.MatchString(n.Value) || n.Label.CS == "" || n.Label.EN == ""
	})
	// Values for keys outside the catalog are dropped by the caller's schema
	// validation; proposals for new attributes go to the staff queue.
	reKey := regexp.MustCompile(`^[a-z][a-z0-9_]{1,40}$`)
	out.NewAttributes = slices.DeleteFunc(out.NewAttributes, func(n NewAttribute) bool {
		_, exists := known[n.Key]
		return exists || !reKey.MatchString(n.Key) || !slices.Contains([]string{"bool", "int", "enum", "set"}, n.Type) ||
			n.Label.CS == "" || n.Label.EN == ""
	})
	out.Model = model
	return out, nil
}

const draftSystem = `You write rental listing texts for a Czech platform. Use only the facts provided, never invent
features, prices or distances. Write a factual title (max 80 characters) and a description of 3-6 short
paragraphs or bullet lists, first in Czech, then the same content in English. No superlatives, no emojis.
Answer with one JSON object only.`

// DraftText implements Assistant.
func (c *Client) DraftText(ctx context.Context, req DraftRequest) (DraftResult, error) {
	facts, _ := json.MarshalIndent(req, "", "  ")
	texts := map[string]any{"type": "object", "properties": map[string]any{
		"cs": map[string]any{"type": "string"}, "en": map[string]any{"type": "string"}}, "required": []string{"cs", "en"}}
	schema := map[string]any{"type": "object", "properties": map[string]any{"title": texts, "description": texts},
		"required": []string{"title", "description"}}
	var out DraftResult
	model, err := c.complete(ctx, draftSystem, "Facts:\n"+string(facts), "listing_text", schema, &out)
	if err != nil {
		return DraftResult{}, err
	}
	out.Title.CS = truncateRunes(out.Title.CS, MaxTitleRunes)
	out.Title.EN = truncateRunes(out.Title.EN, MaxTitleRunes)
	out.Description.CS = truncateRunes(out.Description.CS, MaxDescriptionRunes)
	out.Description.EN = truncateRunes(out.Description.EN, MaxDescriptionRunes)
	out.Model = model
	return out, nil
}

// Listing text limits (the same as the editor enforces).
const (
	MaxTitleRunes       = 120
	MaxDescriptionRunes = 10000
)

// truncateRunes cuts s to at most n characters without splitting a UTF-8
// sequence (a byte cut produces invalid UTF-8, which jsonb rejects).
func truncateRunes(s string, n int) string {
	if utf8.RuneCountInString(s) <= n {
		return s
	}
	r := []rune(s)
	return string(r[:n])
}
