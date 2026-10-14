package messaging

import (
	"context"
	"encoding/json"
	"errors"
	"slices"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"github.com/terrareality/terrareality/services/api/internal/audit"
	"github.com/terrareality/terrareality/services/api/internal/auth"
	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/org"
	"github.com/terrareality/terrareality/services/api/internal/platform/apperr"
)

// SetPrescreen replaces a listing's pre-screening questions.
func (s *Service) SetPrescreen(ctx context.Context, p *auth.Principal, orgID, listingID uuid.UUID, in []PrescreenQuestion) ([]PrescreenQuestion, error) {
	qs, err := NormalizePrescreen(in)
	if err != nil {
		return nil, err
	}
	raw, _ := json.Marshal(qs)
	err = s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		if _, err := org.Access(ctx, q, p.UserID, orgID, org.PermCatalogWrite); err != nil {
			return err
		}
		n, err := q.UpdateListingPrescreen(ctx, db.UpdateListingPrescreenParams{ID: listingID, OrgID: orgID, Prescreen: raw})
		if err != nil {
			return err
		}
		if n == 0 {
			return apperr.NotFound("listing_not_found", "listing not found")
		}
		return audit.Record(ctx, q, audit.Event{OrgID: &orgID, Entity: "listing", EntityID: &listingID,
			Action: "listing.prescreen", Diff: map[string]any{"questions": len(qs)}})
	})
	return qs, err
}

// Notifications returns the caller's latest in-app notifications and the
// unread count.
func (s *Service) Notifications(ctx context.Context, p *auth.Principal) ([]db.Notification, int32, error) {
	var out []db.Notification
	var unread int32
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		var err error
		if out, err = q.ListNotifications(ctx, p.UserID); err != nil {
			return err
		}
		unread, err = q.CountUnreadNotifications(ctx, p.UserID)
		return err
	})
	return out, unread, err
}

// MarkNotificationsRead marks one (id) or all notifications read.
func (s *Service) MarkNotificationsRead(ctx context.Context, p *auth.Principal, id *uuid.UUID) error {
	return s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		return q.MarkNotificationsRead(ctx, db.MarkNotificationsReadParams{UserID: p.UserID, ID: id})
	})
}

// Preferences are a user's notification settings.
type Preferences struct {
	EmailMessages string `json:"email_messages"` // instant | daily | off
	PushMessages  bool   `json:"push_messages"`
}

// GetPreferences returns the caller's settings (defaults when unset).
func (s *Service) GetPreferences(ctx context.Context, p *auth.Principal) (Preferences, error) {
	out := Preferences{EmailMessages: "instant", PushMessages: true}
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		r, err := q.GetNotificationPreferences(ctx, p.UserID)
		if errors.Is(err, pgx.ErrNoRows) {
			return nil
		}
		if err != nil {
			return err
		}
		out = Preferences{EmailMessages: r.EmailMessages, PushMessages: r.PushMessages}
		return nil
	})
	return out, err
}

// SetPreferences stores the caller's settings.
func (s *Service) SetPreferences(ctx context.Context, p *auth.Principal, in Preferences) (Preferences, error) {
	if !slices.Contains([]string{"instant", "daily", "off"}, in.EmailMessages) {
		return Preferences{}, apperr.Unprocessable("invalid_preference", "email_messages is instant, daily or off")
	}
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		_, err := q.UpsertNotificationPreferences(ctx, db.UpsertNotificationPreferencesParams{UserID: p.UserID,
			EmailMessages: in.EmailMessages, PushMessages: in.PushMessages})
		return err
	})
	return in, err
}

// RegisterDevice stores a push token for the caller (FCM token from the
// Flutter app, or a web push subscription).
func (s *Service) RegisterDevice(ctx context.Context, p *auth.Principal, platform, token string, keys json.RawMessage, label string) (db.PushDevice, error) {
	if !slices.Contains([]string{"fcm", "apns", "webpush"}, platform) {
		return db.PushDevice{}, apperr.Unprocessable("invalid_platform", "platform is fcm, apns or webpush")
	}
	if token == "" || len(token) > 4096 {
		return db.PushDevice{}, apperr.Unprocessable("invalid_token", "missing push token")
	}
	if len(label) > 120 {
		label = label[:120]
	}
	// A token moves with the device: when another account signs in on the
	// same phone, the previous owner's registration is dropped (system
	// context, RLS would hide the row).
	if err := db.New(s.Pool).DeletePushDeviceOfOthers(ctx, db.DeletePushDeviceOfOthersParams{Platform: platform,
		Token: token, UserID: p.UserID}); err != nil {
		return db.PushDevice{}, err
	}
	var out db.PushDevice
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		var err error
		out, err = q.UpsertPushDevice(ctx, db.UpsertPushDeviceParams{UserID: p.UserID, Platform: platform, Token: token,
			Keys: keys, Label: label})
		return err
	})
	return out, err
}

// Devices lists the caller's push devices.
func (s *Service) Devices(ctx context.Context, p *auth.Principal) ([]db.PushDevice, error) {
	var out []db.PushDevice
	err := s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		var err error
		out, err = q.ListPushDevices(ctx, p.UserID)
		return err
	})
	return out, err
}

// DeleteDevice unregisters a push device.
func (s *Service) DeleteDevice(ctx context.Context, p *auth.Principal, id uuid.UUID) error {
	return s.asUser(ctx, p, func(q *db.Queries, _ pgx.Tx) error {
		n, err := q.DeletePushDevice(ctx, db.DeletePushDeviceParams{ID: id, UserID: p.UserID})
		if err != nil {
			return err
		}
		if n == 0 {
			return apperr.NotFound("device_not_found", "device not found")
		}
		return nil
	})
}
