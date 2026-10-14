package realtime

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/json"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
)

func TestTokensAreValidHS256(t *testing.T) {
	tk := Tokens{Secret: []byte("secret"), TTL: time.Hour}
	uid := uuid.New()
	tok, exp := tk.Connect(uid, time.Unix(1000, 0))
	if exp.Unix() != 4600 {
		t.Fatalf("exp = %d", exp.Unix())
	}
	parts := strings.Split(tok, ".")
	if len(parts) != 3 {
		t.Fatalf("token %q", tok)
	}
	mac := hmac.New(sha256.New, []byte("secret"))
	mac.Write([]byte(parts[0] + "." + parts[1]))
	if b64.EncodeToString(mac.Sum(nil)) != parts[2] {
		t.Fatal("bad signature")
	}
	raw, _ := b64.DecodeString(parts[1])
	var claims struct {
		Sub      string   `json:"sub"`
		Channels []string `json:"channels"`
	}
	_ = json.Unmarshal(raw, &claims)
	if claims.Sub != uid.String() || len(claims.Channels) != 1 || claims.Channels[0] != UserChannel(uid) {
		t.Fatalf("claims %+v", claims)
	}
}
