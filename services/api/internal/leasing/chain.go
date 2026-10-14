package leasing

import (
	"bytes"
	"crypto/sha256"
	"encoding/json"
	"fmt"
)

// Canonical encodes a payload deterministically: JSON with object keys sorted
// (encoding/json sorts map keys) and no insignificant whitespace.
func Canonical(payload map[string]any) ([]byte, error) {
	var v any
	raw, err := json.Marshal(payload)
	if err != nil {
		return nil, err
	}
	// Round-trip through any so nested structs become sorted maps too.
	if err := json.Unmarshal(raw, &v); err != nil {
		return nil, err
	}
	return json.Marshal(v)
}

// GenesisHash is the prev_hash of the first event of every lease.
var GenesisHash = make([]byte, sha256.Size)

// ChainHash is sha256(prev_hash || canonical_json(payload)).
func ChainHash(prev, canonical []byte) []byte {
	h := sha256.New()
	h.Write(prev)
	h.Write(canonical)
	return h.Sum(nil)
}

// ChainEvent is one stored event.
type ChainEvent struct {
	Seq      int32
	Payload  []byte // canonical JSON as stored
	PrevHash []byte
	Hash     []byte
}

// VerifyChain checks sequence numbers, links and hashes. It returns the
// number of valid events and an error describing the first break.
func VerifyChain(events []ChainEvent) (int, error) {
	prev := GenesisHash
	for i, e := range events {
		if int(e.Seq) != i+1 {
			return i, fmt.Errorf("event %d: sequence %d, want %d", i+1, e.Seq, i+1)
		}
		if !bytes.Equal(e.PrevHash, prev) {
			return i, fmt.Errorf("event %d: previous hash does not link", e.Seq)
		}
		var v any
		if err := json.Unmarshal(e.Payload, &v); err != nil {
			return i, fmt.Errorf("event %d: payload: %w", e.Seq, err)
		}
		canon, _ := json.Marshal(v)
		if !bytes.Equal(ChainHash(prev, canon), e.Hash) {
			return i, fmt.Errorf("event %d: hash mismatch", e.Seq)
		}
		prev = e.Hash
	}
	return len(events), nil
}
