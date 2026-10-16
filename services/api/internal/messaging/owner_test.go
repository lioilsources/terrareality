package messaging

import (
	"bytes"
	"testing"

	"github.com/google/uuid"

	"github.com/terrareality/terrareality/services/api/internal/db"
)

func TestContentMatchesSniffsHEIC(t *testing.T) {
	heic := append([]byte{0, 0, 0, 0x18}, []byte("ftypheic\x00\x00\x00\x00mif1heic")...)
	html := []byte("<!doctype html><script>alert(1)</script>")
	if !contentMatches("image/heic", heic) {
		t.Fatal("real HEIC rejected")
	}
	if contentMatches("image/heic", html) {
		t.Fatal("HTML accepted as HEIC")
	}
	if contentMatches("image/heic", []byte("ftyp")) {
		t.Fatal("truncated header accepted")
	}
	if contentMatches("image/heic", append([]byte{0, 0, 0, 0x18}, []byte("ftypisom")...)) {
		t.Fatal("MP4 accepted as HEIC")
	}
	if !contentMatches("application/pdf", []byte("%PDF-1.7\n")) || contentMatches("application/pdf", html) {
		t.Fatal("PDF sniffing")
	}
	if contentMatches("image/png", bytes.Repeat([]byte("a"), 64)) {
		t.Fatal("text accepted as PNG")
	}
}

func TestCanUnblock(t *testing.T) {
	seeker, agent, colleague := uuid.New(), uuid.New(), uuid.New()
	byOrg := db.Conversation{SeekerID: seeker, BlockedBy: &agent}
	bySeeker := db.Conversation{SeekerID: seeker, BlockedBy: &seeker}
	cases := []struct {
		name string
		c    db.Conversation
		role string
		user uuid.UUID
		want bool
	}{
		{"blocker agent", byOrg, RoleOwner, agent, true},
		{"colleague of the blocking agent", byOrg, RoleOwner, colleague, true},
		{"seeker cannot lift the org's block", byOrg, RoleSeeker, seeker, false},
		{"seeker lifts own block", bySeeker, RoleSeeker, seeker, true},
		{"org cannot lift the seeker's block", bySeeker, RoleOwner, agent, false},
		{"not blocked", db.Conversation{SeekerID: seeker}, RoleSeeker, seeker, true},
	}
	for _, c := range cases {
		if got := canUnblock(c.c, c.role, c.user); got != c.want {
			t.Errorf("%s: %v", c.name, got)
		}
	}
}

func TestLastOtherSender(t *testing.T) {
	seeker, agent, other := uuid.New(), uuid.New(), uuid.New()
	rows := []db.ListMessagesRow{{SenderID: &seeker}, {SenderID: nil}, {SenderID: &agent}, {SenderID: &other}}
	if got := lastOtherSender(rows, seeker); got == nil || *got != agent {
		t.Fatalf("got %v", got)
	}
	if got := lastOtherSender([]db.ListMessagesRow{{SenderID: &seeker}}, seeker); got != nil {
		t.Fatalf("seeker-only thread: %v", got)
	}
}
