package httpapi

import (
	"errors"
	"io"
	"net/http"

	"github.com/go-chi/chi/v5"

	"github.com/oxisoft/oxipoker/server/internal/accounts"
)

// setAvatar takes the raw image as the request body (any Content-Type).
func (a *authAPI) setAvatar(w http.ResponseWriter, r *http.Request) {
	data, err := io.ReadAll(http.MaxBytesReader(w, r.Body, a.maxUpload))
	var tooBig *http.MaxBytesError
	switch {
	case errors.As(err, &tooBig):
		writeError(w, http.StatusRequestEntityTooLarge, "too_large")
		return
	case err != nil:
		writeError(w, http.StatusBadRequest, "bad_request")
		return
	}
	u := currentUser(r)
	ver, err := a.acc.SetAvatar(r.Context(), u.ID, data)
	switch {
	case errors.Is(err, accounts.ErrBadImage):
		writeError(w, http.StatusUnsupportedMediaType, "bad_image")
		return
	case errors.Is(err, accounts.ErrImageLarge):
		writeError(w, http.StatusRequestEntityTooLarge, "image_too_large")
		return
	case err != nil:
		writeError(w, http.StatusInternalServerError, "internal")
		return
	}
	u.Avatar = ver
	writeJSON(w, http.StatusOK, u)
}

func (a *authAPI) removeAvatar(w http.ResponseWriter, r *http.Request) {
	u := currentUser(r)
	if err := a.acc.RemoveAvatar(r.Context(), u.ID); err != nil {
		writeError(w, http.StatusInternalServerError, "internal")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// avatar serves a user's picture to signed-in users. Clients add ?v=<avatar>
// to the URL, so a cached copy is replaced as soon as the version changes.
func (a *authAPI) avatar(w http.ResponseWriter, r *http.Request) {
	data, ver, err := a.acc.Avatar(r.Context(), chi.URLParam(r, "id"))
	switch {
	case errors.Is(err, accounts.ErrNotFound):
		writeError(w, http.StatusNotFound, "not_found")
		return
	case err != nil:
		writeError(w, http.StatusInternalServerError, "internal")
		return
	}
	h := w.Header()
	etag := `"` + ver + `"`
	h.Set("ETag", etag)
	h.Set("Cache-Control", "private, max-age=86400")
	h.Set("Content-Security-Policy", "default-src 'none'")
	if r.Header.Get("If-None-Match") == etag {
		w.WriteHeader(http.StatusNotModified)
		return
	}
	h.Set("Content-Type", "image/png")
	_, _ = w.Write(data)
}
