package main

import (
	"context"
	"fmt"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/terrareality/terrareality/services/api/internal/db"
	"github.com/terrareality/terrareality/services/api/internal/notify"
	platformdb "github.com/terrareality/terrareality/services/api/internal/platform/db"
	"github.com/terrareality/terrareality/services/api/internal/platform/tokens"
)

func TestParseOwnersCSV(t *testing.T) {
	in := "\ufeffemail;name;org;locale\n" +
		"Jana@Example.cz; Jana Nováková ;Nováková Reality;\n" +
		"\n" +
		"petr@example.cz;Petr Svoboda;;en\n"
	got, err := parseOwnersCSV(strings.NewReader(in))
	if err != nil {
		t.Fatal(err)
	}
	want := []pilotOwner{
		{Email: "jana@example.cz", Name: "Jana Nováková", Org: "Nováková Reality", Locale: "cs"},
		{Email: "petr@example.cz", Name: "Petr Svoboda", Org: "Petr Svoboda", Locale: "en"},
	}
	if len(got) != len(want) {
		t.Fatalf("got %+v", got)
	}
	for i := range want {
		if got[i] != want[i] {
			t.Errorf("row %d: got %+v, want %+v", i, got[i], want[i])
		}
	}
}

func TestParseOwnersCSVRejectsBadRows(t *testing.T) {
	for name, in := range map[string]string{
		"missing column": "email,name\na@b.cz,A\n",
		"bad e-mail":     "email,name,org\nnot-an-email,A,B\n",
		"no name":        "email,name,org\na@b.cz,,\n",
		"duplicate":      "email,name,org\na@b.cz,A,B\nA@B.cz,C,D\n",
	} {
		if _, err := parseOwnersCSV(strings.NewReader(in)); err == nil {
			t.Errorf("%s: expected an error", name)
		}
	}
}

// TestOnboardCreatesInvitedOrganization needs a database (TEST_DATABASE_URL).
func TestOnboardCreatesInvitedOrganization(t *testing.T) {
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
	render, err := notify.NewRenderer()
	if err != nil {
		t.Fatal(err)
	}
	box := &notify.MemoryOutbox{}
	ob := onboarder{Pool: pool, Outbox: box, Render: render, WebBaseURL: "http://web.test"}
	email := fmt.Sprintf("pilot-%d@example.cz", time.Now().UnixNano())
	p, err := validOwner(pilotOwner{Email: email, Name: "Pilot Owner", Org: "Pilot Reality"})
	if err != nil {
		t.Fatal(err)
	}
	created, err := ob.Onboard(ctx, p)
	if err != nil || !created {
		t.Fatalf("created=%v err=%v", created, err)
	}
	msg, ok := box.Last(email, "invitation")
	if !ok || !strings.Contains(msg.Text, "http://web.test/invite/") || !strings.Contains(msg.Text, "Pilot Reality") {
		t.Fatalf("invitation e-mail: %+v", msg)
	}
	inv, err := db.New(pool).GetInvitationByToken(ctx, tokens.Hash(notify.LinkToken(msg.Text)))
	if err != nil {
		t.Fatal(err)
	}
	if inv.Role != "owner" || inv.Email != email || inv.InvitedBy != nil || inv.OrgName != "Pilot Reality" {
		t.Fatalf("invitation %+v", inv)
	}
	members, err := db.New(pool).ListMembers(ctx, inv.OrgID)
	if err != nil || len(members) != 0 {
		t.Fatalf("organization must start without members: %v %v", members, err)
	}
}
