package httpapi

import (
	"context"
	"encoding/json"
	"errors"
	"math"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"

	"github.com/oxisoft/oxipoker/server/internal/accounts"
	"github.com/oxisoft/oxipoker/server/internal/store"
)

// Sign-in limits: failures per client IP and per account in 15 minutes.
const (
	ipFailLimit      = 20
	accountFailLimit = 10
	failWindow       = 15 * time.Minute
)

type ctxKey int

const (
	ctxUser ctxKey = iota
	ctxSession
)

type authAPI struct {
	acc        *accounts.Service
	pk         *accounts.Passkeys // nil when PUBLIC_URL is not set
	st         *store.Store
	secure     bool   // cookies get Secure (PUBLIC_URL is https)
	origin     string // allowed Origin, "" = same host as the request
	ipFails    *failLimiter
	userFails  *failLimiter
	challenges *challengeStore // password accepted, second factor pending
	maxUpload  int64           // byte cap for uploaded images
}

func newAuthAPI(opt Options) *authAPI {
	a := &authAPI{acc: opt.Accounts, pk: opt.Passkeys, st: opt.Store, challenges: newChallengeStore(), maxUpload: accounts.DefaultMaxUpload,
		ipFails: newFailLimiter(ipFailLimit, failWindow), userFails: newFailLimiter(accountFailLimit, failWindow)}
	if u, err := url.Parse(opt.PublicURL); err == nil && u.Host != "" {
		a.origin = u.Scheme + "://" + u.Host
		a.secure = u.Scheme == "https"
	}
	return a
}

func (a *authAPI) cookieName() string {
	if a.secure {
		return "__Host-oxipoker_session"
	}
	return "oxipoker_session"
}

// checkOrigin rejects state-changing browser requests from other origins.
// Native apps send no Origin and authenticate with a bearer token; a request
// with neither is refused, so a cookie alone can never change state.
func (a *authAPI) checkOrigin(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodGet, http.MethodHead, http.MethodOptions:
			next.ServeHTTP(w, r)
			return
		}
		origin := r.Header.Get("Origin")
		ok := false
		switch {
		case origin == "":
			ok = bearer(r) != "" || signinPaths[r.URL.Path] && !hasCookie(r, a.cookieName())
		case a.origin != "":
			ok = origin == a.origin
		default:
			if u, err := url.Parse(origin); err == nil {
				ok = u.Host == r.Host
			}
		}
		if !ok {
			writeError(w, http.StatusForbidden, "bad_origin")
			return
		}
		next.ServeHTTP(w, r)
	})
}

// signinPaths may be called by native apps before they hold a token.
var signinPaths = map[string]bool{
	"/api/v1/auth/signin":                true,
	"/api/v1/auth/totp":                  true,
	"/api/v1/auth/passkey/begin":         true,
	"/api/v1/auth/passkey/finish":        true,
	"/api/v1/invitations/check":          true,
	"/api/v1/auth/signup":                true,
	"/api/v1/auth/signup/passkey/begin":  true,
	"/api/v1/auth/signup/passkey/finish": true,
}

func hasCookie(r *http.Request, name string) bool {
	_, err := r.Cookie(name)
	return err == nil
}

func bearer(r *http.Request) string {
	h := r.Header.Get("Authorization")
	if len(h) > 7 && strings.EqualFold(h[:7], "bearer ") {
		return strings.TrimSpace(h[7:])
	}
	return ""
}

// authenticate attaches the signed-in user, if any, to the request context.
func (a *authAPI) authenticate(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		token := bearer(r)
		if token == "" {
			if c, err := r.Cookie(a.cookieName()); err == nil {
				token = c.Value
			}
		}
		if token != "" {
			ss, u, err := a.acc.SessionUser(r.Context(), token)
			if err == nil {
				ctx := context.WithValue(r.Context(), ctxUser, u)
				r = r.WithContext(context.WithValue(ctx, ctxSession, ss))
			} else if !errors.Is(err, accounts.ErrNotFound) {
				writeError(w, http.StatusInternalServerError, "internal")
				return
			}
		}
		next.ServeHTTP(w, r)
	})
}

func currentUser(r *http.Request) *accounts.User {
	u, _ := r.Context().Value(ctxUser).(*accounts.User)
	return u
}

func currentSession(r *http.Request) *accounts.Session {
	s, _ := r.Context().Value(ctxSession).(*accounts.Session)
	return s
}

func requireUser(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if currentUser(r) == nil {
			writeError(w, http.StatusUnauthorized, "unauthenticated")
			return
		}
		next.ServeHTTP(w, r)
	})
}

func (a *authAPI) routes(r chi.Router) {
	r.Post("/auth/signin", a.signin)
	r.Post("/auth/totp", a.totpSignin)
	r.Post("/invitations/check", a.checkInvitation)
	r.Post("/auth/signup", a.signup)
	if a.pk != nil {
		r.Post("/auth/passkey/begin", a.passkeyLoginBegin)
		r.Post("/auth/passkey/finish", a.passkeyLoginFinish)
		r.Post("/auth/signup/passkey/begin", a.signupPasskeyBegin)
		r.Post("/auth/signup/passkey/finish", a.signupPasskeyFinish)
	}
	r.Group(func(r chi.Router) {
		r.Use(requireUser, requireAdmin)
		r.Post("/admin/invitations", a.createInvitation)
		r.Get("/admin/invitations", a.listInvitations)
		r.Delete("/admin/invitations/{id}", a.revokeInvitation)
	})
	r.Group(func(r chi.Router) {
		r.Use(requireUser)
		r.Post("/auth/signout", a.signout)
		r.Get("/me", a.me)
		r.Patch("/me", a.updateMe)
		r.Delete("/me", a.deleteMe)
		r.Post("/me/password", a.changePassword)
		r.Put("/me/avatar", a.setAvatar)
		r.Delete("/me/avatar", a.removeAvatar)
		r.Get("/users/{id}/avatar", a.avatar)
		r.Get("/me/sessions", a.sessions)
		r.Delete("/me/sessions/{id}", a.revokeSession)
		r.Post("/me/sessions/revoke-others", a.revokeOthers)
		r.Get("/me/totp", a.totpStatus)
		r.Post("/me/totp/begin", a.totpBegin)
		r.Post("/me/totp/confirm", a.totpConfirm)
		r.Post("/me/totp/disable", a.totpDisable)
		if a.pk != nil {
			r.Get("/me/passkeys", a.passkeyList)
			r.Post("/me/passkeys/begin", a.passkeyAddBegin)
			r.Post("/me/passkeys/finish", a.passkeyAddFinish)
			r.Patch("/me/passkeys/{id}", a.passkeyRename)
			r.Delete("/me/passkeys/{id}", a.passkeyRemove)
		}
	})
}

type signinRequest struct {
	Username string `json:"username"`
	Password string `json:"password"`
	Client   string `json:"client"` // "web" (cookie, default) or "app" (token in the body)
}

type signinResponse struct {
	User    *accounts.User    `json:"user"`
	Session *accounts.Session `json:"session"`
	Token   string            `json:"token,omitempty"`
}

func (a *authAPI) signin(w http.ResponseWriter, r *http.Request) {
	var req signinRequest
	if !readJSON(w, r, &req, 8<<10) {
		return
	}
	kind := sessionKind(req.Client)
	ip := clientIP(r)
	userKey := strings.ToLower(req.Username)
	if wait := max(a.ipFails.blocked(ip), a.userFails.blocked(userKey)); wait > 0 {
		w.Header().Set("Retry-After", strconv.Itoa(int(math.Ceil(wait.Seconds()))))
		writeError(w, http.StatusTooManyRequests, "rate_limited")
		return
	}
	u, err := a.acc.Authenticate(r.Context(), req.Username, req.Password)
	if errors.Is(err, accounts.ErrInvalidCredentials) {
		a.ipFails.fail(ip)
		a.userFails.fail(userKey)
		a.audit(r, nil, "auth.signin_failed", "", map[string]any{"username": truncate(req.Username, 64)})
		writeError(w, http.StatusUnauthorized, "invalid_credentials")
		return
	}
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal")
		return
	}
	a.userFails.clear(userKey)
	st, err := a.acc.TOTPStatus(r.Context(), u.ID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal")
		return
	}
	if st.Enabled {
		id, ok := a.challenges.put(u.ID, kind)
		if !ok {
			writeError(w, http.StatusServiceUnavailable, "busy")
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{"totp_required": true, "challenge": id})
		return
	}
	a.issueSession(w, r, u, kind, "password")
}

func sessionKind(client string) string {
	if client == accounts.KindApp {
		return accounts.KindApp
	}
	return accounts.KindWeb
}

// issueSession signs u in: a cookie for the web app, a token in the body for
// native apps.
func (a *authAPI) issueSession(w http.ResponseWriter, r *http.Request, u *accounts.User, kind, method string) {
	token, ss, err := a.acc.CreateSession(r.Context(), u.ID, kind, clientIP(r), r.UserAgent())
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal")
		return
	}
	ss.Current = true
	a.audit(r, u, "auth.signin", ss.ID, map[string]any{"method": method, "kind": kind})
	resp := signinResponse{User: u, Session: ss}
	if kind == accounts.KindApp {
		resp.Token = token
	} else {
		http.SetCookie(w, &http.Cookie{Name: a.cookieName(), Value: token, Path: "/", HttpOnly: true, Secure: a.secure,
			SameSite: http.SameSiteLaxMode, Expires: ss.ExpiresAt, MaxAge: int(accounts.SessionTTL.Seconds())})
	}
	writeJSON(w, http.StatusOK, resp)
}

func (a *authAPI) signout(w http.ResponseWriter, r *http.Request) {
	u, ss := currentUser(r), currentSession(r)
	if err := a.acc.RevokeSession(r.Context(), u.ID, ss.ID); err != nil && !errors.Is(err, accounts.ErrNotFound) {
		writeError(w, http.StatusInternalServerError, "internal")
		return
	}
	a.clearCookie(w)
	a.audit(r, u, "auth.signout", ss.ID, nil)
	w.WriteHeader(http.StatusNoContent)
}

func (a *authAPI) clearCookie(w http.ResponseWriter) {
	http.SetCookie(w, &http.Cookie{Name: a.cookieName(), Value: "", Path: "/", HttpOnly: true, Secure: a.secure,
		SameSite: http.SameSiteLaxMode, MaxAge: -1})
}

func (a *authAPI) me(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, currentUser(r))
}

func (a *authAPI) sessions(w http.ResponseWriter, r *http.Request) {
	list, err := a.acc.ListSessions(r.Context(), currentUser(r).ID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal")
		return
	}
	cur := currentSession(r).ID
	for i := range list {
		list[i].Current = list[i].ID == cur
	}
	writeJSON(w, http.StatusOK, map[string]any{"sessions": list})
}

func (a *authAPI) revokeSession(w http.ResponseWriter, r *http.Request) {
	u, id := currentUser(r), chi.URLParam(r, "id")
	err := a.acc.RevokeSession(r.Context(), u.ID, id)
	if errors.Is(err, accounts.ErrNotFound) {
		writeError(w, http.StatusNotFound, "not_found")
		return
	}
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal")
		return
	}
	if id == currentSession(r).ID {
		a.clearCookie(w)
	}
	a.audit(r, u, "session.revoke", id, nil)
	w.WriteHeader(http.StatusNoContent)
}

func (a *authAPI) revokeOthers(w http.ResponseWriter, r *http.Request) {
	u := currentUser(r)
	n, err := a.acc.RevokeAllSessions(r.Context(), u.ID, currentSession(r).ID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal")
		return
	}
	a.audit(r, u, "session.revoke_others", "", map[string]any{"count": n})
	writeJSON(w, http.StatusOK, map[string]any{"revoked": n})
}

func (a *authAPI) audit(r *http.Request, u *accounts.User, action, target string, detail map[string]any) {
	e := store.AuditEvent{Action: action, Target: target, IP: clientIP(r), Detail: detail}
	if u != nil {
		e.ActorID, e.ActorName = u.ID, u.Username
	}
	_ = a.st.Audit(r.Context(), e)
}

func clientIP(r *http.Request) string {
	host := r.RemoteAddr
	if i := strings.LastIndexByte(host, ':'); i > 0 && !strings.HasSuffix(host, "]") {
		host = host[:i]
	}
	return strings.Trim(host, "[]")
}

func truncate(s string, n int) string {
	if len(s) > n {
		return s[:n]
	}
	return s
}

func readJSON(w http.ResponseWriter, r *http.Request, v any, limit int64) bool {
	dec := json.NewDecoder(http.MaxBytesReader(w, r.Body, limit))
	dec.DisallowUnknownFields()
	if err := dec.Decode(v); err != nil {
		writeError(w, http.StatusBadRequest, "bad_request")
		return false
	}
	return true
}

func writeError(w http.ResponseWriter, status int, code string) {
	writeJSON(w, status, map[string]string{"error": code})
}
