// Package realtime publishes events to Centrifugo and issues the tokens
// clients use to connect. It lives in ol1n_platform_kit/realtime (ADR 0013);
// this package keeps TerraReality's channel names.
package realtime

import (
	"github.com/google/uuid"
	kit "github.com/lioilsources/ol1n_platform_kit/realtime"
)

type (
	Publisher  = kit.Publisher
	Centrifugo = kit.Centrifugo
	Memory     = kit.Memory
	Event      = kit.Event
	Tokens     = kit.Tokens
)

var (
	NewCentrifugo = kit.NewCentrifugo
	UserChannel   = kit.UserChannel
)

// ConversationChannel is the channel of one conversation.
func ConversationChannel(id uuid.UUID) string { return kit.Channel("conv", id) }
