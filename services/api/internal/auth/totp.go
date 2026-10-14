package auth

import (
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha1"
	"crypto/subtle"
	"encoding/base32"
	"encoding/binary"
	"fmt"
	"net/url"
	"strings"
	"time"
)

// TOTP per RFC 6238: HMAC-SHA1, 30 s steps, 6 digits. That is what common
// authenticator apps support.
const (
	totpPeriod = 30
	totpDigits = 6
	totpSkew   = 1 // accept one step before and after (clock drift)
)

var b32 = base32.StdEncoding.WithPadding(base32.NoPadding)

// NewTOTPSecret returns a random 160-bit secret.
func NewTOTPSecret() []byte {
	s := make([]byte, 20)
	if _, err := rand.Read(s); err != nil {
		panic(err)
	}
	return s
}

// TOTPSecretString encodes a secret for manual entry.
func TOTPSecretString(secret []byte) string { return b32.EncodeToString(secret) }

// TOTPURI builds the otpauth:// URI rendered as a QR code.
func TOTPURI(secret []byte, issuer, account string) string {
	label := url.PathEscape(issuer + ":" + account)
	q := url.Values{}
	q.Set("secret", TOTPSecretString(secret))
	q.Set("issuer", issuer)
	q.Set("algorithm", "SHA1")
	q.Set("digits", fmt.Sprint(totpDigits))
	q.Set("period", fmt.Sprint(totpPeriod))
	return "otpauth://totp/" + label + "?" + q.Encode()
}

// TOTPCode computes the code for a time step.
func TOTPCode(secret []byte, step int64) string {
	var msg [8]byte
	binary.BigEndian.PutUint64(msg[:], uint64(step))
	m := hmac.New(sha1.New, secret)
	m.Write(msg[:])
	sum := m.Sum(nil)
	off := sum[len(sum)-1] & 0x0f
	v := binary.BigEndian.Uint32(sum[off:off+4]) & 0x7fffffff
	return fmt.Sprintf("%0*d", totpDigits, v%1_000_000)
}

// TOTPStep returns the time step for t.
func TOTPStep(t time.Time) int64 { return t.Unix() / totpPeriod }

// ValidateTOTP returns the matched step (for replay protection) or 0.
func ValidateTOTP(secret []byte, code string, now time.Time) int64 {
	code = strings.TrimSpace(strings.ReplaceAll(code, " ", ""))
	if len(code) != totpDigits {
		return 0
	}
	cur := TOTPStep(now)
	for d := -totpSkew; d <= totpSkew; d++ {
		step := cur + int64(d)
		if subtle.ConstantTimeCompare([]byte(TOTPCode(secret, step)), []byte(code)) == 1 {
			return step
		}
	}
	return 0
}

// NewRecoveryCodes returns n codes formatted xxxxx-xxxxx (base32, lowercase).
func NewRecoveryCodes(n int) []string {
	out := make([]string, n)
	for i := range out {
		b := make([]byte, 7)
		if _, err := rand.Read(b); err != nil {
			panic(err)
		}
		s := strings.ToLower(b32.EncodeToString(b))[:10]
		out[i] = s[:5] + "-" + s[5:]
	}
	return out
}

// NormalizeRecoveryCode lowercases and strips spaces so user input matches.
func NormalizeRecoveryCode(s string) string {
	s = strings.ToLower(strings.ReplaceAll(strings.TrimSpace(s), " ", ""))
	if len(s) == 10 && !strings.Contains(s, "-") {
		s = s[:5] + "-" + s[5:]
	}
	return s
}
