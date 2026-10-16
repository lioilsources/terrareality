package main

import (
	"context"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"

	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/terrareality/terrareality/services/api/internal/listing"
	"github.com/terrareality/terrareality/services/api/internal/media"
	"github.com/terrareality/terrareality/services/api/internal/platform/config"
	"github.com/terrareality/terrareality/services/api/internal/search"
	"github.com/terrareality/terrareality/services/api/internal/storage"
)

const demoUsage = `usage: terractl demo seed --photos <dir> [--org "TerraReality – ukázka"] [--count 15] | demo list | demo remove`

// demoCmd implements
//
//	terractl demo seed --photos <dir> [--org name] [--count 15]
//	terractl demo list
//	terractl demo remove
//
// Demo listings ("ukázkové inzeráty") are allowed in every APP_ENV (staging
// is the point); see docs/runbooks/seed-praha.md.
func demoCmd(ctx context.Context, cfg config.Config, pool *pgxpool.Pool, args []string, out io.Writer) error {
	if len(args) == 0 {
		return errors.New(demoUsage)
	}
	switch args[0] {
	case "seed":
		fs := flag.NewFlagSet("demo seed", flag.ContinueOnError)
		photos := fs.String("photos", "", "directory with manifest.json and flat-NN/{living,kitchen,bedroom,bathroom}.jpg")
		orgName := fs.String("org", listing.DefaultDemoOrg, "name of the demo organization (created without members)")
		count := fs.Int("count", 15, "at most this many demo listings")
		if err := fs.Parse(args[1:]); err != nil {
			return err
		}
		if *photos == "" {
			return errors.New("demo seed needs --photos <dir> (" + demoUsage + ")")
		}
		svc, err := demoService(cfg, pool)
		if err != nil {
			return err
		}
		res, err := svc.SeedDemo(ctx, listing.DemoSeed{OrgName: *orgName, Dir: *photos, Count: *count})
		if err != nil {
			return err
		}
		if res.OrgCreated {
			fmt.Fprintf(out, "created organization %q (%s)\n", *orgName, res.OrgID)
		}
		for _, id := range res.Created {
			fmt.Fprintf(out, "published demo listing %s\n", id)
		}
		fmt.Fprintf(out, "%d demo listings created, %d already present\n", len(res.Created), res.Skipped)
		return nil
	case "list":
		svc := &listing.Service{Pool: pool}
		rows, err := svc.DemoListings(ctx)
		if err != nil {
			return err
		}
		for _, l := range rows {
			var title map[string]string
			_ = json.Unmarshal(l.Title, &title)
			rent := int64(0)
			if l.RentAmount != nil {
				rent = *l.RentAmount / 100
			}
			fmt.Fprintf(out, "%s  %-6s %-9s search=%-5v photos=%d  %d %s  %s  (%s)\n", l.ID, l.UnitLabel, l.Status, l.InSearch,
				l.Photos, rent, l.Currency, title["cs"], l.AddressLabel)
		}
		fmt.Fprintf(out, "%d demo listings\n", len(rows))
		return nil
	case "remove":
		svc, err := demoService(cfg, pool)
		if err != nil {
			return err
		}
		n, photos, err := svc.RemoveDemoListings(ctx)
		fmt.Fprintf(out, "removed %d demo listings, deleted %d photos\n", n, photos)
		return err
	}
	return errors.New(demoUsage)
}

// demoService is the catalog service with the adapters the media pipeline
// needs. The photos must land in the object store the api serves from, so
// the in-memory store of dev is refused.
func demoService(cfg config.Config, pool *pgxpool.Pool) (*listing.Service, error) {
	if cfg.S3Endpoint == "" {
		return nil, errors.New("demo needs S3_ENDPOINT: photos must be stored where the api and imgproxy read them")
	}
	blob, err := storage.NewS3(storage.S3Config{Endpoint: cfg.S3Endpoint, AccessKey: cfg.S3AccessKey,
		SecretKey: cfg.S3SecretKey, Bucket: cfg.S3Bucket, Region: cfg.S3Region, UseSSL: cfg.S3UseSSL})
	if err != nil {
		return nil, err
	}
	var scanner media.Scanner = media.NoScanner{}
	if cfg.ClamAVAddr != "" {
		scanner = media.ClamAV{Addr: cfg.ClamAVAddr}
	}
	// No vision, no LLM: Flags stay off, texts are generated from templates.
	return &listing.Service{Pool: pool, Blob: blob, Scanner: scanner, WebBaseURL: cfg.WebBaseURL, Search: search.Indexer{}}, nil
}
