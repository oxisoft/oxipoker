package httpapi

import (
	"context"
	"testing"

	"github.com/oxisoft/oxipoker/server/internal/accounts"
)

func TestOwnAccount(t *testing.T) {
	ts := newTestServer(t, "")
	token := appSignin(t, ts)
	other := appSignin(t, ts)

	res, out := ts.do(t, nil, req{method: "PATCH", path: "/api/v1/me", token: token, body: map[string]string{"display_name": "  Alex B  "}})
	if res.StatusCode != 200 || out["display_name"] != "Alex B" {
		t.Fatalf("rename: %d %v", res.StatusCode, out)
	}
	if res, _ := ts.do(t, nil, req{method: "PATCH", path: "/api/v1/me", token: token, body: map[string]string{"display_name": " "}}); res.StatusCode != 400 {
		t.Fatalf("empty display name: %d", res.StatusCode)
	}

	pw := func(cur, next string) int {
		res, _ := ts.do(t, nil, req{method: "POST", path: "/api/v1/me/password", token: token,
			body: map[string]string{"current_password": cur, "new_password": next}})
		return res.StatusCode
	}
	if c := pw("wrong password", "a new long password"); c != 403 {
		t.Fatalf("wrong current: %d", c)
	}
	if c := pw("long enough pw", "short"); c != 400 {
		t.Fatalf("weak new: %d", c)
	}
	if c := pw("long enough pw", "a new long password"); c != 204 {
		t.Fatalf("change: %d", c)
	}
	// This session stays, the other one is signed out, the old password is dead.
	if res, _ := ts.do(t, nil, req{method: "GET", path: "/api/v1/me", token: token}); res.StatusCode != 200 {
		t.Fatalf("own session after change: %d", res.StatusCode)
	}
	if res, _ := ts.do(t, nil, req{method: "GET", path: "/api/v1/me", token: other}); res.StatusCode != 401 {
		t.Fatalf("other session after change: %d", res.StatusCode)
	}
	if res, _ := ts.do(t, nil, req{method: "POST", path: "/api/v1/auth/signin",
		body: map[string]string{"username": "alex", "password": "long enough pw"}}); res.StatusCode != 401 {
		t.Fatalf("old password: %d", res.StatusCode)
	}

	// The only admin cannot delete itself.
	if res, out := ts.do(t, nil, req{method: "DELETE", path: "/api/v1/me", token: token, body: map[string]string{"password": "a new long password"}}); res.StatusCode != 409 || out["error"] != "last_admin" {
		t.Fatalf("delete last admin: %d %v", res.StatusCode, out)
	}

	// A player deletes their account.
	ctx := context.Background()
	u, err := ts.acc.CreateUser(ctx, accounts.NewUser{Username: "sam", Password: "sams password"})
	if err != nil {
		t.Fatal(err)
	}
	samToken, _, _ := ts.acc.CreateSession(ctx, u.ID, accounts.KindApp, "", "")
	if res, _ := ts.do(t, nil, req{method: "DELETE", path: "/api/v1/me", token: samToken, body: map[string]string{"password": "not it at all"}}); res.StatusCode != 403 {
		t.Fatalf("delete with wrong password: %d", res.StatusCode)
	}
	if res, _ := ts.do(t, nil, req{method: "DELETE", path: "/api/v1/me", token: samToken, body: map[string]string{"password": "sams password"}}); res.StatusCode != 204 {
		t.Fatalf("delete: %d", res.StatusCode)
	}
	if res, _ := ts.do(t, nil, req{method: "GET", path: "/api/v1/me", token: samToken}); res.StatusCode != 401 {
		t.Fatalf("session after delete: %d", res.StatusCode)
	}
	if _, err := ts.acc.UserByID(ctx, u.ID); err == nil {
		t.Fatal("user still there")
	}
}
