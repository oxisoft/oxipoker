package httpapi

import (
	"context"
	"encoding/json"
	"strings"
	"testing"

	"github.com/oxisoft/oxipoker/server/internal/accounts"
	"github.com/oxisoft/oxipoker/server/internal/webauthntest"
)

func createInvite(t *testing.T, ts *testServer, token string, body map[string]any) (string, string) {
	t.Helper()
	res, out := ts.do(t, nil, req{method: "POST", path: "/api/v1/admin/invitations", token: token, body: body})
	if res.StatusCode != 201 {
		t.Fatalf("create invitation: %d %v", res.StatusCode, out)
	}
	inv := out["invitation"].(map[string]any)
	return out["token"].(string), inv["id"].(string)
}

func TestInvitationsHTTP(t *testing.T) {
	ts := newPasskeyServer(t)
	admin := appSignin(t, ts)

	// Only admins manage invitations.
	ctx := context.Background()
	u, _ := ts.acc.CreateUser(ctx, accounts.NewUser{Username: "player", Password: "players password"})
	player, _, _ := ts.acc.CreateSession(ctx, u.ID, accounts.KindApp, "", "")
	if res, out := ts.do(t, nil, req{method: "POST", path: "/api/v1/admin/invitations", token: player, body: map[string]any{}}); res.StatusCode != 403 || out["error"] != "admin_only" {
		t.Fatalf("player creates invitation: %d %v", res.StatusCode, out)
	}
	if res, _ := ts.do(t, nil, req{method: "GET", path: "/api/v1/admin/invitations"}); res.StatusCode != 401 {
		t.Fatalf("anonymous list: %d", res.StatusCode)
	}
	if res, _ := ts.do(t, nil, req{method: "POST", path: "/api/v1/admin/invitations", token: admin, body: map[string]any{"max_uses": 500}}); res.StatusCode != 400 {
		t.Fatalf("bad params: %d", res.StatusCode)
	}

	res, out := ts.do(t, nil, req{method: "POST", path: "/api/v1/admin/invitations", token: admin,
		body: map[string]any{"expires_in_hours": 24, "note": "for Sam"}})
	if res.StatusCode != 201 || !strings.HasPrefix(out["url"].(string), pkOrigin+"/invite#") {
		t.Fatalf("create: %d %v", res.StatusCode, out)
	}
	single := out["token"].(string)

	if res, out := ts.do(t, nil, req{method: "POST", path: "/api/v1/invitations/check", body: map[string]string{"token": single}}); res.StatusCode != 200 || out["note"] != "for Sam" || out["passkeys"] != true {
		t.Fatalf("check: %d %v", res.StatusCode, out)
	}
	signup := func(tok, name string) (int, map[string]any) {
		res, out := ts.do(t, nil, req{method: "POST", path: "/api/v1/auth/signup",
			body: map[string]string{"token": tok, "username": name, "password": name + " password", "client": "app"}})
		return res.StatusCode, out
	}
	if code, out := signup(single, "x"); code != 400 || out["error"] != "bad_username" {
		t.Fatalf("bad username: %d %v", code, out)
	}
	if code, out := signup(single, "PLAYER"); code != 409 {
		t.Fatalf("taken username: %d %v", code, out)
	}
	code, out := signup(single, "sam")
	if code != 200 || out["token"] == nil || out["user"].(map[string]any)["is_admin"] != false {
		t.Fatalf("sign-up: %d %v", code, out)
	}
	if res, me := ts.do(t, nil, req{method: "GET", path: "/api/v1/me", token: out["token"].(string)}); res.StatusCode != 200 || me["username"] != "sam" {
		t.Fatalf("new session: %d %v", res.StatusCode, me)
	}
	// Single use: a second sign-up and a check both refuse.
	if code, out := signup(single, "kim"); code != 410 || out["error"] != "invitation_used" {
		t.Fatalf("reused link: %d %v", code, out)
	}
	if res, out := ts.do(t, nil, req{method: "POST", path: "/api/v1/invitations/check", body: map[string]string{"token": single}}); res.StatusCode != 410 {
		t.Fatalf("check used: %d %v", res.StatusCode, out)
	}

	// Expired.
	expired, _ := createInvite(t, ts, admin, map[string]any{})
	if _, err := ts.st.DB().Exec(`UPDATE invitations SET expires_at = 1 WHERE uses = 0`); err != nil {
		t.Fatal(err)
	}
	if code, out := signup(expired, "kim"); code != 410 || out["error"] != "invitation_expired" {
		t.Fatalf("expired link: %d %v", code, out)
	}

	// Revoked and unknown.
	revoked, revokedID := createInvite(t, ts, admin, map[string]any{})
	if res, _ := ts.do(t, nil, req{method: "DELETE", path: "/api/v1/admin/invitations/" + revokedID, token: admin}); res.StatusCode != 204 {
		t.Fatalf("revoke: %d", res.StatusCode)
	}
	for _, tok := range []string{revoked, "made-up-token"} {
		if code, out := signup(tok, "kim"); code != 404 || out["error"] != "invitation_invalid" {
			t.Fatalf("invalid link: %d %v", code, out)
		}
	}

	// Passkey sign-up: no password at all, then a passkey sign-in.
	pkInvite, _ := createInvite(t, ts, admin, map[string]any{})
	res, out = ts.do(t, nil, req{method: "POST", path: "/api/v1/auth/signup/passkey/begin",
		body: map[string]string{"token": pkInvite, "username": "kim", "display_name": "Kim"}})
	if res.StatusCode != 200 {
		t.Fatalf("passkey sign-up begin: %d %v", res.StatusCode, out)
	}
	c, o := optionsJSON(t, out)
	auth := webauthntest.New(pkOrigin, "poker.example")
	cred, err := auth.Create(o, "")
	if err != nil {
		t.Fatal(err)
	}
	finish := func() (int, map[string]any) {
		res, out := ts.do(t, nil, req{method: "POST", path: "/api/v1/auth/signup/passkey/finish",
			body: map[string]any{"ceremony": c, "credential": json.RawMessage(cred), "name": "Phone", "client": "app"}})
		return res.StatusCode, out
	}
	if code, out := finish(); code != 200 || out["user"].(map[string]any)["username"] != "kim" {
		t.Fatalf("passkey sign-up finish: %d %v", code, out)
	}
	if code, _ := finish(); code != 400 {
		t.Fatalf("ceremony replay: %d", code)
	}
	res, out = passkeySignin(t, ts, auth, 0)
	if res.StatusCode != 200 || out["user"].(map[string]any)["username"] != "kim" {
		t.Fatalf("kim signs in with the passkey: %d %v", res.StatusCode, out)
	}
	// The link was used up by the passkey sign-up.
	if res, _ := ts.do(t, nil, req{method: "POST", path: "/api/v1/auth/signup/passkey/begin",
		body: map[string]string{"token": pkInvite, "username": "lee"}}); res.StatusCode != 410 {
		t.Fatalf("used passkey link: %d", res.StatusCode)
	}

	res, out = ts.do(t, nil, req{method: "GET", path: "/api/v1/admin/invitations", token: admin})
	list := out["invitations"].([]any)
	if res.StatusCode != 200 || len(list) != 4 {
		t.Fatalf("list: %d %v", res.StatusCode, out)
	}
	joined := 0
	for _, it := range list {
		joined += len(it.(map[string]any)["joined"].([]any))
	}
	if joined != 2 {
		t.Fatalf("joined = %d, want sam and kim", joined)
	}
}
