package httpapi

import (
	"errors"
	"net/http"
	"sync"
	"time"

	"github.com/oxisoft/oxipoker/server/internal/accounts"
)

// Second-factor challenges: issued after a correct password, valid for
// challengeTTL and challengeTries wrong codes.
const (
	challengeTTL   = 5 * time.Minute
	challengeTries = 5
	maxChallenges  = 1000
)

type challenge struct {
	userID, kind string
	expires      time.Time
	tries        int
}

type challengeStore struct {
	mu  sync.Mutex
	m   map[string]*challenge
	now func() time.Time
}

func newChallengeStore() *challengeStore {
	return &challengeStore{m: map[string]*challenge{}, now: time.Now}
}

func (c *challengeStore) put(userID, kind string) (string, bool) {
	c.mu.Lock()
	defer c.mu.Unlock()
	now := c.now()
	for id, ch := range c.m {
		if now.After(ch.expires) {
			delete(c.m, id)
		}
	}
	if len(c.m) >= maxChallenges {
		return "", false
	}
	id := accounts.NewID()
	c.m[id] = &challenge{userID: userID, kind: kind, expires: now.Add(challengeTTL)}
	return id, true
}

// get returns a live challenge and counts one try; the last allowed try
// removes it.
func (c *challengeStore) get(id string) (challenge, bool) {
	c.mu.Lock()
	defer c.mu.Unlock()
	ch, ok := c.m[id]
	if !ok || c.now().After(ch.expires) {
		delete(c.m, id)
		return challenge{}, false
	}
	ch.tries++
	if ch.tries >= challengeTries {
		delete(c.m, id)
	}
	return *ch, true
}

func (c *challengeStore) drop(id string) {
	c.mu.Lock()
	delete(c.m, id)
	c.mu.Unlock()
}

type codeRequest struct {
	Challenge string `json:"challenge,omitempty"`
	Code      string `json:"code"`
}

func (a *authAPI) totpSignin(w http.ResponseWriter, r *http.Request) {
	if a.ipLimited(w, r) {
		return
	}
	var req codeRequest
	if !readJSON(w, r, &req, 4<<10) {
		return
	}
	ch, ok := a.challenges.get(req.Challenge)
	if !ok {
		writeError(w, http.StatusUnauthorized, "challenge_expired")
		return
	}
	if wait := a.userFails.blocked("id:" + ch.userID); wait > 0 {
		a.challenges.drop(req.Challenge)
		writeError(w, http.StatusTooManyRequests, "rate_limited")
		return
	}
	method, err := a.acc.VerifySecondFactor(r.Context(), ch.userID, req.Code)
	if errors.Is(err, accounts.ErrInvalidCode) {
		a.ipFails.fail(clientIP(r))
		a.userFails.fail("id:" + ch.userID)
		u, _ := a.acc.UserByID(r.Context(), ch.userID)
		a.audit(r, u, "auth.totp_failed", "", nil)
		writeError(w, http.StatusUnauthorized, "invalid_code")
		return
	}
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal")
		return
	}
	a.challenges.drop(req.Challenge)
	u, err := a.acc.UserByID(r.Context(), ch.userID)
	if err != nil || u.Disabled() {
		writeError(w, http.StatusUnauthorized, "invalid_credentials")
		return
	}
	a.issueSession(w, r, u, ch.kind, "password+"+method)
}

func (a *authAPI) totpStatus(w http.ResponseWriter, r *http.Request) {
	st, err := a.acc.TOTPStatus(r.Context(), currentUser(r).ID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal")
		return
	}
	writeJSON(w, http.StatusOK, st)
}

func (a *authAPI) totpBegin(w http.ResponseWriter, r *http.Request) {
	e, err := a.acc.BeginTOTP(r.Context(), currentUser(r))
	switch {
	case errors.Is(err, accounts.ErrTOTPEnabled):
		writeError(w, http.StatusConflict, "totp_enabled")
	case err != nil:
		writeError(w, http.StatusInternalServerError, "internal")
	default:
		writeJSON(w, http.StatusOK, e)
	}
}

func (a *authAPI) totpConfirm(w http.ResponseWriter, r *http.Request) {
	var req codeRequest
	if !readJSON(w, r, &req, 4<<10) {
		return
	}
	u := currentUser(r)
	codes, err := a.acc.ConfirmTOTP(r.Context(), u, req.Code)
	switch {
	case errors.Is(err, accounts.ErrTOTPEnabled):
		writeError(w, http.StatusConflict, "totp_enabled")
	case errors.Is(err, accounts.ErrTOTPNotEnabled):
		writeError(w, http.StatusConflict, "totp_not_started")
	case errors.Is(err, accounts.ErrInvalidCode):
		writeError(w, http.StatusBadRequest, "invalid_code")
	case err != nil:
		writeError(w, http.StatusInternalServerError, "internal")
	default:
		a.audit(r, u, "totp.enable", u.ID, nil)
		writeJSON(w, http.StatusOK, map[string]any{"recovery_codes": codes})
	}
}

func (a *authAPI) totpDisable(w http.ResponseWriter, r *http.Request) {
	var req codeRequest
	if !readJSON(w, r, &req, 4<<10) {
		return
	}
	u := currentUser(r)
	if wait := a.userFails.blocked("id:" + u.ID); wait > 0 {
		writeError(w, http.StatusTooManyRequests, "rate_limited")
		return
	}
	err := a.acc.DisableTOTP(r.Context(), u, req.Code)
	switch {
	case errors.Is(err, accounts.ErrTOTPNotEnabled):
		writeError(w, http.StatusConflict, "totp_not_enabled")
	case errors.Is(err, accounts.ErrInvalidCode):
		a.userFails.fail("id:" + u.ID)
		writeError(w, http.StatusBadRequest, "invalid_code")
	case err != nil:
		writeError(w, http.StatusInternalServerError, "internal")
	default:
		a.audit(r, u, "totp.disable", u.ID, nil)
		w.WriteHeader(http.StatusNoContent)
	}
}
