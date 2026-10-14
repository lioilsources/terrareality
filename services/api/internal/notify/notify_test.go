package notify

import (
	"strings"
	"testing"
)

func TestRenderLocalesAndLinks(t *testing.T) {
	r, err := NewRenderer()
	if err != nil {
		t.Fatal(err)
	}
	link := "http://localhost:5173/auth/magic?token=abc_DEF-123"
	cs, err := r.Render(Email, "a@b.cz", "cs", "magic_link", map[string]any{"Link": link})
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(cs.Subject, "Přihlášení") || !strings.Contains(cs.HTML, `<a href="`+link) {
		t.Fatalf("cs render: %+v", cs)
	}
	en, _ := r.Render(Email, "a@b.cz", "en", "magic_link", map[string]any{"Link": link})
	if !strings.HasPrefix(en.Subject, "Sign in") {
		t.Fatalf("en subject %q", en.Subject)
	}
	if LinkToken(cs.Text) != "abc_DEF-123" {
		t.Fatalf("token %q", LinkToken(cs.Text))
	}
	x, _ := r.Render(Email, "a@b.cz", "en", "invitation", map[string]any{"OrgName": "<b>Evil</b>", "InviterName": "A", "Role": "agent", "Link": link})
	if strings.Contains(x.HTML, "<b>Evil</b>") {
		t.Fatal("html not escaped")
	}
}
