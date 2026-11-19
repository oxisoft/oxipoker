package httpapi

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestRealIPTrustsOnlyTheProxyHop(t *testing.T) {
	cases := []struct {
		name, peer string
		hdr        map[string][]string
		want       string
	}{
		{"direct, no headers", "203.0.113.7:5000", nil, "203.0.113.7"},
		{"direct client forging headers", "203.0.113.7:5000",
			map[string][]string{"X-Forwarded-For": {"198.51.100.1"}, "X-Real-Ip": {"198.51.100.2"}}, "203.0.113.7"},
		{"behind Caddy", "127.0.0.1:41000", map[string][]string{"X-Forwarded-For": {"203.0.113.7"}}, "203.0.113.7"},
		{"behind nginx, client forged a left entry", "172.17.0.1:41000",
			map[string][]string{"X-Forwarded-For": {"198.51.100.1, 203.0.113.7"}}, "203.0.113.7"},
		{"X-Real-IP is never believed", "127.0.0.1:41000",
			map[string][]string{"X-Real-Ip": {"198.51.100.2"}, "True-Client-Ip": {"198.51.100.3"}, "X-Forwarded-For": {"203.0.113.7"}}, "203.0.113.7"},
		{"two proxies", "10.0.0.2:41000", map[string][]string{"X-Forwarded-For": {"203.0.113.7, 10.0.0.9"}}, "203.0.113.7"},
		{"several header lines", "[::1]:41000", map[string][]string{"X-Forwarded-For": {"198.51.100.1", "203.0.113.7"}}, "203.0.113.7"},
		{"garbage from the client", "127.0.0.1:41000", map[string][]string{"X-Forwarded-For": {"evil, 203.0.113.7"}}, "203.0.113.7"},
		{"only garbage", "127.0.0.1:41000", map[string][]string{"X-Forwarded-For": {"evil"}}, "127.0.0.1"},
		{"local client through the proxy", "127.0.0.1:41000", map[string][]string{"X-Forwarded-For": {"192.168.1.20"}}, "192.168.1.20"},
		{"IPv6 client", "[::1]:41000", map[string][]string{"X-Forwarded-For": {"2001:db8::5"}}, "2001:db8::5"},
	}
	for _, c := range cases {
		var got string
		h := realIP(http.HandlerFunc(func(_ http.ResponseWriter, r *http.Request) { got = clientIP(r) }))
		r := httptest.NewRequest("GET", "/", nil)
		r.RemoteAddr = c.peer
		for k, v := range c.hdr {
			r.Header[k] = v
		}
		h.ServeHTTP(httptest.NewRecorder(), r)
		if got != c.want {
			t.Errorf("%s: got %q, want %q", c.name, got, c.want)
		}
	}
}

// Rotating X-Real-IP or True-Client-IP does not reset the per-address
// sign-in limit (the test client is on loopback, so it counts as the proxy).
func TestSigninLimitIgnoresForgedAddresses(t *testing.T) {
	ts := newTestServer(t, "")
	blocked := false
	for i := range ipFailLimit + 2 {
		forged := "198.51.100." + string(rune('1'+i%9))
		res, _ := ts.do(t, nil, req{method: "POST", path: "/api/v1/auth/signin",
			body:   map[string]string{"username": "nobody" + string(rune('a'+i)), "password": "wrong password here"},
			header: map[string]string{"X-Real-IP": forged, "True-Client-IP": forged}})
		if res.StatusCode == http.StatusTooManyRequests {
			blocked = true
			break
		}
	}
	if !blocked {
		t.Fatal("forged addresses dodged the per-address limit")
	}
}
