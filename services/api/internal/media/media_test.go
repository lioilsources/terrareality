package media

import (
	"bytes"
	"encoding/binary"
	"hash/crc32"
	"image"
	"image/color"
	"image/jpeg"
	"image/png"
	"strings"
	"testing"
)

func testImage() image.Image {
	img := image.NewRGBA(image.Rect(0, 0, 320, 240))
	for x := 0; x < 320; x++ {
		img.Set(x, x%240, color.RGBA{200, 50, 50, 255})
	}
	return img
}

// exifAPP1 builds an APP1 segment with orientation and a fake GPS marker.
func exifAPP1(orientation uint16) []byte {
	tiff := []byte("MM\x00\x2a\x00\x00\x00\x08")
	ifd := make([]byte, 2+12+4)
	binary.BigEndian.PutUint16(ifd[0:2], 1)
	binary.BigEndian.PutUint16(ifd[2:4], 0x0112)
	binary.BigEndian.PutUint16(ifd[4:6], 3)
	binary.BigEndian.PutUint32(ifd[6:10], 1)
	binary.BigEndian.PutUint16(ifd[10:12], orientation)
	payload := append([]byte("Exif\x00\x00"), append(tiff, ifd...)...)
	payload = append(payload, []byte("GPS-50.0841N-14.4251E")...)
	seg := []byte{0xFF, 0xE1, 0, 0}
	binary.BigEndian.PutUint16(seg[2:4], uint16(len(payload)+2))
	return append(seg, payload...)
}

func TestSanitizeJPEGStripsEXIFAndKeepsOrientation(t *testing.T) {
	var buf bytes.Buffer
	if err := jpeg.Encode(&buf, testImage(), &jpeg.Options{Quality: 80}); err != nil {
		t.Fatal(err)
	}
	raw := buf.Bytes()
	withExif := append(append(append([]byte{}, raw[:2]...), exifAPP1(6)...), raw[2:]...)
	clean, info, err := Sanitize(withExif)
	if err != nil {
		t.Fatal(err)
	}
	if bytes.Contains(clean, []byte("GPS-50.0841")) || bytes.Contains(clean, []byte("Exif")) {
		t.Fatal("EXIF survived")
	}
	if info.Orientation != 6 || info.Width != 320 || info.Height != 240 || info.ContentType != "image/jpeg" {
		t.Fatalf("info %+v", info)
	}
	if _, err := jpeg.Decode(bytes.NewReader(clean)); err != nil {
		t.Fatalf("clean JPEG does not decode: %v", err)
	}
}

func pngChunk(typ string, data []byte) []byte {
	c := make([]byte, 8, 12+len(data))
	binary.BigEndian.PutUint32(c[0:4], uint32(len(data)))
	copy(c[4:8], typ)
	c = append(c, data...)
	crc := crc32.ChecksumIEEE(append([]byte(typ), data...))
	return binary.BigEndian.AppendUint32(c, crc)
}

func TestSanitizePNGStripsText(t *testing.T) {
	var buf bytes.Buffer
	if err := png.Encode(&buf, testImage()); err != nil {
		t.Fatal(err)
	}
	raw := buf.Bytes()
	// Insert a tEXt chunk after IHDR (8 signature + 25 IHDR).
	withText := append(append(append([]byte{}, raw[:33]...), pngChunk("tEXt", []byte("Comment\x00secret owner phone"))...), raw[33:]...)
	clean, info, err := Sanitize(withText)
	if err != nil {
		t.Fatal(err)
	}
	if bytes.Contains(clean, []byte("secret owner phone")) || info.ContentType != "image/png" {
		t.Fatal("text chunk survived")
	}
	if _, err := png.Decode(bytes.NewReader(clean)); err != nil {
		t.Fatal(err)
	}
}

func TestSanitizeRejects(t *testing.T) {
	if _, _, err := Sanitize([]byte("%PDF-1.7 not an image")); err != ErrUnsupported {
		t.Fatalf("pdf: %v", err)
	}
	var buf bytes.Buffer
	_ = png.Encode(&buf, image.NewRGBA(image.Rect(0, 0, 50, 50)))
	if _, _, err := Sanitize(buf.Bytes()); err != ErrTooSmall {
		t.Fatalf("tiny: %v", err)
	}
}

func TestImgproxySignature(t *testing.T) {
	// Values from the imgproxy documentation example key/salt "secret"/"hello".
	p, err := NewImgproxy("http://img.test", "terra", "736563726574", "68656C6C6F")
	if err != nil {
		t.Fatal(err)
	}
	u := p.URL("orgs/x/media/y/original", 400, 6)
	if !strings.HasPrefix(u, "http://img.test/") || !strings.Contains(u, "/rs:fit:400:0:0/ar:false/rot:90/") {
		t.Fatalf("url %s", u)
	}
	if p.URL("k", 400, 1) == p.URL("k", 1024, 1) {
		t.Fatal("variants share a signature")
	}
}
