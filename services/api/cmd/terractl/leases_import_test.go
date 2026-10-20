package main

import (
	"bytes"
	"context"
	"fmt"
	"log/slog"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/leasing"
	platformdb "github.com/terrareality/terrareality/services/api/internal/platform/db"
)

// TestImportLeases runs terractl leases import against a database
// (TEST_DATABASE_URL): problems are printed per line and nothing is
// written, a dry run writes nothing, the real run imports the file.
func TestImportLeases(t *testing.T) {
	url := os.Getenv("TEST_DATABASE_URL")
	if url == "" {
		t.Skip("TEST_DATABASE_URL not set")
	}
	ctx := context.Background()
	pool, err := platformdb.Open(ctx, url)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	if err := platformdb.Migrate(ctx, pool); err != nil {
		t.Fatal(err)
	}
	q := db.New(pool)
	name := fmt.Sprintf("Paper Reality %d", time.Now().UnixNano())
	u, err := q.CreateUser(ctx, db.CreateUserParams{Email: fmt.Sprintf("paper-%d@example.cz", time.Now().UnixNano()),
		DisplayName: "Jana Nováková", Locale: "cs"})
	if err != nil {
		t.Fatal(err)
	}
	o, err := q.CreateOrganization(ctx, db.CreateOrganizationParams{Kind: "company", Name: name, JurisdictionCode: "CZ"})
	if err != nil {
		t.Fatal(err)
	}
	if err := q.AddMembership(ctx, db.AddMembershipParams{OrgID: o.ID, UserID: u.ID, Role: "owner"}); err != nil {
		t.Fatal(err)
	}
	svc := &leasing.Service{Pool: pool, Log: slog.Default()}
	count := func() int {
		var n int
		if err := pool.QueryRow(ctx, "SELECT count(*) FROM leases WHERE org_id = $1", o.ID).Scan(&n); err != nil {
			t.Fatal(err)
		}
		return n
	}
	header := strings.Join(leasing.ImportColumns, ",") + "\n"
	good := header +
		`x1,"Dejvická 12, Praha 6",,2+kk,,2024-03-01,,18000,3500,36000,ano,5,3,CZ6508000000192000145399,Jana Nováková,4321,,Petr Svoboda,,,0` + "\n"
	bad := good + `x2,"Dejvická 14, Praha 6",,,,2024-03-01,,nic,,,,5,,CZ6508000000192000145399,Jana,,,Eva,,,` + "\n"

	var out bytes.Buffer
	if err := importLeases(ctx, svc, name, strings.NewReader(bad), false, time.Now(), &out); err == nil ||
		!strings.Contains(out.String(), "line 3 (lease x2): rent") {
		t.Fatalf("bad row: %v\n%s", err, out.String())
	}
	if n := count(); n != 0 {
		t.Fatalf("a file with problems wrote %d leases", n)
	}

	out.Reset()
	if err := importLeases(ctx, svc, strings.ToUpper(name), strings.NewReader(good), true, time.Now(), &out); err != nil {
		t.Fatalf("dry run: %v\n%s", err, out.String())
	}
	if !strings.Contains(out.String(), "would import lease x1") || !strings.Contains(out.String(), "VS 4321") ||
		!strings.Contains(out.String(), "dry run: 1 leases") {
		t.Fatalf("dry run output:\n%s", out.String())
	}
	if n := count(); n != 0 {
		t.Fatalf("dry run wrote %d leases", n)
	}

	out.Reset()
	if err := importLeases(ctx, svc, o.ID.String(), strings.NewReader(good), false, time.Now(), &out); err != nil {
		t.Fatalf("import: %v\n%s", err, out.String())
	}
	if !strings.Contains(out.String(), "imported lease x1") || !strings.Contains(out.String(), "1 leases imported") {
		t.Fatalf("import output:\n%s", out.String())
	}
	var origin, state string
	if err := pool.QueryRow(ctx, "SELECT origin, state FROM leases WHERE org_id = $1", o.ID).Scan(&origin, &state); err != nil ||
		origin != "imported" || state != "active" {
		t.Fatalf("lease %s %s %v", origin, state, err)
	}
	if err := importLeases(ctx, svc, "no such organization "+name, strings.NewReader(good), true, time.Now(), &out); err == nil {
		t.Fatal("unknown organization accepted")
	}
}
