package main

import (
	"bytes"
	"context"
	"crypto/aes"
	"crypto/cipher"
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"fmt"
	"os"
	"testing"
	"time"

	"github.com/terrareality/terrareality/services/api/internal/db"
	platformdb "github.com/terrareality/terrareality/services/api/internal/platform/db"
	"github.com/terrareality/terrareality/services/api/internal/platform/secretbox"
	"github.com/terrareality/terrareality/services/api/internal/platform/tokens"
)

// legacySeal reproduces the pre-keyring secretbox format (nonce | ciphertext).
func legacySeal(t *testing.T, secret string, plaintext []byte) []byte {
	t.Helper()
	m := hmac.New(sha256.New, []byte(secret))
	m.Write([]byte("terra/seal/v1"))
	block, err := aes.NewCipher(m.Sum(nil))
	if err != nil {
		t.Fatal(err)
	}
	aead, err := cipher.NewGCM(block)
	if err != nil {
		t.Fatal(err)
	}
	nonce := make([]byte, aead.NonceSize())
	if _, err := rand.Read(nonce); err != nil {
		t.Fatal(err)
	}
	return aead.Seal(nonce, nonce, plaintext, nil)
}

// TestRotateSecrets needs a database (TEST_DATABASE_URL). Rows of other tests
// are sealed with other keys: they count as unreadable and stay untouched.
func TestRotateSecrets(t *testing.T) {
	url := os.Getenv("TEST_DATABASE_URL")
	if url == "" {
		t.Skip("TEST_DATABASE_URL not set")
	}
	ctx := context.Background()
	pool, err := platformdb.Open(ctx, url)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	if err := platformdb.Migrate(ctx, pool); err != nil {
		t.Fatal(err)
	}
	oldSecret, newSecret := tokens.New(), tokens.New() // 43 characters each
	oldBox, err := secretbox.New(oldSecret)
	if err != nil {
		t.Fatal(err)
	}
	ring, err := secretbox.New(newSecret, oldSecret)
	if err != nil {
		t.Fatal(err)
	}
	newOnly, _ := secretbox.New(newSecret)

	// Fixture: TOTP secret sealed with the old key, a pending secret in the
	// legacy format, a Revolut API key sealed with the old key.
	q := db.New(pool)
	u, err := q.CreateUser(ctx, db.CreateUserParams{Email: fmt.Sprintf("rotate-%d@example.cz", time.Now().UnixNano()),
		DisplayName: "Rotate", Locale: "cs"})
	if err != nil {
		t.Fatal(err)
	}
	totp, _ := oldBox.Seal([]byte("totp-secret"))
	pending := legacySeal(t, oldSecret, []byte("pending-secret"))
	if _, err := pool.Exec(ctx, `UPDATE users SET totp_secret = $2, totp_pending_secret = $3 WHERE id = $1`, u.ID, totp, pending); err != nil {
		t.Fatal(err)
	}
	o, err := q.CreateOrganization(ctx, db.CreateOrganizationParams{Kind: "personal", Name: "Rotate", JurisdictionCode: "CZ", PersonalOwnerID: &u.ID})
	if err != nil {
		t.Fatal(err)
	}
	apiKey, _ := oldBox.Seal([]byte("sk_revolut_key"))
	if _, err := q.UpsertRevolutAccount(ctx, db.UpsertRevolutAccountParams{OrgID: o.ID, ApiKeyEnc: apiKey, Mode: "sandbox", ConnectedBy: &u.ID}); err != nil {
		t.Fatal(err)
	}

	load := func() (totp, pending, apiKey []byte) {
		t.Helper()
		if err := pool.QueryRow(ctx, `SELECT totp_secret, totp_pending_secret FROM users WHERE id = $1`, u.ID).Scan(&totp, &pending); err != nil {
			t.Fatal(err)
		}
		if err := pool.QueryRow(ctx, `SELECT api_key_enc FROM org_revolut_accounts WHERE org_id = $1`, o.ID).Scan(&apiKey); err != nil {
			t.Fatal(err)
		}
		return
	}

	// Dry run: counts, changes nothing.
	stats, err := resealAll(ctx, pool, ring, 2, true)
	if err != nil {
		t.Fatal(err)
	}
	for _, s := range stats {
		if s.Rotated < 1 {
			t.Errorf("dry run %s.%s: nothing to rotate: %+v", s.Column.Table, s.Column.Column, s)
		}
	}
	t1, p1, k1 := load()
	if !bytes.Equal(t1, totp) || !bytes.Equal(p1, pending) || !bytes.Equal(k1, apiKey) {
		t.Fatal("dry run modified data")
	}

	// Real run with a small batch to cross batch boundaries.
	if _, err := resealAll(ctx, pool, ring, 2, false); err != nil {
		t.Fatal(err)
	}
	t2, p2, k2 := load()
	for name, c := range map[string]struct {
		sealed []byte
		want   string
	}{"totp_secret": {t2, "totp-secret"}, "totp_pending_secret": {p2, "pending-secret"}, "api_key_enc": {k2, "sk_revolut_key"}} {
		if !ring.IsCurrent(c.sealed) {
			t.Errorf("%s not sealed with the current key", name)
		}
		// After rotation the old key can be dropped.
		if got, err := newOnly.Open(c.sealed); err != nil || string(got) != c.want {
			t.Errorf("%s: %q %v", name, got, err)
		}
	}

	// Idempotent: a second run leaves the rotated values as they are.
	if _, err := resealAll(ctx, pool, ring, 500, false); err != nil {
		t.Fatal(err)
	}
	t3, p3, k3 := load()
	if !bytes.Equal(t2, t3) || !bytes.Equal(p2, p3) || !bytes.Equal(k2, k3) {
		t.Fatal("second run re-encrypted values that already use the current key")
	}
}
