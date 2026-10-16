// Package media handles listing photos: format checks, metadata stripping,
// malware scanning and signed imgproxy URLs for resized variants.
package media

import (
	"bytes"
	"crypto/sha256"
	"encoding/binary"
	"errors"
	"image"
	_ "image/jpeg" // register decoders for DecodeConfig
	_ "image/png"

	_ "golang.org/x/image/webp"
)

// Limits for uploads.
const (
	MaxBytes  = 20 << 20   // 20 MiB per photo
	MaxPixels = 50_000_000 // decompression bomb guard
	MinSide   = 200
)

// Info describes a sanitized image.
type Info struct {
	ContentType string
	Width       int
	Height      int
	Orientation int // EXIF orientation (1 = upright), applied when rendering
	SHA256      []byte
	Size        int64
}

// Rejection reasons (stable codes shown to users).
var (
	ErrUnsupported = errors.New("unsupported_format")
	ErrTooLarge    = errors.New("file_too_large")
	ErrTooSmall    = errors.New("image_too_small")
	ErrCorrupt     = errors.New("corrupt_image")
)

// Sanitize verifies the image and removes metadata (EXIF incl. GPS, XMP,
// IPTC, text chunks) without re-encoding, so quality is untouched.
func Sanitize(data []byte) ([]byte, Info, error) {
	if len(data) > MaxBytes {
		return nil, Info{}, ErrTooLarge
	}
	var (
		clean  []byte
		orient = 1
		ct     string
		err    error
	)
	switch {
	case bytes.HasPrefix(data, []byte{0xFF, 0xD8, 0xFF}):
		ct = "image/jpeg"
		clean, orient, err = stripJPEG(data)
	case bytes.HasPrefix(data, []byte("\x89PNG\r\n\x1a\n")):
		ct = "image/png"
		clean, err = stripPNG(data)
	case len(data) > 12 && string(data[0:4]) == "RIFF" && string(data[8:12]) == "WEBP":
		ct = "image/webp"
		clean, err = stripWebP(data)
	default:
		return nil, Info{}, ErrUnsupported
	}
	if err != nil {
		return nil, Info{}, ErrCorrupt
	}
	cfg, _, err := image.DecodeConfig(bytes.NewReader(clean))
	if err != nil {
		return nil, Info{}, ErrCorrupt
	}
	if cfg.Width <= 0 || cfg.Height <= 0 || cfg.Width > MaxPixels || cfg.Height > MaxPixels ||
		cfg.Width*cfg.Height > MaxPixels {
		return nil, Info{}, ErrTooLarge
	}
	if cfg.Width < MinSide || cfg.Height < MinSide {
		return nil, Info{}, ErrTooSmall
	}
	sum := sha256.Sum256(clean)
	return clean, Info{ContentType: ct, Width: cfg.Width, Height: cfg.Height, Orientation: orient,
		SHA256: sum[:], Size: int64(len(clean))}, nil
}

// stripJPEG drops APP1 (EXIF/XMP), APP13 (IPTC) and COM segments and returns
// the EXIF orientation found before removal.
func stripJPEG(data []byte) ([]byte, int, error) {
	out := bytes.NewBuffer(make([]byte, 0, len(data)))
	out.Write(data[:2]) // SOI
	orient := 1
	i := 2
	for i+4 <= len(data) {
		if data[i] != 0xFF {
			return nil, 1, ErrCorrupt
		}
		marker := data[i+1]
		if marker == 0xD8 || (marker >= 0xD0 && marker <= 0xD7) || marker == 0x01 || marker == 0xFF {
			out.Write(data[i : i+2])
			i += 2
			continue
		}
		size := int(binary.BigEndian.Uint16(data[i+2 : i+4]))
		if size < 2 || i+2+size > len(data) {
			return nil, 1, ErrCorrupt
		}
		seg := data[i : i+2+size]
		switch {
		case marker == 0xE1:
			if o := exifOrientation(seg[4:]); o != 0 {
				orient = o
			}
		case marker == 0xED || marker == 0xFE:
			// IPTC and comments: dropped
		case marker == 0xDA:
			// Start of scan: the rest is entropy-coded image data.
			out.Write(data[i:])
			return out.Bytes(), orient, nil
		default:
			out.Write(seg)
		}
		i += 2 + size
	}
	return nil, 1, ErrCorrupt
}

// exifOrientation reads tag 0x0112 from an APP1 "Exif\0\0" payload.
func exifOrientation(p []byte) int {
	if len(p) < 14 || string(p[:6]) != "Exif\x00\x00" {
		return 0
	}
	t := p[6:]
	var bo binary.ByteOrder
	switch string(t[:2]) {
	case "II":
		bo = binary.LittleEndian
	case "MM":
		bo = binary.BigEndian
	default:
		return 0
	}
	off := int(bo.Uint32(t[4:8]))
	if off < 0 || off > len(t) || off+2 > len(t) {
		return 0
	}
	n := int(bo.Uint16(t[off : off+2]))
	for k := 0; k < n; k++ {
		e := off + 2 + k*12
		if e+12 > len(t) {
			return 0
		}
		if bo.Uint16(t[e:e+2]) == 0x0112 {
			v := int(bo.Uint16(t[e+8 : e+10]))
			if v >= 1 && v <= 8 {
				return v
			}
		}
	}
	return 0
}

// stripPNG drops ancillary metadata chunks.
func stripPNG(data []byte) ([]byte, error) {
	drop := map[string]bool{"eXIf": true, "tEXt": true, "iTXt": true, "zTXt": true, "tIME": true}
	out := bytes.NewBuffer(make([]byte, 0, len(data)))
	out.Write(data[:8])
	i := 8
	for i+12 <= len(data) {
		n := int(binary.BigEndian.Uint32(data[i : i+4]))
		if n < 0 || n > len(data) || i+12+n > len(data) {
			return nil, ErrCorrupt
		}
		typ := string(data[i+4 : i+8])
		if !drop[typ] {
			out.Write(data[i : i+12+n])
		}
		i += 12 + n
		if typ == "IEND" {
			return out.Bytes(), nil
		}
	}
	return nil, ErrCorrupt
}

// stripWebP drops EXIF and XMP chunks and clears their VP8X flags.
func stripWebP(data []byte) ([]byte, error) {
	out := bytes.NewBuffer(make([]byte, 0, len(data)))
	out.Write(data[:12])
	i := 12
	for i+8 <= len(data) {
		typ := string(data[i : i+4])
		n := int(binary.LittleEndian.Uint32(data[i+4 : i+8]))
		end := i + 8 + n + n%2
		if n < 0 || end < i || end > len(data) {
			return nil, ErrCorrupt
		}
		switch typ {
		case "EXIF", "XMP ":
		case "VP8X":
			// VP8X has a fixed 10 byte payload; anything shorter is
			// malformed (and would index past the chunk below).
			if n < 10 {
				return nil, ErrCorrupt
			}
			chunk := append([]byte(nil), data[i:end]...)
			chunk[8] &^= 0x08 | 0x04 // EXIF and XMP flags
			out.Write(chunk)
		default:
			out.Write(data[i:end])
		}
		i = end
	}
	b := out.Bytes()
	binary.LittleEndian.PutUint32(b[4:8], uint32(len(b)-8))
	return b, nil
}
