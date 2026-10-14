package leasing

import (
	"bytes"
	"context"
	"errors"
	"testing"
)

func TestTypstRendersAllTemplates(t *testing.T) {
	data := map[string]any{"draft": true, "code": 2600000001, "document_id": "test", "generated_at": "14. 10. 2026",
		"parties":  []map[string]any{{"role": "landlord", "name": "L", "email": ""}, {"role": "tenant", "name": "T", "email": "t@x", "share_pct": 100}},
		"property": map[string]string{"address": "Dejvická 1, Praha", "unit": "2+kk"}, "starts_on": "1. 11. 2026", "ends_on": nil,
		"rent": "22 000 Kč", "services": "3 500 Kč", "deposit": "44 000 Kč", "due_day": 15, "notice_months": 3,
		"payee": map[string]string{"iban": "CZ65 0800 0000 1920 0014 5399", "name": "L"}, "clauses": []string{"no_smoking"}}
	for _, tpl := range Templates {
		pdf, err := Typst{}.Render(context.Background(), tpl, data)
		if errors.Is(err, ErrNoTypst) {
			t.Skip("typst not installed")
		}
		if err != nil || !bytes.HasPrefix(pdf, []byte("%PDF")) {
			t.Fatalf("%s: %v", tpl, err)
		}
	}
}
