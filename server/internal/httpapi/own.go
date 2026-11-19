package httpapi

import (
	"errors"
	"net/http"

	"github.com/oxisoft/oxipoker/server/internal/accounts"
)

func (a *authAPI) updateMe(w http.ResponseWriter, r *http.Request) {
	var req struct {
		DisplayName *string `json:"display_name"`
		Theme       *string `json:"theme"`
		CardBack    *string `json:"card_back"`
	}
	if !readJSON(w, r, &req, 4<<10) {
		return
	}
	u := currentUser(r)
	ctx := r.Context()
	// Appearance is checked first, so a bad value changes nothing.
	err := a.acc.SetAppearance(ctx, u.ID, accounts.Appearance{Theme: req.Theme, CardBack: req.CardBack})
	switch {
	case errors.Is(err, accounts.ErrBadTheme):
		writeError(w, http.StatusBadRequest, "bad_theme")
		return
	case errors.Is(err, accounts.ErrBadCardBack):
		writeError(w, http.StatusBadRequest, "bad_card_back")
		return
	case err != nil:
		writeError(w, http.StatusInternalServerError, "internal")
		return
	}
	if req.DisplayName != nil {
		_, err := a.acc.SetDisplayName(ctx, u.ID, *req.DisplayName)
		switch {
		case errors.Is(err, accounts.ErrBadDisplayName):
			writeError(w, http.StatusBadRequest, "bad_display_name")
			return
		case err != nil:
			writeError(w, http.StatusInternalServerError, "internal")
			return
		}
	}
	fresh, err := a.acc.UserByID(ctx, u.ID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal")
		return
	}
	writeJSON(w, http.StatusOK, fresh)
}

func (a *authAPI) changePassword(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Current string `json:"current_password"`
		New     string `json:"new_password"`
	}
	if !readJSON(w, r, &req, 4<<10) {
		return
	}
	u := currentUser(r)
	if a.userBlocked(w, u) {
		return
	}
	err := a.acc.ChangePassword(r.Context(), u, req.Current, req.New, currentSession(r).ID)
	if !errors.Is(err, accounts.ErrWrongPassword) {
		a.userFails.undo("id:" + u.ID)
	}
	switch {
	case errors.Is(err, accounts.ErrWrongPassword):
		writeError(w, http.StatusForbidden, "wrong_password")
	case errors.Is(err, accounts.ErrWeakPassword):
		writeError(w, http.StatusBadRequest, "bad_password")
	case err != nil:
		writeError(w, http.StatusInternalServerError, "internal")
	default:
		a.audit(r, u, "user.password_change", u.ID, nil)
		w.WriteHeader(http.StatusNoContent)
	}
}

func (a *authAPI) deleteMe(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Password string `json:"password"`
	}
	if !readJSON(w, r, &req, 4<<10) {
		return
	}
	u := currentUser(r)
	if a.userBlocked(w, u) {
		return
	}
	err := a.acc.DeleteOwnAccount(r.Context(), u, req.Password)
	if !errors.Is(err, accounts.ErrWrongPassword) {
		a.userFails.undo("id:" + u.ID)
	}
	switch {
	case errors.Is(err, accounts.ErrWrongPassword):
		writeError(w, http.StatusForbidden, "wrong_password")
	case errors.Is(err, accounts.ErrLastAdmin):
		writeError(w, http.StatusConflict, "last_admin")
	case err != nil:
		writeError(w, http.StatusInternalServerError, "internal")
	default:
		a.clearCookie(w)
		a.audit(r, nil, "user.delete_self", u.ID, map[string]any{"username": u.Username})
		w.WriteHeader(http.StatusNoContent)
	}
}

func (a *authAPI) userBlocked(w http.ResponseWriter, u *accounts.User) bool {
	if a.userFails.take("id:"+u.ID) > 0 {
		writeError(w, http.StatusTooManyRequests, "rate_limited")
		return true
	}
	return false
}
