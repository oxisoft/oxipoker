package httpapi

import (
	"net/http"
	"net/url"
	"strings"
)

// contentSecurityPolicy is the policy for the embedded Flutter web app (and
// harmless on JSON). Handlers that serve user content (avatars, card backs) set
// their own stricter `default-src 'none'`.
//
//   - script-src: the bundle only; 'wasm-unsafe-eval' lets CanvasKit compile its
//     WebAssembly, it does not allow eval of JavaScript.
//   - style-src 'unsafe-inline': the Flutter engine writes style attributes and
//     <style> elements at run time. Styles cannot run code.
//   - connect-src: the API and WebSocket on this server, plus LiveKit when voice
//     and video are on. Nothing else: no font or CanvasKit CDN (the build bundles
//     both), so a browser never talks to a third party.
//   - frame-ancestors 'none' repeats X-Frame-Options for current browsers.
func contentSecurityPolicy(publicURL, liveKitURL string) string {
	connect := []string{"'self'"}
	connect = append(connect, socketOrigins(publicURL)...)
	connect = append(connect, socketOrigins(liveKitURL)...)
	return strings.Join([]string{
		"default-src 'self'",
		"script-src 'self' 'wasm-unsafe-eval'",
		"style-src 'self' 'unsafe-inline'",
		"img-src 'self' data: blob:",
		"font-src 'self' data:",
		"media-src 'self' blob:",
		"worker-src 'self' blob:",
		"connect-src " + strings.Join(dedupe(connect), " "),
		"object-src 'none'",
		"base-uri 'self'",
		"form-action 'self'",
		"frame-ancestors 'none'",
	}, "; ")
}

// socketOrigins returns the https and wss origins of a ws(s):// or http(s)://
// address. 'self' already covers same-origin WebSockets in current browsers;
// the explicit wss origin is for older Safari, which did not match ws against
// 'self'.
func socketOrigins(raw string) []string {
	u, err := url.Parse(strings.TrimSpace(raw))
	if err != nil || u.Host == "" {
		return nil
	}
	switch u.Scheme {
	case "https", "wss":
		return []string{"https://" + u.Host, "wss://" + u.Host}
	case "http", "ws":
		return []string{"http://" + u.Host, "ws://" + u.Host}
	}
	return nil
}

func dedupe(in []string) []string {
	seen := map[string]bool{}
	out := in[:0]
	for _, s := range in {
		if !seen[s] {
			seen[s] = true
			out = append(out, s)
		}
	}
	return out
}

// securityHeaders sets the headers every response carries. HSTS is sent only
// when PUBLIC_URL is https, so the server does not depend on the reverse proxy
// adding it; without includeSubDomains, because other names under the same
// domain are not ours to pin.
func securityHeaders(opt Options) func(http.Handler) http.Handler {
	liveKit := ""
	if opt.Media {
		liveKit = opt.LiveKit.URL
	}
	csp := contentSecurityPolicy(opt.PublicURL, liveKit)
	hsts := strings.HasPrefix(strings.ToLower(strings.TrimSpace(opt.PublicURL)), "https://")
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			h := w.Header()
			h.Set("X-Content-Type-Options", "nosniff")
			h.Set("Referrer-Policy", "no-referrer")
			h.Set("X-Frame-Options", "DENY")
			h.Set("Content-Security-Policy", csp)
			h.Set("Cross-Origin-Opener-Policy", "same-origin")
			h.Set("Permissions-Policy", "camera=(self), microphone=(self), geolocation=(), payment=(), usb=()")
			if hsts {
				h.Set("Strict-Transport-Security", "max-age=31536000")
			}
			next.ServeHTTP(w, r)
		})
	}
}
