package search

import (
	"context"
	"encoding/json"
	"fmt"
	"regexp"
	"slices"
	"strconv"
	"strings"
	"unicode"

	"github.com/jackc/pgx/v5/pgxpool"
	"golang.org/x/text/runes"
	"golang.org/x/text/transform"
	"golang.org/x/text/unicode/norm"

	"github.com/terrareality/terrareality/services/api/internal/ai"
	"github.com/terrareality/terrareality/services/api/internal/catalog"
	"github.com/terrareality/terrareality/services/api/internal/db"
)

// Place is a resolved administrative unit.
type Place struct {
	Path string    `json:"path"`
	Name string    `json:"name"`
	BBox []float64 `json:"bbox"` // west, south, east, north
}

// ChatOutcome is what one chat message changes.
type ChatOutcome struct {
	Query    Query  `json:"query"`
	Place    *Place `json:"place,omitempty"`
	Reply    string `json:"reply"`
	Model    string `json:"model"`    // "rules" when the offline parser answered
	Degraded bool   `json:"degraded"` // LLM unavailable, rules were used
}

// ToolCaller is implemented by ai.Client.
type ToolCaller interface {
	CallTools(ctx context.Context, messages []ai.ChatMessage, tools []ai.Tool) ([]ai.ToolCall, string, error)
}

// Chat turns natural language into search filters and map moves.
type Chat struct {
	Pool  *pgxpool.Pool
	LLM   ToolCaller // nil = rules only
	Model string
}

func fold(s string) string {
	t := transform.Chain(norm.NFD, runes.Remove(runes.In(unicode.Mn)), norm.NFC)
	out, _, _ := transform.String(t, strings.ToLower(s))
	return out
}

var (
	reLayout   = regexp.MustCompile(`\b([1-6])\s*\+\s*(kk|1)\b`)
	reMoney    = regexp.MustCompile(`\b(do|max(?:imalne)?|pod|od|min(?:imalne)?|nad|za)\s+(\d[\d\s.]*)(\s*(?:tis(?:ic)?|k|000))?\b`)
	reArea     = regexp.MustCompile(`\b(od|nad|alespon|min|do|pod|max)\s+(\d{2,4})\s*(?:m2|m²|metru|metr)`)
	rePlace    = regexp.MustCompile(`\b(?:v|ve|na|u|okoli|blizko|kolem)\s+([a-z]+(?:\s+\d{1,2})?(?:\s+[a-z]+)?)`)
	placeNorms = []struct{ from, to string }{
		{"praze", "praha"}, {"brne", "brno"}, {"ostrave", "ostrava"}, {"plzni", "plzen"}, {"olomouci", "olomouc"},
		{"liberci", "liberec"}, {"vicich", "vice"}, {"icich", "ice"}, {"anech", "any"}, {"ove", "ov"}, {"ach", "y"},
	}
)

// normalizePlace undoes common Czech locative endings ("v Dejvicích" -> "dejvice").
func normalizePlace(s string) string {
	words := strings.Fields(s)
	for i, w := range words {
		for _, n := range placeNorms {
			if strings.HasSuffix(w, n.from) {
				words[i] = strings.TrimSuffix(w, n.from) + n.to
				break
			}
		}
	}
	return strings.Join(words, " ")
}

func parseAmount(num, unit string) (int64, bool) {
	digits := strings.NewReplacer(" ", "", ".", "", " ", "").Replace(num)
	n, err := strconv.ParseInt(digits, 10, 64)
	if err != nil {
		return 0, false
	}
	if u := strings.TrimSpace(unit); u == "tis" || u == "tisic" || u == "k" {
		n *= 1000
	} else if u == "000" {
		n *= 1000
	}
	if n < 1000 && n > 0 {
		n *= 1000 // "do 18" in a rent context means thousands
	}
	return n * 100, n > 0 // minor units
}

// Rules parses a Czech/English query without an LLM. It merges into the
// current query so follow-ups ("a s balkonem") refine the search.
func (c *Chat) Rules(ctx context.Context, text string, cur Query, schema *catalog.Schema) (Query, *Place) {
	q := cur
	t := " " + fold(text) + " "
	switch {
	case strings.Contains(t, "pokoj") || strings.Contains(t, "spolubydl") || strings.Contains(t, " room"):
		q.Kinds = []string{"room"}
	case strings.Contains(t, " dum") || strings.Contains(t, " domek") || strings.Contains(t, " house"):
		q.Kinds = []string{"house"}
	case strings.Contains(t, " byt") || strings.Contains(t, " flat") || strings.Contains(t, "apartm") || reLayout.MatchString(t):
		q.Kinds = []string{"apartment"}
	}
	if ms := reLayout.FindAllStringSubmatch(t, -1); ms != nil {
		q.Layouts = nil
		for _, m := range ms {
			q.Layouts = append(q.Layouts, m[1]+"+"+m[2])
		}
	}
	for _, m := range reMoney.FindAllStringSubmatch(t, -1) {
		v, ok := parseAmount(m[2], m[3])
		if !ok {
			continue
		}
		if strings.HasPrefix(m[1], "od") || strings.HasPrefix(m[1], "min") || m[1] == "nad" {
			q.RentMin = &v
		} else {
			q.RentMax = &v
		}
	}
	for _, m := range reArea.FindAllStringSubmatch(t, -1) {
		v, _ := strconv.ParseFloat(m[2], 64)
		if m[1] == "do" || m[1] == "pod" || m[1] == "max" {
			q.AreaMax = &v
		} else {
			q.AreaMin = &v
		}
	}
	// Attributes through the catalog keywords (same rules as listing ingest).
	kind := "apartment"
	if len(q.Kinds) == 1 {
		kind = q.Kinds[0]
	}
	petsText := strings.NewReplacer("psem", "pes ", "psy", "pes ", "kockou", "kocka ").Replace(t)
	res, _ := ai.Mock{}.ExtractAttributes(ctx, ai.ExtractRequest{Text: petsText, UnitKind: kind, Attrs: schema.For(kind)})
	for k, v := range res.Values {
		if k == "layout" || k == "floor_area" || k == "floor" || k == "heating" && v == "stove" {
			continue
		}
		a, ok := schema.Get(k)
		if !ok || !a.Filter {
			continue
		}
		if q.Attributes == nil {
			q.Attributes = map[string]AttrFilter{}
		} else {
			q.Attributes = cloneAttrs(q.Attributes)
		}
		switch x := v.(type) {
		case bool:
			q.Attributes[k] = AttrFilter{Bool: &x}
		case string:
			q.Attributes[k] = AttrFilter{Values: []string{x}}
		case []string:
			q.Attributes[k] = AttrFilter{Values: x}
		}
	}
	var place *Place
	for _, m := range rePlace.FindAllStringSubmatch(t, -1) {
		cand := normalizePlace(m[1])
		for len(cand) > 0 {
			if p := c.findPlace(ctx, cand); p != nil {
				place = p
				break
			}
			// Drop the last word ("praha 6 se" -> "praha 6").
			i := strings.LastIndex(cand, " ")
			if i < 0 {
				break
			}
			cand = cand[:i]
		}
		if place != nil {
			break
		}
	}
	if place != nil {
		q.AdminPath = place.Path
		q.BBox = nil
	}
	q.Offset = 0
	return q, place
}

func cloneAttrs(m map[string]AttrFilter) map[string]AttrFilter {
	out := make(map[string]AttrFilter, len(m))
	for k, v := range m {
		out[k] = v
	}
	return out
}

func (c *Chat) findPlace(ctx context.Context, name string) *Place {
	rows, err := db.New(c.Pool).FindAdminUnits(ctx, name)
	if err != nil || len(rows) == 0 {
		return nil
	}
	r := rows[0]
	if r.Score < 0.45 && fold(r.Name) != name {
		return nil
	}
	return &Place{Path: r.Path, Name: r.Name, BBox: []float64{r.West, r.South, r.East, r.North}}
}

var chatTools = []ai.Tool{
	{Name: "set_filters", Description: "Set search filters for rentals. Omit fields that the user did not mention. Prices are monthly rent in CZK.",
		Parameters: map[string]any{"type": "object", "properties": map[string]any{
			"kinds":    map[string]any{"type": "array", "items": map[string]any{"type": "string", "enum": []string{"apartment", "house", "room", "parking", "storage", "commercial"}}},
			"layouts":  map[string]any{"type": "array", "items": map[string]any{"type": "string"}, "description": "Czech layouts like 2+kk, 3+1"},
			"rent_min": map[string]any{"type": "number"}, "rent_max": map[string]any{"type": "number"},
			"area_min": map[string]any{"type": "number"}, "area_max": map[string]any{"type": "number"},
			"attributes": map[string]any{"type": "object", "description": "attribute key -> true for features, or list of option values",
				"additionalProperties": true},
			"text": map[string]any{"type": "string", "description": "free text for fulltext search, only when nothing else fits"},
		}}},
	{Name: "move_map", Description: "Move the map to a Czech place: region, city, district (Praha 6) or neighbourhood (Dejvice). Use the nominative form.",
		Parameters: map[string]any{"type": "object", "properties": map[string]any{"place": map[string]any{"type": "string"}},
			"required": []string{"place"}}},
}

const chatSystem = `You turn rental search requests (Czech or English) into tool calls on a Czech rental platform.
Call set_filters with every constraint the user states and move_map for any place. Keep earlier filters unless the
user changes them; the current filters are given as JSON. Prices are CZK per month (e.g. "do 18 000" -> rent_max 18000).
Pets: "se psem" -> attributes {"pets": ["dogs"]}. Use only these attribute keys and values:
%s`

// Ask runs one chat turn. The deterministic rules always run first (places,
// numbers, layouts are reliable there); the LLM, when available, adds what
// rules cannot express and overrides them where it is explicit.
func (c *Chat) Ask(ctx context.Context, text string, cur Query, schema *catalog.Schema, locale string) ChatOutcome {
	q, place := c.Rules(ctx, text, cur, schema)
	out := ChatOutcome{Query: q, Place: place, Model: "rules"}
	if c.LLM != nil {
		llm, err := c.askLLM(ctx, text, q, schema)
		if err == nil {
			if llm.Place == nil {
				llm.Place = place
			}
			if len(llm.Query.Kinds) == 0 && len(llm.Query.Layouts) > 0 {
				llm.Query.Kinds = []string{"apartment"}
			}
			out = llm
		} else {
			out.Degraded = true
		}
	}
	out.Reply = reply(out, locale, schema)
	return out
}

func (c *Chat) askLLM(ctx context.Context, text string, cur Query, schema *catalog.Schema) (ChatOutcome, error) {
	var lines []string
	for _, a := range schema.Attrs {
		if !a.Filter || a.Type == "int" || a.Type == "range" || a.Key == "layout" {
			continue
		}
		line := a.Key + " (" + a.Label.CS + ")"
		if len(a.Options) > 0 {
			vals := make([]string, 0, len(a.Options))
			for _, o := range a.Options {
				vals = append(vals, o.Value)
			}
			line += ": " + strings.Join(vals, ", ")
		}
		lines = append(lines, line)
	}
	curJSON, _ := json.Marshal(cur)
	calls, _, err := c.LLM.CallTools(ctx, []ai.ChatMessage{
		{Role: "system", Content: fmt.Sprintf(chatSystem, strings.Join(lines, "\n"))},
		{Role: "user", Content: "Current filters: " + string(curJSON) + "\nUser: " + text},
	}, chatTools)
	if err != nil {
		return ChatOutcome{}, err
	}
	q := cur
	q.Offset = 0
	var place *Place
	for _, call := range calls {
		switch call.Name {
		case "set_filters":
			var f struct {
				Kinds      []string       `json:"kinds"`
				Layouts    []string       `json:"layouts"`
				RentMin    *float64       `json:"rent_min"`
				RentMax    *float64       `json:"rent_max"`
				AreaMin    *float64       `json:"area_min"`
				AreaMax    *float64       `json:"area_max"`
				Attributes map[string]any `json:"attributes"`
				Text       string         `json:"text"`
			}
			if err := json.Unmarshal(call.Arguments, &f); err != nil {
				return ChatOutcome{}, fmt.Errorf("set_filters arguments: %w", err)
			}
			if len(f.Kinds) > 0 {
				q.Kinds = f.Kinds
			}
			if len(f.Layouts) > 0 {
				q.Layouts = f.Layouts
			}
			if f.RentMin != nil {
				v := int64(*f.RentMin) * 100
				q.RentMin = &v
			}
			if f.RentMax != nil {
				v := int64(*f.RentMax) * 100
				q.RentMax = &v
			}
			q.AreaMin, q.AreaMax = firstNonNil(f.AreaMin, q.AreaMin), firstNonNil(f.AreaMax, q.AreaMax)
			if f.Text != "" {
				q.Text = f.Text
			}
			for k, v := range f.Attributes {
				a, ok := schema.Get(k)
				if !ok || !a.Filter {
					continue // the model invented a key; ignore it
				}
				if q.Attributes == nil {
					q.Attributes = map[string]AttrFilter{}
				} else {
					q.Attributes = cloneAttrs(q.Attributes)
				}
				switch x := v.(type) {
				case bool:
					q.Attributes[k] = AttrFilter{Bool: &x}
				case string:
					if a.HasOption(x) {
						q.Attributes[k] = AttrFilter{Values: []string{x}}
					}
				case []any:
					var vals []string
					for _, e := range x {
						if s, ok := e.(string); ok && a.HasOption(s) {
							vals = append(vals, s)
						}
					}
					if len(vals) > 0 {
						q.Attributes[k] = AttrFilter{Values: vals}
					}
				}
			}
		case "move_map":
			var m struct {
				Place string `json:"place"`
			}
			if json.Unmarshal(call.Arguments, &m) == nil {
				if p := c.findPlace(ctx, normalizePlace(fold(m.Place))); p != nil {
					place = p
					q.AdminPath, q.BBox = p.Path, nil
				}
			}
		}
	}
	return ChatOutcome{Query: q, Place: place, Model: c.Model}, nil
}

func firstNonNil(a, b *float64) *float64 {
	if a != nil {
		return a
	}
	return b
}

var kindNamesCS = map[string]string{"apartment": "byty", "house": "domy", "room": "pokoje", "parking": "parkovací místa",
	"storage": "sklady", "commercial": "komerční prostory"}
var kindNamesEN = map[string]string{"apartment": "flats", "house": "houses", "room": "rooms", "parking": "parking spaces",
	"storage": "storage units", "commercial": "commercial spaces"}

// reply summarizes the applied filters (template, no extra LLM call).
func reply(o ChatOutcome, locale string, schema *catalog.Schema) string {
	q := o.Query
	var parts []string
	names := kindNamesCS
	if locale == "en" {
		names = kindNamesEN
	}
	if len(q.Kinds) > 0 {
		var ks []string
		for _, k := range q.Kinds {
			ks = append(ks, names[k])
		}
		parts = append(parts, strings.Join(ks, ", "))
	}
	if len(q.Layouts) > 0 {
		parts = append(parts, strings.Join(q.Layouts, ", "))
	}
	if q.RentMax != nil {
		if locale == "en" {
			parts = append(parts, fmt.Sprintf("up to CZK %d", *q.RentMax/100))
		} else {
			parts = append(parts, fmt.Sprintf("do %d Kč", *q.RentMax/100))
		}
	}
	if q.RentMin != nil {
		if locale == "en" {
			parts = append(parts, fmt.Sprintf("from CZK %d", *q.RentMin/100))
		} else {
			parts = append(parts, fmt.Sprintf("od %d Kč", *q.RentMin/100))
		}
	}
	if o.Place != nil {
		parts = append(parts, o.Place.Name)
	}
	keys := make([]string, 0, len(q.Attributes))
	for k := range q.Attributes {
		keys = append(keys, k)
	}
	slices.Sort(keys)
	for _, k := range keys {
		if a, ok := schema.Get(k); ok {
			if locale == "en" {
				parts = append(parts, a.Label.EN)
			} else {
				parts = append(parts, a.Label.CS)
			}
		}
	}
	prefix := "Hledám: "
	if locale == "en" {
		prefix = "Searching: "
	}
	msg := prefix + strings.Join(parts, " · ")
	if len(parts) == 0 {
		msg = map[bool]string{true: "I did not recognise any filter, try e.g. \"2+kk up to 18 000 in Praha 6\".",
			false: "Nerozpoznal jsem žádný filtr, zkuste třeba „2+kk do 18 000 v Praze 6“."}[locale == "en"]
	}
	if o.Degraded {
		msg += map[bool]string{true: " (AI is offline now, simple rules were used.)", false: " (AI je teď mimo provoz, použil jsem jednoduché rozpoznání.)"}[locale == "en"]
	}
	return msg
}
