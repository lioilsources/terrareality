// Package audit records who changed what (plan, section 5: every mutation of
// a domain object produces an audit event). The event logic lives in
// ol1n_platform_kit/audit; this shim keeps the sqlc Querier that TerraReality
// threads through its services (ADR 0013).
package audit

import (
	"context"

	"github.com/google/uuid"
	kitaudit "github.com/lioilsources/ol1n_platform_kit/audit"

	"github.com/terrareality/terrareality/services/api/internal/db"
)

// Event describes one change. Actor and request data come from ctx.
type Event = kitaudit.Event

// Record inserts the event using q (usually the transaction of the change).
func Record(ctx context.Context, q db.Querier, e Event) error {
	row, err := kitaudit.Build(ctx, e)
	if err != nil {
		return err
	}
	return q.InsertAuditEvent(ctx, db.InsertAuditEventParams(row))
}

// Ptr is a helper for optional ids.
func Ptr(id uuid.UUID) *uuid.UUID { return &id }
