package search

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"

	"github.com/terrareality/terrareality/services/api/internal/catalog"
	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/notify"
)

// Digest e-mails new listings matching saved searches (daily per search).
type Digest struct {
	Engine     *Engine
	Outbox     notify.Outbox
	Render     *notify.Renderer
	WebBaseURL string
}

// Run sends due digests and returns how many e-mails were queued.
func (d *Digest) Run(ctx context.Context) (int, error) {
	q := db.New(d.Engine.Pool)
	due, err := q.SavedSearchesToNotify(ctx)
	if err != nil {
		return 0, err
	}
	schema, err := catalog.Load(ctx, q)
	if err != nil {
		return 0, err
	}
	sent := 0
	for _, s := range due {
		var query Query
		if err := json.Unmarshal(s.Query, &query); err != nil {
			continue
		}
		since := s.LastNotifiedAt
		now := time.Now()
		query.PublishedAfter, query.Limit, query.Offset, query.Sort = &since, 10, 0, "newest"
		res, err := d.Engine.Search(ctx, query, schema)
		if err != nil {
			return sent, fmt.Errorf("saved search %s: %w", s.ID, err)
		}
		err = pgx.BeginFunc(ctx, d.Engine.Pool, func(tx pgx.Tx) error {
			if res.Total > 0 {
				var lines []string
				for _, c := range res.Items {
					title := c.Title["cs"]
					if s.Locale == "en" && c.Title["en"] != "" {
						title = c.Title["en"]
					}
					lines = append(lines, fmt.Sprintf("- %s, %d Kč: %s/inzerat/%s", title, c.RentAmount/100, d.WebBaseURL, c.ListingID))
				}
				m, err := d.Render.Render(notify.Email, s.Email, s.Locale, "saved_search_digest", map[string]any{
					"Name": s.Name, "Count": res.Total, "Items": strings.Join(lines, "\n"), "Link": d.WebBaseURL + "/hledat"})
				if err != nil {
					return err
				}
				if err := d.Outbox.Enqueue(ctx, tx, m); err != nil {
					return err
				}
				sent++
			}
			return db.New(tx).MarkSavedSearchNotified(ctx, db.MarkSavedSearchNotifiedParams{ID: s.ID, LastNotifiedAt: now})
		})
		if err != nil {
			return sent, err
		}
	}
	return sent, nil
}
