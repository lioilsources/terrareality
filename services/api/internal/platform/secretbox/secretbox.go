// Package secretbox seals small secrets (TOTP keys) at rest with AES-256-GCM
// and signs short payloads with HMAC-SHA256, both keyed from APP_SECRET_KEY.
package secretbox

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"errors"
)

// Box holds keys derived from the application secret.
type Box struct {
	aead   cipher.AEAD
	macKey []byte
}

// New derives an encryption and a MAC key from secret.
func New(secret string) (*Box, error) {
	if len(secret) < 32 {
		return nil, errors.New("secretbox: secret too short")
	}
	encKey := derive(secret, "terra/seal/v1")
	block, err := aes.NewCipher(encKey)
	if err != nil {
		return nil, err
	}
	aead, err := cipher.NewGCM(block)
	if err != nil {
		return nil, err
	}
	return &Box{aead: aead, macKey: derive(secret, "terra/mac/v1")}, nil
}

func derive(secret, label string) []byte {
	m := hmac.New(sha256.New, []byte(secret))
	m.Write([]byte(label))
	return m.Sum(nil)
}

// Seal encrypts plaintext; the nonce is prepended to the output.
func (b *Box) Seal(plaintext []byte) ([]byte, error) {
	nonce := make([]byte, b.aead.NonceSize())
	if _, err := rand.Read(nonce); err != nil {
		return nil, err
	}
	return b.aead.Seal(nonce, nonce, plaintext, nil), nil
}

// Open decrypts a value produced by Seal.
func (b *Box) Open(sealed []byte) ([]byte, error) {
	n := b.aead.NonceSize()
	if len(sealed) < n {
		return nil, errors.New("secretbox: sealed value too short")
	}
	return b.aead.Open(nil, sealed[:n], sealed[n:], nil)
}

// Sign returns an HMAC-SHA256 tag over data.
func (b *Box) Sign(data []byte) []byte {
	m := hmac.New(sha256.New, b.macKey)
	m.Write(data)
	return m.Sum(nil)
}

// Verify checks a tag produced by Sign in constant time.
func (b *Box) Verify(data, tag []byte) bool {
	return hmac.Equal(b.Sign(data), tag)
}
