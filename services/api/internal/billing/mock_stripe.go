package billing

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"html/template"
	"io"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/google/uuid"
)

// MockStripe is the offline Stripe Checkout used by `make dev` and tests. Its
// checkout page is served by the API itself (Handler); paying signs a
// checkout.session.completed event with the webhook secret and delivers it.
type MockStripe struct {
	APIPublicURL  string // e.g. http://localhost:8080
	WebhookSecret string
	// Deliver sends a signed event to the webhook handler. Nil means HTTP POST
	// to <APIPublicURL>/v1/webhooks/stripe.
	Deliver func(ctx context.Context, payload []byte, sig string) error
	HTTP    *http.Client

	mu       sync.Mutex
	sessions map[string]*MockSession
}

// MockSession is a checkout session held by MockStripe.
type MockSession struct {
	ID     string
	Input  CheckoutInput
	Status string // open | processing | complete | canceled
}

// NewMockStripe creates the mock adapter.
func NewMockStripe(apiPublicURL, webhookSecret string) *MockStripe {
	return &MockStripe{APIPublicURL: strings.TrimRight(apiPublicURL, "/"), WebhookSecret: webhookSecret,
		HTTP: &http.Client{Timeout: 30 * time.Second}}
}

// CreateCheckout implements StripeClient.
func (m *MockStripe) CreateCheckout(_ context.Context, in CheckoutInput) (CheckoutSession, error) {
	id := "cs_mock_" + uuid.NewString()
	m.mu.Lock()
	defer m.mu.Unlock()
	if m.sessions == nil {
		m.sessions = map[string]*MockSession{}
	}
	m.sessions[id] = &MockSession{ID: id, Input: in, Status: "open"}
	return CheckoutSession{ID: id, URL: m.APIPublicURL + "/mock/stripe/checkout/" + id}, nil
}

// ParseWebhook implements StripeClient.
func (m *MockStripe) ParseWebhook(payload []byte, sigHeader string) (Event, error) {
	return ParseEvent(m.WebhookSecret, payload, sigHeader, time.Now())
}

// Session returns a copy of a session (tests and dev tools).
func (m *MockStripe) Session(id string) (MockSession, bool) {
	m.mu.Lock()
	defer m.mu.Unlock()
	s, ok := m.sessions[id]
	if !ok {
		return MockSession{}, false
	}
	return *s, true
}

// CompletedEvent builds a signed Stripe-shaped checkout.session.completed
// event for a session.
func (m *MockStripe) CompletedEvent(id string) (payload []byte, sig string, err error) {
	s, ok := m.Session(id)
	if !ok {
		return nil, "", fmt.Errorf("mock stripe: unknown session %q", id)
	}
	meta := map[string]string{"order_id": s.Input.OrderID}
	for k, v := range s.Input.Metadata {
		meta[k] = v
	}
	ev := map[string]any{
		"id": "evt_mock_" + uuid.NewString(), "object": "event", "type": EventCheckoutCompleted,
		"created": time.Now().Unix(), "livemode": false,
		"data": map[string]any{"object": map[string]any{
			"id": s.ID, "object": "checkout.session", "client_reference_id": s.Input.OrderID,
			"payment_status": "paid", "status": "complete", "amount_total": s.Input.AmountGross,
			"currency": strings.ToLower(s.Input.Currency), "customer_email": s.Input.CustomerEmail, "metadata": meta,
		}},
	}
	payload, err = json.Marshal(ev)
	if err != nil {
		return nil, "", err
	}
	return payload, SignWebhook(m.WebhookSecret, payload, time.Now()), nil
}

func (m *MockStripe) deliver(ctx context.Context, payload []byte, sig string) error {
	if m.Deliver != nil {
		return m.Deliver(ctx, payload, sig)
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, m.APIPublicURL+"/v1/webhooks/stripe", bytes.NewReader(payload))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Stripe-Signature", sig)
	client := m.HTTP
	if client == nil {
		client = http.DefaultClient
	}
	res, err := client.Do(req)
	if err != nil {
		return err
	}
	defer res.Body.Close()
	_, _ = io.Copy(io.Discard, io.LimitReader(res.Body, 1<<16))
	if res.StatusCode >= 300 {
		return fmt.Errorf("mock stripe: webhook returned %d", res.StatusCode)
	}
	return nil
}

var mockCheckoutPage = template.Must(template.New("checkout").Parse(`<!doctype html>
<html lang="cs"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Testovací platba kartou</title>
<style>body{font-family:system-ui,sans-serif;max-width:28rem;margin:3rem auto;padding:0 1rem;color:#111;background:#fff}
.box{border:1px solid #ccc;border-radius:.5rem;padding:1.5rem}.amount{font-size:2rem;font-weight:700;margin:.5rem 0}
.note{color:#555;font-size:.9rem}button{font-size:1rem;padding:.6rem 1.2rem;margin-right:.5rem;border-radius:.4rem;border:1px solid #333;cursor:pointer}
button.pay{background:#111;color:#fff}form{display:inline}</style></head>
<body><main class="box" aria-labelledby="h">
<h1 id="h">Testovací platba kartou</h1>
<p class="note">Simulace Stripe Checkout pro vývoj. Žádné peníze se nepřevádějí.</p>
<p>{{.Description}}</p>
<p class="amount" aria-label="Částka k úhradě">{{.Amount}}</p>
{{if eq .Status "open"}}
<form method="post" action="/mock/stripe/checkout/{{.ID}}/pay"><button class="pay" type="submit" aria-label="Zaplatit {{.Amount}}">Zaplatit</button></form>
<form method="post" action="/mock/stripe/checkout/{{.ID}}/cancel"><button type="submit" aria-label="Zrušit platbu">Zrušit</button></form>
{{else}}<p role="status">Platba je ve stavu: {{.Status}}</p>{{end}}
</main></body></html>`))

// Handler serves the mock checkout page:
//
//	GET  /mock/stripe/checkout/{id}
//	POST /mock/stripe/checkout/{id}/pay     delivers the signed event, 303 to SuccessURL
//	POST /mock/stripe/checkout/{id}/cancel  303 to CancelURL
func (m *MockStripe) Handler() http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /mock/stripe/checkout/{id}", func(w http.ResponseWriter, r *http.Request) {
		s, ok := m.Session(r.PathValue("id"))
		if !ok {
			http.NotFound(w, r)
			return
		}
		w.Header().Set("Content-Type", "text/html; charset=utf-8")
		_ = mockCheckoutPage.Execute(w, map[string]string{"ID": s.ID, "Description": s.Input.Description,
			"Amount": FormatAmount(s.Input.AmountGross, s.Input.Currency), "Status": s.Status})
	})
	mux.HandleFunc("POST /mock/stripe/checkout/{id}/pay", func(w http.ResponseWriter, r *http.Request) {
		id := r.PathValue("id")
		s, ok := m.Session(id)
		if !ok {
			http.NotFound(w, r)
			return
		}
		if m.transition(id, "open", "processing") {
			payload, sig, err := m.CompletedEvent(id)
			if err == nil {
				err = m.deliver(r.Context(), payload, sig)
			}
			if err != nil {
				m.transition(id, "processing", "open")
				http.Error(w, "mock stripe: webhook delivery failed: "+err.Error(), http.StatusBadGateway)
				return
			}
			m.transition(id, "processing", "complete")
		}
		http.Redirect(w, r, s.Input.SuccessURL, http.StatusSeeOther)
	})
	mux.HandleFunc("POST /mock/stripe/checkout/{id}/cancel", func(w http.ResponseWriter, r *http.Request) {
		id := r.PathValue("id")
		s, ok := m.Session(id)
		if !ok {
			http.NotFound(w, r)
			return
		}
		m.transition(id, "open", "canceled")
		http.Redirect(w, r, s.Input.CancelURL, http.StatusSeeOther)
	})
	return mux
}

// transition moves a session from one status to another; false when the
// session is not in the expected status (so a double click pays once).
func (m *MockStripe) transition(id, from, to string) bool {
	m.mu.Lock()
	defer m.mu.Unlock()
	s, ok := m.sessions[id]
	if !ok || s.Status != from {
		return false
	}
	s.Status = to
	return true
}
