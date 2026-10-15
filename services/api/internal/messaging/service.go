// Package messaging implements conversations between seekers and landlords:
// messages with attachments and read receipts, contact masking and scam
// flags, reply templates and pre-screening questions, reports and the
// moderation queue, and notifications (in-app, push, e-mail).
//
// User-facing operations run with row-level security (db.AsUser). Realtime
// events are published to Centrifugo after the transaction commits; push and
// e-mail are sent by a delayed job so that a recipient who is reading the
// conversation is not disturbed.
package messaging

import (
	"context"
	"encoding/json"
	"errors"
	"log/slog"
	"slices"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/terrareality/terrareality/services/api/internal/audit"
	"github.com/terrareality/terrareality/services/api/internal/auth"
	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/media"
	"github.com/terrareality/terrareality/services/api/internal/notify"
	"github.com/terrareality/terrareality/services/api/internal/org"
	"github.com/terrareality/terrareality/services/api/internal/platform/apperr"
	platformdb "github.com/terrareality/terrareality/services/api/internal/platform/db"
	"github.com/terrareality/terrareality/services/api/internal/realtime"
	"github.com/terrareality/terrareality/services/api/internal/storage"
	"github.com/terrareality/terrareality/services/api/internal/textscan"
)

// Roles in a conversation.
const (
	RoleSeeker = "seeker"
	RoleOwner  = "owner"
)

// Jobs enqueues background work in the caller's transaction.
type Jobs interface {
	NotifyMessage(ctx context.Context, tx pgx.Tx, messageID uuid.UUID, delay time.Duration) error
	SuggestVerdict(ctx context.Context, tx pgx.Tx, caseID uuid.UUID) error
}

// Service implements conversations for the API.
type Service struct {
	Pool        *pgxpool.Pool
	RT          realtime.Publisher
	Tokens      realtime.Tokens
	WSURL       string // browser/mobile Centrifugo websocket URL
	Jobs        Jobs
	Blob        storage.Blob
	Scanner     media.Scanner
	NotifyDelay time.Duration
	Outbox      notify.Outbox
	Render      *notify.Renderer
	WebBaseURL  string
	Log         *slog.Logger
}

var (
	errNotFound = apperr.NotFound("conversation_not_found", "conversation not found")
	errBlocked  = apperr.Forbidden("conversation_blocked", "this conversation is blocked")
)

func (s *Service) asUser(ctx context.Context, p *auth.Principal, fn func(q *db.Queries, tx pgx.Tx) error) error {
	return platformdb.AsUser(ctx, s.Pool, p.UserID, func(tx pgx.Tx) error { return fn(db.New(tx), tx) })
}

func (s *Service) system(ctx context.Context, fn func(q *db.Queries, tx pgx.Tx) error) error {
	return platformdb.InTx(ctx, s.Pool, func(tx pgx.Tx) error { return fn(db.New(tx), tx) })
}

// access loads a conversation visible to the caller and their role in it.
// Organization members need the messages permission.
func access(ctx context.Context, q *db.Queries, userID, id uuid.UUID) (db.Conversation, string, error) {
	c, err := q.GetConversation(ctx, id)
	if errors.Is(err, pgx.ErrNoRows) {
		return c, "", errNotFound
	}
	if err != nil {
		return c, "", err
	}
	if c.SeekerID == userID {
		return c, RoleSeeker, nil
	}
	if _, err := org.Access(ctx, q, userID, c.OrgID, org.PermMessages); err != nil {
		return c, "", err
	}
	return c, RoleOwner, nil
}

// ---------------------------------------------------------------------------
// Conversations.

// PrescreenQuestion is a question the owner asks before the first message.
type PrescreenQuestion struct {
	ID       string            `json:"id"`
	Text     map[string]string `json:"text"`
	Kind     string            `json:"kind"` // text | yes_no | number
	Required bool              `json:"required"`
}

// PrescreenAnswer is stored with the conversation.
type PrescreenAnswer struct {
	ID       string            `json:"id"`
	Question map[string]string `json:"question"`
	Kind     string            `json:"kind"`
	Answer   string            `json:"answer"`
}

// Attachment is a file sent with a message.
type Attachment struct {
	ID          uuid.UUID `json:"id"`
	Filename    string    `json:"filename"`
	ContentType string    `json:"content_type"`
	SizeBytes   int64     `json:"size_bytes"`
	URL         string    `json:"url"`
}

// Message is a message as clients see it.
type Message struct {
	ID             uuid.UUID    `json:"id"`
	ConversationID uuid.UUID    `json:"conversation_id"`
	SenderID       *uuid.UUID   `json:"sender_id"`
	Kind           string       `json:"kind"`
	Body           string       `json:"body"`
	Flags          []string     `json:"flags"`
	Removed        bool         `json:"removed"`
	CreatedAt      time.Time    `json:"created_at"`
	Attachments    []Attachment `json:"attachments"`
}

// Conversation is an inbox row with the caller's view on it.
type Conversation struct {
	db.ListConversationsRow
	Role        string
	BlockedByMe bool
}

// View is a conversation with details for the thread screen.
type View struct {
	Conversation
	PeerReadAt *time.Time
	Prescreen  []PrescreenAnswer
}

// Start opens (or reuses) the caller's conversation about a published
// listing and sends the first message.
func (s *Service) Start(ctx context.Context, p *auth.Principal, listingID uuid.UUID, body string, answers map[string]string) (uuid.UUID, Message, error) {
	if err := s.checkSender(ctx, p); err != nil {
		return uuid.Nil, Message{}, err
	}
	sys := db.New(s.Pool)
	l, err := sys.ListingForConversation(ctx, listingID)
	if errors.Is(err, pgx.ErrNoRows) {
		return uuid.Nil, Message{}, apperr.NotFound("listing_not_found", "listing not found")
	}
	if err != nil {
		return uuid.Nil, Message{}, err
	}
	if _, err := sys.GetMembership(ctx, db.GetMembershipParams{OrgID: l.OrgID, UserID: p.UserID}); err == nil {
		return uuid.Nil, Message{}, apperr.Conflict("own_listing", "you cannot message your own listing")
	}
	if blocked, err := sys.SeekerBlockedByOrg(ctx, db.SeekerBlockedByOrgParams{SeekerID: p.UserID, OrgID: l.OrgID}); err != nil {
		return uuid.Nil, Message{}, err
	} else if blocked {
		return uuid.Nil, Message{}, errBlocked
	}
	var questions []PrescreenQuestion
	_ = json.Unmarshal(l.Prescreen, &questions)
	stored, err := MatchAnswers(questions, answers)
	if err != nil {
		return uuid.Nil, Message{}, err
	}
	raw, _ := json.Marshal(stored)

	var conv db.CreateConversationRow
	var msg db.Message
	err = s.asUser(ctx, p, func(q *db.Queries, tx pgx.Tx) error {
		var err error
		conv, err = q.CreateConversation(ctx, db.CreateConversationParams{OrgID: l.OrgID, ListingID: listingID,
			SeekerID: p.UserID, PrescreenAnswers: raw})
		if err != nil {
			return err
		}
		if conv.BlockedAt != nil {
			return errBlocked
		}
		if conv.Created {
			if err := audit.Record(ctx, q, audit.Event{OrgID: &l.OrgID, Entity: "conversation", EntityID: &conv.ID,
				Action: "conversation.start", Diff: map[string]any{"listing_id": listingID}}); err != nil {
				return err
			}
		}
		msg, err = s.send(ctx, q, tx, conv.ID, p.UserID, body, nil)
		return err
	})
	if err != nil {
		return uuid.Nil, Message{}, err
	}
	out := messageDTO(msg)
	s.publishMessage(ctx, conv.ID, out)
	return conv.ID, out, nil
}

// MatchAnswers validates answers against the listing's questions.
func MatchAnswers(questions []PrescreenQuestion, answers map[string]string) ([]PrescreenAnswer, error) {
	out := []PrescreenAnswer{}
	fe := apperr.Unprocessable("prescreen_incomplete", "answer the landlord's required questions")
	for _, q := range questions {
		a := strings.TrimSpace(answers[q.ID])
		if a == "" {
			if q.Required {
				return nil, fe
			}
			continue
		}
		if utf8.RuneCountInString(a) > 500 {
			a = string([]rune(a)[:500])
		}
		if q.Kind == "yes_no" && a != "yes" && a != "no" {
			return nil, apperr.Unprocessable("prescreen_invalid", "yes/no questions take yes or no")
		}
		masked, _ := textscan.Scan(a)
		out = append(out, PrescreenAnswer{ID: q.ID, Question: q.Text, Kind: q.Kind, Answer: masked})
	}
	return out, nil
}

func (s *Service) checkSender(ctx context.Context, p *auth.Principal) error {
	suspended, err := db.New(s.Pool).UserMessagingSuspended(ctx, p.UserID)
	if err != nil {
		return err
	}
	if suspended {
		return apperr.Forbidden("messaging_suspended", "your account cannot send messages; contact support")
	}
	return nil
}

// send stores a message inside the caller's transaction.
func (s *Service) send(ctx context.Context, q *db.Queries, tx pgx.Tx, convID, sender uuid.UUID, body string, attachmentIDs []uuid.UUID) (db.Message, error) {
	body = strings.TrimSpace(body)
	if body == "" && len(attachmentIDs) == 0 {
		return db.Message{}, apperr.Unprocessable("message_empty", "write a message")
	}
	if utf8.RuneCountInString(body) > 4000 {
		return db.Message{}, apperr.Unprocessable("message_too_long", "messages are limited to 4000 characters")
	}
	masked, flags := textscan.Scan(body)
	if flags == nil {
		flags = []string{}
	}
	msg, err := q.InsertMessage(ctx, db.InsertMessageParams{ConversationID: convID, SenderID: &sender, Kind: "text",
		Body: masked, Flags: flags})
	if err != nil {
		return msg, err
	}
	if len(attachmentIDs) > 0 {
		n, err := q.AttachToMessage(ctx, db.AttachToMessageParams{MessageID: &msg.ID, Ids: attachmentIDs,
			ConversationID: convID, UploadedBy: &sender})
		if err != nil {
			return msg, err
		}
		if int(n) != len(attachmentIDs) {
			return msg, apperr.Unprocessable("attachment_invalid", "an attachment is missing, already sent or not scanned yet")
		}
	}
	if err := q.TouchConversation(ctx, db.TouchConversationParams{ID: convID, LastMessageAt: msg.CreatedAt}); err != nil {
		return msg, err
	}
	if err := q.MarkRead(ctx, db.MarkReadParams{ConversationID: convID, UserID: sender, LastReadAt: msg.CreatedAt}); err != nil {
		return msg, err
	}
	if slices.Contains(flags, textscan.AdvancePayment) {
		caseID, err := q.FlagMessage(ctx, db.FlagMessageParams{MessageID: msg.ID, Reason: "advance_payment",
			Note: "automatic: payment before viewing or untraceable payment"})
		if err != nil {
			return msg, err
		}
		if caseID != uuid.Nil && s.Jobs != nil {
			if err := s.Jobs.SuggestVerdict(ctx, tx, caseID); err != nil {
				return msg, err
			}
		}
	}
	if s.Jobs != nil {
		if err := s.Jobs.NotifyMessage(ctx, tx, msg.ID, s.NotifyDelay); err != nil {
			return msg, err
		}
	}
	return msg, nil
}

// Send posts a message to a conversation.
func (s *Service) Send(ctx context.Context, p *auth.Principal, convID uuid.UUID, body string, attachmentIDs []uuid.UUID) (Message, error) {
	if err := s.checkSender(ctx, p); err != nil {
		return Message{}, err
	}
	var out Message
	err := s.asUser(ctx, p, func(q *db.Queries, tx pgx.Tx) error {
		c, _, err := access(ctx, q, p.UserID, convID)
		if err != nil {
			return err
		}
		if c.BlockedAt != nil {
			return errBlocked
		}
		msg, err := s.send(ctx, q, tx, convID, p.UserID, body, attachmentIDs)
		if err != nil {
			return err
		}
		out = messageDTO(msg)
		if len(attachmentIDs) > 0 {
			rows, err := q.ListAttachments(ctx, []uuid.UUID{msg.ID})
			if err != nil {
				return err
			}
			out.Attachments = s.attachmentDTOs(ctx, rows)
		}
		return nil
	})
	if err != nil {
		return Message{}, err
	}
	s.publishMessage(ctx, convID, out)
	return out, nil
}

func messageDTO(m db.Message) Message {
	body := m.Body
	if m.RemovedAt != nil {
		body = ""
	}
	flags := m.Flags
	if flags == nil {
		flags = []string{}
	}
	return Message{ID: m.ID, ConversationID: m.ConversationID, SenderID: m.SenderID, Kind: m.Kind, Body: body,
		Flags: flags, Removed: m.RemovedAt != nil, CreatedAt: m.CreatedAt, Attachments: []Attachment{}}
}

func (s *Service) attachmentDTOs(ctx context.Context, rows []db.MessageAttachment) []Attachment {
	out := make([]Attachment, 0, len(rows))
	for _, a := range rows {
		// Download disposition and the validated type: the uploader chose
		// the Content-Type of the presigned PUT, so a plain GET could
		// serve an HTML page from the storage origin.
		u, err := s.Blob.PresignDownload(ctx, a.ObjectKey, a.Filename, a.ContentType, time.Hour)
		if err != nil {
			s.Log.Warn("presign attachment", "err", err)
		}
		out = append(out, Attachment{ID: a.ID, Filename: a.Filename, ContentType: a.ContentType, SizeBytes: a.SizeBytes, URL: u})
	}
	return out
}

// Event is published to Centrifugo channels.
type Event struct {
	Type           string     `json:"type"` // message | read | blocked | removed | notification
	ConversationID uuid.UUID  `json:"conversation_id"`
	Message        *Message   `json:"message,omitempty"`
	UserID         *uuid.UUID `json:"user_id,omitempty"`
	Role           string     `json:"role,omitempty"`
	At             *time.Time `json:"at,omitempty"`
}

// publishMessage fans a new message out to the conversation channel and to
// the user channels of all parties (inbox badges). Failures are logged: the
// message is stored and clients catch up on reconnect.
func (s *Service) publishMessage(ctx context.Context, convID uuid.UUID, m Message) {
	s.publish(ctx, convID, Event{Type: "message", ConversationID: convID, Message: &m}, true)
}

func (s *Service) publish(ctx context.Context, convID uuid.UUID, e Event, toUsers bool) {
	if s.RT == nil {
		return
	}
	ctx = context.WithoutCancel(ctx)
	if err := s.RT.Publish(ctx, realtime.ConversationChannel(convID), e); err != nil {
		s.Log.Warn("realtime publish", "err", err)
	}
	if !toUsers {
		return
	}
	parties, err := db.New(s.Pool).ConversationParties(ctx, convID)
	if err != nil {
		s.Log.Warn("conversation parties", "err", err)
		return
	}
	for _, u := range parties {
		if err := s.RT.Publish(ctx, realtime.UserChannel(u), e); err != nil {
			s.Log.Warn("realtime publish", "err", err)
		}
	}
}

// List returns the caller's conversations. With orgID only that
// organization's inbox; with asSeeker only conversations the caller started.
func (s *Service) List(ctx context.Context, p *auth.Principal, orgID *uuid.UUID, asSeeker bool) ([]Conversation, error) {
	var out []Conversation
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		if orgID != nil {
			if _, err := org.Access(ctx, q, p.UserID, *orgID, org.PermMessages); err != nil {
				return err
			}
		}
		rows, err := q.ListConversations(ctx, db.ListConversationsParams{UserID: p.UserID, OrgID: orgID, AsSeeker: asSeeker})
		if err != nil {
			return err
		}
		for _, r := range rows {
			out = append(out, conversationOf(r, p.UserID))
		}
		return nil
	})
	return out, err
}

func conversationOf(r db.ListConversationsRow, me uuid.UUID) Conversation {
	role := RoleOwner
	if r.SeekerID == me {
		role = RoleSeeker
	}
	return Conversation{ListConversationsRow: r, Role: role, BlockedByMe: r.BlockedBy != nil && *r.BlockedBy == me}
}

// Get returns one conversation with read receipts and pre-screening answers.
func (s *Service) Get(ctx context.Context, p *auth.Principal, id uuid.UUID) (View, error) {
	var v View
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		c, role, err := access(ctx, q, p.UserID, id)
		if err != nil {
			return err
		}
		rows, err := q.ListConversations(ctx, db.ListConversationsParams{UserID: p.UserID, ConversationID: &id})
		if err != nil {
			return err
		}
		if len(rows) == 0 {
			return errNotFound
		}
		v.Conversation = conversationOf(rows[0], p.UserID)
		v.Role = role
		_ = json.Unmarshal(c.PrescreenAnswers, &v.Prescreen)
		reads, err := q.ListReads(ctx, id)
		if err != nil {
			return err
		}
		v.PeerReadAt = peerRead(reads, c.SeekerID, role)
		return nil
	})
	return v, err
}

// peerRead is when the other side last read: the seeker, or the latest of
// the organization's members.
func peerRead(reads []db.ConversationRead, seeker uuid.UUID, role string) *time.Time {
	var at *time.Time
	for _, r := range reads {
		if (role == RoleSeeker) == (r.UserID == seeker) {
			continue
		}
		if at == nil || r.LastReadAt.After(*at) {
			t := r.LastReadAt
			at = &t
		}
	}
	return at
}

// Messages returns a page of messages, newest first.
func (s *Service) Messages(ctx context.Context, p *auth.Principal, id uuid.UUID, before *time.Time, limit int32) ([]Message, error) {
	if limit <= 0 || limit > 100 {
		limit = 50
	}
	var out []Message
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		if _, _, err := access(ctx, q, p.UserID, id); err != nil {
			return err
		}
		rows, err := q.ListMessages(ctx, db.ListMessagesParams{ConversationID: id, Before: before, Limit: limit})
		if err != nil {
			return err
		}
		ids := make([]uuid.UUID, 0, len(rows))
		for _, m := range rows {
			ids = append(ids, m.ID)
			out = append(out, messageDTO(db.Message{ID: m.ID, ConversationID: m.ConversationID, SenderID: m.SenderID,
				Kind: m.Kind, Body: m.Body, Flags: m.Flags, RemovedAt: m.RemovedAt, CreatedAt: m.CreatedAt}))
		}
		atts, err := q.ListAttachments(ctx, ids)
		if err != nil {
			return err
		}
		byMsg := map[uuid.UUID][]db.MessageAttachment{}
		for _, a := range atts {
			if a.MessageID != nil {
				byMsg[*a.MessageID] = append(byMsg[*a.MessageID], a)
			}
		}
		for i := range out {
			if a := byMsg[out[i].ID]; len(a) > 0 && !out[i].Removed {
				out[i].Attachments = s.attachmentDTOs(ctx, a)
			}
		}
		return nil
	})
	return out, err
}

// MarkRead records that the caller has read the conversation up to now.
func (s *Service) MarkRead(ctx context.Context, p *auth.Principal, id uuid.UUID) error {
	now := time.Now()
	var role string
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		var err error
		if _, role, err = access(ctx, q, p.UserID, id); err != nil {
			return err
		}
		if err := q.MarkRead(ctx, db.MarkReadParams{ConversationID: id, UserID: p.UserID, LastReadAt: now}); err != nil {
			return err
		}
		return q.MarkConversationNotificationsRead(ctx, db.MarkConversationNotificationsReadParams{UserID: p.UserID,
			ConversationID: id.String()})
	})
	if err != nil {
		return err
	}
	uid := p.UserID
	s.publish(ctx, id, Event{Type: "read", ConversationID: id, UserID: &uid, Role: role, At: &now}, false)
	return nil
}

// SetBlocked blocks or unblocks a conversation. Either side may block; only
// the side that blocked can unblock. A seeker blocked by an organization
// cannot start new conversations with it.
func (s *Service) SetBlocked(ctx context.Context, p *auth.Principal, id uuid.UUID, blocked bool) error {
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		c, role, err := access(ctx, q, p.UserID, id)
		if err != nil {
			return err
		}
		if !blocked {
			if c.BlockedBy == nil {
				return nil
			}
			if !canUnblock(c, role, p.UserID) {
				return apperr.Forbidden("not_blocker", "only the side that blocked can unblock")
			}
		} else if c.BlockedAt != nil {
			return nil
		}
		var by *uuid.UUID
		if blocked {
			by = &p.UserID
		}
		if err := q.SetConversationBlock(ctx, db.SetConversationBlockParams{ID: id, BlockedBy: by}); err != nil {
			return err
		}
		action := "conversation.unblock"
		if blocked {
			action = "conversation.block"
		}
		return audit.Record(ctx, q, audit.Event{OrgID: &c.OrgID, Entity: "conversation", EntityID: &id, Action: action})
	})
	if err != nil {
		return err
	}
	s.publish(ctx, id, Event{Type: "blocked", ConversationID: id}, true)
	return nil
}

// canUnblock: a block belongs to the side that set it. The seeker lifts
// their own block; an organization's block can be lifted by any member who
// handles messages (access already checked the permission), not only the
// person who set it, so a block survives staff changes.
func canUnblock(c db.Conversation, role string, userID uuid.UUID) bool {
	if c.BlockedBy == nil {
		return true
	}
	byOwnerSide := *c.BlockedBy != c.SeekerID
	if role == RoleSeeker {
		return !byOwnerSide && *c.BlockedBy == userID
	}
	return byOwnerSide
}

// lastOtherSender returns the newest sender who is not the seeker (rows
// are newest first), or nil when the organization side never wrote.
func lastOtherSender(rows []db.ListMessagesRow, seekerID uuid.UUID) *uuid.UUID {
	for _, m := range rows {
		if m.SenderID != nil && *m.SenderID != seekerID {
			id := *m.SenderID
			return &id
		}
	}
	return nil
}

// Report reasons users can pick.
var reportReasons = []string{"scam", "advance_payment", "harassment", "discrimination", "spam", "other"}

// Report files a report about a conversation (optionally one message).
func (s *Service) Report(ctx context.Context, p *auth.Principal, id uuid.UUID, messageID *uuid.UUID, reason, note string) (uuid.UUID, error) {
	if !slices.Contains(reportReasons, reason) {
		return uuid.Nil, apperr.Unprocessable("invalid_reason", "unknown report reason")
	}
	var caseID uuid.UUID
	err := s.asUser(ctx, p, func(q *db.Queries, tx pgx.Tx) error {
		c, role, err := access(ctx, q, p.UserID, id)
		if err != nil {
			return err
		}
		var reported *uuid.UUID
		if role == RoleOwner {
			reported = &c.SeekerID
		}
		if messageID == nil && role == RoleSeeker {
			// The other side is an organization: report the member who
			// wrote last, so moderation has a person to act on.
			rows, err := q.ListMessages(ctx, db.ListMessagesParams{ConversationID: id, Limit: 1000})
			if err != nil {
				return err
			}
			reported = lastOtherSender(rows, c.SeekerID)
		}
		if messageID != nil {
			rows, err := q.ListMessages(ctx, db.ListMessagesParams{ConversationID: id, Limit: 1000})
			if err != nil {
				return err
			}
			i := slices.IndexFunc(rows, func(m db.ListMessagesRow) bool { return m.ID == *messageID })
			if i < 0 {
				return apperr.NotFound("message_not_found", "message not found")
			}
			if rows[i].SenderID != nil && *rows[i].SenderID == p.UserID {
				return apperr.Unprocessable("own_message", "you cannot report your own message")
			}
			reported = rows[i].SenderID
		}
		var notePtr *string
		if note = strings.TrimSpace(note); note != "" {
			notePtr = &note
		}
		caseID, err = q.CreateReport(ctx, db.CreateReportParams{ConversationID: &id, MessageID: messageID,
			ReporterID: &p.UserID, ReportedID: reported, Reason: reason, Note: notePtr, AiStatus: "pending"})
		if err != nil {
			return err
		}
		if err := audit.Record(ctx, q, audit.Event{OrgID: &c.OrgID, Entity: "conversation", EntityID: &id,
			Action: "conversation.report", Diff: map[string]any{"case_id": caseID, "reason": reason}}); err != nil {
			return err
		}
		if s.Jobs != nil {
			return s.Jobs.SuggestVerdict(ctx, tx, caseID)
		}
		return nil
	})
	return caseID, err
}

// RealtimeToken returns a Centrifugo connection token for the caller.
func (s *Service) RealtimeToken(p *auth.Principal) (token string, exp time.Time, url string) {
	token, exp = s.Tokens.Connect(p.UserID, time.Now())
	return token, exp, s.WSURL
}

// SubscribeToken returns a token for one conversation channel.
func (s *Service) SubscribeToken(ctx context.Context, p *auth.Principal, id uuid.UUID) (string, string, time.Time, error) {
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		_, _, err := access(ctx, q, p.UserID, id)
		return err
	})
	if err != nil {
		return "", "", time.Time{}, err
	}
	ch := realtime.ConversationChannel(id)
	tok, exp := s.Tokens.Subscribe(p.UserID, ch, time.Now())
	return tok, ch, exp, nil
}
