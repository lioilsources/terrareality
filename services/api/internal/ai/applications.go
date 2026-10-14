package ai

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
)

// ApplicationFacts is what the landlord sees about an application. It never
// contains protected characteristics (they are not collected).
type ApplicationFacts struct {
	ListingTitle   string            `json:"listing_title"`
	Rent           int64             `json:"rent,omitempty"` // minor units
	Message        string            `json:"message"`
	Answers        map[string]string `json:"answers,omitempty"` // question -> answer
	PreferredFrom  string            `json:"preferred_from,omitempty"`
	DurationMonths int               `json:"duration_months,omitempty"`
	HouseholdSize  int               `json:"household_size"`
	People         []PersonFacts     `json:"people"`
}

// PersonFacts are verification facts of one applicant.
type PersonFacts struct {
	Verification string `json:"verification"` // none | email | phone | identity
	IncomeProof  bool   `json:"income_proof"`
	Insolvency   string `json:"insolvency"` // unchecked | clear | record | error
}

// ApplicationSummary is a short suggestion for the landlord.
type ApplicationSummary struct {
	Summary   string   `json:"summary"` // Czech, two or three sentences
	Strengths []string `json:"strengths"`
	Gaps      []string `json:"gaps"` // missing information worth asking about
	Model     string   `json:"model"`
}

// Summarizer writes application summaries.
type Summarizer interface {
	SummarizeApplication(ctx context.Context, f ApplicationFacts) (ApplicationSummary, error)
}

// SummarizeApplication implements Summarizer with templates.
func (Mock) SummarizeApplication(_ context.Context, f ApplicationFacts) (ApplicationSummary, error) {
	out := ApplicationSummary{Model: "mock-rules", Strengths: []string{}, Gaps: []string{}}
	who := "Zájemce"
	if len(f.People) > 1 {
		who = fmt.Sprintf("Skupina %d lidí", len(f.People))
	}
	parts := []string{fmt.Sprintf("%s (domácnost %d os.)", who, f.HouseholdSize)}
	if f.PreferredFrom != "" {
		parts = append(parts, "nastěhování od "+f.PreferredFrom)
	}
	if f.DurationMonths > 0 {
		parts = append(parts, fmt.Sprintf("na %d měsíců", f.DurationMonths))
	}
	out.Summary = strings.Join(parts, ", ") + "."
	identity, income := 0, 0
	for _, p := range f.People {
		if p.Verification == "identity" {
			identity++
		}
		if p.IncomeProof {
			income++
		}
		if p.Insolvency == "record" {
			out.Gaps = append(out.Gaps, "Insolvenční rejstřík uvádí záznam; ověřte podrobnosti.")
		}
	}
	if identity == len(f.People) && identity > 0 {
		out.Strengths = append(out.Strengths, "Všichni mají ověřenou identitu (BankID).")
	} else {
		out.Gaps = append(out.Gaps, "Ne všichni mají ověřenou identitu.")
	}
	if income > 0 {
		out.Strengths = append(out.Strengths, fmt.Sprintf("Potvrzení o příjmu nahráno (%d/%d).", income, len(f.People)))
	} else {
		out.Gaps = append(out.Gaps, "Chybí potvrzení o příjmu.")
	}
	if f.DurationMonths == 0 {
		out.Gaps = append(out.Gaps, "Neuvedená délka nájmu.")
	}
	if len(strings.TrimSpace(f.Message)) < 40 {
		out.Gaps = append(out.Gaps, "Krátká zpráva, zeptejte se na podrobnosti.")
	}
	return out, nil
}

const summarySystem = `You help a landlord in Czechia read a rental application. Summarize it in Czech in two
or three neutral sentences, then list strengths and gaps (missing information worth asking about).
Never mention or infer protected characteristics (age, sex, ethnicity, nationality, religion, health,
family status, sexual orientation) and never recommend accepting or rejecting the applicant: the
landlord decides. Answer with one JSON object only.`

// SummarizeApplication implements Summarizer.
func (c *Client) SummarizeApplication(ctx context.Context, f ApplicationFacts) (ApplicationSummary, error) {
	in, _ := json.MarshalIndent(f, "", "  ")
	list := map[string]any{"type": "array", "items": map[string]any{"type": "string"}}
	schema := map[string]any{"type": "object", "properties": map[string]any{
		"summary": map[string]any{"type": "string"}, "strengths": list, "gaps": list,
	}, "required": []string{"summary", "strengths", "gaps"}}
	var out ApplicationSummary
	if err := c.complete(ctx, summarySystem, "Application:\n"+string(in), "application_summary", schema, &out); err != nil {
		return ApplicationSummary{}, err
	}
	if out.Strengths == nil {
		out.Strengths = []string{}
	}
	if out.Gaps == nil {
		out.Gaps = []string{}
	}
	out.Model = c.Model
	return out, nil
}
