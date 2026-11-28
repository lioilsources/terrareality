package notify

import (
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/sha256"
	"encoding/base64"
	"testing"
)

// The VAPID key must stay what it was before the kit (every browser
// subscription is bound to it): sha256("terra-vapid:" + seed) as the P-256 key.
func TestVAPIDKeyUnchanged(t *testing.T) {
	seed := "dev-secret"
	sum := sha256.Sum256([]byte("terra-vapid:" + seed))
	key, err := ecdsa.ParseRawPrivateKey(elliptic.P256(), sum[:])
	if err != nil {
		t.Fatal(err)
	}
	pub, err := key.PublicKey.Bytes()
	if err != nil {
		t.Fatal(err)
	}
	w, err := NewWebPush(seed, "mailto:ops@example.org")
	if err != nil {
		t.Fatal(err)
	}
	if got, want := w.VAPIDPublic(), base64.RawURLEncoding.EncodeToString(pub); got != want {
		t.Fatalf("VAPID public key changed: %s != %s", got, want)
	}
}
