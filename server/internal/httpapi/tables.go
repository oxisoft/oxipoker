package httpapi

import (
	"context"
	"errors"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/coder/websocket"
	"github.com/go-chi/chi/v5"

	"github.com/oxisoft/oxipoker/server/internal/accounts"
	"github.com/oxisoft/oxipoker/server/internal/history"
	"github.com/oxisoft/oxipoker/server/internal/realtime"
	"github.com/oxisoft/oxipoker/server/internal/table"
)

// MaxTableName is the longest table name in characters.
const MaxTableName = 40

type gameAPI struct {
	*authAPI
	tables *table.Manager
	hub    *realtime.Hub
	hist   *history.Store
	rt     *realtime.Server
}

func newGameAPI(a *authAPI, opt Options) *gameAPI {
	g := &gameAPI{authAPI: a, tables: opt.Tables, hub: opt.Hub, hist: opt.History}
	g.rt = &realtime.Server{Hub: opt.Hub, Tables: opt.Tables, PingEvery: opt.PingEvery, Blocks: a.acc.BlockedIDs}
	return g
}

func displayName(u *accounts.User) string {
	if u.DisplayName != "" {
		return u.DisplayName
	}
	return u.Username
}

func (g *gameAPI) routes(r chi.Router) {
	r.Get("/tables", g.listTables)
	r.Post("/tables", g.createTable)
	r.Delete("/tables/{id}", g.closeTable)
	g.moderationRoutes(r)
	if g.hist != nil {
		r.Get("/me/hands", g.listHands)
		r.Get("/me/hands/{id}", g.getHand)
		r.Get("/me/stats", g.stats)
		r.Get("/me/games", g.listGames)
	}
}

func (g *gameAPI) listHands(w http.ResponseWriter, r *http.Request) {
	before, _ := strconv.ParseInt(r.URL.Query().Get("before"), 10, 64)
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	hs, err := g.hist.List(r.Context(), currentUser(r).ID, before, limit)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"hands": hs})
}

func (g *gameAPI) getHand(w http.ResponseWriter, r *http.Request) {
	id, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		writeError(w, http.StatusNotFound, "not_found")
		return
	}
	h, err := g.hist.Get(r.Context(), currentUser(r).ID, id)
	switch {
	case errors.Is(err, history.ErrNotFound):
		writeError(w, http.StatusNotFound, "not_found")
	case err != nil:
		writeError(w, http.StatusInternalServerError, "internal")
	default:
		writeJSON(w, http.StatusOK, h)
	}
}

func (g *gameAPI) listGames(w http.ResponseWriter, r *http.Request) {
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	gs, err := g.hist.Games(r.Context(), currentUser(r).ID, limit)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"games": gs})
}

func (g *gameAPI) stats(w http.ResponseWriter, r *http.Request) {
	st, err := g.hist.StatsOf(r.Context(), currentUser(r).ID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal")
		return
	}
	writeJSON(w, http.StatusOK, st)
}

func (g *gameAPI) listTables(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]any{"tables": g.hub.Lobby()})
}

type createTableRequest struct {
	Name          string `json:"name"`
	Seats         int    `json:"seats"`
	SmallBlind    int64  `json:"small_blind"`
	BigBlind      int64  `json:"big_blind"`
	StartingStack int64  `json:"starting_stack"`
	TurnTime      int    `json:"turn_time"` // seconds
	Spectators    bool   `json:"spectators"`
	Kind          string `json:"kind"`      // cash (default) or sng
	Structure     string `json:"structure"` // sng: turbo, regular or slow
}

func (g *gameAPI) createTable(w http.ResponseWriter, r *http.Request) {
	u := currentUser(r)
	set, err := g.settings(r.Context())
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal")
		return
	}
	if set.TableCreation == "admins" && !u.IsAdmin {
		writeError(w, http.StatusForbidden, "admins_only")
		return
	}
	var req createTableRequest
	if !readJSON(w, r, &req, 4<<10) {
		return
	}
	name := strings.TrimSpace(req.Name)
	tt := time.Duration(req.TurnTime) * time.Second
	switch {
	case name == "" || utf8.RuneCountInString(name) > MaxTableName || !utf8.ValidString(name):
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "bad_settings", "detail": "name: 1 to 40 characters"})
		return
	case tt < table.MinTurnTime || tt > table.MaxTurnTime:
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "bad_settings", "detail": "turn time: 5 to 300 seconds"})
		return
	}
	s := table.Settings{Name: name, Seats: req.Seats, SmallBlind: req.SmallBlind, BigBlind: req.BigBlind,
		StartingStack: req.StartingStack, TurnTime: tt, Spectators: req.Spectators, Kind: req.Kind, Structure: req.Structure}
	if err := s.Validate(); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "bad_settings", "detail": err.Error()})
		return
	}
	t, err := g.tables.Create(u.ID, s)
	switch {
	case errors.Is(err, table.ErrTooMany):
		writeError(w, http.StatusServiceUnavailable, "too_many_tables")
		return
	case err != nil:
		writeError(w, http.StatusInternalServerError, "internal")
		return
	}
	st, err := t.Snapshot()
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal")
		return
	}
	g.hub.Publish(st)
	g.audit(r, u, "table.create", t.ID(), map[string]any{"name": name, "seats": s.Seats, "big_blind": s.BigBlind, "kind": s.Kind})
	writeJSON(w, http.StatusCreated, realtime.Summary(st))
}

func (g *gameAPI) closeTable(w http.ResponseWriter, r *http.Request) {
	u := currentUser(r)
	id := chi.URLParam(r, "id")
	switch err := g.tables.Close(id, u.ID, u.IsAdmin); {
	case errors.Is(err, table.ErrNoTable):
		writeError(w, http.StatusNotFound, "not_found")
		return
	case errors.Is(err, table.ErrForbidden):
		writeError(w, http.StatusForbidden, "host_or_admin_only")
		return
	case err != nil:
		writeError(w, http.StatusInternalServerError, "internal")
		return
	}
	g.audit(r, u, "table.close", id, nil)
	w.WriteHeader(http.StatusNoContent)
}

// wsOriginOK: browsers always send Origin on a WebSocket handshake and it
// must be this server; native apps send none and must use a bearer token,
// so a cookie can never be used by another site.
func (g *gameAPI) wsOriginOK(r *http.Request) bool {
	origin := r.Header.Get("Origin")
	switch {
	case origin == "":
		return bearer(r) != ""
	case g.origin != "":
		return origin == g.origin
	}
	u, err := url.Parse(origin)
	return err == nil && u.Host == r.Host
}

// ws upgrades GET /api/v1/ws. One connection per tab carries the lobby, the
// watched table and its chat.
func (g *gameAPI) ws(w http.ResponseWriter, r *http.Request) {
	if !g.wsOriginOK(r) {
		writeError(w, http.StatusForbidden, "bad_origin")
		return
	}
	u, ss := currentUser(r), currentSession(r)
	c, err := websocket.Accept(w, r, &websocket.AcceptOptions{InsecureSkipVerify: true}) // Origin checked above
	if err != nil {
		return
	}
	token := bearer(r)
	if token == "" {
		if ck, err := r.Cookie(g.cookieName()); err == nil {
			token = ck.Value
		}
	}
	srv := *g.rt
	srv.Check = func(ctx context.Context) error {
		cs, cu, err := g.acc.SessionUser(ctx, token)
		if err != nil {
			return err
		}
		if cs.ID != ss.ID || cu.Disabled() || cu.MustChangePassword {
			return errors.New("session changed")
		}
		return nil
	}
	// The request context ends with the handler; the connection lives on
	// its own context until either side closes it.
	_ = srv.Serve(context.WithoutCancel(r.Context()), c, realtime.User{ID: u.ID, Name: displayName(u), Admin: u.IsAdmin})
}
