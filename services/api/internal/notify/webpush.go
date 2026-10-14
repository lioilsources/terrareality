package notify

import (
	"bytes"
	"context"
	"crypto/aes"
	"crypto/cipher"
	"crypto/ecdh"
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/binary"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"time"

	"golang.org/x/crypto/hkdf"
)

// WebPush sends Web Push messages (RFC 8030) with VAPID authentication
// (RFC 8292) and aes128gcm payload encryption (RFC 8291). Browsers subscribe
// with the public key from VAPIDPublic.
type WebPush struct {
	key     *ecdsa.PrivateKey
	subject string // mailto: or https: contact for push services
	HTTP    *http.Client
}

var b64u = base64.RawURLEncoding

// NewWebPush derives the VAPID key pair from seed (APP_SECRET_KEY or a
// dedicated WEBPUSH_VAPID_SEED), so it stays stable across restarts without
// extra configuration.
func NewWebPush(seed, subject string) (*WebPush, error) {
	sum := sha256.Sum256([]byte("terra-vapid:" + seed))
	key, err := ecdsa.ParseRawPrivateKey(elliptic.P256(), sum[:])
	if err != nil {
		return nil, fmt.Errorf("vapid key: %w", err)
	}
	return &WebPush{key: key, subject: subject, HTTP: &http.Client{Timeout: 10 * time.Second}}, nil
}

// VAPIDPublic is the application server key for PushManager.subscribe.
func (w *WebPush) VAPIDPublic() string {
	return b64u.EncodeToString(w.publicBytes())
}

func (w *WebPush) publicBytes() []byte {
	b, _ := w.key.PublicKey.Bytes() // 0x04 || X || Y
	return b
}

// Push implements Pusher for platform "webpush".
func (w *WebPush) Push(ctx context.Context, p Push) error {
	var keys struct {
		P256dh string `json:"p256dh"`
		Auth   string `json:"auth"`
	}
	if err := json.Unmarshal(p.Keys, &keys); err != nil {
		return ErrDeviceGone
	}
	uaPub, err1 := b64u.DecodeString(trimPad(keys.P256dh))
	auth, err2 := b64u.DecodeString(trimPad(keys.Auth))
	if err1 != nil || err2 != nil {
		return ErrDeviceGone
	}
	payload, _ := json.Marshal(map[string]string{"title": p.Title, "body": p.Body, "link": p.Link})
	body, err := Encrypt(payload, uaPub, auth, nil, nil)
	if err != nil {
		return ErrDeviceGone
	}
	endpoint, err := url.Parse(p.Token)
	if err != nil || endpoint.Scheme != "https" {
		return ErrDeviceGone
	}
	jwt, err := w.vapidJWT(endpoint.Scheme + "://" + endpoint.Host)
	if err != nil {
		return err
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, p.Token, bytes.NewReader(body))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Encoding", "aes128gcm")
	req.Header.Set("Content-Type", "application/octet-stream")
	req.Header.Set("TTL", "86400")
	req.Header.Set("Urgency", "normal")
	req.Header.Set("Authorization", "vapid t="+jwt+", k="+w.VAPIDPublic())
	res, err := w.HTTP.Do(req)
	if err != nil {
		return fmt.Errorf("webpush: %w", err)
	}
	defer res.Body.Close()
	raw, _ := io.ReadAll(io.LimitReader(res.Body, 4<<10))
	switch {
	case res.StatusCode < 300:
		return nil
	case res.StatusCode == http.StatusNotFound || res.StatusCode == http.StatusGone:
		return ErrDeviceGone
	}
	return fmt.Errorf("webpush: status %d: %.200s", res.StatusCode, raw)
}

func trimPad(s string) string {
	for len(s) > 0 && s[len(s)-1] == '=' {
		s = s[:len(s)-1]
	}
	return s
}

func (w *WebPush) vapidJWT(aud string) (string, error) {
	head := b64u.EncodeToString([]byte(`{"typ":"JWT","alg":"ES256"}`))
	claims, _ := json.Marshal(map[string]any{"aud": aud, "exp": time.Now().Add(12 * time.Hour).Unix(), "sub": w.subject})
	msg := head + "." + b64u.EncodeToString(claims)
	h := sha256.Sum256([]byte(msg))
	r, s, err := ecdsa.Sign(rand.Reader, w.key, h[:])
	if err != nil {
		return "", err
	}
	sig := make([]byte, 64)
	r.FillBytes(sig[:32])
	s.FillBytes(sig[32:])
	return msg + "." + b64u.EncodeToString(sig), nil
}

// Encrypt encrypts a push payload for a subscription (RFC 8291, aes128gcm).
// salt and asPriv are random when nil (tests pass fixed values).
func Encrypt(plaintext, uaPublic, authSecret, salt []byte, asPriv *ecdh.PrivateKey) ([]byte, error) {
	curve := ecdh.P256()
	ua, err := curve.NewPublicKey(uaPublic)
	if err != nil {
		return nil, err
	}
	if len(authSecret) != 16 {
		return nil, errors.New("webpush: auth secret must be 16 bytes")
	}
	if asPriv == nil {
		if asPriv, err = curve.GenerateKey(rand.Reader); err != nil {
			return nil, err
		}
	}
	if salt == nil {
		salt = make([]byte, 16)
		if _, err := rand.Read(salt); err != nil {
			return nil, err
		}
	}
	shared, err := asPriv.ECDH(ua)
	if err != nil {
		return nil, err
	}
	asPublic := asPriv.PublicKey().Bytes()
	keyInfo := append(append([]byte("WebPush: info\x00"), uaPublic...), asPublic...)
	ikm := expand(hkdf.Extract(sha256.New, shared, authSecret), keyInfo, 32)
	prk := hkdf.Extract(sha256.New, ikm, salt)
	cek := expand(prk, []byte("Content-Encoding: aes128gcm\x00"), 16)
	nonce := expand(prk, []byte("Content-Encoding: nonce\x00"), 12)
	block, err := aes.NewCipher(cek)
	if err != nil {
		return nil, err
	}
	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return nil, err
	}
	record := gcm.Seal(nil, nonce, append(append([]byte{}, plaintext...), 0x02), nil)
	header := make([]byte, 0, 16+4+1+len(asPublic))
	header = append(header, salt...)
	header = binary.BigEndian.AppendUint32(header, 4096)
	header = append(header, byte(len(asPublic)))
	header = append(header, asPublic...)
	return append(header, record...), nil
}

func expand(prk, info []byte, n int) []byte {
	out := make([]byte, n)
	_, _ = io.ReadFull(hkdf.Expand(sha256.New, prk, info), out)
	return out
}

// PlatformRouter sends web push subscriptions through WebPush and
// everything else through Mobile (FCM, mock or log).
type PlatformRouter struct {
	Web    Pusher
	Mobile Pusher
}

// Push implements Pusher.
func (r PlatformRouter) Push(ctx context.Context, p Push) error {
	if p.Platform == "webpush" && r.Web != nil {
		return r.Web.Push(ctx, p)
	}
	return r.Mobile.Push(ctx, p)
}
