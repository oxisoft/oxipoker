package httpapi

import (
	"context"
	"errors"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"

	"github.com/oxisoft/oxipoker/server/internal/accounts"
	"github.com/oxisoft/oxipoker/server/internal/store"
)

// Server settings an admin can change.
const (
	settingTableCreation = "table_creation"   // "everyone" or "admins"
	settingMaxUpload     = "max_upload_bytes" // image upload cap
	minUpload            = 256 << 10
	maxUploadCap         = 20 << 20
)

// Settings is the body of GET/PATCH /admin/settings.
type Settings struct {
	TableCreation  string `json:"table_creation"`
	MaxUploadBytes int64  `json:"max_upload_bytes"`
}

func (a *authAPI) settings(ctx context.Context) (Settings, error) {
	s := Settings{TableCreation: "everyone", MaxUploadBytes: accounts.DefaultMaxUpload}
	v, err := a.st.Setting(ctx, settingTableCreation, s.TableCreation)
	if err != nil {
		return s, err
	}
	s.TableCreation = v
	v, err = a.st.Setting(ctx, settingMaxUpload, "")
	if err != nil {
		return s, err
	}
	if n, err := strconv.ParseInt(v, 10, 64); err == nil && n >= minUpload && n <= maxUploadCap {
		s.MaxUploadBytes = n
	}
	return s, nil
}

// uploadCap is the current byte limit for uploaded images.
func (a *authAPI) uploadCap(ctx context.Context) int64 {
	s, err := a.settings(ctx)
	if err != nil {
		return accounts.DefaultMaxUpload
	}
	return s.MaxUploadBytes
}

func (a *authAPI) getSettings(w http.ResponseWriter, r *http.Request) {
	s, err := a.settings(r.Context())
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal")
		return
	}
	writeJSON(w, http.StatusOK, s)
}

func (a *authAPI) patchSettings(w http.ResponseWriter, r *http.Request) {
	var req struct {
		TableCreation  *string `json:"table_creation"`
		MaxUploadBytes *int64  `json:"max_upload_bytes"`
	}
	if !readJSON(w, r, &req, 4<<10) {
		return
	}
	if req.TableCreation != nil && *req.TableCreation != "everyone" && *req.TableCreation != "admins" {
		writeError(w, http.StatusBadRequest, "bad_settings")
		return
	}
	if req.MaxUploadBytes != nil && (*req.MaxUploadBytes < minUpload || *req.MaxUploadBytes > maxUploadCap) {
		writeError(w, http.StatusBadRequest, "bad_settings")
		return
	}
	ctx := r.Context()
	detail := map[string]any{}
	if req.TableCreation != nil {
		if err := a.st.SetSetting(ctx, settingTableCreation, *req.TableCreation); err != nil {
			writeError(w, http.StatusInternalServerError, "internal")
			return
		}
		detail[settingTableCreation] = *req.TableCreation
	}
	if req.MaxUploadBytes != nil {
		if err := a.st.SetSetting(ctx, settingMaxUpload, strconv.FormatInt(*req.MaxUploadBytes, 10)); err != nil {
			writeError(w, http.StatusInternalServerError, "internal")
			return
		}
		detail[settingMaxUpload] = *req.MaxUploadBytes
	}
	a.audit(r, currentUser(r), "settings.update", "", detail)
	a.getSettings(w, r)
}

func queryInt(r *http.Request, key string) int {
	n, _ := strconv.Atoi(r.URL.Query().Get(key))
	return n
}

func (a *authAPI) listUsers(w http.ResponseWriter, r *http.Request) {
	page, err := a.acc.ListUsers(r.Context(), r.URL.Query().Get("q"), queryInt(r, "limit"), queryInt(r, "offset"))
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal")
		return
	}
	writeJSON(w, http.StatusOK, page)
}

func (a *authAPI) createUser(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Username    string `json:"username"`
		DisplayName string `json:"display_name"`
		IsAdmin     bool   `json:"is_admin"`
	}
	if !readJSON(w, r, &req, 4<<10) {
		return
	}
	// The admin never picks the password: the new user gets a one-time one and
	// must replace it at the first sign-in.
	temp := accounts.NewTemporaryPassword()
	u, err := a.acc.CreateUser(r.Context(), accounts.NewUser{Username: req.Username, DisplayName: req.DisplayName,
		Password: temp, IsAdmin: req.IsAdmin, MustChange: true})
	if a.signupError(w, r, err) {
		return
	}
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal")
		return
	}
	a.audit(r, currentUser(r), "user.create", u.ID, map[string]any{"username": u.Username, "is_admin": u.IsAdmin})
	writeJSON(w, http.StatusCreated, map[string]any{"user": u, "temporary_password": temp})
}

func (a *authAPI) userError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, accounts.ErrNotFound):
		writeError(w, http.StatusNotFound, "not_found")
	case errors.Is(err, accounts.ErrLastAdmin):
		writeError(w, http.StatusConflict, "last_admin")
	case errors.Is(err, accounts.ErrSelf):
		writeError(w, http.StatusConflict, "self")
	default:
		writeError(w, http.StatusInternalServerError, "internal")
	}
}

func (a *authAPI) patchUser(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Disabled *bool `json:"disabled"`
		IsAdmin  *bool `json:"is_admin"`
	}
	if !readJSON(w, r, &req, 4<<10) {
		return
	}
	id := chi.URLParam(r, "id")
	me := currentUser(r)
	ctx := r.Context()
	if id == me.ID && ((req.Disabled != nil && *req.Disabled) || (req.IsAdmin != nil && !*req.IsAdmin)) {
		a.userError(w, accounts.ErrSelf)
		return
	}
	if req.Disabled != nil {
		if err := a.acc.SetDisabled(ctx, id, *req.Disabled); err != nil {
			a.userError(w, err)
			return
		}
		action := "user.enable"
		if *req.Disabled {
			action = "user.disable"
		}
		a.audit(r, me, action, id, nil)
	}
	if req.IsAdmin != nil {
		if err := a.acc.SetAdmin(ctx, id, *req.IsAdmin); err != nil {
			a.userError(w, err)
			return
		}
		action := "user.admin_grant"
		if !*req.IsAdmin {
			action = "user.admin_revoke"
		}
		a.audit(r, me, action, id, nil)
	}
	u, err := a.acc.UserByID(ctx, id)
	if err != nil {
		a.userError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, u)
}

func (a *authAPI) deleteUser(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	me := currentUser(r)
	if id == me.ID {
		a.userError(w, accounts.ErrSelf)
		return
	}
	u, err := a.acc.UserByID(r.Context(), id)
	if err != nil {
		a.userError(w, err)
		return
	}
	if err := a.acc.DeleteUser(r.Context(), id); err != nil {
		a.userError(w, err)
		return
	}
	a.audit(r, me, "user.delete", id, map[string]any{"username": u.Username})
	w.WriteHeader(http.StatusNoContent)
}

func (a *authAPI) resetUserPassword(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	temp, err := a.acc.ResetPassword(r.Context(), id)
	if err != nil {
		a.userError(w, err)
		return
	}
	a.audit(r, currentUser(r), "user.password_reset", id, nil)
	writeJSON(w, http.StatusOK, map[string]string{"temporary_password": temp})
}

func (a *authAPI) resetUser2FA(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	if _, err := a.acc.UserByID(r.Context(), id); err != nil {
		a.userError(w, err)
		return
	}
	if err := a.acc.ResetTOTP(r.Context(), id); err != nil {
		a.userError(w, err)
		return
	}
	a.audit(r, currentUser(r), "user.totp_reset", id, nil)
	w.WriteHeader(http.StatusNoContent)
}

func (a *authAPI) listAudit(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	before, _ := strconv.ParseInt(q.Get("before"), 10, 64)
	events, err := a.st.ListAudit(r.Context(), store.AuditFilter{ActorID: q.Get("actor"), Action: q.Get("action"),
		Before: before, Limit: queryInt(r, "limit")})
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal")
		return
	}
	if events == nil {
		events = []store.AuditEvent{}
	}
	writeJSON(w, http.StatusOK, map[string]any{"events": events})
}
