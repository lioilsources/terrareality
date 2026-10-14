// Package notify renders localized e-mail and SMS messages and delivers them
// through a transactional outbox (a River job inserted in the same database
// transaction as the change that triggered it).
package notify

import (
	"bytes"
	"context"
	"embed"
	"encoding/json"
	"fmt"
	"html"
	"regexp"
	"strings"
	"sync"
	"text/template"

	"github.com/jackc/pgx/v5"
)

// Channels.
const (
	Email = "email"
	SMS   = "sms"
)

// Message is a rendered message ready for delivery.
type Message struct {
	Channel  string `json:"channel"`
	To       string `json:"to"`
	Template string `json:"template"`
	Subject  string `json:"subject"`
	Text     string `json:"text"`
	HTML     string `json:"html,omitempty"`
}

// Outbox enqueues messages inside a transaction.
type Outbox interface {
	Enqueue(ctx context.Context, tx pgx.Tx, msg Message) error
}

//go:embed messages/*.json
var messageFS embed.FS

type tmpl struct{ subject, text *template.Template }

// Renderer renders message templates for a locale (cs falls back for unknown locales).
type Renderer struct{ byLocale map[string]map[string]tmpl }

// NewRenderer parses the embedded templates.
func NewRenderer() (*Renderer, error) {
	r := &Renderer{byLocale: map[string]map[string]tmpl{}}
	for _, loc := range []string{"cs", "en"} {
		raw, err := messageFS.ReadFile("messages/" + loc + ".json")
		if err != nil {
			return nil, err
		}
		var defs map[string]struct{ Subject, Text string }
		if err := json.Unmarshal(raw, &defs); err != nil {
			return nil, fmt.Errorf("messages/%s.json: %w", loc, err)
		}
		r.byLocale[loc] = map[string]tmpl{}
		for key, d := range defs {
			s, err := template.New(key).Parse(d.Subject)
			if err != nil {
				return nil, err
			}
			t, err := template.New(key).Parse(d.Text)
			if err != nil {
				return nil, err
			}
			r.byLocale[loc][key] = tmpl{s, t}
		}
	}
	for key := range r.byLocale["cs"] {
		if _, ok := r.byLocale["en"][key]; !ok {
			return nil, fmt.Errorf("message %q missing in en", key)
		}
	}
	return r, nil
}

// Render builds a message for channel/to from template key.
func (r *Renderer) Render(channel, to, locale, key string, data any) (Message, error) {
	set, ok := r.byLocale[locale]
	if !ok {
		set = r.byLocale["cs"]
	}
	t, ok := set[key]
	if !ok {
		return Message{}, fmt.Errorf("unknown message %q", key)
	}
	var subj, body bytes.Buffer
	if err := t.subject.Execute(&subj, data); err != nil {
		return Message{}, err
	}
	if err := t.text.Execute(&body, data); err != nil {
		return Message{}, err
	}
	m := Message{Channel: channel, To: to, Template: key, Subject: subj.String(), Text: body.String()}
	if channel == Email {
		m.HTML = toHTML(m.Text)
	}
	return m, nil
}

var urlRe = regexp.MustCompile(`https?://[^\s]+|terra://[^\s]+`)

// toHTML turns the plain text body into minimal, escaped HTML with links.
func toHTML(text string) string {
	var b strings.Builder
	b.WriteString(`<!doctype html><html><body style="font-family:system-ui,sans-serif;line-height:1.5;color:#1c1917">`)
	for _, para := range strings.Split(text, "\n\n") {
		esc := html.EscapeString(para)
		esc = urlRe.ReplaceAllStringFunc(esc, func(u string) string {
			return `<a href="` + u + `" style="color:#0f766e">` + u + `</a>`
		})
		b.WriteString("<p>" + strings.ReplaceAll(esc, "\n", "<br>") + "</p>")
	}
	b.WriteString("</body></html>")
	return b.String()
}

// MemoryOutbox collects messages in memory (tests).
type MemoryOutbox struct {
	mu   sync.Mutex
	msgs []Message
}

// Enqueue implements Outbox.
func (o *MemoryOutbox) Enqueue(_ context.Context, _ pgx.Tx, m Message) error {
	o.mu.Lock()
	defer o.mu.Unlock()
	o.msgs = append(o.msgs, m)
	return nil
}

// Last returns the newest message to a recipient with the template key.
func (o *MemoryOutbox) Last(to, key string) (Message, bool) {
	o.mu.Lock()
	defer o.mu.Unlock()
	for i := len(o.msgs) - 1; i >= 0; i-- {
		if strings.EqualFold(o.msgs[i].To, to) && o.msgs[i].Template == key {
			return o.msgs[i], true
		}
	}
	return Message{}, false
}

// All returns all messages to a recipient with the template key.
func (o *MemoryOutbox) All(to, key string) []Message {
	o.mu.Lock()
	defer o.mu.Unlock()
	var out []Message
	for _, m := range o.msgs {
		if strings.EqualFold(m.To, to) && m.Template == key {
			out = append(out, m)
		}
	}
	return out
}

// LinkToken extracts the token query parameter from the first link in text.
func LinkToken(text string) string {
	u := urlRe.FindString(text)
	if i := strings.Index(u, "token="); i >= 0 {
		t := u[i+len("token="):]
		if j := strings.IndexAny(t, "&#"); j >= 0 {
			t = t[:j]
		}
		return t
	}
	if i := strings.LastIndex(u, "/"); i >= 0 {
		return u[i+1:]
	}
	return ""
}
