package httpapi

import (
	"io"
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

// mediaWebhook receives LiveKit's webhooks. A call token stays valid for
// its lifetime and LiveKit cannot revoke it, so whoever joins a table's
// call is checked here: a user who is no longer at the table, or was sent
// out of the call, is removed again at once (finding F8).
func (g *gameAPI) mediaWebhook(w http.ResponseWriter, r *http.Request) {
	if !g.media.Enabled() {
		writeError(w, http.StatusNotFound, "media_off")
		return
	}
	body, err := io.ReadAll(io.LimitReader(r.Body, 64<<10))
	if err != nil {
		writeError(w, http.StatusBadRequest, "bad_request")
		return
	}
	ev, err := g.media.VerifyWebhook(r.Header.Get("Authorization"), body, time.Now())
	if err != nil {
		writeError(w, http.StatusUnauthorized, "bad_signature")
		return
	}
	if ev.Event == "participant_joined" {
		if id, ok := media.TableOf(ev.Room.Name); ok && ev.Participant.Identity != "" {
			g.hub.EnforceCall(id, ev.Participant.Identity)
		}
	}
	w.WriteHeader(http.StatusNoContent)
}
