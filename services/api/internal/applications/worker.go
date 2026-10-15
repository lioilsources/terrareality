package applications

import (
	"context"
	"encoding/json"
	"errors"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/terrareality/terrareality/services/api/internal/ai"
	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/notify"
	platformdb "github.com/terrareality/terrareality/services/api/internal/platform/db"
)

// Summaries writes AI summaries of submitted applications (worker side).
type Summaries struct {
	Pool    *pgxpool.Pool
	AI      ai.Summarizer
	Enabled bool // feature flag ai.applications when Flags is nil (tests)
	// Flags is the live flag store (backoffice-editable); it overrides Enabled.
	Flags interface {
		Enabled(ctx context.Context, key string) bool
	}
}

func (s *Summaries) enabled(ctx context.Context) bool {
	if s.Flags != nil {
		return s.Flags.Enabled(ctx, "ai.applications")
	}
	return s.Enabled
}

type answer struct {
	Question map[string]string `json:"question"`
	Answer   string            `json:"answer"`
}

// Summarize stores a suggestion; final marks the last retry.
func (s *Summaries) Summarize(ctx context.Context, id uuid.UUID, final bool) error {
	q := db.New(s.Pool)
	a, err := q.SystemGetApplication(ctx, id)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil
	}
	if err != nil || a.AiStatus != "pending" {
		return err
	}
	if !s.enabled(ctx) {
		return q.SetApplicationAI(ctx, db.SetApplicationAIParams{ID: id, AiStatus: "disabled"})
	}
	people, err := q.ApplicationPeople(ctx, id)
	if err != nil {
		return err
	}
	facts := ai.ApplicationFacts{ListingTitle: pick(i18n(a.ListingTitle), "cs"), Message: a.Message,
		HouseholdSize: int(a.HouseholdSize), Answers: map[string]string{}}
	if f, err := q.ListingMatchFacts(ctx, a.ListingID); err == nil {
		facts.Rent = f.RentAmount
	}
	if a.PreferredFrom.Valid {
		facts.PreferredFrom = a.PreferredFrom.Time.Format("2006-01-02")
	}
	if a.DurationMonths != nil {
		facts.DurationMonths = int(*a.DurationMonths)
	}
	var answers []answer
	_ = json.Unmarshal(a.Answers, &answers)
	for _, x := range answers {
		facts.Answers[pick(x.Question, "cs")] = x.Answer
	}
	for _, p := range people {
		facts.People = append(facts.People, ai.PersonFacts{Verification: p.VerificationLevel, IncomeProof: p.IncomeKey != nil,
			Insolvency: p.IsirStatus})
	}
	res, err := s.AI.SummarizeApplication(ctx, facts)
	if err != nil {
		if final {
			_ = q.SetApplicationAI(ctx, db.SetApplicationAIParams{ID: id, AiStatus: "failed"})
		}
		return err
	}
	raw, _ := json.Marshal(res)
	model := res.Model
	return q.SetApplicationAI(ctx, db.SetApplicationAIParams{ID: id, AiStatus: "ready", AiSummary: raw, AiModel: &model})
}

// Reminders sends viewing reminders (worker side).
type Reminders struct {
	Pool       *pgxpool.Pool
	Outbox     notify.Outbox
	Render     *notify.Renderer
	Pusher     notify.Pusher
	WebBaseURL string
}

// Remind notifies the applicants of a booking unless it was cancelled.
func (r *Reminders) Remind(ctx context.Context, bookingID uuid.UUID) error {
	q := db.New(r.Pool)
	b, err := q.BookingForReminder(ctx, bookingID)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil
	}
	if err != nil || b.CancelledAt != nil {
		return err
	}
	people, err := q.ApplicationPeople(ctx, b.ApplicationID)
	if err != nil {
		return err
	}
	when := b.StartsAt.In(prague).Format("2. 1. 2006 15:04")
	link := r.WebBaseURL + "/zadosti/" + b.ApplicationID.String()
	svc := &Service{Outbox: r.Outbox, Render: r.Render, WebBaseURL: r.WebBaseURL}
	to := make([]recipient, 0, len(people))
	for _, p := range people {
		to = append(to, recipient{ID: p.ID, Email: p.Email, Locale: p.Locale})
	}
	title := i18n(b.ListingTitle)
	err = platformdb.InTx(ctx, r.Pool, func(tx pgx.Tx) error {
		return svc.notifyAll(ctx, db.New(tx), tx, to, "viewing_reminder", link,
			map[string]any{"ListingTitle": title, "When": when, "City": b.City, "Note": b.Note})
	})
	if err != nil || r.Pusher == nil {
		return err
	}
	for _, p := range people {
		devices, err := q.SystemPushDevices(ctx, p.ID)
		if err != nil {
			return err
		}
		for _, d := range devices {
			_ = r.Pusher.Push(ctx, notify.Push{Platform: d.Platform, Token: d.Token, Keys: d.Keys, UserID: p.ID.String(),
				Title: pick(title, p.Locale), Body: when, Link: link,
				Data: notify.PushData(notify.PushViewing, bookingID.String(), map[string]string{"application_id": b.ApplicationID.String()})})
		}
	}
	return nil
}
