package media

import (
	"bufio"
	"context"
	"encoding/binary"
	"fmt"
	"net"
	"strings"
	"time"
)

// Scanner checks uploads for malware.
type Scanner interface {
	// Scan returns "clean", "infected" or "skipped" (no scanner configured).
	Scan(ctx context.Context, data []byte) (status, signature string, err error)
}

// NoScanner is used when ClamAV is not configured (dev without the av profile).
type NoScanner struct{}

// Scan implements Scanner.
func (NoScanner) Scan(context.Context, []byte) (string, string, error) { return "skipped", "", nil }

// ClamAV talks to clamd over TCP (INSTREAM).
type ClamAV struct{ Addr string }

// Scan implements Scanner.
func (c ClamAV) Scan(ctx context.Context, data []byte) (string, string, error) {
	d := net.Dialer{Timeout: 5 * time.Second}
	conn, err := d.DialContext(ctx, "tcp", c.Addr)
	if err != nil {
		return "", "", fmt.Errorf("clamd: %w", err)
	}
	defer conn.Close()
	_ = conn.SetDeadline(time.Now().Add(60 * time.Second))
	if _, err := conn.Write([]byte("zINSTREAM\x00")); err != nil {
		return "", "", err
	}
	const chunk = 64 << 10
	var size [4]byte
	for off := 0; off < len(data); off += chunk {
		end := min(off+chunk, len(data))
		binary.BigEndian.PutUint32(size[:], uint32(end-off))
		if _, err := conn.Write(size[:]); err != nil {
			return "", "", err
		}
		if _, err := conn.Write(data[off:end]); err != nil {
			return "", "", err
		}
	}
	binary.BigEndian.PutUint32(size[:], 0)
	if _, err := conn.Write(size[:]); err != nil {
		return "", "", err
	}
	reply, err := bufio.NewReader(conn).ReadString(0)
	if err != nil && reply == "" {
		return "", "", err
	}
	reply = strings.TrimRight(reply, "\x00\n")
	switch {
	case strings.HasSuffix(reply, "OK"):
		return "clean", "", nil
	case strings.HasSuffix(reply, "FOUND"):
		sig := strings.TrimSuffix(strings.TrimPrefix(reply, "stream: "), " FOUND")
		return "infected", sig, nil
	}
	return "", "", fmt.Errorf("clamd: unexpected reply %q", reply)
}
