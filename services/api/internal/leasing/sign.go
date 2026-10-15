package leasing

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"time"
)

// SignRequest asks a provider to sign a document for one party.
type SignRequest struct {
	DocumentSHA256 []byte
	PartyName      string
	PartyEmail     string
	IP             string
	UserAgent      string
}

// SignResult is a completed signature or a pending session.
type SignResult struct {
	Signed      bool
	ExternalID  string
	RedirectURL string         // set when the signer must continue at the provider
	Evidence    map[string]any // stored with the signature
}

// SignatureProvider signs lease documents. Implementations: Mock (dev and
// tests, simple electronic signature with evidence), UploadScan (the
// landlord uploads a scan signed on paper) and Bank iD SIGN (qualified
// signature, needs a contract with Bank iD; see OQ-19).
type SignatureProvider interface {
	Name() string
	Sign(ctx context.Context, req SignRequest) (SignResult, error)
}

// MockSigner records a simple electronic signature with evidence.
type MockSigner struct{}

// Name implements SignatureProvider.
func (MockSigner) Name() string { return "mock" }

// Sign implements SignatureProvider.
func (MockSigner) Sign(_ context.Context, r SignRequest) (SignResult, error) {
	at := time.Now().UTC().Format(time.RFC3339)
	sum := sha256.Sum256([]byte(hex.EncodeToString(r.DocumentSHA256) + "|" + r.PartyEmail + "|" + at))
	return SignResult{Signed: true, ExternalID: "mock-" + hex.EncodeToString(sum[:8]), Evidence: map[string]any{
		"provider": "mock", "document_sha256": hex.EncodeToString(r.DocumentSHA256), "signer": r.PartyName,
		"email": r.PartyEmail, "ip": r.IP, "user_agent": r.UserAgent, "signed_at": at,
		"level": "simple electronic signature (mock)",
	}}, nil
}
