// Package audit records who changed what (plan, section 5: every mutation of
// a domain object produces an audit event).
package audit

import (
	"context"
	"encoding/json"
	"net/netip"

	"github.com/google/uuid"

	"github.com/terrareality/terrareality/services/api/internal/auth"
	"github.com/terrareality/terrareality/services/api/internal/db"
)

// Event describes one change. Actor and request data come from ctx.
type Event struct {
	OrgID    *uuid.UUID
	Entity   string
	EntityID *uuid.UUID
	Action   string
	Diff     map[string]any
	// ActorID overrides the principal (e.g. a job acting for a user).
	ActorID *uuid.UUID
}

// Record inserts the event using q (usually the transaction of the change).
func Record(ctx context.Context, q db.Querier, e Event) error {
	diff, err := json.Marshal(e.Diff)
	if err != nil {
		return err
	}
	if e.Diff == nil {
		diff = []byte("{}")
	}
	p := auth.FromContext(ctx)
	actor := e.ActorID
	var imp *uuid.UUID
	if p != nil {
		if actor == nil {
			id := p.UserID
			actor = &id
		}
		imp = p.ImpersonatorID
	}
	meta := auth.Meta(ctx)
	var ip *netip.Addr
	if a, err := netip.ParseAddr(meta.IP); err == nil {
		ip = &a
	}
	var rid *string
	if meta.RequestID != "" {
		rid = &meta.RequestID
	}
	return q.InsertAuditEvent(ctx, db.InsertAuditEventParams{
		ActorID: actor, ImpersonatorID: imp, OrgID: e.OrgID, Entity: e.Entity, EntityID: e.EntityID,
		Action: e.Action, Diff: diff, Ip: ip, RequestID: rid,
	})
}

// Ptr is a helper for optional ids.
func Ptr(id uuid.UUID) *uuid.UUID { return &id }
