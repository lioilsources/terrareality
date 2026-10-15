package leasing

import (
	"encoding/json"
	"strings"
	"testing"
	"time"
)

func TestChain(t *testing.T) {
	prev := GenesisHash
	var events []ChainEvent
	for i, p := range []map[string]any{{"kind": "created", "b": 1, "a": "x"}, {"kind": "signed", "party": "p1"}} {
		c, err := Canonical(p)
		if err != nil {
			t.Fatal(err)
		}
		h := ChainHash(prev, c)
		events = append(events, ChainEvent{Seq: int32(i + 1), Payload: c, PrevHash: prev, Hash: h})
		prev = h
	}
	if string(events[0].Payload) != `{"a":"x","b":1,"kind":"created"}` {
		t.Fatalf("canonical %s", events[0].Payload)
	}
	if n, err := VerifyChain(events); err != nil || n != 2 {
		t.Fatalf("verify %d %v", n, err)
	}
	// Storing JSON with different key order or spacing still verifies.
	var v any
	_ = json.Unmarshal(events[1].Payload, &v)
	events[1].Payload, _ = json.MarshalIndent(v, "", "  ")
	if _, err := VerifyChain(events); err != nil {
		t.Fatalf("re-encoded payload: %v", err)
	}
	events[0].Payload = []byte(`{"a":"y","b":1,"kind":"created"}`)
	if n, err := VerifyChain(events); err == nil || n != 0 {
		t.Fatal("tampering not detected")
	}
}

func TestIBANAndSPAYD(t *testing.T) {
	if !ValidIBAN("CZ65 0800 0000 1920 0014 5399") || ValidIBAN("CZ66 0800 0000 1920 0014 5399") {
		t.Fatal("iban checksum")
	}
	got := SPAYD(Payment{IBAN: "CZ65 0800 0000 1920 0014 5399", Amount: 1_275_050, Currency: "CZK", VS: "2600000001",
		SS: "2", Message: "Nájem 2026-11 * Byt", Payee: "Lucie N."})
	want := "SPD*1.0*ACC:CZ6508000000192000145399*AM:12750.50*CC:CZK*RN:LUCIE N.*MSG:NÁJEM 2026-11   BYT*X-VS:2600000001*X-SS:2"
	if got != want {
		t.Fatalf("spayd\n got %s\nwant %s", got, want)
	}
}

func TestSchedule(t *testing.T) {
	d := func(y, m, day int) time.Time { return time.Date(y, time.Month(m), day, 0, 0, 0, 0, time.UTC) }
	end := d(2027, 4, 30)
	shares := []Share{{"a", 5000}, {"b", 5000}}
	items := Schedule(Terms{StartsOn: d(2026, 11, 10), EndsOn: &end, Rent: 2_200_001, Services: 350_000, Deposit: 4_400_000, DueDay: 5}, shares, time.Time{})
	if len(items) != 7 || items[0].Kind != "deposit" || items[1].Period != "2026-11" || items[6].Period != "2027-04" {
		t.Fatalf("items %+v", items)
	}
	if !items[1].DueOn.Equal(d(2026, 11, 10)) || !items[2].DueOn.Equal(d(2026, 12, 5)) {
		t.Fatalf("due dates %v %v", items[1].DueOn, items[2].DueOn)
	}
	if items[1].Splits["a"]+items[1].Splits["b"] != 2_550_001 || items[1].Splits["a"] != 1_275_001 {
		t.Fatalf("splits %+v", items[1].Splits)
	}
	indef := Schedule(Terms{StartsOn: d(2026, 11, 1), Rent: 100, DueDay: 15}, shares, time.Time{})
	if len(indef) != IndefiniteHorizon || !strings.HasPrefix(indef[11].Period, "2027-10") {
		t.Fatalf("indefinite %d %s", len(indef), indef[len(indef)-1].Period)
	}
	next := Schedule(Terms{StartsOn: d(2026, 11, 1), Rent: 100, DueDay: 15}, shares, d(2027, 11, 1))
	if len(next) != IndefiniteHorizon || next[0].Period != "2027-11" {
		t.Fatalf("extension %+v", next[0])
	}
}

// GoCardless transactions without any id get a stable content id; identical
// ones in one response stay distinct.
func TestGoCardlessFallbackID(t *testing.T) {
	tx := func(id, amount string) gcTxn {
		var g gcTxn
		g.TransactionID, g.BookingDate, g.TransactionAmount.Amount, g.TransactionAmount.Currency = id, "2026-10-15", amount, "CZK"
		g.DebtorName = "Anna"
		return g
	}
	got := gcTransactions([]gcTxn{tx("t1", "100.00"), tx("", "200.00"), tx("", "200.00"), tx("", "300.00")})
	if len(got) != 4 || got[0].ExternalID != "t1" {
		t.Fatalf("%+v", got)
	}
	ids := map[string]bool{}
	for _, g := range got {
		if g.ExternalID == "" || ids[g.ExternalID] {
			t.Fatalf("empty or duplicate id %q in %+v", g.ExternalID, got)
		}
		ids[g.ExternalID] = true
	}
	again := gcTransactions([]gcTxn{tx("", "200.00")})
	if again[0].ExternalID != got[1].ExternalID || !strings.HasPrefix(again[0].ExternalID, "sha256:") {
		t.Fatalf("fallback id not stable: %q vs %q", again[0].ExternalID, got[1].ExternalID)
	}
}

func TestGoCardlessCurrencyNormalized(t *testing.T) {
	var g gcTxn
	g.TransactionID, g.BookingDate, g.TransactionAmount.Amount, g.TransactionAmount.Currency = "x", "2026-10-15", "1.00", " czk "
	if got := gcTransactions([]gcTxn{g}); got[0].Currency != "CZK" || !validCurrency(got[0].Currency) {
		t.Fatalf("%+v", got)
	}
	if validCurrency("") || validCurrency("Kč") || validCurrency("czk") {
		t.Fatal("invalid currency accepted")
	}
}
