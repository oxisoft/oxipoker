// Package httpapi wires the HTTP routes: the JSON API under /api/v1 and the
// embedded web client for everything else.
package httpapi

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"

	"github.com/oxisoft/oxipoker/server/internal/accounts"
	"github.com/oxisoft/oxipoker/server/internal/applinks"
	"github.com/oxisoft/oxipoker/server/internal/history"
	"github.com/oxisoft/oxipoker/server/internal/media"
	"github.com/oxisoft/oxipoker/server/internal/realtime"
	"github.com/oxisoft/oxipoker/server/internal/secret"
	"github.com/oxisoft/oxipoker/server/internal/store"
	"github.com/oxisoft/oxipoker/server/internal/table"
	"github.com/oxisoft/oxipoker/server/internal/version"
	"github.com/oxisoft/oxipoker/server/internal/webapp"
)

// Options configures the router.
type Options struct {
	// Media reports whether the full deployment (LiveKit) is configured.
	Media bool
	// LiveKit signs call tokens; used when Media is true.
	LiveKit media.Config
	// Store is the database; nil only in tests of the static routes.
	Store *store.Store
	// Secret is the server's root secret.
	Secret *secret.Secret
	// Accounts enables the account and session endpoints.
	Accounts *accounts.Service
	// Passkeys enables WebAuthn; nil without a PUBLIC_URL.
	Passkeys *accounts.Passkeys
	// PublicURL is the server's public address (Origin check, Secure cookies).
	PublicURL string
	// AndroidApps are published in /.well-known/assetlinks.json; nil = the official app.
	AndroidApps []applinks.App
	// Tables and Hub enable the game: lobby API and WebSocket. Both or neither.
	Tables *table.Manager
	Hub    *realtime.Hub
	// History serves the own hand history and stats; nil = off.
	History *history.Store
	// PingEvery is the WebSocket keepalive interval (0 = default).
	PingEvery time.Duration
}

// Health is the body of GET /api/v1/health.
type Health struct {
	Status   string `json:"status"`
	Version  string `json:"version"`
	API      int    `json:"api"`
	WebApp   bool   `json:"webapp"`
	Media    bool   `json:"media"`
	Database string `json:"database"`
}

// NewRouter returns the server's root handler.
func NewRouter(opt Options) http.Handler {
	r := chi.NewRouter()
	r.Use(realIP)
	r.Use(middleware.Recoverer)
	r.Use(securityHeaders(opt))

	r.Route("/api/v1", func(api chi.Router) {
		// No timeout on the whole tree: the WebSocket outlives any request.
		api.With(middleware.Timeout(30*time.Second)).Get("/health", func(w http.ResponseWriter, r *http.Request) {
			h := Health{Status: "ok", Version: version.Version, API: version.API, WebApp: webapp.Bundled(), Media: opt.Media, Database: "none"}
			code := http.StatusOK
			if opt.Store != nil {
				h.Database = "ok"
				if err := opt.Store.Ping(r.Context()); err != nil {
					h.Status, h.Database, code = "degraded", "error", http.StatusServiceUnavailable
				}
			}
			writeJSON(w, code, h)
		})
		api.NotFound(func(w http.ResponseWriter, _ *http.Request) {
			writeJSON(w, http.StatusNotFound, map[string]string{"error": "not_found"})
		})
		if opt.Accounts != nil {
			a := newAuthAPI(opt)
			var game *gameAPI
			if opt.Tables != nil && opt.Hub != nil {
				game = newGameAPI(a, opt)
			}
			api.Group(func(g chi.Router) {
				g.Use(middleware.Timeout(30*time.Second), a.checkOrigin, a.authenticate)
				a.routes(g)
				if game != nil {
					g.Group(func(g chi.Router) {
						g.Use(requireUser)
						game.routes(g)
					})
				}
			})
			if game != nil {
				api.With(a.authenticate, requireUser).Get("/ws", game.ws)
				// Signed by LiveKit, not sent by a browser: outside the origin check.
				api.With(middleware.Timeout(30*time.Second)).Post("/media/webhook", game.mediaWebhook)
			}
		}
	})

	apps := opt.AndroidApps
	if apps == nil {
		apps = []applinks.App{applinks.Official}
	}
	r.Method(http.MethodGet, "/.well-known/assetlinks.json", applinks.Handler(apps))

	// Never r.NotFound for the web app: chi would propagate it into /api/v1.
	r.Handle("/*", webapp.Handler())
	return r
}

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}
