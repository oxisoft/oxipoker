package httpapi

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/oxisoft/oxipoker/server/internal/media"
)

func headersFor(t *testing.T, opt Options, path string) http.Header {
	t.Helper()
	rec := httptest.NewRecorder()
	NewRouter(opt).ServeHTTP(rec, httptest.NewRequest(http.MethodGet, path, nil))
	return rec.Header()
}

func TestWebAppContentSecurityPolicy(t *testing.T) {
	h := headersFor(t, Options{PublicURL: "https://poker.example.org"}, "/")
	csp := h.Get("Content-Security-Policy")
	for _, want := range []string{
		"default-src 'self'",
		"script-src 'self' 'wasm-unsafe-eval'",
		"connect-src 'self' https://poker.example.org wss://poker.example.org;",
		"object-src 'none'",
		"frame-ancestors 'none'",
	} {
		if !strings.Contains(csp, want) {
			t.Errorf("CSP lacks %q: %s", want, csp)
		}
	}
	for _, bad := range []string{"'unsafe-eval'", "gstatic", "googleapis", "*"} {
		if strings.Contains(strings.ReplaceAll(csp, "'wasm-unsafe-eval'", ""), bad) {
			t.Errorf("CSP allows %q: %s", bad, csp)
		}
	}
	if got := h.Get("Strict-Transport-Security"); got != "max-age=31536000" {
		t.Errorf("HSTS = %q", got)
	}
	if h.Get("X-Frame-Options") != "DENY" || h.Get("X-Content-Type-Options") != "nosniff" {
		t.Errorf("basic headers missing: %v", h)
	}
}

func TestContentSecurityPolicyAllowsLiveKitOnlyWhenMediaIsOn(t *testing.T) {
	lk := media.Config{URL: "wss://rtc.example.org", Key: "k", Secret: "s"}
	on := headersFor(t, Options{PublicURL: "https://poker.example.org", Media: true, LiveKit: lk}, "/api/v1/health").Get("Content-Security-Policy")
	if !strings.Contains(on, "https://rtc.example.org wss://rtc.example.org") {
		t.Errorf("media on, CSP lacks LiveKit: %s", on)
	}
	off := headersFor(t, Options{PublicURL: "https://poker.example.org", LiveKit: lk}, "/").Get("Content-Security-Policy")
	if strings.Contains(off, "rtc.example.org") {
		t.Errorf("media off, CSP still allows LiveKit: %s", off)
	}
}

func TestNoHSTSWithoutHTTPS(t *testing.T) {
	for _, pub := range []string{"", "http://127.0.0.1:8080"} {
		h := headersFor(t, Options{PublicURL: pub}, "/")
		if got := h.Get("Strict-Transport-Security"); got != "" {
			t.Errorf("PUBLIC_URL %q: HSTS %q", pub, got)
		}
		if h.Get("Content-Security-Policy") == "" {
			t.Errorf("PUBLIC_URL %q: no CSP", pub)
		}
	}
}
