package integration

import (
	"bytes"
	"context"
	"encoding/json"
	"io"
	"net/http"
	"os/exec"
	"regexp"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/terrareality/terrareality/services/api/internal/billing"
)

type promoProductDTO struct {
	ID          uuid.UUID `json:"id"`
	Code        string    `json:"code"`
	Kind        string    `json:"kind"`
	NetAmount   int64     `json:"net_amount"`
	VatAmount   int64     `json:"vat_amount"`
	GrossAmount int64     `json:"gross_amount"`
	VatRateBp   int       `json:"vat_rate_bp"`
}

type orderDTO struct {
	ID          uuid.UUID  `json:"id"`
	ListingID   uuid.UUID  `json:"listing_id"`
	Status      string     `json:"status"`
	ProductCode string     `json:"product_code"`
	GrossAmount int64      `json:"gross_amount"`
	InvoiceID   *uuid.UUID `json:"invoice_id"`
	PaidAt      *time.Time `json:"paid_at"`
}

type invoiceDTO struct {
	ID          uuid.UUID `json:"id"`
	Number      string    `json:"number"`
	OrderID     uuid.UUID `json:"order_id"`
	GrossAmount int64     `json:"gross_amount"`
	VatAmount   int64     `json:"vat_amount"`
}

type promoSearch struct {
	Total int `json:"total"`
	Items []struct {
		ID          uuid.UUID `json:"id"`
		Promoted    bool      `json:"promoted"`
		Highlighted bool      `json:"highlighted"`
	} `json:"items"`
}

// postWebhook posts a raw Stripe event the way Stripe does.
func (e *env) postWebhook(payload []byte, sig string) int {
	e.t.Helper()
	req, _ := http.NewRequest("POST", e.srv.URL+"/v1/webhooks/stripe", bytes.NewReader(payload))
	req.Header.Set("Content-Type", "application/json; charset=utf-8")
	req.Header.Set("Stripe-Signature", sig)
	res, err := http.DefaultClient.Do(req)
	if err != nil {
		e.t.Fatal(err)
	}
	defer res.Body.Close()
	_, _ = io.Copy(io.Discard, res.Body)
	return res.StatusCode
}

func checkoutEvent(t *testing.T, eventID, sessionID string, orderID uuid.UUID) []byte {
	t.Helper()
	b, err := json.Marshal(map[string]any{"id": eventID, "object": "event", "type": billing.EventCheckoutCompleted,
		"data": map[string]any{"object": map[string]any{"id": sessionID, "object": "checkout.session",
			"client_reference_id": orderID.String(), "payment_status": "paid", "status": "complete",
			"metadata": map[string]string{"order_id": orderID.String()}}}})
	if err != nil {
		t.Fatal(err)
	}
	return b
}

// Acceptance M7 (billing): an owner buys a 7-day top placement by card (mock
// Stripe); the signed webhook marks the order paid, creates the promotion,
// moves the listing first in search with the "Promoted" label and issues an
// invoice that is e-mailed; a repeated webhook changes nothing; a bad
// signature is refused; another organization sees none of it.
func TestPromoCheckoutAndInvoice(t *testing.T) {
	e := newEnv(t)
	ctx := context.Background()
	tok, orgID := e.ownerOrg("promo-owner")
	staff := e.staffToken()
	orgPath := "/v1/orgs/" + orgID.String()
	token := "Promo" + strings.ReplaceAll(uuid.NewString()[:8], "-", "")
	mine := e.publishFlat(tok, orgID, staff, "Byt "+token+" topovaný", "approximate")
	// Published later, so it would come first without the promotion.
	otherTok, otherOrg := e.ownerOrg("promo-rival")
	rival := e.publishFlat(otherTok, otherOrg, staff, "Byt "+token+" konkurence", "approximate")

	var products struct {
		Items []promoProductDTO `json:"items"`
	}
	e.must(200, "GET", "/v1/promo-products", "", nil, &products)
	var top promoProductDTO
	for _, p := range products.Items {
		if p.Code == "top_7d" {
			top = p
		}
	}
	if top.Code == "" || top.VatRateBp != 2100 || top.GrossAmount != top.NetAmount+top.VatAmount || top.VatAmount != top.NetAmount*21/100 {
		t.Fatalf("catalog %+v", products.Items)
	}

	// Open redirects through Stripe are refused.
	checkout := orgPath + "/listings/" + mine.String() + "/promotions/checkout"
	var p problem
	if code := e.call("POST", checkout, tok, map[string]any{"product_code": "top_7d", "success_url": "https://evil.example/ok",
		"cancel_url": "http://web.test/x"}, &p); code != 422 || p.Code != "invalid_redirect" {
		t.Fatalf("open redirect: %d %+v", code, p)
	}
	// Another organization cannot buy for this listing.
	if code := e.call("POST", "/v1/orgs/"+otherOrg.String()+"/listings/"+mine.String()+"/promotions/checkout", otherTok,
		map[string]any{"product_code": "top_7d", "success_url": "http://web.test/ok", "cancel_url": "http://web.test/x"}, nil); code != 404 {
		t.Fatalf("foreign listing checkout: %d", code)
	}

	var co struct {
		OrderID     uuid.UUID `json:"order_id"`
		CheckoutURL string    `json:"checkout_url"`
	}
	e.must(201, "POST", checkout, tok, map[string]any{"product_code": "top_7d",
		"success_url": "http://web.test/admin/orgs/" + orgID.String() + "/fakturace?paid=1",
		"cancel_url":  "http://web.test/admin/orgs/" + orgID.String() + "/listings"}, &co)
	if !strings.Contains(co.CheckoutURL, "/mock/stripe/checkout/cs_mock_") {
		t.Fatalf("checkout url %q", co.CheckoutURL)
	}
	sessionID := co.CheckoutURL[strings.LastIndex(co.CheckoutURL, "/")+1:]
	var o orderDTO
	e.must(200, "GET", orgPath+"/orders/"+co.OrderID.String(), tok, nil, &o)
	if o.Status != "pending" || o.GrossAmount != top.GrossAmount || o.InvoiceID != nil {
		t.Fatalf("pending order %+v", o)
	}
	// The mock checkout page renders.
	var page []byte
	if code := e.callRaw("GET", "/mock/stripe/checkout/"+sessionID, "", &page); code != 200 || !strings.Contains(string(page), "Zaplatit") {
		t.Fatalf("mock checkout page: %d", code)
	}

	// Bad signatures are refused and change nothing.
	payload := checkoutEvent(t, "evt_test_"+uuid.NewString(), sessionID, co.OrderID)
	if code := e.postWebhook(payload, billing.SignWebhook("whsec_wrong", payload, time.Now())); code != 400 && code != 401 {
		t.Fatalf("bad signature: %d", code)
	}
	if code := e.postWebhook(payload, "t=1,v1=deadbeef"); code != 400 && code != 401 {
		t.Fatalf("garbage signature: %d", code)
	}
	e.must(200, "GET", orgPath+"/orders/"+co.OrderID.String(), tok, nil, &o)
	if o.Status != "pending" {
		t.Fatalf("order after bad webhook %+v", o)
	}

	// The signed webhook pays the order.
	sig := billing.SignWebhook("whsec_test", payload, time.Now())
	if code := e.postWebhook(payload, sig); code != 204 {
		t.Fatalf("webhook: %d", code)
	}
	e.must(200, "GET", orgPath+"/orders/"+co.OrderID.String(), tok, nil, &o)
	if o.Status != "paid" || o.PaidAt == nil || o.InvoiceID == nil {
		t.Fatalf("paid order %+v", o)
	}
	var promos struct {
		Items []struct {
			Kind     string    `json:"kind"`
			Active   bool      `json:"active"`
			StartsAt time.Time `json:"starts_at"`
			EndsAt   time.Time `json:"ends_at"`
			OrderID  uuid.UUID `json:"order_id"`
		} `json:"items"`
	}
	e.must(200, "GET", orgPath+"/listings/"+mine.String()+"/promotions", tok, nil, &promos)
	if len(promos.Items) != 1 || promos.Items[0].Kind != "top" || !promos.Items[0].Active || promos.Items[0].OrderID != co.OrderID ||
		promos.Items[0].EndsAt.Sub(promos.Items[0].StartsAt) != 7*24*time.Hour {
		t.Fatalf("promotions %+v", promos)
	}

	// Search: the boosted listing comes first and carries the label.
	var res promoSearch
	e.must(200, "POST", "/v1/search", "", map[string]any{"text": token}, &res)
	if len(res.Items) != 2 || res.Items[0].ID != mine || !res.Items[0].Promoted || res.Items[1].ID != rival || res.Items[1].Promoted {
		t.Fatalf("search with promotion %+v", res)
	}
	// An explicit sort is kept; the label stays.
	e.must(200, "POST", "/v1/search", "", map[string]any{"text": token, "sort": "newest"}, &res)
	if len(res.Items) != 2 || res.Items[0].ID != rival || res.Items[1].ID != mine || !res.Items[1].Promoted {
		t.Fatalf("search sorted by newest %+v", res)
	}

	// Invoice: number, amounts and the e-mail with the link to the invoices page.
	var invs struct {
		Items []invoiceDTO `json:"items"`
	}
	e.must(200, "GET", orgPath+"/invoices", tok, nil, &invs)
	if len(invs.Items) != 1 || invs.Items[0].OrderID != co.OrderID || invs.Items[0].GrossAmount != top.GrossAmount ||
		!regexp.MustCompile(`^TR-\d{4}-\d{6}$`).MatchString(invs.Items[0].Number) || *o.InvoiceID != invs.Items[0].ID {
		t.Fatalf("invoices %+v", invs)
	}
	m, ok := e.outbox.Last(e.emailOf(tok), "invoice_issued")
	if !ok || !strings.Contains(m.Text, invs.Items[0].Number) || !strings.Contains(m.Text, "/admin/orgs/"+orgID.String()+"/fakturace") {
		t.Fatalf("invoice e-mail %+v (sent %v)", m, ok)
	}
	var pdf []byte
	code := e.callRaw("GET", orgPath+"/invoices/"+invs.Items[0].ID.String()+"/pdf", tok, &pdf)
	if _, err := exec.LookPath("typst"); err == nil {
		if code != 200 || !strings.HasPrefix(string(pdf), "%PDF") {
			t.Fatalf("invoice pdf: %d", code)
		}
	} else if code != 503 {
		t.Fatalf("invoice pdf without typst: %d", code)
	}

	// Repeated deliveries (same event, or a new event for the paid session) are no-ops.
	if code := e.postWebhook(payload, sig); code != 204 {
		t.Fatalf("duplicate webhook: %d", code)
	}
	again := checkoutEvent(t, "evt_test_"+uuid.NewString(), sessionID, co.OrderID)
	if code := e.postWebhook(again, billing.SignWebhook("whsec_test", again, time.Now())); code != 204 {
		t.Fatalf("second event: %d", code)
	}
	e.must(200, "GET", orgPath+"/invoices", tok, nil, &invs)
	e.must(200, "GET", orgPath+"/listings/"+mine.String()+"/promotions", tok, nil, &promos)
	var promoRows int
	if err := e.pool.QueryRow(ctx, "SELECT count(*) FROM promotions WHERE order_id = $1", co.OrderID).Scan(&promoRows); err != nil {
		t.Fatal(err)
	}
	if len(invs.Items) != 1 || len(promos.Items) != 1 || promoRows != 1 {
		t.Fatalf("after duplicates: %d invoices, %d promotions", len(invs.Items), promoRows)
	}

	// Row-level security: the rival sees neither orders nor invoices.
	if code := e.call("GET", orgPath+"/orders", otherTok, nil, nil); code != 404 {
		t.Fatalf("foreign orders: %d", code)
	}
	if code := e.call("GET", orgPath+"/invoices", otherTok, nil, nil); code != 404 {
		t.Fatalf("foreign invoices: %d", code)
	}
	var theirs struct {
		Items []orderDTO `json:"items"`
	}
	e.must(200, "GET", "/v1/orgs/"+otherOrg.String()+"/orders", otherTok, nil, &theirs)
	if len(theirs.Items) != 0 {
		t.Fatalf("rival orders %+v", theirs)
	}

	// The periodic recompute keeps a running promotion and ends an expired one.
	if _, err := e.billing.RecomputePromos(ctx); err != nil {
		t.Fatal(err)
	}
	e.must(200, "POST", "/v1/search", "", map[string]any{"text": token}, &res)
	if len(res.Items) != 2 || res.Items[0].ID != mine || !res.Items[0].Promoted {
		t.Fatalf("after recompute %+v", res)
	}
	if _, err := e.pool.Exec(ctx, "UPDATE promotions SET starts_at = now() - interval '8 days', ends_at = now() - interval '1 day' WHERE order_id = $1",
		co.OrderID); err != nil {
		t.Fatal(err)
	}
	if _, err := e.billing.RecomputePromos(ctx); err != nil {
		t.Fatal(err)
	}
	e.must(200, "POST", "/v1/search", "", map[string]any{"text": token}, &res)
	if len(res.Items) != 2 || res.Items[0].ID != rival || res.Items[1].Promoted {
		t.Fatalf("after expiry %+v", res)
	}

	// An expired checkout session cancels its pending order.
	e.must(201, "POST", checkout, tok, map[string]any{"product_code": "highlight_30d",
		"success_url": "http://web.test/ok", "cancel_url": "http://web.test/x"}, &co)
	sessionID = co.CheckoutURL[strings.LastIndex(co.CheckoutURL, "/")+1:]
	expired, _ := json.Marshal(map[string]any{"id": "evt_test_" + uuid.NewString(), "type": billing.EventCheckoutExpired,
		"data": map[string]any{"object": map[string]any{"id": sessionID, "payment_status": "unpaid",
			"metadata": map[string]string{"order_id": co.OrderID.String()}}}})
	if code := e.postWebhook(expired, billing.SignWebhook("whsec_test", expired, time.Now())); code != 204 {
		t.Fatalf("expired webhook: %d", code)
	}
	e.must(200, "GET", orgPath+"/orders/"+co.OrderID.String(), tok, nil, &o)
	if o.Status != "canceled" {
		t.Fatalf("expired order %+v", o)
	}
}

// Revolut Business payment link: landlord-direct money (ADR 0002); 409 until
// the landlord connects an account; the tenant of the share can create and
// read it; the API key is never returned.
func TestRevolutPaymentLink(t *testing.T) {
	if _, err := exec.LookPath("typst"); err != nil {
		t.Skip("typst not installed")
	}
	e := newEnv(t)
	ownerTok, orgID := e.ownerOrg("revolut-owner")
	tenant := uniqueEmail("revolut-tenant")
	tenantTok := e.register(tenant)
	e.verifyEmail(tenant) // parties link to verified accounts only
	stranger := e.register(uniqueEmail("revolut-stranger"))
	today := time.Now().UTC()
	lpath := "/v1/orgs/" + orgID.String() + "/leases"
	var d leaseDetail
	e.must(201, "POST", lpath, ownerTok, map[string]any{"template": "byt_doba_neurcita", "starts_on": today.Format("2006-01-02"),
		"rent_amount": 2_000_000, "services_amount": 300_000, "deposit_amount": 4_000_000, "due_day": min(today.Day(), 28),
		"payee_iban": "CZ65 0800 0000 1920 0014 5399", "payee_name": "Pronajímatel", "property_address": "Dejvická 12, Praha 6",
		"unit_label": "2+kk", "parties": []map[string]any{{"name": "Nájemce", "email": tenant, "role": "tenant"}}}, &d)
	id := d.Lease.ID.String()
	e.must(200, "POST", lpath+"/"+id+"/propose", ownerTok, nil, nil)
	e.must(200, "POST", "/v1/leases/"+id+"/sign", tenantTok, map[string]string{"provider": "mock"}, nil)
	e.must(200, "POST", "/v1/leases/"+id+"/sign", ownerTok, map[string]string{"provider": "mock"}, nil)
	var shares []share
	e.must(200, "GET", "/v1/leases/"+id+"/obligations", tenantTok, nil, &shares)
	var sh share
	for _, s := range shares {
		if s.Mine && s.PaidAmount < s.Amount {
			sh = s
			break
		}
	}
	if sh.ID == uuid.Nil {
		t.Fatalf("no open share for the tenant in %+v", shares)
	}
	link := "/v1/obligation-shares/" + sh.ID.String() + "/payment-link"

	var p problem
	if code := e.call("POST", link, tenantTok, nil, &p); code != 409 || p.Code != "revolut_not_connected" {
		t.Fatalf("without account: %d %+v", code, p)
	}
	if code := e.call("GET", link, tenantTok, nil, nil); code != 404 {
		t.Fatalf("no link yet: %d", code)
	}
	// Only owner/admin connect the account; the key never comes back.
	const apiKey = "sk_sandbox_secret_123456"
	var raw json.RawMessage
	e.must(200, "PUT", "/v1/orgs/"+orgID.String()+"/revolut", ownerTok, map[string]string{"api_key": apiKey, "mode": "sandbox"}, &raw)
	if strings.Contains(string(raw), apiKey) || !strings.Contains(string(raw), `"connected":true`) {
		t.Fatalf("revolut account %s", raw)
	}
	e.must(200, "GET", "/v1/orgs/"+orgID.String()+"/revolut", ownerTok, nil, &raw)
	if strings.Contains(string(raw), apiKey) || !strings.Contains(string(raw), `"connected":true`) {
		t.Fatalf("revolut account %s", raw)
	}
	if code := e.call("PUT", "/v1/orgs/"+orgID.String()+"/revolut", stranger, map[string]string{"api_key": apiKey, "mode": "sandbox"}, nil); code != 404 {
		t.Fatalf("stranger connects: %d", code)
	}

	var pl struct {
		ID       uuid.UUID `json:"id"`
		ShareID  uuid.UUID `json:"share_id"`
		Provider string    `json:"provider"`
		URL      string    `json:"url"`
		Amount   int64     `json:"amount"`
		Status   string    `json:"status"`
	}
	e.must(201, "POST", link, tenantTok, nil, &pl)
	if pl.ShareID != sh.ID || pl.Provider != "revolut" || pl.Amount != sh.Amount-sh.PaidAmount || pl.Status != "created" ||
		!strings.Contains(pl.URL, "/mock/revolut/pay/") {
		t.Fatalf("payment link %+v", pl)
	}
	var got struct {
		ID uuid.UUID `json:"id"`
	}
	e.must(200, "GET", link, tenantTok, nil, &got)
	if got.ID != pl.ID {
		t.Fatalf("latest link %v want %v", got.ID, pl.ID)
	}
	e.must(200, "GET", link, ownerTok, nil, &got)
	if code := e.call("GET", link, stranger, nil, nil); code != 404 {
		t.Fatalf("stranger reads link: %d", code)
	}
	if code := e.call("POST", link, stranger, nil, nil); code != 404 {
		t.Fatalf("stranger creates link: %d", code)
	}
	var stored []byte
	if err := e.pool.QueryRow(context.Background(), "SELECT api_key_enc FROM org_revolut_accounts WHERE org_id = $1", orgID).Scan(&stored); err != nil {
		t.Fatal(err)
	}
	if bytes.Contains(stored, []byte(apiKey)) {
		t.Fatal("api key stored in plain text")
	}
	e.must(204, "DELETE", "/v1/orgs/"+orgID.String()+"/revolut", ownerTok, nil, nil)
	if code := e.call("POST", link, ownerTok, nil, &p); code != 409 {
		t.Fatalf("after disconnect: %d", code)
	}
}

func stripeEvent(t *testing.T, kind, sessionID, orderID, paymentStatus string) []byte {
	t.Helper()
	b, err := json.Marshal(map[string]any{"id": "evt_test_" + uuid.NewString(), "object": "event", "type": kind,
		"data": map[string]any{"object": map[string]any{"id": sessionID, "object": "checkout.session",
			"client_reference_id": orderID, "payment_status": paymentStatus, "status": "complete",
			"metadata": map[string]string{"order_id": orderID}}}})
	if err != nil {
		t.Fatal(err)
	}
	return b
}

// S-B1, S-B2: an event whose order does not match the session is
// acknowledged (no Stripe retries) without paying anything; a delayed payment
// method completes the session unpaid and pays with async_payment_succeeded;
// async_payment_failed cancels a pending order.
func TestStripeWebhookMismatchAndAsyncPayment(t *testing.T) {
	e := newEnv(t)
	tok, orgID := e.ownerOrg("promo-async")
	staff := e.staffToken()
	orgPath := "/v1/orgs/" + orgID.String()
	listing := e.publishFlat(tok, orgID, staff, "Byt async "+uuid.NewString()[:8], "approximate")
	checkout := func() (uuid.UUID, string) {
		var co struct {
			OrderID     uuid.UUID `json:"order_id"`
			CheckoutURL string    `json:"checkout_url"`
		}
		e.must(201, "POST", orgPath+"/listings/"+listing.String()+"/promotions/checkout", tok, map[string]any{"product_code": "top_7d",
			"success_url": "http://web.test/admin/orgs/" + orgID.String() + "/fakturace", "cancel_url": "http://web.test/admin"}, &co)
		return co.OrderID, co.CheckoutURL[strings.LastIndex(co.CheckoutURL, "/")+1:]
	}
	post := func(payload []byte) {
		t.Helper()
		if code := e.postWebhook(payload, billing.SignWebhook("whsec_test", payload, time.Now())); code != 204 {
			t.Fatalf("webhook: %d", code)
		}
	}
	status := func(id uuid.UUID) string {
		var o orderDTO
		e.must(200, "GET", orgPath+"/orders/"+id.String(), tok, nil, &o)
		return o.Status
	}

	orderID, session := checkout()
	post(stripeEvent(t, billing.EventCheckoutCompleted, session, uuid.NewString(), "paid"))
	if s := status(orderID); s != "pending" {
		t.Fatalf("mismatched event paid the order: %s", s)
	}
	post(stripeEvent(t, billing.EventCheckoutCompleted, session, orderID.String(), "unpaid"))
	if s := status(orderID); s != "pending" {
		t.Fatalf("unpaid completion: %s", s)
	}
	post(stripeEvent(t, billing.EventCheckoutAsyncSucceeded, session, orderID.String(), "paid"))
	if s := status(orderID); s != "paid" {
		t.Fatalf("async payment succeeded: %s", s)
	}

	failed, session2 := checkout()
	post(stripeEvent(t, billing.EventCheckoutAsyncFailed, session2, failed.String(), "unpaid"))
	if s := status(failed); s != "canceled" {
		t.Fatalf("async payment failed: %s", s)
	}
}
