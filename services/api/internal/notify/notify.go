// Package notify renders localized e-mail and SMS messages, delivers them
// through a transactional outbox (a River job inserted in the same database
// transaction as the change that triggered it) and sends push notifications.
// The mechanics live in ol1n_platform_kit/notify (ADR 0013); this package
// keeps TerraReality's templates, push titles and kinds, and the values
// already deployed (VAPID salt, mock domains).
package notify

import (
	"embed"

	kit "github.com/lioilsources/ol1n_platform_kit/notify"
)

// Channels.
const (
	Email = kit.Email
	SMS   = kit.SMS
)

// Push kinds. The mobile app deep-links by data "kind" + "id" and falls back
// to "link" (apps/mobile/lib/src/push/push_registrar.dart).
const (
	PushConversation = "conversation"
	PushApplication  = "application"
	PushViewing      = "viewing"
	PushLease        = "lease"
	PushObligation   = "obligation"
)

// MockDomain receives mock SMS and pushes in dev (Mailpit).
const MockDomain = "terra.local"

// vapidSalt derives the VAPID key from the seed. Never change it: every
// browser subscription is bound to the key.
const vapidSalt = "terra-vapid:"

type (
	Message        = kit.Message
	Outbox         = kit.Outbox
	Renderer       = kit.Renderer
	MemoryOutbox   = kit.MemoryOutbox
	Sender         = kit.Sender
	SMTP           = kit.SMTP
	Log            = kit.Log
	SMSViaEmail    = kit.SMSViaEmail
	Router         = kit.Router
	Push           = kit.Push
	Pusher         = kit.Pusher
	PushViaEmail   = kit.PushViaEmail
	PushLog        = kit.PushLog
	FCM            = kit.FCM
	WebPush        = kit.WebPush
	PlatformRouter = kit.PlatformRouter
	PushQueue      = kit.PushQueue
	Pushes         = kit.Pushes
	Text           = kit.Text
)

var (
	ErrDeviceGone = kit.ErrDeviceGone
	LinkToken     = kit.LinkToken
	PushData      = kit.PushData
	NewFCM        = kit.NewFCM
	NewPushes     = kit.NewPushes
	Encrypt       = kit.Encrypt
)

//go:embed messages/*.json
var messageFS embed.FS

// NewRenderer parses the embedded cs and en templates.
func NewRenderer() (*Renderer, error) {
	return kit.NewRenderer(kit.RendererConfig{FS: messageFS, Dir: "messages", Locales: []string{"cs", "en"}})
}

// NewWebPush derives the VAPID key pair from seed (APP_SECRET_KEY or a
// dedicated WEBPUSH_VAPID_SEED) with TerraReality's fixed salt.
func NewWebPush(seed, subject string) (*WebPush, error) {
	return kit.NewWebPush(vapidSalt, seed, subject)
}
