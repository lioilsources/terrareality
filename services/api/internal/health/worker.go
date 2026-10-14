package health

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5"

	"github.com/terrareality/terrareality/services/api/internal/db"
)

// WorkerHeartbeat fails when the worker has not refreshed its heartbeat row
// within maxAge. The worker writes it every 30 s (see jobs.HeartbeatWorker).
func WorkerHeartbeat(q db.Querier, key string, maxAge time.Duration) CheckFunc {
	return func(ctx context.Context) error {
		row, err := q.GetAppMeta(ctx, key)
		if errors.Is(err, pgx.ErrNoRows) {
			return errors.New("no heartbeat yet")
		}
		if err != nil {
			return err
		}
		var v struct {
			At time.Time `json:"at"`
		}
		if err := json.Unmarshal(row.Value, &v); err != nil {
			return fmt.Errorf("bad heartbeat payload: %w", err)
		}
		if age := time.Since(v.At); age > maxAge {
			return fmt.Errorf("last heartbeat %s ago", age.Round(time.Second))
		}
		return nil
	}
}
