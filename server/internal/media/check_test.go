package media

import (
	"context"
	"crypto/tls"
	"crypto/x509"
	"errors"
	"net"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"
)

// fakeLiveKit answers "/" with OK and /rtc/validate like LiveKit: 200 for a
// token signed with secret, 401 otherwise.
func fakeValidator(t *testing.T, key, secret string) *httptest.Server {
	t.Helper()
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.URL.Path {
		case "/":
			_, _ = w.Write([]byte("OK"))
		case "/rtc/validate":
			cfg := Config{URL: "ws://x", Key: key, Secret: secret}
			if _, err := cfg.Verify(r.URL.Query().Get("access_token"), time.Now()); err != nil {
				http.Error(w, "invalid authorization token: "+err.Error(), http.StatusUnauthorized)
				return
			}
			_, _ = w.Write([]byte("success"))
		default:
			http.NotFound(w, r)
		}
	}))
	t.Cleanup(srv.Close)
	return srv
}

func byName(rep Report) map[string]CheckResult {
	m := map[string]CheckResult{}
	for _, c := range rep.Checks {
		m[c.Name] = c
	}
	return m
}

func TestCheckMediaOff(t *testing.T) {
	rep := Checker{}.Run(context.Background())
	if rep.Enabled || len(rep.Checks) != 1 || rep.Checks[0].Status != CheckSkipped || !strings.Contains(rep.Checks[0].Detail, "LIVEKIT_URL") {
		t.Fatalf("media off: %+v", rep)
	}
}

func TestCheckAllGood(t *testing.T) {
	lk := fakeValidator(t, "key", "secret-secret-secret-secret-secret")
	cfg := Config{URL: "ws" + strings.TrimPrefix(lk.URL, "http"), Key: "key", Secret: "secret-secret-secret-secret-secret",
		TURNDomain: "turn.example.com", TURNTLSPort: 5349}
	var dialed string
	rep := Checker{Config: cfg, DialTLS: func(_ context.Context, addr string, c *tls.Config) error {
		dialed = addr + " " + c.ServerName
		return nil
	}}.Run(context.Background())
	m := byName(rep)
	for _, n := range []string{"signalling", "token", "turn_tls"} {
		if m[n].Status != CheckOK {
			t.Errorf("%s: %+v", n, m[n])
		}
	}
	if dialed != "turn.example.com:5349 turn.example.com" {
		t.Fatalf("dialed %q", dialed)
	}
}

func TestCheckWrongSecret(t *testing.T) {
	lk := fakeValidator(t, "key", "the-secret-livekit-was-started-with")
	cfg := Config{URL: lk.URL, Key: "key", Secret: "another-secret-in-the-oxipoker-env"}
	m := byName(Checker{Config: cfg}.Run(context.Background()))
	if m["signalling"].Status != CheckOK {
		t.Fatalf("signalling: %+v", m["signalling"])
	}
	if m["token"].Status != CheckFailed || !strings.Contains(m["token"].Detail, "LIVEKIT_API_SECRET") {
		t.Fatalf("token: %+v", m["token"])
	}
	if m["turn_tls"].Status != CheckSkipped || !strings.Contains(m["turn_tls"].Detail, "UDP") {
		t.Fatalf("turn off: %+v", m["turn_tls"])
	}
}

func TestCheckNotLiveKit(t *testing.T) {
	other := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		http.Error(w, "<html>welcome to nginx</html>", http.StatusBadGateway)
	}))
	defer other.Close()
	m := byName(Checker{Config: Config{URL: other.URL, Key: "k", Secret: "s"}}.Run(context.Background()))
	if m["signalling"].Status != CheckFailed || !strings.Contains(m["signalling"].Detail, "HTTP 502") {
		t.Fatalf("signalling: %+v", m["signalling"])
	}
	if m["token"].Status != CheckSkipped {
		t.Fatalf("token must be skipped: %+v", m["token"])
	}
}

func TestCheckRefusedAndTURNErrors(t *testing.T) {
	ln, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	addr := ln.Addr().String()
	ln.Close() // nothing listens there now
	cases := []struct {
		err  error
		want string
	}{
		{&net.OpError{Op: "dial", Net: "tcp", Err: errors.New("connection refused")}, "LIVEKIT_TURN_TLS_PORT/tcp"},
		{x509.HostnameError{Certificate: &x509.Certificate{}, Host: "turn.example.com"}, "another name"},
		{&tls.CertificateVerificationError{Err: x509.UnknownAuthorityError{}}, "not valid"},
		{&net.DNSError{Err: "no such host", Name: "turn.example.com", IsNotFound: true}, "DNS record"},
	}
	for _, c := range cases {
		m := byName(Checker{Config: Config{URL: "ws://" + addr, Key: "k", Secret: "s", TURNDomain: "turn.example.com", TURNTLSPort: 5349},
			DialTLS: func(context.Context, string, *tls.Config) error { return c.err }}.Run(context.Background()))
		if m["signalling"].Status != CheckFailed || !strings.Contains(m["signalling"].Detail, "connection refused") {
			t.Fatalf("signalling: %+v", m["signalling"])
		}
		if m["turn_tls"].Status != CheckFailed || !strings.Contains(m["turn_tls"].Detail, c.want) {
			t.Errorf("turn %v: %+v", c.err, m["turn_tls"])
		}
	}
}

func TestCheckRealTLSDial(t *testing.T) {
	srv := httptest.NewTLSServer(http.HandlerFunc(func(http.ResponseWriter, *http.Request) {}))
	defer srv.Close()
	host, port, _ := net.SplitHostPort(strings.TrimPrefix(srv.URL, "https://"))
	_ = host
	// The test certificate is self-signed: the real dial must report it.
	err := dialTLS(context.Background(), "127.0.0.1:"+port, &tls.Config{ServerName: "example.com", MinVersion: tls.VersionTLS12})
	var certErr *tls.CertificateVerificationError
	if !errors.As(err, &certErr) {
		t.Fatalf("self-signed: %v", err)
	}
}
