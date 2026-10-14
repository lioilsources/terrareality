package health

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

func TestCheckerAggregates(t *testing.T) {
	c := New(time.Second)
	c.Add("ok", func(context.Context) error { return nil })
	c.Add("off", func(context.Context) error { return ErrDisabled })
	res, healthy := c.Run(context.Background())
	if !healthy {
		t.Fatalf("expected healthy, got %+v", res)
	}
	if res["off"].Status != Disabled || res["ok"].Status != OK {
		t.Fatalf("unexpected statuses %+v", res)
	}

	c.Add("bad", func(context.Context) error { return errors.New("boom") })
	res, healthy = c.Run(context.Background())
	if healthy || res["bad"].Status != Fail || res["bad"].Err != "boom" {
		t.Fatalf("expected failure, got %+v", res)
	}
}

func TestHTTPCheck(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "/bad" {
			w.WriteHeader(http.StatusInternalServerError)
		}
	}))
	defer srv.Close()
	ctx := context.Background()
	if err := HTTPCheck(srv.Client(), srv.URL+"/ok")(ctx); err != nil {
		t.Fatalf("ok: %v", err)
	}
	if err := HTTPCheck(srv.Client(), srv.URL+"/bad")(ctx); err == nil {
		t.Fatal("bad: expected error")
	}
	if err := HTTPCheck(srv.Client(), "")(ctx); err != ErrDisabled {
		t.Fatalf("empty url: expected disabled, got %v", err)
	}
}
