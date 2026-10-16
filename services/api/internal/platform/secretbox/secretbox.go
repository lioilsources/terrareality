// Package secretbox seals small secrets (TOTP keys, landlord API keys) at rest
// with AES-256-GCM and signs short payloads with HMAC-SHA256, both keyed from
// APP_SECRET_KEY.
//
// A Box is a keyring (ASVS V6.4): one current key plus optional previous keys
// (APP_SECRET_KEY_PREVIOUS). Seal and Sign always use the current key; Open
// and Verify accept any key in the ring, so a key can be rotated without
// downtime and old data is re-encrypted later (terractl rotate-secrets).
//
// Sealed format: "TRK\x01" | key id (4 bytes) | nonce (12) | ciphertext+tag.
// Values sealed before the keyring existed have no header (nonce | ciphertext)
// and stay readable: Open tries every key on them.
package secretbox

import (
	"bytes"
	"crypto/aes"
	"crypto/cipher"
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
)

// MinSecretLen is the minimum length of every secret in the ring.
const MinSecretLen = 32

var (
	// ErrUnknownKey means the value names a key id that is not in the ring
	// (a previous key was removed too early).
	ErrUnknownKey = errors.New("secretbox: sealed with an unknown key")
	// ErrDecrypt means no key in the ring authenticates the value.
	ErrDecrypt = errors.New("secretbox: cannot open sealed value")
	// ErrTooShort means the value cannot contain a nonce and a tag.
	ErrTooShort = errors.New("secretbox: sealed value too short")
)

var magic = []byte{'T', 'R', 'K', 1}

const (
	kidLen    = 4
	headerLen = 4 + kidLen
)

type key struct {
	id     []byte
	aead   cipher.AEAD
	macKey []byte
}

// Box holds the keys derived from the current and previous application secrets.
type Box struct {
	keys []key // keys[0] is current
}

// New builds a keyring from the current secret and any previous secrets
// (newest first). Empty previous entries and duplicates of a newer key are
// ignored.
func New(current string, previous ...string) (*Box, error) {
	b := &Box{}
	seen := map[string]bool{}
	for i, s := range append([]string{current}, previous...) {
		if i > 0 && s == "" {
			continue
		}
		if len(s) < MinSecretLen {
			if i == 0 {
				return nil, errors.New("secretbox: secret too short")
			}
			return nil, fmt.Errorf("secretbox: previous secret #%d too short", i)
		}
		if seen[s] {
			continue
		}
		seen[s] = true
		k, err := newKey(s)
		if err != nil {
			return nil, err
		}
		for _, o := range b.keys {
			if bytes.Equal(o.id, k.id) {
				return nil, errors.New("secretbox: key id collision, choose another secret")
			}
		}
		b.keys = append(b.keys, k)
	}
	return b, nil
}

func newKey(secret string) (key, error) {
	block, err := aes.NewCipher(derive(secret, "terra/seal/v1"))
	if err != nil {
		return key{}, err
	}
	aead, err := cipher.NewGCM(block)
	if err != nil {
		return key{}, err
	}
	return key{id: derive(secret, "terra/kid/v1")[:kidLen], aead: aead, macKey: derive(secret, "terra/mac/v1")}, nil
}

func derive(secret, label string) []byte {
	m := hmac.New(sha256.New, []byte(secret))
	m.Write([]byte(label))
	return m.Sum(nil)
}

// KeyID returns the hex id of the current key (safe to log; it reveals
// nothing about the secret).
func (b *Box) KeyID() string { return hex.EncodeToString(b.keys[0].id) }

// KeyIDs returns the hex ids of all keys, current first.
func (b *Box) KeyIDs() []string {
	out := make([]string, len(b.keys))
	for i, k := range b.keys {
		out[i] = hex.EncodeToString(k.id)
	}
	return out
}

// Seal encrypts plaintext with the current key.
func (b *Box) Seal(plaintext []byte) ([]byte, error) {
	k := b.keys[0]
	n := k.aead.NonceSize()
	out := make([]byte, headerLen+n, headerLen+n+len(plaintext)+k.aead.Overhead())
	copy(out, magic)
	copy(out[len(magic):], k.id)
	nonce := out[headerLen:]
	if _, err := rand.Read(nonce); err != nil {
		return nil, err
	}
	return k.aead.Seal(out, nonce, plaintext, nil), nil
}

// Open decrypts a value produced by Seal under any key in the ring, including
// values in the legacy format without a key id.
func (b *Box) Open(sealed []byte) ([]byte, error) {
	if kid, body, ok := split(sealed); ok {
		if k, found := b.find(kid); found {
			if p, err := open(k, body); err == nil {
				return p, nil
			}
		} else if p, ok := b.openLegacy(sealed); ok {
			// A legacy nonce that happens to start with the header bytes.
			return p, nil
		} else {
			return nil, fmt.Errorf("%w (key id %s)", ErrUnknownKey, hex.EncodeToString(kid))
		}
	}
	if len(sealed) < b.keys[0].aead.NonceSize()+b.keys[0].aead.Overhead() {
		return nil, ErrTooShort
	}
	if p, ok := b.openLegacy(sealed); ok {
		return p, nil
	}
	return nil, ErrDecrypt
}

// IsCurrent reports whether sealed carries the current key id, i.e. whether
// rotation would leave it unchanged.
func (b *Box) IsCurrent(sealed []byte) bool {
	kid, _, ok := split(sealed)
	return ok && bytes.Equal(kid, b.keys[0].id)
}

// Reseal re-encrypts sealed with the current key. It returns changed=false
// (and the input) when the value already uses the current key.
func (b *Box) Reseal(sealed []byte) (out []byte, changed bool, err error) {
	if b.IsCurrent(sealed) {
		if _, err := b.Open(sealed); err != nil {
			return nil, false, err
		}
		return sealed, false, nil
	}
	p, err := b.Open(sealed)
	if err != nil {
		return nil, false, err
	}
	out, err = b.Seal(p)
	return out, err == nil, err
}

func split(sealed []byte) (kid, body []byte, ok bool) {
	if len(sealed) < headerLen || !bytes.Equal(sealed[:len(magic)], magic) {
		return nil, nil, false
	}
	return sealed[len(magic):headerLen], sealed[headerLen:], true
}

func (b *Box) find(kid []byte) (key, bool) {
	for _, k := range b.keys {
		if bytes.Equal(k.id, kid) {
			return k, true
		}
	}
	return key{}, false
}

func (b *Box) openLegacy(sealed []byte) ([]byte, bool) {
	for _, k := range b.keys {
		if p, err := open(k, sealed); err == nil {
			return p, true
		}
	}
	return nil, false
}

func open(k key, body []byte) ([]byte, error) {
	n := k.aead.NonceSize()
	if len(body) < n+k.aead.Overhead() {
		return nil, ErrTooShort
	}
	return k.aead.Open(nil, body[:n], body[n:], nil)
}

// Sign returns an HMAC-SHA256 tag over data under the current key.
func (b *Box) Sign(data []byte) []byte { return mac(b.keys[0].macKey, data) }

// Tags returns the tags of data under every key, current first. Use it to
// look up values stored as Sign hashes (recovery codes) during a rotation.
func (b *Box) Tags(data []byte) [][]byte {
	out := make([][]byte, len(b.keys))
	for i, k := range b.keys {
		out[i] = mac(k.macKey, data)
	}
	return out
}

// Verify checks a tag produced by Sign under any key, in constant time per key.
func (b *Box) Verify(data, tag []byte) bool {
	ok := false
	for _, t := range b.Tags(data) {
		if hmac.Equal(t, tag) {
			ok = true
		}
	}
	return ok
}

func mac(k, data []byte) []byte {
	m := hmac.New(sha256.New, k)
	m.Write(data)
	return m.Sum(nil)
}
