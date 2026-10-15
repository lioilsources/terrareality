package ai

import (
	"context"
	"encoding/json"
	"strings"

	"github.com/terrareality/terrareality/services/api/internal/textscan"
)

// Moderation verdicts. They mirror the decisions staff can take.
const (
	VerdictDismiss       = "dismiss"
	VerdictWarn          = "warn"
	VerdictRemoveMessage = "remove_message"
	VerdictSuspendUser   = "suspend_user"
)

// TranscriptLine is one message of the conversation under review.
type TranscriptLine struct {
	Role     string `json:"role"` // seeker | owner
	Text     string `json:"text"`
	Reported bool   `json:"reported,omitempty"`
}

// ModerationRequest describes a report or automatic flag.
type ModerationRequest struct {
	Reason       string           `json:"reason"`
	Note         string           `json:"note,omitempty"`
	ReportedRole string           `json:"reported_role"` // seeker | owner
	Transcript   []TranscriptLine `json:"transcript"`
}

// ModerationResult is a suggested verdict for staff.
type ModerationResult struct {
	Verdict    string  `json:"verdict"`
	Reason     string  `json:"reason"`
	Confidence float64 `json:"confidence"`
	Model      string  `json:"model"`
}

// Moderator suggests verdicts. Both the LLM client and the mock implement it.
type Moderator interface {
	Moderate(ctx context.Context, req ModerationRequest) (ModerationResult, error)
}

// Moderate implements Moderator with rules: payment scams suggest a
// suspension, shared contacts a warning, everything else a dismissal with low
// confidence so a human looks closely.
func (Mock) Moderate(_ context.Context, req ModerationRequest) (ModerationResult, error) {
	var reported []string
	for _, l := range req.Transcript {
		if l.Role == req.ReportedRole {
			reported = append(reported, l.Text)
		}
	}
	text := strings.Join(reported, "\n")
	out := ModerationResult{Model: "mock-rules"}
	switch {
	case textscan.AdvancePaymentRequested(text):
		out.Verdict, out.Confidence = VerdictSuspendUser, 0.8
		out.Reason = "The reported party asks for money before a viewing or through an untraceable channel, a typical rental scam."
	case strings.Contains(text, textscan.Mask):
		out.Verdict, out.Confidence = VerdictWarn, 0.6
		out.Reason = "The reported party tries to move the conversation off the platform."
	case req.Reason == "harassment" || req.Reason == "discrimination":
		out.Verdict, out.Confidence = VerdictWarn, 0.4
		out.Reason = "Rules cannot judge tone; read the conversation."
	default:
		out.Verdict, out.Confidence = VerdictDismiss, 0.3
		out.Reason = "No known scam pattern found in the reported messages."
	}
	return out, nil
}

const moderationSystem = `You help trust & safety staff of a long-term rental platform in Central Europe.
You get a report about a chat between a seeker and a landlord (messages are usually Czech) and suggest a
verdict for a human moderator: "dismiss" (no violation), "warn" (minor violation, e.g. sharing contacts,
rude tone), "remove_message" (one message is abusive or dangerous) or "suspend_user" (scam: asking for
money before a viewing, keys by courier, untraceable payments, identity theft; or repeated harassment or
discrimination). Contact details in the transcript are already masked as [•••]. Judge only the reported
party. Explain in one or two English sentences and give a confidence between 0 and 1.
Answer with one JSON object only.`

// Moderate implements Moderator.
func (c *Client) Moderate(ctx context.Context, req ModerationRequest) (ModerationResult, error) {
	in, _ := json.MarshalIndent(req, "", "  ")
	schema := map[string]any{"type": "object", "properties": map[string]any{
		"verdict":    map[string]any{"type": "string", "enum": []string{VerdictDismiss, VerdictWarn, VerdictRemoveMessage, VerdictSuspendUser}},
		"reason":     map[string]any{"type": "string"},
		"confidence": map[string]any{"type": "number"},
	}, "required": []string{"verdict", "reason", "confidence"}}
	var out ModerationResult
	model, err := c.complete(ctx, moderationSystem, "Report:\n"+string(in), "moderation_verdict", schema, &out)
	if err != nil {
		return ModerationResult{}, err
	}
	switch out.Verdict {
	case VerdictDismiss, VerdictWarn, VerdictRemoveMessage, VerdictSuspendUser:
	default:
		out.Verdict = VerdictDismiss
		out.Confidence = 0
	}
	out.Confidence = min(max(out.Confidence, 0), 1)
	out.Model = model
	return out, nil
}
