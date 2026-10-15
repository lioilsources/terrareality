// Package billing holds the payment adapters for platform services (Stripe
// Checkout for promotions, ADR 0002: the platform only charges for its own
// services) and the landlord's own Revolut Business merchant account (money
// goes landlord-direct), plus VAT and invoice helpers. The adapters and
// helpers are pure; Service (service.go) adds the database-backed flows.
package billing

import (
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"sort"
	"strconv"
	"strings"
	"time"
)

// CheckoutInput describes one Stripe Checkout payment for an order.
type CheckoutInput struct {
	OrderID       string
	Description   string
	AmountGross   int64 // minor units including VAT
	Currency      string
	CustomerEmail string
	SuccessURL    string
	CancelURL     string
	Metadata      map[string]string
}

// CheckoutSession is the created Stripe Checkout session.
type CheckoutSession struct {
	ID  string
	URL string
}

// Event is the part of a Stripe webhook event the platform needs.
type Event struct {
	ID            string
	Type          string
	SessionID     string
	OrderID       string // metadata.order_id, falling back to client_reference_id
	PaymentStatus string // paid | unpaid | no_payment_required
}

// Event types handled by the platform.
const (
	EventCheckoutCompleted      = "checkout.session.completed"
	EventCheckoutExpired        = "checkout.session.expired"
	EventCheckoutAsyncSucceeded = "checkout.session.async_payment_succeeded"
	EventCheckoutAsyncFailed    = "checkout.session.async_payment_failed"
)

// StripeClient creates Checkout sessions and verifies webhooks.
type StripeClient interface {
	CreateCheckout(ctx context.Context, in CheckoutInput) (CheckoutSession, error)
	ParseWebhook(payload []byte, sigHeader string) (Event, error)
}

// Webhook signature errors.
var (
	ErrInvalidSignature = errors.New("stripe: invalid webhook signature")
	ErrExpiredSignature = errors.New("stripe: webhook timestamp outside tolerance")
)

// WebhookTolerance is the maximum age (and clock skew) of a signed webhook.
const WebhookTolerance = 5 * time.Minute

// SignWebhook returns a Stripe-Signature header value for payload.
func SignWebhook(secret string, payload []byte, t time.Time) string {
	ts := strconv.FormatInt(t.Unix(), 10)
	return "t=" + ts + ",v1=" + signature(secret, ts, payload)
}

func signature(secret, ts string, payload []byte) string {
	mac := hmac.New(sha256.New, []byte(secret))
	mac.Write([]byte(ts))
	mac.Write([]byte("."))
	mac.Write(payload)
	return hex.EncodeToString(mac.Sum(nil))
}

// VerifyWebhook checks a Stripe-Signature header (t=...,v1=...) against payload.
func VerifyWebhook(secret string, payload []byte, header string, now time.Time) error {
	var ts string
	var sigs []string
	for _, part := range strings.Split(header, ",") {
		k, v, ok := strings.Cut(strings.TrimSpace(part), "=")
		if !ok {
			continue
		}
		switch k {
		case "t":
			ts = v
		case "v1":
			sigs = append(sigs, v)
		}
	}
	if ts == "" || len(sigs) == 0 || secret == "" {
		return ErrInvalidSignature
	}
	sec, err := strconv.ParseInt(ts, 10, 64)
	if err != nil {
		return ErrInvalidSignature
	}
	want := []byte(signature(secret, ts, payload))
	match := false
	for _, s := range sigs {
		if hmac.Equal(want, []byte(s)) {
			match = true
		}
	}
	if !match {
		return ErrInvalidSignature
	}
	if d := now.Sub(time.Unix(sec, 0)); d > WebhookTolerance || d < -WebhookTolerance {
		return ErrExpiredSignature
	}
	return nil
}

type stripeEvent struct {
	ID   string `json:"id"`
	Type string `json:"type"`
	Data struct {
		Object struct {
			ID                string            `json:"id"`
			ClientReferenceID string            `json:"client_reference_id"`
			PaymentStatus     string            `json:"payment_status"`
			Metadata          map[string]string `json:"metadata"`
		} `json:"object"`
	} `json:"data"`
}

// ParseEvent verifies the signature and decodes a webhook payload.
func ParseEvent(secret string, payload []byte, sigHeader string, now time.Time) (Event, error) {
	if err := VerifyWebhook(secret, payload, sigHeader, now); err != nil {
		return Event{}, err
	}
	var e stripeEvent
	if err := json.Unmarshal(payload, &e); err != nil {
		return Event{}, fmt.Errorf("stripe: decode event: %w", err)
	}
	o := e.Data.Object
	order := o.Metadata["order_id"]
	if order == "" {
		order = o.ClientReferenceID
	}
	return Event{ID: e.ID, Type: e.Type, SessionID: o.ID, OrderID: order, PaymentStatus: o.PaymentStatus}, nil
}

// StripeHTTP talks to the Stripe API with plain HTTP (no SDK).
type StripeHTTP struct {
	BaseURL       string // default https://api.stripe.com
	SecretKey     string
	WebhookSecret string
	HTTP          *http.Client
	Now           func() time.Time // for tests; default time.Now
}

// NewStripeHTTP creates the live adapter.
func NewStripeHTTP(secretKey, webhookSecret string) *StripeHTTP {
	return &StripeHTTP{BaseURL: "https://api.stripe.com", SecretKey: secretKey, WebhookSecret: webhookSecret,
		HTTP: &http.Client{Timeout: 30 * time.Second}}
}

// CreateCheckout implements StripeClient.
func (s *StripeHTTP) CreateCheckout(ctx context.Context, in CheckoutInput) (CheckoutSession, error) {
	f := checkoutForm(in)
	base := s.BaseURL
	if base == "" {
		base = "https://api.stripe.com"
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, base+"/v1/checkout/sessions", strings.NewReader(f.Encode()))
	if err != nil {
		return CheckoutSession{}, err
	}
	req.SetBasicAuth(s.SecretKey, "")
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	if in.OrderID != "" {
		req.Header.Set("Idempotency-Key", "checkout-"+in.OrderID)
	}
	client := s.HTTP
	if client == nil {
		client = http.DefaultClient
	}
	res, err := client.Do(req)
	if err != nil {
		return CheckoutSession{}, fmt.Errorf("stripe: %w", err)
	}
	defer res.Body.Close()
	raw, _ := io.ReadAll(io.LimitReader(res.Body, 1<<20))
	if res.StatusCode >= 300 {
		return CheckoutSession{}, fmt.Errorf("stripe create checkout: status %d: %.300s", res.StatusCode, raw)
	}
	var out struct {
		ID  string `json:"id"`
		URL string `json:"url"`
	}
	if err := json.Unmarshal(raw, &out); err != nil {
		return CheckoutSession{}, fmt.Errorf("stripe: decode session: %w", err)
	}
	return CheckoutSession{ID: out.ID, URL: out.URL}, nil
}

func checkoutForm(in CheckoutInput) url.Values {
	f := url.Values{}
	f.Set("mode", "payment")
	// Card only: the invoice says "paid by card" and the order is fulfilled
	// on checkout.session.completed (async methods are handled, but must not
	// appear by a dashboard switch).
	f.Set("payment_method_types[0]", "card")
	f.Set("success_url", in.SuccessURL)
	f.Set("cancel_url", in.CancelURL)
	f.Set("client_reference_id", in.OrderID)
	if in.CustomerEmail != "" {
		f.Set("customer_email", in.CustomerEmail)
	}
	f.Set("line_items[0][quantity]", "1")
	f.Set("line_items[0][price_data][currency]", strings.ToLower(in.Currency))
	f.Set("line_items[0][price_data][unit_amount]", strconv.FormatInt(in.AmountGross, 10))
	f.Set("line_items[0][price_data][product_data][name]", in.Description)
	meta := map[string]string{"order_id": in.OrderID}
	for k, v := range in.Metadata {
		meta[k] = v
	}
	keys := make([]string, 0, len(meta))
	for k := range meta {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	for _, k := range keys {
		f.Set("metadata["+k+"]", meta[k])
		f.Set("payment_intent_data[metadata]["+k+"]", meta[k])
	}
	return f
}

// ParseWebhook implements StripeClient.
func (s *StripeHTTP) ParseWebhook(payload []byte, sigHeader string) (Event, error) {
	now := time.Now
	if s.Now != nil {
		now = s.Now
	}
	return ParseEvent(s.WebhookSecret, payload, sigHeader, now())
}
