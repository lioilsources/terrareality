package isir

import (
	"bytes"
	"context"
	"encoding/xml"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"
)

// DefaultURL is the public ISIR web service of the Ministry of Justice.
const DefaultURL = "https://isir.justice.cz:8443/isir_cuzk_ws/IsirWsCuzkService"

// Client calls the ISIR_CUZK_WS SOAP service: surname, given name and birth
// date, current proceedings only, exact relevance (match on all three).
type Client struct {
	URL  string
	HTTP *http.Client
}

// NewClient creates a client for url (DefaultURL when empty).
func NewClient(url string) *Client {
	if url == "" {
		url = DefaultURL
	}
	return &Client{URL: url, HTTP: &http.Client{Timeout: 20 * time.Second}}
}

type envelope struct {
	Body struct {
		Fault *struct {
			String string `xml:"faultstring"`
		} `xml:"Fault"`
		Response struct {
			Data   []record `xml:"data"`
			Status struct {
				Count     int    `xml:"pocetVysledku"`
				Relevance int    `xml:"relevanceVysledku"`
				Code      string `xml:"kodChyby"`
				Text      string `xml:"textChyby"`
			} `xml:"stav"`
		} `xml:"getIsirWsCuzkDataResponse"`
	} `xml:"Body"`
}

// record is one proceeding in the response with the debtor's identity.
type record struct {
	DruhStavKonkursu string `xml:"druhStavKonkursu"`
	Surname          string `xml:"nazevOsoby"`
	GivenName        string `xml:"jmeno"`
	Birthdate        string `xml:"datumNarozeni"`
}

// ErrAmbiguous means the register returned proceedings of people whose
// name or birth date differ from the applicant (a namesake, or a record
// without the birth date). Such results are never shown as "record": the
// check ends in "error" and a human looks at the register if needed.
var ErrAmbiguous = errors.New("isir: results do not match the person exactly")

func norm(s string) string { return strings.ToLower(strings.Join(strings.Fields(s), " ")) }

// matches reports whether a returned proceeding belongs to exactly this
// person: same surname, same birth date and the same given name (the first
// given name is enough, BankID may carry middle names the court did not).
func (r record) matches(p Person) bool {
	if norm(r.Surname) == "" || norm(r.Surname) != norm(p.FamilyName) {
		return false
	}
	bd := strings.TrimSpace(r.Birthdate)
	if len(bd) < 10 || bd[:10] != p.Birthdate.Format("2006-01-02") {
		return false
	}
	g, want := norm(r.GivenName), norm(p.GivenName)
	if g == want {
		return true
	}
	first := func(s string) string { f, _, _ := strings.Cut(s, " "); return f }
	return g != "" && want != "" && first(g) == first(want)
}

func esc(s string) string {
	var b strings.Builder
	_ = xml.EscapeText(&b, []byte(s))
	return b.String()
}

// Check implements Checker.
func (c *Client) Check(ctx context.Context, p Person) (string, error) {
	body := `<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:typ="http://isirws.cca.cz/types/">` +
		`<soapenv:Body><typ:getIsirWsCuzkDataRequest>` +
		`<nazevOsoby>` + esc(p.FamilyName) + `</nazevOsoby>` +
		`<jmeno>` + esc(p.GivenName) + `</jmeno>` +
		`<datumNarozeni>` + p.Birthdate.Format("2006-01-02") + `</datumNarozeni>` +
		`<filtrAktualniRizeni>T</filtrAktualniRizeni>` +
		`<maxRelevanceVysledku>4</maxRelevanceVysledku>` +
		`</typ:getIsirWsCuzkDataRequest></soapenv:Body></soapenv:Envelope>`
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.URL, bytes.NewBufferString(body))
	if err != nil {
		return "", err
	}
	req.Header.Set("Content-Type", "text/xml; charset=utf-8")
	req.Header.Set("SOAPAction", `""`)
	res, err := c.HTTP.Do(req)
	if err != nil {
		return "", fmt.Errorf("isir: %w", err)
	}
	defer res.Body.Close()
	raw, _ := io.ReadAll(io.LimitReader(res.Body, 1<<20))
	var env envelope
	if err := xml.Unmarshal(raw, &env); err != nil {
		return "", fmt.Errorf("isir: status %d: %.200s", res.StatusCode, raw)
	}
	if env.Body.Fault != nil {
		return "", fmt.Errorf("isir: %s", env.Body.Fault.String)
	}
	return classify(env, p)
}

// classify turns a parsed response into the result. The relevance the
// service reports (relevanceVysledku) is not trusted on its own: its scale
// is not part of the public contract we rely on (open question OQ-17), so
// "record" requires a returned proceeding whose surname, given name and
// birth date equal the verified identity. Anything else returned is
// ambiguous and reported as an error, never as an insolvency.
func classify(env envelope, p Person) (string, error) {
	st := env.Body.Response.Status
	data := env.Body.Response.Data
	switch {
	case st.Code == "WS2" || (st.Code == "" && len(data) == 0):
		return Clear, nil
	case st.Code != "":
		return "", fmt.Errorf("isir: %s %s", st.Code, st.Text)
	}
	for _, r := range data {
		if r.matches(p) {
			return Record, nil
		}
	}
	return "", fmt.Errorf("%w (%d results, relevance %d)", ErrAmbiguous, len(data), st.Relevance)
}
