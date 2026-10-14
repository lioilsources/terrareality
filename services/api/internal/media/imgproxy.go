package media

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"fmt"
	"strings"
)

// Imgproxy builds signed URLs for resized, metadata-free variants. Originals
// are private in object storage; browsers only ever see imgproxy URLs.
type Imgproxy struct {
	BaseURL string // public imgproxy URL, e.g. http://localhost:8081
	Bucket  string
	key     []byte
	salt    []byte
}

// NewImgproxy parses the hex key and salt (IMGPROXY_KEY / IMGPROXY_SALT).
func NewImgproxy(baseURL, bucket, keyHex, saltHex string) (*Imgproxy, error) {
	key, err := hex.DecodeString(keyHex)
	if err != nil {
		return nil, fmt.Errorf("imgproxy key: %w", err)
	}
	salt, err := hex.DecodeString(saltHex)
	if err != nil {
		return nil, fmt.Errorf("imgproxy salt: %w", err)
	}
	return &Imgproxy{BaseURL: strings.TrimRight(baseURL, "/"), Bucket: bucket, key: key, salt: salt}, nil
}

// Variant sizes used by clients.
var Variants = map[string]int{"thumb": 400, "medium": 1024, "large": 1920}

// URL returns a signed URL for object key resized to width (fit, no upscale).
func (p *Imgproxy) URL(key string, width, orientation int) string {
	opts := []string{fmt.Sprintf("rs:fit:%d:0:0", width), "ar:false"}
	switch orientation {
	case 3:
		opts = append(opts, "rot:180")
	case 6:
		opts = append(opts, "rot:90")
	case 8:
		opts = append(opts, "rot:270")
	}
	src := base64.RawURLEncoding.EncodeToString([]byte("s3://" + p.Bucket + "/" + key))
	path := "/" + strings.Join(opts, "/") + "/" + src
	mac := hmac.New(sha256.New, p.key)
	mac.Write(p.salt)
	mac.Write([]byte(path))
	return p.BaseURL + "/" + base64.RawURLEncoding.EncodeToString(mac.Sum(nil)) + path
}

// URLs returns all variants of a photo.
func (p *Imgproxy) URLs(key string, orientation int) map[string]string {
	out := make(map[string]string, len(Variants))
	for name, w := range Variants {
		out[name] = p.URL(key, w, orientation)
	}
	return out
}
