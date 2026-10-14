package messaging

import (
	"context"
	"encoding/json"
	"errors"
	"slices"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/terrareality/terrareality/services/api/internal/ai"
	"github.com/terrareality/terrareality/services/api/internal/audit"
	"github.com/terrareality/terrareality/services/api/internal/auth"
	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/notify"
	"github.com/terrareality/terrareality/services/api/internal/platform/apperr"
	platformdb "github.com/terrareality/terrareality/services/api/internal/platform/db"
)

// Decisions staff can take on a case.
var decisions = []string{ai.VerdictDismiss, ai.VerdictWarn, ai.VerdictRemoveMessage, ai.VerdictSuspendUser}

// Case is a moderation case with context for staff.
type Case struct {
	db.GetModerationCaseRow
	Transcript []db.ModerationTranscriptRow
}

// Queue lists open cases, oldest first (staff, system context).
func (s *Service) Queue(ctx context.Context) ([]db.ListOpenModerationCasesRow, error) {
	return db.New(s.Pool).ListOpenModerationCases(ctx)
}

// Case returns one case with the conversation transcript.
func (s *Service) Case(ctx context.Context, id uuid.UUID) (Case, error) {
	q := db.New(s.Pool)
	c, err := q.GetModerationCase(ctx, id)
	if errors.Is(err, pgx.ErrNoRows) {
		return Case{}, apperr.NotFound("case_not_found", "case not found")
	}
	if err != nil {
		return Case{}, err
	}
	t, err := q.ModerationTranscript(ctx, c.ConversationID)
	return Case{GetModerationCaseRow: c, Transcript: t}, err
}

// Decide resolves a case. The AI suggestion is advisory; this is the human
// decision (ADR 0003) and it is the only place sanctions are applied.
func (s *Service) Decide(ctx context.Context, staff *auth.Principal, id uuid.UUID, decision, note string) error {
	if !slices.Contains(decisions, decision) {
		return apperr.Unprocessable("invalid_decision", "unknown decision")
	}
	var convID uuid.UUID
	err := s.system(ctx, func(q *db.Queries, tx pgx.Tx) error {
		c, err := q.GetModerationCase(ctx, id)
		if errors.Is(err, pgx.ErrNoRows) {
			return apperr.NotFound("case_not_found", "case not found")
		}
		if err != nil {
			return err
		}
		convID = c.ConversationID
		if decision == ai.VerdictRemoveMessage && c.MessageID == nil {
			return apperr.Unprocessable("no_message", "this case is not about a single message")
		}
		if (decision == ai.VerdictSuspendUser || decision == ai.VerdictWarn) && c.ReportedID == nil {
			return apperr.Unprocessable("no_reported_user", "this case has no reported user")
		}
		var notePtr *string
		if note != "" {
			notePtr = &note
		}
		n, err := q.DecideModerationCase(ctx, db.DecideModerationCaseParams{ID: id, Decision: &decision,
			DecisionNote: notePtr, DecidedBy: &staff.UserID})
		if err != nil {
			return err
		}
		if n == 0 {
			return apperr.Conflict("case_resolved", "this case was already resolved")
		}
		switch decision {
		case ai.VerdictRemoveMessage:
			if err := q.RemoveMessage(ctx, *c.MessageID); err != nil {
				return err
			}
		case ai.VerdictSuspendUser:
			if err := q.SuspendMessaging(ctx, *c.ReportedID); err != nil {
				return err
			}
		}
		conv, err := q.GetConversation(ctx, c.ConversationID)
		if err != nil {
			return err
		}
		if err := audit.Record(ctx, q, audit.Event{OrgID: &conv.OrgID, Entity: "moderation_case", EntityID: &id,
			Action: "moderation.decide", Diff: map[string]any{"decision": decision, "note": note,
				"ai_suggestion": json.RawMessage(orEmpty(c.AiSuggestion))}}); err != nil {
			return err
		}
		if decision != ai.VerdictWarn && decision != ai.VerdictSuspendUser || s.Outbox == nil {
			return nil
		}
		u, err := q.GetUser(ctx, *c.ReportedID)
		if err != nil || u.PseudonymizedAt != nil {
			return err
		}
		key := "moderation_warning"
		if decision == ai.VerdictSuspendUser {
			key = "messaging_suspended"
		}
		m, err := s.Render.Render(notify.Email, u.Email, u.Locale, key, map[string]any{
			"Listing": i18n(c.ListingTitle, u.Locale), "Note": note, "Link": ConversationLink(s.WebBaseURL, c.ConversationID)})
		if err != nil {
			return err
		}
		return s.Outbox.Enqueue(ctx, tx, m)
	})
	if err != nil {
		return err
	}
	if decision == ai.VerdictRemoveMessage {
		s.publish(ctx, convID, Event{Type: "removed", ConversationID: convID}, false)
	}
	return nil
}

func orEmpty(b []byte) []byte {
	if len(b) == 0 {
		return []byte("null")
	}
	return b
}

// Verdicts produces AI verdict suggestions for cases (worker side).
type Verdicts struct {
	Pool    *pgxpool.Pool
	AI      ai.Moderator
	Enabled bool // feature flag ai.moderation
}

// Suggest stores a suggested verdict for a case. final marks the last retry:
// on error the case is marked failed so staff do not wait for it.
func (v *Verdicts) Suggest(ctx context.Context, id uuid.UUID, final bool) error {
	q := db.New(v.Pool)
	c, err := q.GetModerationCase(ctx, id)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil
	}
	if err != nil || c.AiStatus != "pending" {
		return err
	}
	if !v.Enabled {
		return q.SetModerationAI(ctx, db.SetModerationAIParams{ID: id, AiStatus: "disabled"})
	}
	conv, err := q.GetConversation(ctx, c.ConversationID)
	if err != nil {
		return err
	}
	lines, err := q.ModerationTranscript(ctx, c.ConversationID)
	if err != nil {
		return err
	}
	req := ai.ModerationRequest{Reason: c.Reason, ReportedRole: RoleOwner}
	if c.Note != nil {
		req.Note = *c.Note
	}
	if c.ReportedID != nil && *c.ReportedID == conv.SeekerID {
		req.ReportedRole = RoleSeeker
	}
	for _, l := range lines {
		role := RoleOwner
		if l.FromSeeker {
			role = RoleSeeker
		}
		text := l.Body
		if l.RemovedAt != nil {
			text = "[removed]"
		}
		req.Transcript = append(req.Transcript, ai.TranscriptLine{Role: role, Text: text,
			Reported: c.MessageID != nil && l.ID == *c.MessageID})
	}
	res, err := v.AI.Moderate(ctx, req)
	if err != nil {
		if final {
			_ = q.SetModerationAI(ctx, db.SetModerationAIParams{ID: id, AiStatus: "failed"})
		}
		return err
	}
	model := res.Model
	return platformdb.InTx(ctx, v.Pool, func(tx pgx.Tx) error {
		return db.New(tx).SetModerationAI(ctx, db.SetModerationAIParams{ID: id, AiStatus: "ready",
			AiSuggestion: mustJSON(res), AiModel: &model})
	})
}
