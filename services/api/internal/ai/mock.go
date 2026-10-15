package ai

import (
	"context"
	"fmt"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"unicode"

	"golang.org/x/text/runes"
	"golang.org/x/text/transform"
	"golang.org/x/text/unicode/norm"

	"github.com/terrareality/terrareality/services/api/internal/catalog"
)

// Mock extracts attributes with keyword rules from the catalog and writes
// template texts. It is good enough for development and tests and is the
// fallback when the Spark is unreachable.
type Mock struct{}

// fold lowercases and removes diacritics ("Výtah" -> "vytah").
func fold(s string) string {
	t := transform.Chain(norm.NFD, runes.Remove(runes.In(unicode.Mn)), norm.NFC)
	out, _, _ := transform.String(t, strings.ToLower(s))
	return out
}

var (
	reLayout = regexp.MustCompile(`\b([1-6])\s*\+\s*(kk|1)\b`)
	reArea   = regexp.MustCompile(`(\d{2,4}(?:[.,]\d+)?)\s*(?:m2|m²|metru|metru ctverecnich|sqm)`)
	reFloor  = regexp.MustCompile(`(\d{1,2})\.\s*(?:patro|patre|podlazi|nadzemni)`)
	negators = []string{"bez ", "neni ", "no ", "without "}
)

// photoTagAttrs maps vision tags to attribute values.
var photoTagAttrs = map[string][2]any{
	"balcony": {"balcony", true}, "terrace": {"terrace", true}, "garden": {"garden", true},
	"cellar": {"cellar", true}, "fireplace": {"fireplace", true}, "air_conditioning": {"air_conditioning", true},
	"elevator": {"elevator", true}, "bathtub": {"bathtub", true}, "shower": {"shower", true},
	"washing_machine": {"washing_machine", true}, "garage": {"parking", "garage"},
}

// stem drops a Czech inflection ending so "cihlová" also matches "cihlový".
func stem(phrase string) string {
	f := []rune(fold(phrase))
	if len(f) > 6 {
		return string(f[:len(f)-2])
	}
	return string(f)
}

func contains(text, kw string) (found, negated bool) {
	kw = fold(kw)
	i := strings.Index(text, kw)
	if i < 0 {
		return false, false
	}
	before := text[max(0, i-8):i]
	for _, n := range negators {
		if strings.HasSuffix(before, n) {
			return true, true
		}
	}
	return true, false
}

// ExtractAttributes implements Assistant.
func (Mock) ExtractAttributes(_ context.Context, req ExtractRequest) (ExtractResult, error) {
	text := fold(req.Text)
	vals := map[string]any{}
	applicable := map[string]catalog.Attribute{}
	for _, a := range req.Attrs {
		applicable[a.Key] = a
	}
	set := func(k string, v any) {
		if _, ok := applicable[k]; ok {
			vals[k] = v
		}
	}
	if m := reLayout.FindStringSubmatch(text); m != nil {
		set("layout", m[1]+"+"+m[2])
	}
	if m := reArea.FindStringSubmatch(text); m != nil {
		if f, err := strconv.ParseFloat(strings.ReplaceAll(m[1], ",", "."), 64); err == nil {
			set("floor_area", f)
		}
	}
	if m := reFloor.FindStringSubmatch(text); m != nil {
		if n, err := strconv.Atoi(m[1]); err == nil {
			set("floor", float64(n))
		}
	}
	for _, a := range req.Attrs {
		switch a.Type {
		case "bool":
			for _, kw := range append(a.Keywords["cs"], a.Keywords["en"]...) {
				if found, neg := contains(text, kw); found {
					vals[a.Key] = !neg
					break
				}
			}
		case "enum", "set":
			var hits []string
			for _, o := range a.Options {
				for _, phrase := range []string{o.Label.CS, o.Label.EN} {
					if len(phrase) < 4 {
						continue
					}
					if found, neg := contains(text, stem(phrase)); found && !neg {
						hits = append(hits, o.Value)
						break
					}
				}
			}
			if len(hits) == 0 {
				continue
			}
			if a.Type == "enum" {
				vals[a.Key] = hits[0]
			} else {
				sort.Strings(hits)
				vals[a.Key] = hits
			}
		}
	}
	// Pets need stems ("psa", "pejsek", "kočku").
	if _, ok := applicable["pets"]; ok {
		var pets []string
		if strings.Contains(text, "kock") || strings.Contains(text, "cat") {
			pets = append(pets, "cats")
		}
		if strings.Contains(text, " psa") || strings.Contains(text, " pes") || strings.Contains(text, "pejs") || strings.Contains(text, "dog") {
			pets = append(pets, "dogs")
		}
		if len(pets) > 0 {
			vals["pets"] = pets
		}
	}
	for _, tag := range req.PhotoTags {
		if av, ok := photoTagAttrs[tag]; ok {
			if _, already := vals[av[0].(string)]; !already {
				set(av[0].(string), av[1])
			}
		}
	}
	res := ExtractResult{Values: vals, Model: "mock"}
	// A value outside the schema, so the proposal queue is exercised offline.
	if _, ok := applicable["heating"]; ok && strings.Contains(text, "kamna") {
		res.Values["heating"] = "stove"
		res.NewOptions = append(res.NewOptions, NewOption{Key: "heating", Value: "stove",
			Label: catalog.I18n{CS: "kamna", EN: "stove"}})
	}
	// An attribute outside the catalog ("sauna" is not in packages/attributes),
	// so the backoffice attribute queue is exercised offline (E2E relies on it).
	if strings.Contains(text, "sauna") {
		res.NewAttributes = append(res.NewAttributes, NewAttribute{Key: "sauna", Type: "bool", Group: "equipment",
			Label: catalog.I18n{CS: "Sauna", EN: "Sauna"}})
	}
	return res, nil
}

var kindCS = map[string]string{"apartment": "bytu", "house": "domu", "room": "pokoje", "parking": "parkovacího místa",
	"storage": "skladu", "commercial": "komerčního prostoru"}
var kindEN = map[string]string{"apartment": "Flat", "house": "House", "room": "Room", "parking": "Parking space",
	"storage": "Storage", "commercial": "Commercial space"}

// DraftText implements Assistant.
func (Mock) DraftText(_ context.Context, r DraftRequest) (DraftResult, error) {
	var cs, en []string
	if r.Layout != "" {
		cs, en = append(cs, r.Layout), append(en, r.Layout)
	}
	if r.FloorArea > 0 {
		a := strconv.FormatFloat(r.FloorArea, 'f', -1, 64) + " m²"
		cs, en = append(cs, a), append(en, a)
	}
	title := Texts{
		CS: strings.TrimSpace(fmt.Sprintf("Pronájem %s %s, %s", kindCS[r.UnitKind], strings.Join(cs, ", "), r.Location)),
		EN: strings.TrimSpace(fmt.Sprintf("%s for rent %s, %s", kindEN[r.UnitKind], strings.Join(en, ", "), r.Location)),
	}
	title.CS = strings.ReplaceAll(title.CS, "  ", " ")
	title.EN = strings.ReplaceAll(title.EN, "  ", " ")
	desc := Texts{
		CS: fmt.Sprintf("Nabízíme k pronájmu %s v lokalitě %s.", kindCS[r.UnitKind], r.Location),
		EN: fmt.Sprintf("%s for rent in %s.", kindEN[r.UnitKind], r.Location),
	}
	if r.Floor != nil {
		desc.CS += fmt.Sprintf(" Nachází se v %d. podlaží.", *r.Floor)
		desc.EN += fmt.Sprintf(" It is on floor %d.", *r.Floor)
	}
	desc.CS += bullets(r.Features, "\n\nVybavení a podmínky:")
	desc.EN += bullets(r.FeaturesEN, "\n\nFeatures and terms:")
	return DraftResult{Title: title, Description: desc, Model: "mock"}, nil
}

func bullets(m map[string]string, heading string) string {
	if len(m) == 0 {
		return ""
	}
	keys := make([]string, 0, len(m))
	for k := range m {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	var b strings.Builder
	b.WriteString(heading)
	for _, k := range keys {
		if m[k] == "" {
			b.WriteString("\n- " + k)
		} else {
			b.WriteString("\n- " + k + ": " + m[k])
		}
	}
	return b.String()
}
