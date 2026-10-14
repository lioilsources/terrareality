// Package tokens creates opaque random tokens and the hashes stored in the
// database. Raw tokens are never persisted.
package tokens

import (
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"math/big"
)

// New returns a URL-safe random token with 256 bits of entropy.
func New() string {
	b := make([]byte, 32)
	if _, err := rand.Read(b); err != nil {
		panic(err) // crypto/rand never fails on supported platforms
	}
	return base64.RawURLEncoding.EncodeToString(b)
}

// Hash returns the SHA-256 of a token as stored in the database.
func Hash(token string) []byte {
	h := sha256.Sum256([]byte(token))
	return h[:]
}

// Digits returns a random numeric code of length n (SMS codes).
func Digits(n int) string {
	out := make([]byte, n)
	for i := range out {
		v, err := rand.Int(rand.Reader, big.NewInt(10))
		if err != nil {
			panic(err)
		}
		out[i] = byte('0' + v.Int64())
	}
	return string(out)
}
