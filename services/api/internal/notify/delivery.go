package notify

import (
	"context"
	"fmt"
	"log/slog"
	"mime"
	"net/smtp"
	"strings"
	"time"

	"github.com/google/uuid"
)

// Sender delivers one message.
type Sender interface {
	Send(ctx context.Context, m Message) error
}

// SMTP sends e-mail through an SMTP relay (Mailpit in dev, a transactional
// provider in production). net/smtp upgrades to STARTTLS when offered.
type SMTP struct {
	Addr string
	From string
	Auth smtp.Auth
}

// Send implements Sender.
func (s *SMTP) Send(_ context.Context, m Message) error {
	boundary := "terra-" + uuid.NewString()
	from := s.From
	addr := from
	if i := strings.LastIndex(from, "<"); i >= 0 {
		addr = strings.Trim(from[i:], "<>")
	}
	var b strings.Builder
	h := func(k, v string) { b.WriteString(k + ": " + v + "\r\n") }
	h("From", from)
	h("To", m.To)
	h("Subject", mime.QEncoding.Encode("utf-8", m.Subject))
	h("Date", time.Now().Format(time.RFC1123Z))
	h("Message-ID", "<"+uuid.NewString()+"@terrareality>")
	h("MIME-Version", "1.0")
	h("Content-Type", `multipart/alternative; boundary="`+boundary+`"`)
	b.WriteString("\r\n")
	part := func(ct, body string) {
		b.WriteString("--" + boundary + "\r\nContent-Type: " + ct + "; charset=utf-8\r\nContent-Transfer-Encoding: 8bit\r\n\r\n")
		b.WriteString(strings.ReplaceAll(body, "\n", "\r\n") + "\r\n")
	}
	part("text/plain", m.Text)
	if m.HTML != "" {
		part("text/html", m.HTML)
	}
	b.WriteString("--" + boundary + "--\r\n")
	return smtp.SendMail(s.Addr, s.Auth, addr, []string{m.To}, []byte(b.String()))
}

// Log writes messages to the log instead of delivering them.
type Log struct{ L *slog.Logger }

// Send implements Sender.
func (l Log) Send(_ context.Context, m Message) error {
	l.L.Info("message (not delivered)", "channel", m.Channel, "to", m.To, "template", m.Template, "subject", m.Subject)
	return nil
}

// SMSViaEmail is the mock SMS provider: each SMS becomes an e-mail to
// sms+<number>@sms.terra.local so it shows up in Mailpit next to other mail.
type SMSViaEmail struct{ Email Sender }

// Send implements Sender.
func (s SMSViaEmail) Send(ctx context.Context, m Message) error {
	digits := strings.TrimPrefix(m.To, "+")
	return s.Email.Send(ctx, Message{Channel: Email, To: "sms+" + digits + "@sms.terra.local",
		Template: m.Template, Subject: "SMS " + m.To, Text: m.Text})
}

// Router picks the sender by channel.
type Router struct{ Email, SMS Sender }

// Send implements Sender.
func (r Router) Send(ctx context.Context, m Message) error {
	switch m.Channel {
	case Email:
		return r.Email.Send(ctx, m)
	case SMS:
		return r.SMS.Send(ctx, m)
	}
	return fmt.Errorf("unknown channel %q", m.Channel)
}
