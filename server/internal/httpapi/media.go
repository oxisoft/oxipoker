package httpapi

import (
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"

	"github.com/oxisoft/oxipoker/server/internal/media"
)

// MediaToken is the body of POST /tables/{id}/media-token.
type MediaToken struct {
	URL       string    `json:"url"`
	Token     string    `json:"token"`
	Room      string    `json:"room"`
	ExpiresAt time.Time `json:"expires_at"`
}

// mediaToken lets a user who is at the table (seated or watching, with a
// live connection, not removed) join the table's call.
func (g *gameAPI) mediaToken(w http.ResponseWriter, r *http.Request) {
	if !g.media.Enabled() {
		writeError(w, http.StatusNotFound, "media_off")
		return
	}
	id := chi.URLParam(r, "id")
	if _, ok := g.hub.State(id); !ok {
		writeError(w, http.StatusNotFound, "not_found")
		return
	}
	u := currentUser(r)
	if !g.hub.Watching(id, u.ID) {
		writeError(w, http.StatusForbidden, "not_at_table")
		return
	}
	tok, exp, err := g.media.JoinToken(id, u.ID, displayName(u), time.Now())
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal")
		return
	}
	w.Header().Set("Cache-Control", "no-store")
	writeJSON(w, http.StatusOK, MediaToken{URL: g.media.URL, Token: tok, Room: media.Room(id), ExpiresAt: exp.UTC()})
}
