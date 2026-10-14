package account

import "net/netip"

func parseIP(s string) *netip.Addr {
	a, err := netip.ParseAddr(s)
	if err != nil {
		return nil
	}
	return &a
}

func ptr[T any](v T) *T { return &v }
