package httpapi

import (
	"errors"
	"net/http"

	"github.com/oxisoft/oxipoker/server/internal/accounts"
)

func (a *authAPI) updateMe(w http.ResponseWriter, r *http.Request) {
	var req struct {
		DisplayName string `json:"display_name"`
	}
	if !readJSON(w, r, &req, 4<<10) {
		return
	}
	u := currentUser(r)
	name, err := a.acc.SetDisplayName(r.Context(), u.ID, req.DisplayName)
	switch {
	case errors.Is(err, accounts.ErrBadDisplayName):
		writeError(w, http.StatusBadRequest, "bad_display_name")
		return
	case err != nil:
		writeError(w, http.StatusInternalServerError, "internal")
		return
	}
	u.DisplayName = name
	writeJSON(w, http.StatusOK, u)
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
	switch {
	case errors.Is(err, accounts.ErrWrongPassword):
		a.userFails.fail("id:" + u.ID)
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
	switch {
	case errors.Is(err, accounts.ErrWrongPassword):
		a.userFails.fail("id:" + u.ID)
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
	if a.userFails.blocked("id:"+u.ID) > 0 {
		writeError(w, http.StatusTooManyRequests, "rate_limited")
		return true
	}
	return false
}
