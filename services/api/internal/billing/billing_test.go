package billing

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"strings"
	"testing"
	"time"
)

const secret = "whsec_test"

func TestWebhookSignature(t *testing.T) {
	payload := []byte(`{"id":"evt_1","type":"checkout.session.completed","data":{"object":{"id":"cs_1","client_reference_id":"ord-ref","payment_status":"paid","metadata":{"order_id":"ord-1"}}}}`)
	now := time.Now()
	sig := SignWebhook(secret, payload, now)

	ev, err := ParseEvent(secret, payload, sig, now)
	if err != nil {
		t.Fatal(err)
	}
	if ev.ID != "evt_1" || ev.Type != EventCheckoutCompleted || ev.SessionID != "cs_1" || ev.OrderID != "ord-1" || ev.PaymentStatus != "paid" {
		t.Fatalf("event %+v", ev)
	}
	// Multiple v1 entries (secret rotation) are accepted when one matches.
	if err := VerifyWebhook(secret, payload, sig+",v1=deadbeef", now); err != nil {
		t.Fatal(err)
	}
	tampered := bytes.Replace(payload, []byte("ord-1"), []byte("ord-2"), 1)
	if err := VerifyWebhook(secret, tampered, sig, now); !errors.Is(err, ErrInvalidSignature) {
		t.Fatalf("tampered: %v", err)
	}
	if err := VerifyWebhook("whsec_other", payload, sig, now); !errors.Is(err, ErrInvalidSignature) {
		t.Fatalf("wrong secret: %v", err)
	}
	old := SignWebhook(secret, payload, now.Add(-6*time.Minute))
	if err := VerifyWebhook(secret, payload, old, now); !errors.Is(err, ErrExpiredSignature) {
		t.Fatalf("expired: %v", err)
	}
	for _, h := range []string{"", "t=abc,v1=00", "v1=" + strings.Repeat("0", 64)} {
		if err := VerifyWebhook(secret, payload, h, now); !errors.Is(err, ErrInvalidSignature) {
			t.Fatalf("header %q: %v", h, err)
		}
	}
	// client_reference_id is the fallback for the order id.
	p2 := []byte(`{"id":"evt_2","type":"checkout.session.completed","data":{"object":{"id":"cs_2","client_reference_id":"ord-9"}}}`)
	ev, err = (&StripeHTTP{WebhookSecret: secret}).ParseWebhook(p2, SignWebhook(secret, p2, time.Now()))
	if err != nil || ev.OrderID != "ord-9" {
		t.Fatalf("fallback: %+v %v", ev, err)
	}
}

func TestComputeVAT(t *testing.T) {
	for _, c := range []struct {
		net        int64
		rate       int
		vat, gross int64
	}{
		{19900, 2100, 4179, 24079},
		{49900, 2100, 10479, 60379},
		{29900, 2100, 6279, 36179},
		{69900, 2100, 14679, 84579},
		{50, 2100, 11, 61},    // 10.5 -> 11 (half up)
		{2, 2500, 1, 3},       // 0.5 -> 1
		{1, 2100, 0, 1},       // 0.21 -> 0
		{-50, 2100, -11, -61}, // credit note: half away from zero
		{10000, 0, 0, 10000},
		{10000, 1200, 1200, 11200},
	} {
		vat, gross := ComputeVAT(c.net, c.rate)
		if vat != c.vat || gross != c.gross {
			t.Errorf("ComputeVAT(%d, %d) = %d, %d; want %d, %d", c.net, c.rate, vat, gross, c.vat, c.gross)
		}
	}
}

func TestFormatting(t *testing.T) {
	if got := FormatInvoiceNumber(2026, 1); got != "TR-2026-000001" {
		t.Fatal(got)
	}
	if got := FormatInvoiceNumber(2027, 123456); got != "TR-2027-123456" {
		t.Fatal(got)
	}
	nb := " "
	for in, want := range map[int64]string{24079: "240,79" + nb + "Kč", 123456789: "1" + nb + "234" + nb + "567,89" + nb + "Kč", 5: "0,05" + nb + "Kč", -100: "-1,00" + nb + "Kč"} {
		if got := FormatAmount(in, "CZK"); got != want {
			t.Errorf("FormatAmount(%d) = %q, want %q", in, got, want)
		}
	}
	if got := FormatAmount(1000, "eur"); got != "10,00"+nb+"EUR" {
		t.Error(got)
	}
	if FormatRate(2100) != "21"+nb+"%" || FormatRate(1250) != "12,5"+nb+"%" {
		t.Error(FormatRate(2100), FormatRate(1250))
	}
}

func TestMockStripePayFlow(t *testing.T) {
	m := NewMockStripe("", secret)
	srv := httptest.NewServer(m.Handler())
	defer srv.Close()
	m.APIPublicURL = srv.URL

	var got Event
	m.Deliver = func(_ context.Context, payload []byte, sig string) error {
		ev, err := m.ParseWebhook(payload, sig)
		got = ev
		return err
	}
	s, err := m.CreateCheckout(context.Background(), CheckoutInput{OrderID: "ord-1", Description: "Topování 7 dní",
		AmountGross: 24079, Currency: "CZK", SuccessURL: "http://web.test/ok", CancelURL: "http://web.test/cancel",
		Metadata: map[string]string{"listing_id": "l-1"}})
	if err != nil || !strings.HasPrefix(s.ID, "cs_mock_") || s.URL != srv.URL+"/mock/stripe/checkout/"+s.ID {
		t.Fatalf("%+v %v", s, err)
	}
	client := &http.Client{CheckRedirect: func(*http.Request, []*http.Request) error { return http.ErrUseLastResponse }}

	res, err := client.Get(s.URL)
	if err != nil {
		t.Fatal(err)
	}
	page, _ := io.ReadAll(res.Body)
	res.Body.Close()
	if res.StatusCode != 200 || !strings.Contains(string(page), "Zaplatit") || !strings.Contains(string(page), "240,79") {
		t.Fatalf("page %d: %s", res.StatusCode, page)
	}

	res, err = client.Post(s.URL+"/pay", "application/x-www-form-urlencoded", nil)
	if err != nil {
		t.Fatal(err)
	}
	res.Body.Close()
	if res.StatusCode != http.StatusSeeOther || res.Header.Get("Location") != "http://web.test/ok" {
		t.Fatalf("pay: %d %s", res.StatusCode, res.Header.Get("Location"))
	}
	if got.Type != EventCheckoutCompleted || got.SessionID != s.ID || got.OrderID != "ord-1" || got.PaymentStatus != "paid" || !strings.HasPrefix(got.ID, "evt_mock_") {
		t.Fatalf("event %+v", got)
	}
	// A second click does not deliver again.
	got = Event{}
	res, _ = client.Post(s.URL+"/pay", "", nil)
	res.Body.Close()
	if got.ID != "" {
		t.Fatal("delivered twice")
	}

	s2, _ := m.CreateCheckout(context.Background(), CheckoutInput{OrderID: "ord-2", SuccessURL: "http://web.test/ok", CancelURL: "http://web.test/cancel"})
	res, _ = client.Post(srv.URL+"/mock/stripe/checkout/"+s2.ID+"/cancel", "", nil)
	res.Body.Close()
	if res.StatusCode != http.StatusSeeOther || res.Header.Get("Location") != "http://web.test/cancel" {
		t.Fatalf("cancel: %d", res.StatusCode)
	}
	if st, _ := m.Session(s2.ID); st.Status != "canceled" {
		t.Fatal(st.Status)
	}
}

func TestMockStripeDefaultDelivery(t *testing.T) {
	m := NewMockStripe("", secret)
	var got Event
	mux := http.NewServeMux()
	mux.Handle("/mock/", m.Handler())
	mux.HandleFunc("POST /v1/webhooks/stripe", func(w http.ResponseWriter, r *http.Request) {
		b, _ := io.ReadAll(r.Body)
		ev, err := m.ParseWebhook(b, r.Header.Get("Stripe-Signature"))
		if err != nil {
			http.Error(w, err.Error(), 400)
			return
		}
		got = ev
		w.WriteHeader(http.StatusNoContent)
	})
	srv := httptest.NewServer(mux)
	defer srv.Close()
	m.APIPublicURL = srv.URL
	s, _ := m.CreateCheckout(context.Background(), CheckoutInput{OrderID: "ord-3", SuccessURL: "http://web.test/ok"})
	client := &http.Client{CheckRedirect: func(*http.Request, []*http.Request) error { return http.ErrUseLastResponse }}
	res, err := client.Post(s.URL+"/pay", "", nil)
	if err != nil {
		t.Fatal(err)
	}
	res.Body.Close()
	if res.StatusCode != http.StatusSeeOther || got.OrderID != "ord-3" {
		t.Fatalf("%d %+v", res.StatusCode, got)
	}
}

func TestStripeHTTPCreateCheckout(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		user, _, _ := r.BasicAuth()
		_ = r.ParseForm()
		if r.URL.Path != "/v1/checkout/sessions" || user != "sk_test" || r.Form.Get("mode") != "payment" ||
			r.Form.Get("line_items[0][price_data][unit_amount]") != "24079" || r.Form.Get("line_items[0][price_data][currency]") != "czk" ||
			r.Form.Get("metadata[order_id]") != "ord-1" || r.Form.Get("client_reference_id") != "ord-1" {
			http.Error(w, "bad request: "+r.Form.Encode(), 400)
			return
		}
		_, _ = w.Write([]byte(`{"id":"cs_test_1","url":"https://checkout.stripe.com/c/pay/cs_test_1"}`))
	}))
	defer srv.Close()
	s := NewStripeHTTP("sk_test", secret)
	s.BaseURL = srv.URL
	out, err := s.CreateCheckout(context.Background(), CheckoutInput{OrderID: "ord-1", Description: "Top", AmountGross: 24079,
		Currency: "CZK", SuccessURL: "http://ok", CancelURL: "http://no"})
	if err != nil || out.ID != "cs_test_1" || !strings.HasPrefix(out.URL, "https://checkout.stripe.com/") {
		t.Fatalf("%+v %v", out, err)
	}
}

func TestRevolutHTTP(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		var body map[string]any
		_ = json.NewDecoder(r.Body).Decode(&body)
		ref, _ := body["merchant_order_data"].(map[string]any)
		if r.Method != http.MethodPost || r.URL.Path != "/api/orders" || r.Header.Get("Authorization") != "Bearer sk_landlord" ||
			r.Header.Get("Revolut-Api-Version") != RevolutAPIVersion || body["amount"] != float64(1250000) ||
			body["currency"] != "CZK" || ref["reference"] != "share-1" || !strings.HasPrefix(body["expire_pending_after"].(string), "PT") {
			http.Error(w, "bad", 400)
			return
		}
		w.WriteHeader(http.StatusCreated)
		_, _ = w.Write([]byte(`{"id":"ord_rev_1","token":"tok","state":"pending","checkout_url":"https://checkout.revolut.com/payment-link/tok"}`))
	}))
	defer srv.Close()
	exp := time.Now().Add(72 * time.Hour)
	o, err := NewRevolutHTTP(srv.URL).CreateOrder(context.Background(), "sk_landlord", RevolutOrderInput{Amount: 1250000,
		Currency: "czk", Description: "Nájem 11/2026", MerchantOrderRef: "share-1", ExpiresAt: &exp})
	if err != nil || o.ID != "ord_rev_1" || o.State != "pending" || o.CheckoutURL != "https://checkout.revolut.com/payment-link/tok" {
		t.Fatalf("%+v %v", o, err)
	}
	_, err = NewRevolutHTTP(srv.URL).CreateOrder(context.Background(), "wrong", RevolutOrderInput{Amount: 1})
	if err == nil {
		t.Fatal("expected error")
	}
}

func TestMockRevolut(t *testing.T) {
	m := NewMockRevolut("")
	srv := httptest.NewServer(m.Handler())
	defer srv.Close()
	m.APIPublicURL = srv.URL
	o, err := m.CreateOrder(context.Background(), "key", RevolutOrderInput{Amount: 1250000, Currency: "CZK", Description: "Nájem", MerchantOrderRef: "share-1"})
	if err != nil {
		t.Fatal(err)
	}
	if u, _ := url.Parse(o.CheckoutURL); u.Path != "/mock/revolut/pay/"+o.ID {
		t.Fatal(o.CheckoutURL)
	}
	res, err := http.Get(o.CheckoutURL)
	if err != nil {
		t.Fatal(err)
	}
	page, _ := io.ReadAll(res.Body)
	res.Body.Close()
	if res.StatusCode != 200 || !strings.Contains(string(page), "Sandbox platba") || !strings.Contains(string(page), "12 500,00") {
		t.Fatalf("%d %s", res.StatusCode, page)
	}
	if _, err := m.CreateOrder(context.Background(), "", RevolutOrderInput{}); err == nil {
		t.Fatal("expected error without key")
	}
}

func TestInvoiceRender(t *testing.T) {
	day := time.Date(2026, 10, 15, 0, 0, 0, 0, time.UTC)
	d := InvoiceData{Number: FormatInvoiceNumber(2026, 1), IssuedOn: day, TaxableSupplyOn: day,
		Supplier: Party{Name: "TerraReality s.r.o.", ICO: "12345678", DIC: "CZ12345678", Address: "Dejvická 1, 160 00 Praha 6", IBAN: "CZ65 0800 0000 1920 0014 5399"},
		Buyer:    Party{Name: "Jan Novák", Address: "Brno", Email: "jan@example.com"},
		Lines:    []InvoiceLine{NewInvoiceLine("Topování inzerátu 7 dní – Byt 2+kk", 1, 19900, VATRateCZStandard)},
		Currency: "CZK", OrderRef: "ord-1"}
	if net, vat, gross := d.Totals(); net != 19900 || vat != 4179 || gross != 24079 {
		t.Fatal(net, vat, gross)
	}
	pdf, err := InvoiceRenderer{}.Render(context.Background(), d)
	if errors.Is(err, ErrNoTypst) {
		t.Skip("typst not installed")
	}
	if err != nil || !bytes.HasPrefix(pdf, []byte("%PDF")) {
		t.Fatal(err)
	}
	if p := os.Getenv("INVOICE_PDF_OUT"); p != "" {
		_ = os.WriteFile(p, pdf, 0o600)
	}
}
