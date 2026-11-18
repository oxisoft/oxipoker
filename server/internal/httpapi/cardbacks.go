package httpapi

import (
	"errors"
	"io"
	"net/http"

	"github.com/go-chi/chi/v5"

	"github.com/oxisoft/oxipoker/server/internal/accounts"
)

// listCardBacks returns every back and the server default.
func (a *authAPI) listCardBacks(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	backs, err := a.acc.CardBacks(ctx)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal")
		return
	}
	def, err := a.acc.DefaultCardBackID(ctx)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"default": def, "card_backs": backs})
}

// cardBackImage serves an uploaded back. Ids are random and an upload never
// changes, so clients may cache it for long.
func (a *authAPI) cardBackImage(w http.ResponseWriter, r *http.Request) {
	data, err := a.acc.CardBackImage(r.Context(), chi.URLParam(r, "id"))
	switch {
	case errors.Is(err, accounts.ErrNotFound):
		writeError(w, http.StatusNotFound, "not_found")
		return
	case err != nil:
		writeError(w, http.StatusInternalServerError, "internal")
		return
	}
	h := w.Header()
	h.Set("Cache-Control", "private, max-age=2592000, immutable")
	h.Set("Content-Security-Policy", "default-src 'none'")
	h.Set("Content-Type", "image/png")
	_, _ = w.Write(data)
}

// addCardBack takes the raw image as the body and the name as ?name=.
func (a *authAPI) addCardBack(w http.ResponseWriter, r *http.Request) {
	data, err := io.ReadAll(http.MaxBytesReader(w, r.Body, a.uploadCap(r.Context())))
	var tooBig *http.MaxBytesError
	switch {
	case errors.As(err, &tooBig):
		writeError(w, http.StatusRequestEntityTooLarge, "too_large")
		return
	case err != nil:
		writeError(w, http.StatusBadRequest, "bad_request")
		return
	}
	b, err := a.acc.AddCardBack(r.Context(), r.URL.Query().Get("name"), data)
	switch {
	case errors.Is(err, accounts.ErrBadCardBackName):
		writeError(w, http.StatusBadRequest, "bad_name")
		return
	case errors.Is(err, accounts.ErrTooManyBacks):
		writeError(w, http.StatusConflict, "too_many_card_backs")
		return
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
	a.audit(r, currentUser(r), "card_back.add", b.ID, map[string]any{"name": b.Name})
	writeJSON(w, http.StatusCreated, b)
}

func (a *authAPI) deleteCardBack(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	err := a.acc.DeleteCardBack(r.Context(), id)
	switch {
	case errors.Is(err, accounts.ErrNotFound):
		writeError(w, http.StatusNotFound, "not_found")
	case errors.Is(err, accounts.ErrCardBackBuiltIn):
		writeError(w, http.StatusConflict, "built_in")
	case errors.Is(err, accounts.ErrCardBackDefault):
		writeError(w, http.StatusConflict, "is_default")
	case err != nil:
		writeError(w, http.StatusInternalServerError, "internal")
	default:
		a.audit(r, currentUser(r), "card_back.delete", id, nil)
		w.WriteHeader(http.StatusNoContent)
	}
}
