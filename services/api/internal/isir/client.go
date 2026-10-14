package isir

import (
	"bytes"
	"context"
	"encoding/xml"
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
			Data []struct {
				DruhStavKonkursu string `xml:"druhStavKonkursu"`
			} `xml:"data"`
			Status struct {
				Count     int    `xml:"pocetVysledku"`
				Relevance int    `xml:"relevanceVysledku"`
				Code      string `xml:"kodChyby"`
				Text      string `xml:"textChyby"`
			} `xml:"stav"`
		} `xml:"getIsirWsCuzkDataResponse"`
	} `xml:"Body"`
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
	st := env.Body.Response.Status
	switch {
	case st.Code == "WS2" || (st.Code == "" && len(env.Body.Response.Data) == 0):
		return Clear, nil
	case st.Code != "":
		return "", fmt.Errorf("isir: %s %s", st.Code, st.Text)
	}
	return Record, nil
}
