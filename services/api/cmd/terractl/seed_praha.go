package main

import (
	"context"
	"encoding/csv"
	"errors"
	"flag"
	"fmt"
	"io"
	"net/http"
	"net/mail"
	"os"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/terrareality/terrareality/services/api/internal/audit"
	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/jobs"
	"github.com/terrareality/terrareality/services/api/internal/notify"
	"github.com/terrareality/terrareality/services/api/internal/platform/config"
	platformdb "github.com/terrareality/terrareality/services/api/internal/platform/db"
	"github.com/terrareality/terrareality/services/api/internal/platform/tokens"
	"github.com/terrareality/terrareality/services/api/internal/ruian"
	"github.com/terrareality/terrareality/services/api/internal/search"
)

// importRuian implements
//
//	terractl import-ruian --region praha [--file path.csv|.zip | --url URL|official] [--boundaries units.geojson]
//
// Without --file/--url it loads the embedded offline sample of the region.
// Boundaries come from --boundaries (GeoJSON, see search.ImportGeoJSON); in
// dev/test without it, approximate polygons are derived from the addresses.
func importRuian(ctx context.Context, cfg config.Config, pool *pgxpool.Pool, args []string, out io.Writer) error {
	fs := flag.NewFlagSet("import-ruian", flag.ContinueOnError)
	region := fs.String("region", "", "launch region (praha)")
	file := fs.String("file", "", "RÚIAN address CSV or ZIP of CSVs")
	url := fs.String("url", "", `download URL of the RÚIAN export, or "official" for the latest ČÚZK export`)
	boundaries := fs.String("boundaries", "", "GeoJSON of administrative units (municipalities, districts, city parts)")
	if err := fs.Parse(args); err != nil {
		return err
	}
	r, ok := ruian.Regions[*region]
	if !ok {
		return fmt.Errorf("unknown region %q (known: praha)", *region)
	}
	if *file != "" && *url != "" {
		return errors.New("use either --file or --url")
	}
	if err := platformdb.Migrate(ctx, pool); err != nil {
		return err
	}
	if *url == "official" {
		*url = fmt.Sprintf(ruian.OfficialAddressesURL, ruian.DefaultExportDate(time.Now()))
	}
	if *url != "" {
		fmt.Fprintf(out, "downloading %s\n", *url)
		path, err := ruian.Download(ctx, &http.Client{Timeout: 30 * time.Minute}, *url)
		if err != nil {
			return err
		}
		defer os.Remove(path)
		*file = path
	}
	counter := ruian.NewCounter(r)
	var n int64
	var err error
	if *file != "" {
		n, err = ruian.ImportFileFiltered(ctx, pool, *file, counter.Keep)
	} else {
		fmt.Fprintln(out, "no --file/--url: importing the embedded offline sample")
		n, err = ruian.ImportRegionSample(ctx, pool, r, counter.Keep)
	}
	fmt.Fprintf(out, "%s: imported %d address points\n", r.Name, n)
	if err != nil {
		return err
	}
	if missing := counter.Missing(); len(missing) > 0 {
		fmt.Fprintf(out, "warning: no addresses for %s\n", strings.Join(missing, ", "))
	}
	switch {
	case *boundaries != "":
		f, err := os.Open(*boundaries)
		if err != nil {
			return err
		}
		defer f.Close()
		units, err := search.ImportGeoJSON(ctx, pool, f)
		fmt.Fprintf(out, "imported %d administrative units\n", units)
		return err
	case cfg.Env == "dev" || cfg.Env == "test":
		units, err := search.SeedFromRuian(ctx, pool)
		fmt.Fprintf(out, "derived %d approximate administrative units from addresses (dev only)\n", units)
		return err
	default:
		fmt.Fprintln(out, "warning: no --boundaries given; import official boundaries before launch (docs/runbooks/seed-praha.md)")
		return nil
	}
}

// pilotOwner is one row of the pilot onboarding list.
type pilotOwner struct {
	Email, Name, Org, Locale, RegistrationNo string
}

// parseOwnersCSV reads "email,name,org[,locale][,registration_no]" with a header
// row (comma or semicolon separated). Duplicate e-mails are rejected.
func parseOwnersCSV(r io.Reader) ([]pilotOwner, error) {
	raw, err := io.ReadAll(r)
	if err != nil {
		return nil, err
	}
	text := strings.TrimPrefix(string(raw), "\ufeff")
	cr := csv.NewReader(strings.NewReader(text))
	if first, _, _ := strings.Cut(text, "\n"); strings.Count(first, ";") > strings.Count(first, ",") {
		cr.Comma = ';'
	}
	cr.FieldsPerRecord = -1
	cr.TrimLeadingSpace = true
	header, err := cr.Read()
	if err != nil {
		return nil, fmt.Errorf("read header: %w", err)
	}
	col := map[string]int{}
	for i, h := range header {
		col[strings.ToLower(strings.TrimSpace(h))] = i
	}
	for _, need := range []string{"email", "name", "org"} {
		if _, ok := col[need]; !ok {
			return nil, fmt.Errorf("missing column %q", need)
		}
	}
	get := func(rec []string, name string) string {
		if i, ok := col[name]; ok && i < len(rec) {
			return strings.TrimSpace(rec[i])
		}
		return ""
	}
	var out []pilotOwner
	seen := map[string]int{}
	line := 1
	for {
		rec, err := cr.Read()
		if err == io.EOF {
			break
		}
		line++
		if err != nil {
			return nil, fmt.Errorf("line %d: %w", line, err)
		}
		if len(rec) == 1 && strings.TrimSpace(rec[0]) == "" {
			continue
		}
		o, err := validOwner(pilotOwner{Email: get(rec, "email"), Name: get(rec, "name"), Org: get(rec, "org"),
			Locale: get(rec, "locale"), RegistrationNo: get(rec, "registration_no")})
		if err != nil {
			return nil, fmt.Errorf("line %d: %w", line, err)
		}
		if prev, dup := seen[o.Email]; dup {
			return nil, fmt.Errorf("line %d: %s already on line %d", line, o.Email, prev)
		}
		seen[o.Email] = line
		out = append(out, o)
	}
	return out, nil
}

func validOwner(o pilotOwner) (pilotOwner, error) {
	o.Email = strings.ToLower(strings.TrimSpace(o.Email))
	if a, err := mail.ParseAddress(o.Email); err != nil || a.Address != o.Email {
		return o, fmt.Errorf("invalid e-mail %q", o.Email)
	}
	o.Name, o.Org = strings.TrimSpace(o.Name), strings.TrimSpace(o.Org)
	if o.Org == "" {
		o.Org = o.Name
	}
	if o.Name == "" || o.Org == "" {
		return o, fmt.Errorf("%s: name and org are required", o.Email)
	}
	if o.Locale != "en" {
		o.Locale = "cs"
	}
	return o, nil
}

// pilotInvitationTTL matches the 7 days promised by the invitation e-mail.
const pilotInvitationTTL = 7 * 24 * time.Hour

// onboarder creates an invited owner organization per pilot owner.
type onboarder struct {
	Pool       *pgxpool.Pool
	Outbox     notify.Outbox
	Render     *notify.Renderer
	WebBaseURL string
}

// Onboard creates a company organization without members and an owner
// invitation for the e-mail. The invitation e-mail (sent through the outbox)
// is a sign-in-free link: the owner opens it, signs in with a magic link and
// becomes the organization's owner. No password is ever set by the operator.
// An existing user who already owns an organization of the same name is skipped.
func (o onboarder) Onboard(ctx context.Context, p pilotOwner) (created bool, err error) {
	err = platformdb.InTx(ctx, o.Pool, func(tx pgx.Tx) error {
		q := db.New(tx)
		if u, err := q.GetUserByEmail(ctx, p.Email); err == nil {
			orgs, err := q.ListMyOrganizations(ctx, u.ID)
			if err != nil {
				return err
			}
			for _, m := range orgs {
				if m.Kind == "company" && strings.EqualFold(m.Name, p.Org) {
					return nil
				}
			}
		} else if !errors.Is(err, pgx.ErrNoRows) {
			return err
		}
		var regNo *string
		if p.RegistrationNo != "" {
			regNo = &p.RegistrationNo
		}
		org, err := q.CreateOrganization(ctx, db.CreateOrganizationParams{Kind: "company", Name: p.Org,
			RegistrationNo: regNo, JurisdictionCode: "CZ"})
		if err != nil {
			return err
		}
		tok := tokens.New()
		inv, err := q.CreateInvitation(ctx, db.CreateInvitationParams{OrgID: org.ID, Email: p.Email, Role: "owner",
			TokenHash: tokens.Hash(tok), ExpiresAt: time.Now().Add(pilotInvitationTTL)})
		if err != nil {
			return err
		}
		msg, err := o.Render.Render(notify.Email, p.Email, p.Locale, "invitation", map[string]any{
			"OrgName": org.Name, "InviterName": "TerraReality", "Role": "owner", "Link": o.WebBaseURL + "/invite/" + tok})
		if err != nil {
			return err
		}
		if err := o.Outbox.Enqueue(ctx, tx, msg); err != nil {
			return err
		}
		created = true
		return audit.Record(ctx, q, audit.Event{OrgID: &org.ID, Entity: "invitation", EntityID: &inv.ID,
			Action: "invitation.created", Diff: map[string]any{"email": p.Email, "role": "owner", "source": "terractl onboard-owner",
				"name": p.Name}})
	})
	return created, err
}

// onboardOwners implements
//
//	terractl onboard-owner --email a@b.cz --name "Jana Nováková" --org "Nováková Reality" [--locale cs]
//	terractl onboard-owner --csv pilot-owners.csv [--dry-run]
func onboardOwners(ctx context.Context, cfg config.Config, pool *pgxpool.Pool, args []string, out io.Writer) error {
	fs := flag.NewFlagSet("onboard-owner", flag.ContinueOnError)
	email := fs.String("email", "", "owner e-mail")
	name := fs.String("name", "", "owner name")
	orgName := fs.String("org", "", "organization name (defaults to the name)")
	locale := fs.String("locale", "cs", "e-mail language (cs, en)")
	csvPath := fs.String("csv", "", "CSV with columns email,name,org[,locale][,registration_no]")
	dryRun := fs.Bool("dry-run", false, "validate and print, change nothing")
	if err := fs.Parse(args); err != nil {
		return err
	}
	var owners []pilotOwner
	switch {
	case *csvPath != "" && *email != "":
		return errors.New("use either --csv or --email")
	case *csvPath != "":
		f, err := os.Open(*csvPath)
		if err != nil {
			return err
		}
		defer f.Close()
		if owners, err = parseOwnersCSV(f); err != nil {
			return err
		}
	case *email != "":
		o, err := validOwner(pilotOwner{Email: *email, Name: *name, Org: *orgName, Locale: *locale})
		if err != nil {
			return err
		}
		owners = []pilotOwner{o}
	default:
		return errors.New("usage: terractl onboard-owner --email <e-mail> --name <name> [--org <org>] | --csv <file> [--dry-run]")
	}
	if *dryRun {
		for _, o := range owners {
			fmt.Fprintf(out, "would invite %s (%s) as owner of %q [%s]\n", o.Email, o.Name, o.Org, o.Locale)
		}
		return nil
	}
	if err := platformdb.Migrate(ctx, pool); err != nil {
		return err
	}
	if err := jobs.MigrateRiver(ctx, pool); err != nil {
		return err
	}
	rc, err := jobs.NewInsertOnlyClient(pool)
	if err != nil {
		return err
	}
	render, err := notify.NewRenderer()
	if err != nil {
		return err
	}
	ob := onboarder{Pool: pool, Outbox: jobs.Outbox{Client: rc}, Render: render, WebBaseURL: cfg.WebBaseURL}
	invited := 0
	for _, o := range owners {
		created, err := ob.Onboard(ctx, o)
		if err != nil {
			return fmt.Errorf("%s: %w", o.Email, err)
		}
		if created {
			invited++
			fmt.Fprintf(out, "invited %s as owner of %q\n", o.Email, o.Org)
		} else {
			fmt.Fprintf(out, "skipped %s: already owns %q\n", o.Email, o.Org)
		}
	}
	fmt.Fprintf(out, "%d of %d owners invited; the worker sends the e-mails\n", invited, len(owners))
	return nil
}
