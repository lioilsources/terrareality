package media

import (
	"bytes"
	"encoding/binary"
	"image"
	"image/jpeg"
	"image/png"
	"testing"
)

// webpChunk builds a RIFF chunk (padded to even length).
func webpChunk(typ string, payload []byte) []byte {
	c := append([]byte(typ), 0, 0, 0, 0)
	binary.LittleEndian.PutUint32(c[4:8], uint32(len(payload)))
	c = append(c, payload...)
	if len(payload)%2 == 1 {
		c = append(c, 0)
	}
	return c
}

func riff(chunks ...[]byte) []byte {
	body := []byte("WEBP")
	for _, c := range chunks {
		body = append(body, c...)
	}
	out := append([]byte("RIFF"), 0, 0, 0, 0)
	binary.LittleEndian.PutUint32(out[4:8], uint32(len(body)))
	return append(out, body...)
}

func TestSanitizeWebPShortVP8XIsCorrupt(t *testing.T) {
	for _, n := range []int{0, 1, 9} {
		data := riff(webpChunk("VP8X", make([]byte, n)))
		if _, _, err := Sanitize(data); err != ErrCorrupt {
			t.Fatalf("VP8X len %d: %v", n, err)
		}
	}
}

func TestSanitizeWebPHugeChunkLength(t *testing.T) {
	data := riff([]byte("EXIF\xff\xff\xff\xff"))
	if _, _, err := Sanitize(data); err != ErrCorrupt {
		t.Fatalf("got %v", err)
	}
}

func TestSanitizeJPEGExifOffsetOutOfRange(t *testing.T) {
	var buf bytes.Buffer
	if err := jpeg.Encode(&buf, testImage(), nil); err != nil {
		t.Fatal(err)
	}
	app1 := exifAPP1(6)
	// IFD offset at Exif header (6) + TIFF offset field (4) inside the payload.
	binary.BigEndian.PutUint32(app1[4+6+4:], 0xFFFFFFF0)
	raw := buf.Bytes()
	data := append(append(append([]byte{}, raw[:2]...), app1...), raw[2:]...)
	_, info, err := Sanitize(data)
	if err != nil {
		t.Fatal(err)
	}
	if info.Orientation != 1 {
		t.Fatalf("orientation %d", info.Orientation)
	}
}

// FuzzSanitize feeds untrusted bytes to the strippers; it must never panic
// and anything it accepts must decode and be metadata free.
func FuzzSanitize(f *testing.F) {
	var j bytes.Buffer
	_ = jpeg.Encode(&j, testImage(), nil)
	raw := j.Bytes()
	f.Add(raw)
	f.Add(append(append(append([]byte{}, raw[:2]...), exifAPP1(6)...), raw[2:]...))
	var p bytes.Buffer
	_ = png.Encode(&p, testImage())
	f.Add(p.Bytes())
	f.Add(riff(webpChunk("VP8X", nil)))
	f.Add(riff(webpChunk("VP8X", make([]byte, 10)), webpChunk("EXIF", []byte("Exif\x00\x00MM"))))
	f.Add([]byte("\x89PNG\r\n\x1a\n\xff\xff\xff\xffIHDR"))
	f.Add([]byte{0xFF, 0xD8, 0xFF, 0xE1, 0x00, 0x02})
	f.Fuzz(func(t *testing.T, data []byte) {
		clean, info, err := Sanitize(data)
		if err != nil {
			return
		}
		if int64(len(clean)) != info.Size || len(clean) > len(data) {
			t.Fatalf("size %d vs info %d (input %d)", len(clean), info.Size, len(data))
		}
		if _, _, err := image.DecodeConfig(bytes.NewReader(clean)); err != nil {
			t.Fatalf("accepted output does not decode: %v", err)
		}
	})
}

// FuzzExifOrientation targets the EXIF parser directly.
func FuzzExifOrientation(f *testing.F) {
	f.Add(exifAPP1(6)[4:])
	f.Add([]byte("Exif\x00\x00II*\x00\xff\xff\xff\xff\x00\x00"))
	f.Fuzz(func(t *testing.T, p []byte) {
		if o := exifOrientation(p); o < 0 || o > 8 {
			t.Fatalf("orientation %d", o)
		}
	})
}
