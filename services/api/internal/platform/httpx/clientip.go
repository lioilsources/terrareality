package httpx

import (
	"context"
	"net"
	"net/http"
	"net/netip"
	"strings"
)

type clientIPKey struct{}

// ClientIP returns the client address resolved by TrustedProxies.
func ClientIP(ctx context.Context) string {
	if v, ok := ctx.Value(clientIPKey{}).(string); ok {
		return v
	}
	return ""
}

// ParsePrefixes parses CIDRs or bare IPs (e.g. "10.0.0.0/8,127.0.0.1").
func ParsePrefixes(list []string) ([]netip.Prefix, error) {
	var out []netip.Prefix
	for _, s := range list {
		if !strings.Contains(s, "/") {
			a, err := netip.ParseAddr(s)
			if err != nil {
				return nil, err
			}
			out = append(out, netip.PrefixFrom(a, a.BitLen()))
			continue
		}
		p, err := netip.ParsePrefix(s)
		if err != nil {
			return nil, err
		}
		out = append(out, p)
	}
	return out, nil
}

// TrustedProxies resolves the real client IP. X-Forwarded-For is honoured only
// when the direct peer is a trusted proxy (Caddy), and then the rightmost
// address that is not itself trusted wins. This avoids the spoofing problem of
// taking the leftmost header value.
func TrustedProxies(trusted []netip.Prefix) func(http.Handler) http.Handler {
	isTrusted := func(a netip.Addr) bool {
		for _, p := range trusted {
			if p.Contains(a) {
				return true
			}
		}
		return false
	}
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			ip := peerAddr(r.RemoteAddr)
			if ip.IsValid() && isTrusted(ip) {
				hops := strings.Split(r.Header.Get("X-Forwarded-For"), ",")
				for i := len(hops) - 1; i >= 0; i-- {
					a, err := netip.ParseAddr(strings.TrimSpace(hops[i]))
					if err != nil {
						break
					}
					ip = a
					if !isTrusted(a) {
						break
					}
				}
			}
			s := ""
			if ip.IsValid() {
				s = ip.Unmap().String()
			}
			next.ServeHTTP(w, r.WithContext(context.WithValue(r.Context(), clientIPKey{}, s)))
		})
	}
}

func peerAddr(remote string) netip.Addr {
	host, _, err := net.SplitHostPort(remote)
	if err != nil {
		host = remote
	}
	a, _ := netip.ParseAddr(host)
	return a.Unmap()
}
