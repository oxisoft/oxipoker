package httpapi

import (
	"errors"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"

	"github.com/oxisoft/oxipoker/server/internal/accounts"
)

func requireAdmin(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if u := currentUser(r); u == nil || !u.IsAdmin {
			writeError(w, http.StatusForbidden, "admin_only")
			return
		}
		next.ServeHTTP(w, r)
	})
}

// inviteURL is the link an admin shares. The token sits in the fragment, so
// it never reaches a server or proxy access log; the app reads it and the
// origin tells native apps which server to use.
func (a *authAPI) inviteURL(r *http.Request, token string) string {
	origin := a.origin
	if origin == "" {
		scheme := "http"
		if r.TLS != nil {
			scheme = "https"
		}
		origin = scheme + "://" + r.Host
	}
	return origin + "/invite#" + token
}

func (a *authAPI) createInvitation(w http.ResponseWriter, r *http.Request) {
	var req struct {
		ExpiresInHours int    `json:"expires_in_hours"`
		MaxUses        int    `json:"max_uses"`
		Note           string `json:"note"`
	}
	if !readJSON(w, r, &req, 4<<10) {
		return
	}
	u := currentUser(r)
	token, inv, err := a.acc.CreateInvitation(r.Context(), u, accounts.NewInvitation{
		TTL: time.Duration(req.ExpiresInHours) * time.Hour, MaxUses: req.MaxUses, Note: req.Note})
	switch {
	case errors.Is(err, accounts.ErrInviteParams):
		writeError(w, http.StatusBadRequest, "bad_invitation")
		return
	case err != nil:
		writeError(w, http.StatusInternalServerError, "internal")
		return
	}
	a.audit(r, u, "invitation.create", inv.ID, map[string]any{"max_uses": inv.MaxUses, "expires_at": inv.ExpiresAt})
	writeJSON(w, http.StatusCreated, map[string]any{"invitation": inv, "token": token, "url": a.inviteURL(r, token)})
}

func (a *authAPI) listInvitations(w http.ResponseWriter, r *http.Request) {
	list, err := a.acc.ListInvitations(r.Context())
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"invitations": list})
}

func (a *authAPI) revokeInvitation(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	err := a.acc.RevokeInvitation(r.Context(), id)
	switch {
	case errors.Is(err, accounts.ErrNotFound):
		writeError(w, http.StatusNotFound, "not_found")
	case err != nil:
		writeError(w, http.StatusInternalServerError, "internal")
	default:
		a.audit(r, currentUser(r), "invitation.revoke", id, nil)
		w.WriteHeader(http.StatusNoContent)
	}
}

// signupError answers the errors shared by both sign-up flows. It returns
// false when err is not one of them.
func (a *authAPI) signupError(w http.ResponseWriter, r *http.Request, err error) bool {
	switch {
	case errors.Is(err, accounts.ErrInviteInvalid):
		a.ipFails.fail(clientIP(r))
		writeError(w, http.StatusNotFound, "invitation_invalid")
	case errors.Is(err, accounts.ErrInviteExpired):
		writeError(w, http.StatusGone, "invitation_expired")
	case errors.Is(err, accounts.ErrInviteUsedUp):
		writeError(w, http.StatusGone, "invitation_used")
	case errors.Is(err, accounts.ErrBadUsername):
		writeError(w, http.StatusBadRequest, "bad_username")
	case errors.Is(err, accounts.ErrUsernameTaken):
		writeError(w, http.StatusConflict, "username_taken")
	case errors.Is(err, accounts.ErrBadDisplayName):
		writeError(w, http.StatusBadRequest, "bad_display_name")
	case errors.Is(err, accounts.ErrWeakPassword):
		writeError(w, http.StatusBadRequest, "bad_password")
	default:
		return false
	}
	return true
}

func (a *authAPI) checkInvitation(w http.ResponseWriter, r *http.Request) {
	if a.ipLimited(w, r) {
		return
	}
	var req struct {
		Token string `json:"token"`
	}
	if !readJSON(w, r, &req, 4<<10) {
		return
	}
	info, err := a.acc.CheckInvitation(r.Context(), req.Token)
	if a.signupError(w, r, err) {
		return
	}
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"expires_at": info.ExpiresAt, "note": info.Note, "passkeys": a.pk != nil})
}

type signupRequest struct {
	Token       string `json:"token"`
	Username    string `json:"username"`
	DisplayName string `json:"display_name"`
	Password    string `json:"password"`
	Client      string `json:"client"`
}

func (a *authAPI) signup(w http.ResponseWriter, r *http.Request) {
	if a.ipLimited(w, r) {
		return
	}
	var req signupRequest
	if !readJSON(w, r, &req, 8<<10) {
		return
	}
	u, err := a.acc.SignUpWithPassword(r.Context(), req.Token, req.Username, req.DisplayName, req.Password)
	if a.signupError(w, r, err) {
		return
	}
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal")
		return
	}
	a.audit(r, u, "user.signup", u.ID, map[string]any{"method": "password"})
	a.issueSession(w, r, u, sessionKind(req.Client), "signup")
}

func (a *authAPI) signupPasskeyBegin(w http.ResponseWriter, r *http.Request) {
	if a.ipLimited(w, r) {
		return
	}
	var req signupRequest
	if !readJSON(w, r, &req, 8<<10) {
		return
	}
	id, opts, err := a.pk.BeginSignup(r.Context(), req.Token, req.Username, req.DisplayName)
	if a.signupError(w, r, err) {
		return
	}
	if errors.Is(err, accounts.ErrCeremony) {
		writeError(w, http.StatusServiceUnavailable, "busy")
		return
	}
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal")
		return
	}
	writeJSON(w, http.StatusOK, ceremonyResponse{Ceremony: id, Options: opts})
}

func (a *authAPI) signupPasskeyFinish(w http.ResponseWriter, r *http.Request) {
	if a.ipLimited(w, r) {
		return
	}
	var req passkeyFinishRequest
	if !readJSON(w, r, &req, 72<<10) {
		return
	}
	u, err := a.pk.FinishSignup(r.Context(), req.Ceremony, req.Credential, req.Name)
	if a.signupError(w, r, err) {
		return
	}
	switch {
	case errors.Is(err, accounts.ErrCeremony), errors.Is(err, accounts.ErrPasskeyInvalid):
		a.ipFails.fail(clientIP(r))
		writeError(w, http.StatusBadRequest, "passkey_rejected")
		return
	case errors.Is(err, accounts.ErrBadPasskeyName):
		writeError(w, http.StatusBadRequest, "bad_name")
		return
	case err != nil:
		writeError(w, http.StatusInternalServerError, "internal")
		return
	}
	a.audit(r, u, "user.signup", u.ID, map[string]any{"method": "passkey"})
	a.issueSession(w, r, u, sessionKind(req.Client), "signup")
}
