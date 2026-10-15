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

// RevolutAPIVersion is the Merchant API version the adapter speaks.
const RevolutAPIVersion = "2024-09-01"

// Revolut Merchant API base URLs.
const (
	RevolutSandboxURL = "https://sandbox-merchant.revolut.com"
	RevolutLiveURL    = "https://merchant.revolut.com"
)

// RevolutOrderInput is a payment order in the landlord's own merchant account.
type RevolutOrderInput struct {
	Amount           int64 // minor units
	Currency         string
	Description      string
	MerchantOrderRef string     // our payment link / obligation share reference
	ExpiresAt        *time.Time // optional; pending orders expire after this time
}

// RevolutOrder is the created order.
type RevolutOrder struct {
	ID          string
	CheckoutURL string
	State       string // pending | authorised | completed | ...
}

// RevolutMerchant creates orders with the landlord's Revolut Business merchant
// API key. The money goes straight to the landlord (ADR 0002); the platform
// only creates the payment link.
type RevolutMerchant interface {
	CreateOrder(ctx context.Context, apiKey string, in RevolutOrderInput) (RevolutOrder, error)
}

// RevolutHTTP is the live Revolut Merchant API adapter.
type RevolutHTTP struct {
	BaseURL string // RevolutSandboxURL or RevolutLiveURL
	HTTP    *http.Client
}

// NewRevolutHTTP creates the adapter.
func NewRevolutHTTP(baseURL string) *RevolutHTTP {
	if baseURL == "" {
		baseURL = RevolutSandboxURL
	}
	return &RevolutHTTP{BaseURL: strings.TrimRight(baseURL, "/"), HTTP: &http.Client{Timeout: 30 * time.Second}}
}

// CreateOrder implements RevolutMerchant.
func (r *RevolutHTTP) CreateOrder(ctx context.Context, apiKey string, in RevolutOrderInput) (RevolutOrder, error) {
	body := map[string]any{"amount": in.Amount, "currency": strings.ToUpper(in.Currency), "description": in.Description}
	if in.MerchantOrderRef != "" {
		body["merchant_order_data"] = map[string]string{"reference": in.MerchantOrderRef}
	}
	if in.ExpiresAt != nil {
		if secs := int64(time.Until(*in.ExpiresAt).Seconds()); secs > 0 {
			body["expire_pending_after"] = fmt.Sprintf("PT%dS", secs)
		}
	}
	raw, _ := json.Marshal(body)
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, strings.TrimRight(r.BaseURL, "/")+"/api/orders", bytes.NewReader(raw))
	if err != nil {
		return RevolutOrder{}, err
	}
	req.Header.Set("Authorization", "Bearer "+apiKey)
	req.Header.Set("Revolut-Api-Version", RevolutAPIVersion)
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Accept", "application/json")
	client := r.HTTP
	if client == nil {
		client = http.DefaultClient
	}
	res, err := client.Do(req)
	if err != nil {
		return RevolutOrder{}, fmt.Errorf("revolut: %w", err)
	}
	defer res.Body.Close()
	out, _ := io.ReadAll(io.LimitReader(res.Body, 1<<20))
	if res.StatusCode >= 300 {
		return RevolutOrder{}, fmt.Errorf("revolut create order: status %d: %.300s", res.StatusCode, out)
	}
	var o struct {
		ID          string `json:"id"`
		CheckoutURL string `json:"checkout_url"`
		State       string `json:"state"`
	}
	if err := json.Unmarshal(out, &o); err != nil {
		return RevolutOrder{}, fmt.Errorf("revolut: decode order: %w", err)
	}
	return RevolutOrder{ID: o.ID, CheckoutURL: o.CheckoutURL, State: o.State}, nil
}

// MockRevolut creates sandbox orders served by the API itself (no money moves).
type MockRevolut struct {
	APIPublicURL string

	mu     sync.Mutex
	orders map[string]RevolutOrderInput
}

// NewMockRevolut creates the mock adapter.
func NewMockRevolut(apiPublicURL string) *MockRevolut {
	return &MockRevolut{APIPublicURL: strings.TrimRight(apiPublicURL, "/")}
}

// CreateOrder implements RevolutMerchant.
func (m *MockRevolut) CreateOrder(_ context.Context, apiKey string, in RevolutOrderInput) (RevolutOrder, error) {
	if apiKey == "" {
		return RevolutOrder{}, fmt.Errorf("revolut: missing api key")
	}
	id := "rev_mock_" + uuid.NewString()
	m.mu.Lock()
	defer m.mu.Unlock()
	if m.orders == nil {
		m.orders = map[string]RevolutOrderInput{}
	}
	m.orders[id] = in
	return RevolutOrder{ID: id, CheckoutURL: m.APIPublicURL + "/mock/revolut/pay/" + id, State: "pending"}, nil
}

var mockRevolutPage = template.Must(template.New("revolut").Parse(`<!doctype html>
<html lang="cs"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Sandbox platba</title>
<style>body{font-family:system-ui,sans-serif;max-width:28rem;margin:3rem auto;padding:0 1rem;color:#111;background:#fff}
.box{border:1px solid #ccc;border-radius:.5rem;padding:1.5rem}.amount{font-size:2rem;font-weight:700;margin:.5rem 0}.note{color:#555;font-size:.9rem}</style></head>
<body><main class="box" aria-labelledby="h">
<h1 id="h">Sandbox platba</h1>
<p class="note">Simulace platební stránky Revolut Business pronajímatele. Žádné peníze se nepřevádějí.</p>
<p>{{.Description}}</p>
<p class="amount" aria-label="Částka k úhradě">{{.Amount}}</p>
<p>Reference: {{.Ref}}</p>
</main></body></html>`))

// Handler serves GET /mock/revolut/pay/{id}.
func (m *MockRevolut) Handler() http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /mock/revolut/pay/{id}", func(w http.ResponseWriter, r *http.Request) {
		m.mu.Lock()
		o, ok := m.orders[r.PathValue("id")]
		m.mu.Unlock()
		if !ok {
			http.NotFound(w, r)
			return
		}
		w.Header().Set("Content-Type", "text/html; charset=utf-8")
		_ = mockRevolutPage.Execute(w, map[string]string{"Description": o.Description,
			"Amount": FormatAmount(o.Amount, o.Currency), "Ref": o.MerchantOrderRef})
	})
	return mux
}
