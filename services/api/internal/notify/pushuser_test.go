package notify

import (
	"context"
	"errors"
	"testing"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"github.com/terrareality/terrareality/services/api/internal/db"
)

type fakeDevices struct {
	devices []db.PushDevice
	err     error
	deleted []string
}

func (f *fakeDevices) SystemPushDevices(_ context.Context, _ uuid.UUID) ([]db.PushDevice, error) {
	return f.devices, f.err
}

func (f *fakeDevices) DeletePushDeviceByToken(_ context.Context, arg db.DeletePushDeviceByTokenParams) error {
	f.deleted = append(f.deleted, arg.Token)
	return nil
}

// fakePusher records pushes and fails for tokens listed in errs.
type fakePusher struct {
	got  []Push
	errs map[string]error
}

func (f *fakePusher) Push(_ context.Context, p Push) error {
	if err := f.errs[p.Token]; err != nil {
		return err
	}
	f.got = append(f.got, p)
	return nil
}

func TestPushUserSendsToEveryDevice(t *testing.T) {
	user := uuid.New()
	devs := &fakeDevices{devices: []db.PushDevice{{Platform: "fcm", Token: "a"}, {Platform: "fcm", Token: "gone"},
		{Platform: "webpush", Token: "b", Keys: []byte(`{"p256dh":"x"}`)}, {Platform: "fcm", Token: "broken"}}}
	p := &fakePusher{errs: map[string]error{"gone": ErrDeviceGone, "broken": errors.New("fcm: 500")}}
	n := PushUser(context.Background(), devs, p, nil, user, Push{Title: "t", Body: "b", Link: "http://web.test/smlouvy/l1",
		Data: PushData(PushLease, "l1", map[string]string{"state": "signed"})})
	if n != 2 || len(p.got) != 2 {
		t.Fatalf("sent %d, pushes %+v", n, p.got)
	}
	for _, x := range p.got {
		if x.UserID != user.String() || x.Data["kind"] != PushLease || x.Data["id"] != "l1" || x.Data["state"] != "signed" {
			t.Fatalf("push %+v", x)
		}
	}
	if p.got[1].Platform != "webpush" || string(p.got[1].Keys) != `{"p256dh":"x"}` {
		t.Fatalf("device fields not copied: %+v", p.got[1])
	}
	if len(devs.deleted) != 1 || devs.deleted[0] != "gone" {
		t.Fatalf("deleted %v", devs.deleted)
	}
}

func TestPushUserNeverFails(t *testing.T) {
	// Lookup errors and a missing pusher are swallowed (logged only).
	if n := PushUser(context.Background(), &fakeDevices{err: errors.New("db down")}, &fakePusher{}, nil, uuid.New(), Push{}); n != 0 {
		t.Fatalf("sent %d", n)
	}
	if n := PushUser(context.Background(), &fakeDevices{devices: []db.PushDevice{{Token: "a"}}}, nil, nil, uuid.New(), Push{}); n != 0 {
		t.Fatalf("sent %d without pusher", n)
	}
}

func TestTextPick(t *testing.T) {
	x := Text{"cs": "Ahoj", "en": "Hello"}
	if x.Pick("en") != "Hello" || x.Pick("de") != "Ahoj" || (Text{"en": "Hi"}).Pick("cs") != "Hi" {
		t.Fatal("pick")
	}
}

// The push job retries a failed device lookup; failed deliveries are not
// returned (a retry would repeat the pushes that went through).
func TestDeliverPushReturnsLookupErrorOnly(t *testing.T) {
	if _, err := DeliverPush(context.Background(), &fakeDevices{err: errors.New("db down")}, &fakePusher{}, nil, uuid.New(), Push{}); err == nil {
		t.Fatal("lookup error swallowed")
	}
	p := &fakePusher{errs: map[string]error{"a": errors.New("fcm: 500")}}
	if n, err := DeliverPush(context.Background(), &fakeDevices{devices: []db.PushDevice{{Token: "a"}, {Token: "b"}}}, p, nil, uuid.New(), Push{}); err != nil || n != 1 {
		t.Fatalf("sent %d err %v", n, err)
	}
}

type queueOutbox struct{ MemoryOutbox }

func (*queueOutbox) EnqueuePush(context.Context, pgx.Tx, uuid.UUID, Push) error { return nil }

// NewPushes queues through an outbox that also queues pushes (jobs.Outbox)
// and delivers at once otherwise (MemoryOutbox in tests).
func TestNewPushesPicksQueue(t *testing.T) {
	if ps := NewPushes(&queueOutbox{}, &fakePusher{}, nil); ps.Queue == nil || !ps.Enabled() {
		t.Fatalf("%+v", ps)
	}
	if ps := NewPushes(&MemoryOutbox{}, &fakePusher{}, nil); ps.Queue != nil {
		t.Fatalf("%+v", ps)
	}
	if ps := NewPushes(nil, nil, nil); ps.Enabled() {
		t.Fatal("enabled without a pusher")
	}
}

func TestPushTitlesHaveBothLocales(t *testing.T) {
	for k, v := range PushTitles {
		if v["cs"] == "" || v["en"] == "" {
			t.Fatalf("%s: %v", k, v)
		}
	}
}
