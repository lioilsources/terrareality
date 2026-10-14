package messaging

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"strings"
	"unicode/utf8"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/notify"
	platformdb "github.com/terrareality/terrareality/services/api/internal/platform/db"
	"github.com/terrareality/terrareality/services/api/internal/realtime"
)

// Notifier delivers notifications about new messages (worker side).
type Notifier struct {
	Pool       *pgxpool.Pool
	RT         realtime.Publisher
	Pusher     notify.Pusher
	Outbox     notify.Outbox
	Render     *notify.Renderer
	WebBaseURL string
	Log        *slog.Logger
}

// MessageData is the payload of a "message" notification.
type MessageData struct {
	ConversationID uuid.UUID `json:"conversation_id"`
	Sender         string    `json:"sender"`
	Listing        string    `json:"listing"`
	Preview        string    `json:"preview"`
	Count          int       `json:"count"`
}

func i18n(raw []byte, locale string) string {
	var m map[string]string
	_ = json.Unmarshal(raw, &m)
	if v := m[locale]; v != "" {
		return v
	}
	if v := m["cs"]; v != "" {
		return v
	}
	return m["en"]
}

func preview(s string) string {
	s = strings.Join(strings.Fields(s), " ")
	if utf8.RuneCountInString(s) > 140 {
		return string([]rune(s)[:139]) + "…"
	}
	return s
}

// ConversationLink is the web URL of a conversation.
func ConversationLink(base string, id uuid.UUID) string { return base + "/zpravy/" + id.String() }

// MessageCreated notifies the recipients of a message who have not read it
// yet: an in-app notification always; push and e-mail only when they are not
// connected (no realtime client on their user channel).
func (n *Notifier) MessageCreated(ctx context.Context, messageID uuid.UUID) error {
	q := db.New(n.Pool)
	msg, err := q.SystemGetMessage(ctx, messageID)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil
	}
	if err != nil || msg.RemovedAt != nil {
		return err
	}
	sum, err := q.SystemConversationSummary(ctx, msg.ConversationID)
	if err != nil {
		return err
	}
	recipients, err := q.MessageRecipients(ctx, db.MessageRecipientsParams{ConversationID: msg.ConversationID, SenderID: msg.SenderID})
	if err != nil {
		return err
	}
	sender := sum.OrgName
	if msg.SenderID != nil && *msg.SenderID == sum.SeekerID {
		sender = sum.SeekerName
	}
	text := msg.Body
	if text == "" {
		text = "📎"
	}
	for _, r := range recipients {
		if !r.LastReadAt.Before(msg.CreatedAt) {
			continue // already read (e.g. the thread is open)
		}
		if err := n.notifyOne(ctx, msg, sum, r, sender, preview(text)); err != nil {
			return err
		}
	}
	return nil
}

func (n *Notifier) notifyOne(ctx context.Context, msg db.Message, sum db.SystemConversationSummaryRow, r db.MessageRecipientsRow, sender, prev string) error {
	listing := i18n(sum.ListingTitle, r.Locale)
	link := ConversationLink(n.WebBaseURL, msg.ConversationID)
	online, err := n.RT.Online(ctx, realtime.UserChannel(r.ID))
	if err != nil {
		n.Log.Warn("presence", "err", err)
	}
	var note db.Notification
	err = platformdb.InTx(ctx, n.Pool, func(tx pgx.Tx) error {
		q := db.New(tx)
		data := MessageData{ConversationID: msg.ConversationID, Sender: sender, Listing: listing, Preview: prev, Count: 1}
		prevNote, err := q.BumpMessageNotification(ctx, db.BumpMessageNotificationParams{UserID: r.ID,
			ConversationID: msg.ConversationID.String(), Data: mustJSON(data)})
		switch {
		case err == nil:
			note = prevNote
		case errors.Is(err, pgx.ErrNoRows):
			if note, err = q.InsertNotification(ctx, db.InsertNotificationParams{UserID: r.ID, Kind: "message",
				Data: mustJSON(data), Link: link}); err != nil {
				return err
			}
		default:
			return err
		}
		if online || r.EmailMessages != "instant" || note.EmailedAt != nil {
			return nil
		}
		m, err := n.Render.Render(notify.Email, r.Email, r.Locale, "new_message", map[string]any{
			"Sender": sender, "Listing": listing, "Preview": prev, "Link": link, "Settings": n.WebBaseURL + "/ucet/upozorneni"})
		if err != nil {
			return err
		}
		if err := n.Outbox.Enqueue(ctx, tx, m); err != nil {
			return err
		}
		return q.MarkNotificationEmailed(ctx, []uuid.UUID{note.ID})
	})
	if err != nil {
		return err
	}
	if err := n.RT.Publish(ctx, realtime.UserChannel(r.ID), map[string]any{"type": "notification", "id": note.ID,
		"conversation_id": msg.ConversationID}); err != nil {
		n.Log.Warn("realtime publish", "err", err)
	}
	if online || !r.PushMessages {
		return nil
	}
	devices, err := db.New(n.Pool).SystemPushDevices(ctx, r.ID)
	if err != nil {
		return err
	}
	for _, d := range devices {
		err := n.Pusher.Push(ctx, notify.Push{Platform: d.Platform, Token: d.Token, Keys: d.Keys, UserID: r.ID.String(),
			Title: sender + " · " + listing, Body: prev, Link: link,
			Data: map[string]string{"conversation_id": msg.ConversationID.String()}})
		switch {
		case errors.Is(err, notify.ErrDeviceGone):
			_ = db.New(n.Pool).DeletePushDeviceByToken(ctx, db.DeletePushDeviceByTokenParams{Platform: d.Platform, Token: d.Token})
		case err != nil:
			n.Log.Warn("push", "err", err, "platform", d.Platform)
		}
	}
	return nil
}

func mustJSON(v any) []byte {
	b, _ := json.Marshal(v)
	return b
}

// Digest e-mails unread notifications to users who chose a daily summary.
func (n *Notifier) Digest(ctx context.Context) (int, error) {
	q := db.New(n.Pool)
	users, err := q.DigestRecipients(ctx)
	if err != nil {
		return 0, err
	}
	sent := 0
	for _, u := range users {
		err := platformdb.InTx(ctx, n.Pool, func(tx pgx.Tx) error {
			q := db.New(tx)
			notes, err := q.DigestNotifications(ctx, u.UserID)
			if err != nil || len(notes) == 0 {
				return err
			}
			var lines []string
			ids := make([]uuid.UUID, 0, len(notes))
			for _, x := range notes {
				ids = append(ids, x.ID)
				var d MessageData
				_ = json.Unmarshal(x.Data, &d)
				lines = append(lines, fmt.Sprintf("• %s (%s): %s\n  %s", d.Sender, d.Listing, d.Preview, x.Link))
			}
			m, err := n.Render.Render(notify.Email, u.Email, u.Locale, "messages_digest", map[string]any{
				"Count": len(notes), "Items": strings.Join(lines, "\n"), "Link": n.WebBaseURL + "/zpravy",
				"Settings": n.WebBaseURL + "/ucet/upozorneni"})
			if err != nil {
				return err
			}
			if err := n.Outbox.Enqueue(ctx, tx, m); err != nil {
				return err
			}
			sent++
			return q.MarkNotificationEmailed(ctx, ids)
		})
		if err != nil {
			return sent, err
		}
	}
	return sent, nil
}
