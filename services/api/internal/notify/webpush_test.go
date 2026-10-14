package notify

import (
	"bytes"
	"crypto/aes"
	"crypto/cipher"
	"crypto/ecdh"
	"crypto/sha256"
	"encoding/binary"
	"testing"

	"golang.org/x/crypto/hkdf"
)

func mustB64(t *testing.T, s string) []byte {
	t.Helper()
	b, err := b64u.DecodeString(s)
	if err != nil {
		t.Fatal(err)
	}
	return b
}

// RFC 8291, section 5 (example encryption).
func TestEncryptRFC8291Example(t *testing.T) {
	asPriv, err := ecdh.P256().NewPrivateKey(mustB64(t, "yfWPiYE-n46HLnH0KqZOF1fJJU3MYrct3AELtAQ-oRw"))
	if err != nil {
		t.Fatal(err)
	}
	uaPub := mustB64(t, "BCVxsr7N_eNgVRqvHtD0zTZsEc6-VV-JvLexhqUzORcxaOzi6-AYWXvTBHm4bjyPjs7Vd8pZGH6SRpkNtoIAiw4")
	auth := mustB64(t, "BTBZMqHH6r4Tts7J_aSIgg")
	salt := mustB64(t, "DGv6ra1nlYgDCS1FRnbzlw")
	got, err := Encrypt([]byte("When I grow up, I want to be a watermelon"), uaPub, auth, salt, asPriv)
	if err != nil {
		t.Fatal(err)
	}
	want := mustB64(t, "DGv6ra1nlYgDCS1FRnbzlwAAEABBBP4z9KsN6nGRTbVYI_c7VJSPQTBtkgcy27mlmlMoZIIgDll6e3vCYLocInmYWAmS6TlzAC8wEqKK6PBru3jl7A_yl95bQpu6cVPTpK4Mqgkf1CXztLVBSt2Ks3oZwbuwXPXLWyouBWLVWGNWQexSgSxsj_Qulcy4a-fN")
	if !bytes.Equal(got, want) {
		t.Fatalf("ciphertext differs:\n got %s\nwant %s", b64u.EncodeToString(got), b64u.EncodeToString(want))
	}
}

// A browser (user agent) can decrypt what we send with random keys.
func TestEncryptRoundTrip(t *testing.T) {
	ua, _ := ecdh.P256().GenerateKey(nil)
	auth := bytes.Repeat([]byte{7}, 16)
	msg := []byte(`{"title":"Nová zpráva","body":"Dobrý den"}`)
	body, err := Encrypt(msg, ua.PublicKey().Bytes(), auth, nil, nil)
	if err != nil {
		t.Fatal(err)
	}
	salt, rs, idlen := body[:16], binary.BigEndian.Uint32(body[16:20]), int(body[20])
	asPub := body[21 : 21+idlen]
	as, err := ecdh.P256().NewPublicKey(asPub)
	if err != nil || rs != 4096 {
		t.Fatalf("header: rs %d, %v", rs, err)
	}
	shared, _ := ua.ECDH(as)
	info := append(append([]byte("WebPush: info\x00"), ua.PublicKey().Bytes()...), asPub...)
	ikm := expand(hkdf.Extract(sha256.New, shared, auth), info, 32)
	prk := hkdf.Extract(sha256.New, ikm, salt)
	block, _ := aes.NewCipher(expand(prk, []byte("Content-Encoding: aes128gcm\x00"), 16))
	gcm, _ := cipher.NewGCM(block)
	plain, err := gcm.Open(nil, expand(prk, []byte("Content-Encoding: nonce\x00"), 12), body[21+idlen:], nil)
	if err != nil || !bytes.Equal(plain, append(msg, 2)) {
		t.Fatalf("decrypt: %q %v", plain, err)
	}
}

func TestVAPIDKeyIsStable(t *testing.T) {
	a, _ := NewWebPush("secret", "mailto:ops@terrareality.cz")
	b, _ := NewWebPush("secret", "mailto:ops@terrareality.cz")
	if a.VAPIDPublic() != b.VAPIDPublic() || len(mustB64(t, a.VAPIDPublic())) != 65 {
		t.Fatal("unstable or malformed VAPID key")
	}
	if _, err := a.vapidJWT("https://fcm.googleapis.com"); err != nil {
		t.Fatal(err)
	}
}
