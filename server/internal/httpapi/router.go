// Package httpapi wires the HTTP routes: the JSON API under /api/v1 and the
// embedded web client for everything else.
package httpapi

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"

	"github.com/oxisoft/oxipoker/server/internal/version"
	"github.com/oxisoft/oxipoker/server/internal/webapp"
)

// Options configures the router.
type Options struct {
	// Media reports whether the full deployment (LiveKit) is configured.
	Media bool
}

// Health is the body of GET /api/v1/health.
type Health struct {
	Status  string `json:"status"`
	Version string `json:"version"`
	WebApp  bool   `json:"webapp"`
	Media   bool   `json:"media"`
}

// NewRouter returns the server's root handler.
func NewRouter(opt Options) http.Handler {
	r := chi.NewRouter()
	r.Use(middleware.RealIP)
	r.Use(middleware.Recoverer)
	r.Use(securityHeaders)

	r.Route("/api/v1", func(api chi.Router) {
		api.Use(middleware.Timeout(30 * time.Second))
		api.Get("/health", func(w http.ResponseWriter, _ *http.Request) {
			writeJSON(w, http.StatusOK, Health{Status: "ok", Version: version.Version, WebApp: webapp.Bundled(), Media: opt.Media})
		})
		api.NotFound(func(w http.ResponseWriter, _ *http.Request) {
			writeJSON(w, http.StatusNotFound, map[string]string{"error": "not_found"})
		})
	})

	// Never r.NotFound for the web app: chi would propagate it into /api/v1.
	r.Handle("/*", webapp.Handler())
	return r
}

func securityHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		h := w.Header()
		h.Set("X-Content-Type-Options", "nosniff")
		h.Set("Referrer-Policy", "no-referrer")
		h.Set("X-Frame-Options", "DENY")
		next.ServeHTTP(w, r)
	})
}

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}
