package httpapi

import (
	"encoding/json"
	"errors"
	"math"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"

	"github.com/oxisoft/oxipoker/server/internal/accounts"
)

// ceremonyResponse carries a pending WebAuthn ceremony: the client passes
// options.publicKey to navigator.credentials and sends back the ceremony id.
type ceremonyResponse struct {
	Ceremony string `json:"ceremony"`
	Options  any    `json:"options"`
}

type passkeyFinishRequest struct {
	Ceremony   string          `json:"ceremony"`
	Credential json.RawMessage `json:"credential"`
	Name       string          `json:"name,omitempty"`   // registration only
	Client     string          `json:"client,omitempty"` // sign-in only: "web" or "app"
}

func (a *authAPI) passkeyLoginBegin(w http.ResponseWriter, r *http.Request) {
	if a.ipLimited(w, r) {
		return
	}
	id, opts, err := a.pk.BeginLogin()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, "busy")
		return
	}
	writeJSON(w, http.StatusOK, ceremonyResponse{Ceremony: id, Options: opts})
}

func (a *authAPI) passkeyLoginFinish(w http.ResponseWriter, r *http.Request) {
	if a.ipLimited(w, r) {
		return
	}
	var req passkeyFinishRequest
	if !readJSON(w, r, &req, 72<<10) {
		return
	}
	u, err := a.pk.FinishLogin(r.Context(), req.Ceremony, req.Credential)
	if errors.Is(err, accounts.ErrCeremony) || errors.Is(err, accounts.ErrPasskeyInvalid) {
		a.ipFails.fail(clientIP(r))
		a.audit(r, nil, "auth.signin_failed", "", map[string]any{"method": "passkey"})
		writeError(w, http.StatusUnauthorized, "invalid_credentials")
		return
	}
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal")
		return
	}
	a.issueSession(w, r, u, sessionKind(req.Client), "passkey")
}

// ipLimited answers 429 when the client IP has too many failed sign-ins.
func (a *authAPI) ipLimited(w http.ResponseWriter, r *http.Request) bool {
	if wait := a.ipFails.blocked(clientIP(r)); wait > 0 {
		w.Header().Set("Retry-After", strconv.Itoa(int(math.Ceil(wait.Seconds()))))
		writeError(w, http.StatusTooManyRequests, "rate_limited")
		return true
	}
	return false
}

func (a *authAPI) passkeyList(w http.ResponseWriter, r *http.Request) {
	list, err := a.pk.ListPasskeys(r.Context(), currentUser(r).ID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"passkeys": list})
}

func (a *authAPI) passkeyAddBegin(w http.ResponseWriter, r *http.Request) {
	id, opts, err := a.pk.BeginRegistration(r.Context(), currentUser(r))
	switch {
	case errors.Is(err, accounts.ErrTooManyPasskey):
		writeError(w, http.StatusConflict, "too_many_passkeys")
	case errors.Is(err, accounts.ErrCeremony):
		writeError(w, http.StatusServiceUnavailable, "busy")
	case err != nil:
		writeError(w, http.StatusInternalServerError, "internal")
	default:
		writeJSON(w, http.StatusOK, ceremonyResponse{Ceremony: id, Options: opts})
	}
}

func (a *authAPI) passkeyAddFinish(w http.ResponseWriter, r *http.Request) {
	var req passkeyFinishRequest
	if !readJSON(w, r, &req, 72<<10) {
		return
	}
	u := currentUser(r)
	pk, err := a.pk.FinishRegistration(r.Context(), u, req.Ceremony, req.Credential, req.Name)
	switch {
	case errors.Is(err, accounts.ErrBadPasskeyName):
		writeError(w, http.StatusBadRequest, "bad_name")
	case errors.Is(err, accounts.ErrCeremony), errors.Is(err, accounts.ErrPasskeyInvalid):
		writeError(w, http.StatusBadRequest, "passkey_rejected")
	case err != nil:
		writeError(w, http.StatusInternalServerError, "internal")
	default:
		a.audit(r, u, "passkey.add", pk.ID, map[string]any{"name": pk.Name})
		writeJSON(w, http.StatusCreated, pk)
	}
}

func (a *authAPI) passkeyRename(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Name string `json:"name"`
	}
	if !readJSON(w, r, &req, 4<<10) {
		return
	}
	u, id := currentUser(r), chi.URLParam(r, "id")
	err := a.pk.RenamePasskey(r.Context(), u.ID, id, req.Name)
	switch {
	case errors.Is(err, accounts.ErrBadPasskeyName):
		writeError(w, http.StatusBadRequest, "bad_name")
	case errors.Is(err, accounts.ErrNotFound):
		writeError(w, http.StatusNotFound, "not_found")
	case err != nil:
		writeError(w, http.StatusInternalServerError, "internal")
	default:
		a.audit(r, u, "passkey.rename", id, nil)
		w.WriteHeader(http.StatusNoContent)
	}
}

func (a *authAPI) passkeyRemove(w http.ResponseWriter, r *http.Request) {
	u, id := currentUser(r), chi.URLParam(r, "id")
	err := a.pk.RemovePasskey(r.Context(), u, id)
	switch {
	case errors.Is(err, accounts.ErrLastSignInMethod):
		writeError(w, http.StatusConflict, "last_sign_in_method")
	case errors.Is(err, accounts.ErrNotFound):
		writeError(w, http.StatusNotFound, "not_found")
	case err != nil:
		writeError(w, http.StatusInternalServerError, "internal")
	default:
		a.audit(r, u, "passkey.remove", id, nil)
		w.WriteHeader(http.StatusNoContent)
	}
}
