package httpapi

import (
	"net"
	"net/http"
	"net/netip"
	"strings"
)

// realIP sets r.RemoteAddr to the client's address. Forwarding headers are
// believed only from a reverse proxy on a loopback or private address (the
// usual Caddy or nginx in front of the container), and only X-Forwarded-For,
// read from the right: the first address that is not such a proxy is the
// client. Headers a client can set and a proxy passes on unchanged
// (X-Real-IP, True-Client-IP, the left end of X-Forwarded-For) are ignored,
// so nobody can pick a fresh address per request to dodge the per-address
// sign-in limits. A server reached directly from the internet ignores the
// headers completely.
func realIP(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if ip := forwardedClient(r); ip.IsValid() {
			r.RemoteAddr = net.JoinHostPort(ip.String(), "0")
		}
		next.ServeHTTP(w, r)
	})
}

// trustedProxy: loopback, private (RFC 1918, fc00::/7) and link-local.
func trustedProxy(ip netip.Addr) bool {
	ip = ip.Unmap()
	return ip.IsLoopback() || ip.IsPrivate() || ip.IsLinkLocalUnicast()
}

func forwardedClient(r *http.Request) netip.Addr {
	peer, err := netip.ParseAddrPort(r.RemoteAddr)
	if err != nil || !trustedProxy(peer.Addr()) {
		return netip.Addr{}
	}
	hops := r.Header.Values("X-Forwarded-For")
	var all []string
	for _, h := range hops {
		all = append(all, strings.Split(h, ",")...)
	}
	var last netip.Addr
	for i := len(all) - 1; i >= 0; i-- {
		ip, err := netip.ParseAddr(strings.TrimSpace(all[i]))
		if err != nil {
			return last // garbage left of here came from the client
		}
		ip = ip.Unmap()
		if !trustedProxy(ip) {
			return ip
		}
		last = ip
	}
	return last
}
