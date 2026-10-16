package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"io"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/terrareality/terrareality/services/api/internal/platform/config"
	"github.com/terrareality/terrareality/services/api/internal/platform/secretbox"
)

// sealedColumn is a bytea column holding secretbox.Seal output. Keep this
// list in sync with every Box.Seal call (grep "Box.Seal").
type sealedColumn struct {
	Table, Key, Column string
}

var sealedColumns = []sealedColumn{
	{"users", "id", "totp_secret"},                    // account.EnableTOTP
	{"users", "id", "totp_pending_secret"},            // account.SetupTOTP
	{"org_revolut_accounts", "org_id", "api_key_enc"}, // billing.ConnectRevolut
}

// rotationStats counts one column's rows.
type rotationStats struct {
	Column                    sealedColumn
	Scanned, Rotated, Current int
	Failed                    int
}

// rotateSecrets implements `terractl rotate-secrets [--dry-run] [--batch n]`.
func rotateSecrets(ctx context.Context, cfg config.Config, pool *pgxpool.Pool, args []string, out io.Writer) error {
	fs := flag.NewFlagSet("rotate-secrets", flag.ContinueOnError)
	dry := fs.Bool("dry-run", false, "count values that would be re-encrypted, change nothing")
	batch := fs.Int("batch", 500, "rows per transaction")
	if err := fs.Parse(args); err != nil {
		return err
	}
	box, err := secretbox.New(cfg.SecretKey, cfg.SecretKeyPrevious...)
	if err != nil {
		return err
	}
	fmt.Fprintf(out, "current key id %s, ring %v\n", box.KeyID(), box.KeyIDs())
	stats, err := resealAll(ctx, pool, box, *batch, *dry)
	failed := 0
	for _, s := range stats {
		verb := "re-encrypted"
		if *dry {
			verb = "to re-encrypt"
		}
		fmt.Fprintf(out, "%s.%s: %d scanned, %d %s, %d already current, %d unreadable\n",
			s.Column.Table, s.Column.Column, s.Scanned, s.Rotated, verb, s.Current, s.Failed)
		failed += s.Failed
	}
	if err != nil {
		return err
	}
	if failed > 0 {
		return fmt.Errorf("%d values could not be opened with the configured keys; keep the old key in APP_SECRET_KEY_PREVIOUS", failed)
	}
	return nil
}

// resealAll re-encrypts every sealed value that does not use the current key.
// It is idempotent: values already sealed with the current key are skipped,
// so it can be re-run after an interruption.
func resealAll(ctx context.Context, pool *pgxpool.Pool, box *secretbox.Box, batch int, dryRun bool) ([]rotationStats, error) {
	if batch < 1 {
		return nil, errors.New("batch must be positive")
	}
	var all []rotationStats
	for _, c := range sealedColumns {
		s, err := resealColumn(ctx, pool, box, c, batch, dryRun)
		all = append(all, s)
		if err != nil {
			return all, fmt.Errorf("%s.%s: %w", c.Table, c.Column, err)
		}
	}
	return all, nil
}

func resealColumn(ctx context.Context, pool *pgxpool.Pool, box *secretbox.Box, c sealedColumn, batch int, dryRun bool) (rotationStats, error) {
	st := rotationStats{Column: c}
	// Identifiers come from the fixed sealedColumns list, never from input.
	sel := fmt.Sprintf(`SELECT %[1]s::text, %[2]s FROM %[3]s WHERE %[2]s IS NOT NULL AND %[1]s::text > $1 ORDER BY %[1]s::text LIMIT $2`,
		pgx.Identifier{c.Key}.Sanitize(), pgx.Identifier{c.Column}.Sanitize(), pgx.Identifier{c.Table}.Sanitize())
	upd := fmt.Sprintf(`UPDATE %[3]s SET %[2]s = $2 WHERE %[1]s::text = $1 AND %[2]s = $3`,
		pgx.Identifier{c.Key}.Sanitize(), pgx.Identifier{c.Column}.Sanitize(), pgx.Identifier{c.Table}.Sanitize())
	after := ""
	for {
		n := 0
		err := pgx.BeginFunc(ctx, pool, func(tx pgx.Tx) error {
			rows, err := tx.Query(ctx, sel, after, batch)
			if err != nil {
				return err
			}
			type row struct {
				id     string
				sealed []byte
			}
			var todo []row
			for rows.Next() {
				var r row
				if err := rows.Scan(&r.id, &r.sealed); err != nil {
					rows.Close()
					return err
				}
				todo = append(todo, r)
			}
			rows.Close()
			if err := rows.Err(); err != nil {
				return err
			}
			n = len(todo)
			for _, r := range todo {
				after = r.id
				st.Scanned++
				fresh, changed, err := box.Reseal(r.sealed)
				switch {
				case err != nil:
					st.Failed++
					continue
				case !changed:
					st.Current++
					continue
				}
				st.Rotated++
				if dryRun {
					continue
				}
				// Compare-and-set: a value changed concurrently (new TOTP
				// setup) is already sealed with the current key.
				if _, err := tx.Exec(ctx, upd, r.id, fresh, r.sealed); err != nil {
					return err
				}
			}
			return nil
		})
		if err != nil {
			return st, err
		}
		if n < batch {
			return st, nil
		}
	}
}
