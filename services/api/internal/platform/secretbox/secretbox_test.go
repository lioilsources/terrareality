package secretbox

import (
	"bytes"
	"crypto/rand"
	"errors"
	"strings"
	"testing"
)

var (
	oldSecret = strings.Repeat("o", 32)
	newSecret = strings.Repeat("n", 32)
)

func mustNew(t *testing.T, current string, previous ...string) *Box {
	t.Helper()
	b, err := New(current, previous...)
	if err != nil {
		t.Fatal(err)
	}
	return b
}

// legacySeal reproduces the pre-keyring format: nonce | ciphertext.
func legacySeal(t *testing.T, secret string, plaintext []byte) []byte {
	t.Helper()
	k, err := newKey(secret)
	if err != nil {
		t.Fatal(err)
	}
	nonce := make([]byte, k.aead.NonceSize())
	if _, err := rand.Read(nonce); err != nil {
		t.Fatal(err)
	}
	return k.aead.Seal(nonce, nonce, plaintext, nil)
}

func TestSealOpenRoundTrip(t *testing.T) {
	b := mustNew(t, newSecret)
	sealed, err := b.Seal([]byte("totp"))
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.HasPrefix(sealed, magic) || !b.IsCurrent(sealed) {
		t.Fatalf("sealed value lacks the current key header: %x", sealed[:headerLen])
	}
	got, err := b.Open(sealed)
	if err != nil || string(got) != "totp" {
		t.Fatalf("open: %q %v", got, err)
	}
}

func TestNewKeyUsedOldKeyReadable(t *testing.T) {
	old := mustNew(t, oldSecret)
	sealedOld, _ := old.Seal([]byte("before"))

	ring := mustNew(t, newSecret, oldSecret)
	got, err := ring.Open(sealedOld)
	if err != nil || string(got) != "before" {
		t.Fatalf("old value under the new ring: %q %v", got, err)
	}
	if ring.IsCurrent(sealedOld) {
		t.Fatal("a value sealed with the previous key must not count as current")
	}
	sealedNew, _ := ring.Seal([]byte("after"))
	if !ring.IsCurrent(sealedNew) {
		t.Fatal("Seal must use the current key")
	}
	if _, err := old.Open(sealedNew); err == nil {
		t.Fatal("the old key alone must not open a value sealed with the new key")
	}
	if ring.KeyID() == old.KeyID() || len(ring.KeyIDs()) != 2 || ring.KeyIDs()[1] != old.KeyID() {
		t.Fatalf("key ids: ring %v old %s", ring.KeyIDs(), old.KeyID())
	}
}

func TestLegacyFormatReadable(t *testing.T) {
	legacy := legacySeal(t, oldSecret, []byte("legacy"))
	for name, b := range map[string]*Box{
		"same key":     mustNew(t, oldSecret),
		"previous key": mustNew(t, newSecret, oldSecret),
	} {
		got, err := b.Open(legacy)
		if err != nil || string(got) != "legacy" {
			t.Errorf("%s: %q %v", name, got, err)
		}
		if b.IsCurrent(legacy) {
			t.Errorf("%s: legacy value must not count as current", name)
		}
	}
	if _, err := mustNew(t, newSecret).Open(legacy); !errors.Is(err, ErrDecrypt) {
		t.Fatalf("legacy value without its key: %v", err)
	}
}

func TestUnknownKeyID(t *testing.T) {
	sealed, _ := mustNew(t, oldSecret).Seal([]byte("x"))
	_, err := mustNew(t, newSecret).Open(sealed)
	if !errors.Is(err, ErrUnknownKey) {
		t.Fatalf("want ErrUnknownKey, got %v", err)
	}
}

func TestTamperedAndShortValues(t *testing.T) {
	b := mustNew(t, newSecret)
	sealed, _ := b.Seal([]byte("x"))
	sealed[len(sealed)-1] ^= 1
	if _, err := b.Open(sealed); err == nil {
		t.Fatal("tampered value opened")
	}
	if _, err := b.Open([]byte("short")); !errors.Is(err, ErrTooShort) {
		t.Fatalf("short value: %v", err)
	}
}

func TestReseal(t *testing.T) {
	ring := mustNew(t, newSecret, oldSecret)
	for name, in := range map[string][]byte{
		"previous key": func() []byte { s, _ := mustNew(t, oldSecret).Seal([]byte("v")); return s }(),
		"legacy":       legacySeal(t, oldSecret, []byte("v")),
	} {
		out, changed, err := ring.Reseal(in)
		if err != nil || !changed || !ring.IsCurrent(out) {
			t.Fatalf("%s: changed=%v err=%v", name, changed, err)
		}
		if p, err := mustNew(t, newSecret).Open(out); err != nil || string(p) != "v" {
			t.Fatalf("%s: resealed value not readable with the new key alone: %q %v", name, p, err)
		}
		again, changed, err := ring.Reseal(out)
		if err != nil || changed || !bytes.Equal(again, out) {
			t.Fatalf("%s: second reseal must be a no-op (changed=%v err=%v)", name, changed, err)
		}
	}
	if _, _, err := mustNew(t, newSecret).Reseal(legacySeal(t, oldSecret, []byte("v"))); err == nil {
		t.Fatal("reseal without the old key must fail")
	}
}

func TestSignVerifyAcrossRotation(t *testing.T) {
	old := mustNew(t, oldSecret)
	ring := mustNew(t, newSecret, oldSecret)
	data := []byte("recovery:u:abcd")
	if !ring.Verify(data, old.Sign(data)) {
		t.Fatal("tag under the previous key must verify during the grace period")
	}
	if bytes.Equal(ring.Sign(data), old.Sign(data)) {
		t.Fatal("Sign must use the current key")
	}
	if old.Verify(data, ring.Sign(data)) {
		t.Fatal("the old key must not verify a tag of the new key")
	}
	tags := ring.Tags(data)
	if len(tags) != 2 || !bytes.Equal(tags[0], ring.Sign(data)) || !bytes.Equal(tags[1], old.Sign(data)) {
		t.Fatal("Tags must list the current key first, then previous keys")
	}
	if mustNew(t, newSecret).Verify(data, old.Sign(data)) {
		t.Fatal("tag of a removed key must not verify")
	}
}

func TestNewValidatesSecrets(t *testing.T) {
	if _, err := New("short"); err == nil {
		t.Fatal("short current secret accepted")
	}
	if _, err := New(newSecret, "short"); err == nil {
		t.Fatal("short previous secret accepted")
	}
	b, err := New(newSecret, "", newSecret, oldSecret)
	if err != nil || len(b.keys) != 2 {
		t.Fatalf("empty and duplicate previous secrets must be ignored: %v %d", err, len(b.keys))
	}
}
