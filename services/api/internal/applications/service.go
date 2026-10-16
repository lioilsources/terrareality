// Package applications implements renting as a group, applications for
// listings with group consent, the landlord's applicant overview with
// decisions, viewing slots, roommate profiles with matching and the Tenant
// Passport (income proof, insolvency check).
//
// User-facing operations run with row-level security (db.AsUser). A few
// reads that must see other people's rows (slot capacity, applicants'
// passport facts for the landlord) run in system context after the caller's
// access was checked under RLS.
package applications

import (
	"context"
	"encoding/json"
	"errors"
	"log/slog"
	"net/mail"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/terrareality/terrareality/services/api/internal/audit"
	"github.com/terrareality/terrareality/services/api/internal/auth"
	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/isir"
	"github.com/terrareality/terrareality/services/api/internal/media"
	"github.com/terrareality/terrareality/services/api/internal/notify"
	"github.com/terrareality/terrareality/services/api/internal/platform/apperr"
	platformdb "github.com/terrareality/terrareality/services/api/internal/platform/db"
	"github.com/terrareality/terrareality/services/api/internal/realtime"
	"github.com/terrareality/terrareality/services/api/internal/storage"
)

// Jobs enqueues background work in the caller's transaction.
type Jobs interface {
	SummarizeApplication(ctx context.Context, tx pgx.Tx, applicationID uuid.UUID) error
	ViewingReminder(ctx context.Context, tx pgx.Tx, bookingID uuid.UUID, at time.Time) error
}

// Service implements M5 for the API.
type Service struct {
	Pool       *pgxpool.Pool
	RT         realtime.Publisher
	Jobs       Jobs
	Outbox     notify.Outbox
	Render     *notify.Renderer
	Pusher     notify.Pusher // nil: no push notifications
	Blob       storage.Blob
	Scanner    media.Scanner
	ISIR       isir.Checker
	WebBaseURL string
	Log        *slog.Logger
}

func (s *Service) asUser(ctx context.Context, p *auth.Principal, fn func(q *db.Queries, tx pgx.Tx) error) error {
	return platformdb.AsUser(ctx, s.Pool, p.UserID, func(tx pgx.Tx) error { return fn(db.New(tx), tx) })
}

func (s *Service) system(ctx context.Context, fn func(q *db.Queries, tx pgx.Tx) error) error {
	return platformdb.InTx(ctx, s.Pool, func(tx pgx.Tx) error { return fn(db.New(tx), tx) })
}

// recipient of a notification.
type recipient struct {
	ID     uuid.UUID
	Email  string
	Locale string
}

// notifyAll stores an in-app notification and enqueues an e-mail for each
// recipient (inside tx, system context).
func (s *Service) notifyAll(ctx context.Context, q *db.Queries, tx pgx.Tx, to []recipient, key, link string, data map[string]any) error {
	if s.Outbox == nil {
		return nil
	}
	for _, r := range to {
		d := map[string]any{"Link": link}
		for k, v := range data {
			d[k] = v
		}
		if l, ok := data["ListingTitle"].(map[string]string); ok {
			d["Listing"] = pick(l, r.Locale)
		}
		if code, ok := data["Reason"].(string); ok && code != "" {
			d["ReasonText"] = pick(reasonTexts[code], r.Locale)
		}
		raw, _ := json.Marshal(map[string]any{"template": key, "listing": d["Listing"], "group": data["Group"]})
		if _, err := q.InsertNotification(ctx, db.InsertNotificationParams{UserID: r.ID, Kind: key, Data: raw, Link: link}); err != nil {
			return err
		}
		m, err := s.Render.Render(notify.Email, r.Email, r.Locale, key, d)
		if err != nil {
			return err
		}
		if err := s.Outbox.Enqueue(ctx, tx, m); err != nil {
			return err
		}
	}
	return nil
}

// reasonTexts explains reject reasons in e-mails.
var reasonTexts = map[string]map[string]string{
	"other_applicant_chosen": {"cs": "pronajímatel vybral jiného zájemce", "en": "the landlord chose another applicant"},
	"income_insufficient":    {"cs": "příjem neodpovídá výši nájmu", "en": "the income does not match the rent"},
	"move_in_mismatch":       {"cs": "termín nastěhování nevyhovuje", "en": "the move-in date does not fit"},
	"duration_mismatch":      {"cs": "délka nájmu nevyhovuje", "en": "the lease length does not fit"},
	"incomplete":             {"cs": "žádost není úplná", "en": "the application is incomplete"},
	"listing_withdrawn":      {"cs": "inzerát byl stažen", "en": "the listing was withdrawn"},
	"other":                  {"cs": "jiný důvod", "en": "another reason"},
}

func pick(t map[string]string, locale string) string {
	if v := t[locale]; v != "" {
		return v
	}
	if v := t["cs"]; v != "" {
		return v
	}
	return t["en"]
}

func i18n(raw []byte) map[string]string {
	m := map[string]string{}
	_ = json.Unmarshal(raw, &m)
	return m
}

// ---------------------------------------------------------------------------
// Groups.

// Group is a tenant group with members and recent chat.
type Group struct {
	db.TenantGroup
	Members  []db.ListGroupMembersRow
	Messages []db.ListGroupMessagesRow
	Joined   bool
}

var errGroupNotFound = apperr.NotFound("group_not_found", "group not found")

var errEmailUnverified = apperr.Forbidden("email_unverified", "confirm your e-mail address first")

// verifiedEmail returns the caller's address only when it was confirmed:
// group invitations are matched by e-mail, so an unconfirmed registration
// with someone else's address must not see or join their groups (B-2).
func (s *Service) verifiedEmail(ctx context.Context, id uuid.UUID) (string, error) {
	u, err := db.New(s.Pool).GetUser(ctx, id)
	if err != nil {
		return "", err
	}
	if u.EmailVerifiedAt == nil {
		return "", errEmailUnverified
	}
	return u.Email, nil
}

// MaxInvitesPerDay caps group invitations one person sends (the e-mail
// carries their name and the group name to any address).
const MaxInvitesPerDay = 30

// CreateGroup creates a group with the caller as admin and invites others.
func (s *Service) CreateGroup(ctx context.Context, p *auth.Principal, name string, invites []string) (uuid.UUID, error) {
	name = strings.TrimSpace(name)
	if name == "" || utf8.RuneCountInString(name) > 80 {
		return uuid.Nil, apperr.Unprocessable("group_name", "the name must have 1 to 80 characters")
	}
	me, err := s.verifiedEmail(ctx, p.UserID)
	if err != nil {
		return uuid.Nil, err
	}
	var id uuid.UUID
	err = s.asUser(ctx, p, func(q *db.Queries, tx pgx.Tx) error {
		g, err := q.CreateGroup(ctx, db.CreateGroupParams{Name: name, CreatedBy: &p.UserID})
		if err != nil {
			return err
		}
		id = g.ID
		now := time.Now()
		if _, err := q.AddGroupMember(ctx, db.AddGroupMemberParams{GroupID: id, UserID: &p.UserID, InvitedEmail: me,
			Role: "admin", JoinedAt: &now}); err != nil {
			return err
		}
		if err := audit.Record(ctx, q, audit.Event{Entity: "tenant_group", EntityID: &id, Action: "group.create"}); err != nil {
			return err
		}
		return nil
	})
	if err != nil {
		return uuid.Nil, err
	}
	for _, e := range invites {
		if err := s.Invite(ctx, p, id, e); err != nil {
			return id, err
		}
	}
	return id, nil
}

// Invite adds a pending member by e-mail and sends an invitation.
func (s *Service) Invite(ctx context.Context, p *auth.Principal, groupID uuid.UUID, email string) error {
	addr, err := mail.ParseAddress(strings.TrimSpace(email))
	if err != nil {
		return apperr.Unprocessable("invalid_email", "invalid e-mail address")
	}
	email = strings.ToLower(addr.Address)
	if _, err := s.verifiedEmail(ctx, p.UserID); err != nil {
		return err
	}
	sent, err := db.New(s.Pool).CountRecentActorActions(ctx, db.CountRecentActorActionsParams{ActorID: &p.UserID,
		Action: "group.invite", Since: time.Now().Add(-24 * time.Hour)})
	if err != nil {
		return err
	}
	if sent >= MaxInvitesPerDay {
		return apperr.TooMany("you sent too many invitations today, try again tomorrow")
	}
	var groupName string
	err = s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		if _, err := q.GetGroupMember(ctx, db.GetGroupMemberParams{GroupID: groupID, UserID: &p.UserID}); err != nil {
			return errGroupNotFound
		}
		g, err := q.GetGroup(ctx, groupID)
		if err != nil {
			return err
		}
		groupName = g.Name
		members, err := q.ListGroupMembers(ctx, groupID)
		if err != nil {
			return err
		}
		if len(members) >= 10 {
			return apperr.Unprocessable("group_full", "a group has at most 10 members")
		}
		if _, err = q.AddGroupMember(ctx, db.AddGroupMemberParams{GroupID: groupID, InvitedEmail: email, Role: "member"}); err != nil {
			return err
		}
		return audit.Record(ctx, q, audit.Event{Entity: "tenant_group", EntityID: &groupID, Action: "group.invite"})
	})
	if err != nil {
		return err
	}
	inviter, _ := db.New(s.Pool).GetUser(ctx, p.UserID)
	return s.system(ctx, func(q *db.Queries, tx pgx.Tx) error {
		locale := "cs"
		var to []recipient
		// In-app notification only for a confirmed owner of the address.
		if u, err := q.GetUserByEmail(ctx, email); err == nil && u.EmailVerifiedAt != nil {
			to = append(to, recipient{ID: u.ID, Email: u.Email, Locale: u.Locale})
			locale = u.Locale
		}
		link := s.WebBaseURL + "/skupiny/" + groupID.String()
		data := map[string]any{"Group": groupName, "Inviter": inviter.DisplayName}
		if len(to) > 0 {
			return s.notifyAll(ctx, q, tx, to, "group_invitation", link, data)
		}
		// Not registered yet: e-mail only, the invitation waits for the address.
		data["Link"] = s.WebBaseURL + "/register?next=" + "/skupiny/" + groupID.String()
		m, err := s.Render.Render(notify.Email, email, locale, "group_invitation", data)
		if err != nil {
			return err
		}
		return s.Outbox.Enqueue(ctx, tx, m)
	})
}

// MyGroups lists groups the caller belongs to or is invited to.
func (s *Service) MyGroups(ctx context.Context, p *auth.Principal) ([]db.ListMyGroupsRow, error) {
	// Without a confirmed address only groups the caller already joined
	// are listed, never invitations matched by e-mail.
	email, err := s.verifiedEmail(ctx, p.UserID)
	if errors.Is(err, errEmailUnverified) {
		email, err = "", nil
	}
	if err != nil {
		return nil, err
	}
	var out []db.ListMyGroupsRow
	err = s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		out, err = q.ListMyGroups(ctx, db.ListMyGroupsParams{UserID: p.UserID, Email: email})
		return err
	})
	return out, err
}

// Group returns a group visible to the caller (member or invitee).
func (s *Service) Group(ctx context.Context, p *auth.Principal, id uuid.UUID) (Group, error) {
	var out Group
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		g, err := q.GetGroup(ctx, id)
		if errors.Is(err, pgx.ErrNoRows) {
			return errGroupNotFound
		}
		if err != nil {
			return err
		}
		out.TenantGroup = g
		if out.Members, err = q.ListGroupMembers(ctx, id); err != nil {
			return err
		}
		for _, m := range out.Members {
			if m.UserID != nil && *m.UserID == p.UserID && m.JoinedAt != nil {
				out.Joined = true
			}
		}
		if out.Joined {
			out.Messages, err = q.ListGroupMessages(ctx, id)
		}
		return err
	})
	return out, err
}

// Join accepts an invitation: the caller consents to act as a member.
func (s *Service) Join(ctx context.Context, p *auth.Principal, id uuid.UUID) error {
	email, err := s.verifiedEmail(ctx, p.UserID)
	if err != nil {
		return err
	}
	return s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		n, err := q.JoinGroup(ctx, db.JoinGroupParams{UserID: &p.UserID, GroupID: id, Email: email})
		if err != nil {
			return err
		}
		if n == 0 {
			return errGroupNotFound
		}
		return audit.Record(ctx, q, audit.Event{Entity: "tenant_group", EntityID: &id, Action: "group.join"})
	})
}

// Leave removes the caller from a group.
func (s *Service) Leave(ctx context.Context, p *auth.Principal, id uuid.UUID) error {
	return s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		n, err := q.LeaveGroup(ctx, db.LeaveGroupParams{GroupID: id, UserID: &p.UserID})
		if err != nil {
			return err
		}
		if n == 0 {
			return errGroupNotFound
		}
		return audit.Record(ctx, q, audit.Event{Entity: "tenant_group", EntityID: &id, Action: "group.leave"})
	})
}

// SendGroupMessage posts to the group chat. Flatmates may share contacts,
// so nothing is masked here.
func (s *Service) SendGroupMessage(ctx context.Context, p *auth.Principal, id uuid.UUID, body string) (db.ListGroupMessagesRow, error) {
	body = strings.TrimSpace(body)
	if body == "" || utf8.RuneCountInString(body) > 4000 {
		return db.ListGroupMessagesRow{}, apperr.Unprocessable("message_empty", "write a message")
	}
	var msg db.GroupMessage
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		if _, err := q.GetGroupMember(ctx, db.GetGroupMemberParams{GroupID: id, UserID: &p.UserID}); err != nil {
			return errGroupNotFound
		}
		var err error
		msg, err = q.InsertGroupMessage(ctx, db.InsertGroupMessageParams{GroupID: id, SenderID: &p.UserID, Body: body})
		return err
	})
	u, _ := db.New(s.Pool).GetUser(ctx, p.UserID)
	out := db.ListGroupMessagesRow{ID: msg.ID, GroupID: msg.GroupID, SenderID: msg.SenderID, Body: msg.Body,
		CreatedAt: msg.CreatedAt, SenderName: u.DisplayName}
	if err != nil {
		return out, err
	}
	if s.RT != nil {
		ids, err := db.New(s.Pool).GroupMemberUserIDs(ctx, id)
		if err != nil {
			s.Log.Warn("group members", "err", err)
		}
		ev := map[string]any{"type": "group_message", "group_id": id, "message": map[string]any{
			"id": msg.ID, "sender_id": msg.SenderID, "sender_name": u.DisplayName, "body": msg.Body, "created_at": msg.CreatedAt}}
		for _, uid := range ids {
			if err := s.RT.Publish(context.WithoutCancel(ctx), realtime.UserChannel(uid), ev); err != nil {
				s.Log.Warn("realtime publish", "err", err)
			}
		}
	}
	return out, nil
}
