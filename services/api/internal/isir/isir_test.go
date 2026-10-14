package isir

import (
	"context"
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"testing"
	"time"
)

func fake(t *testing.T, resp string) *Client {
	t.Helper()
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		b := make([]byte, 4096)
		n, _ := r.Body.Read(b)
		if !strings.Contains(string(b[:n]), "<nazevOsoby>Nováková</nazevOsoby>") {
			t.Errorf("request %s", b[:n])
		}
		_, _ = w.Write([]byte(`<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body>` + resp + `</soap:Body></soap:Envelope>`))
	}))
	t.Cleanup(srv.Close)
	return NewClient(srv.URL)
}

var person = Person{GivenName: "Jana", FamilyName: "Nováková", Birthdate: time.Date(1990, 5, 1, 0, 0, 0, 0, time.UTC)}

func TestClientParsesResponses(t *testing.T) {
	empty := `<ns2:getIsirWsCuzkDataResponse xmlns:ns2="http://isirws.cca.cz/types/"><stav><kodChyby>WS2</kodChyby></stav></ns2:getIsirWsCuzkDataResponse>`
	if got, err := fake(t, empty).Check(context.Background(), person); err != nil || got != Clear {
		t.Fatalf("empty: %s %v", got, err)
	}
	hit := `<ns2:getIsirWsCuzkDataResponse xmlns:ns2="http://isirws.cca.cz/types/"><data><druhStavKonkursu>KONKURS</druhStavKonkursu></data><stav><pocetVysledku>1</pocetVysledku><relevanceVysledku>4</relevanceVysledku></stav></ns2:getIsirWsCuzkDataResponse>`
	if got, err := fake(t, hit).Check(context.Background(), person); err != nil || got != Record {
		t.Fatalf("hit: %s %v", got, err)
	}
	bad := `<ns2:getIsirWsCuzkDataResponse xmlns:ns2="http://isirws.cca.cz/types/"><stav><kodChyby>SQL1</kodChyby></stav></ns2:getIsirWsCuzkDataResponse>`
	if _, err := fake(t, bad).Check(context.Background(), person); err == nil {
		t.Fatal("error code ignored")
	}
}

// Live check against the public service, enabled with TEST_ISIR_LIVE=1.
func TestLiveISIR(t *testing.T) {
	if os.Getenv("TEST_ISIR_LIVE") == "" {
		t.Skip("TEST_ISIR_LIVE not set")
	}
	got, err := NewClient("").Check(context.Background(), Person{GivenName: "Xaver", FamilyName: "Neexistujícíaksd",
		Birthdate: time.Date(1901, 1, 1, 0, 0, 0, 0, time.UTC)})
	if err != nil || got != Clear {
		t.Fatalf("%s %v", got, err)
	}
}
