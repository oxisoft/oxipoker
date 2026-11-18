package httpapi

import (
	"bytes"
	"context"
	"net/http"
	"testing"

	"github.com/oxisoft/oxipoker/server/internal/accounts"
)

func TestAdminUsers(t *testing.T) {
	ts := newTestServer(t, "")
	admin := appSignin(t, ts)
	ctx := context.Background()
	alex, _ := ts.acc.UserByUsername(ctx, "alex")

	// Create: the server picks a one-time password.
	res, out := ts.do(t, nil, req{method: "POST", path: "/api/v1/admin/users", token: admin,
		body: map[string]any{"username": "sam", "display_name": "Sam Jones"}})
	if res.StatusCode != 201 || out["temporary_password"] == nil {
		t.Fatalf("create: %d %v", res.StatusCode, out)
	}
	temp := out["temporary_password"].(string)
	samID := out["user"].(map[string]any)["id"].(string)
	if res, _ := ts.do(t, nil, req{method: "POST", path: "/api/v1/admin/users", token: admin,
		body: map[string]any{"username": "Sam"}}); res.StatusCode != 409 {
		t.Fatalf("duplicate: %d", res.StatusCode)
	}

	// Sam must replace the temporary password before anything else.
	res, out = ts.do(t, nil, req{method: "POST", path: "/api/v1/auth/signin",
		body: map[string]string{"username": "sam", "password": temp, "client": "app"}})
	if res.StatusCode != 200 || out["user"].(map[string]any)["must_change_password"] != true {
		t.Fatalf("sam signs in: %d %v", res.StatusCode, out)
	}
	sam := out["token"].(string)
	if res, out := ts.do(t, nil, req{method: "GET", path: "/api/v1/me/sessions", token: sam}); res.StatusCode != 403 || out["error"] != "password_change_required" {
		t.Fatalf("before change: %d %v", res.StatusCode, out)
	}
	if res, _ := ts.do(t, nil, req{method: "POST", path: "/api/v1/me/password", token: sam,
		body: map[string]string{"current_password": temp, "new_password": "sams own password"}}); res.StatusCode != 204 {
		t.Fatalf("change: %d", res.StatusCode)
	}
	if res, _ := ts.do(t, nil, req{method: "GET", path: "/api/v1/me/sessions", token: sam}); res.StatusCode != 200 {
		t.Fatalf("after change: %d", res.StatusCode)
	}
	if res, _ := ts.do(t, nil, req{method: "GET", path: "/api/v1/admin/users", token: sam}); res.StatusCode != 403 {
		t.Fatalf("player lists users: %d", res.StatusCode)
	}

	// List and search.
	res, out = ts.do(t, nil, req{method: "GET", path: "/api/v1/admin/users?q=JON", token: admin})
	if res.StatusCode != 200 || out["total"].(float64) != 1 {
		t.Fatalf("search: %d %v", res.StatusCode, out)
	}
	if _, out = ts.do(t, nil, req{method: "GET", path: "/api/v1/admin/users?q=%25", token: admin}); out["total"].(float64) != 0 {
		t.Fatalf("%% is literal: %v", out)
	}
	if _, out = ts.do(t, nil, req{method: "GET", path: "/api/v1/admin/users", token: admin}); out["total"].(float64) != 2 {
		t.Fatalf("all: %v", out)
	}

	patch := func(id string, body map[string]any) (int, map[string]any) {
		res, out := ts.do(t, nil, req{method: "PATCH", path: "/api/v1/admin/users/" + id, token: admin, body: body})
		return res.StatusCode, out
	}
	// Last admin protected; own account goes through /me.
	if code, out := patch(alex.ID, map[string]any{"is_admin": false}); code != 409 || out["error"] != "self" {
		t.Fatalf("demote self: %d %v", code, out)
	}
	if code, _ := patch(samID, map[string]any{"is_admin": true}); code != 200 {
		t.Fatalf("make admin: %d", code)
	}
	if code, _ := patch(samID, map[string]any{"is_admin": false}); code != 200 {
		t.Fatalf("remove admin: %d", code)
	}
	if err := ts.acc.SetAdmin(ctx, alex.ID, false); err != accounts.ErrLastAdmin {
		t.Fatalf("service: demote last admin: %v", err)
	}
	if code, _ := patch("nope", map[string]any{"disabled": true}); code != 404 {
		t.Fatalf("unknown: %d", code)
	}

	// Disable signs out; enable lets the user back in.
	if code, out := patch(samID, map[string]any{"disabled": true}); code != 200 || out["disabled_at"] == nil {
		t.Fatalf("disable: %d %v", code, out)
	}
	if res, _ := ts.do(t, nil, req{method: "GET", path: "/api/v1/me", token: sam}); res.StatusCode != 401 {
		t.Fatalf("disabled session: %d", res.StatusCode)
	}
	if res, _ := ts.do(t, nil, req{method: "POST", path: "/api/v1/auth/signin",
		body: map[string]string{"username": "sam", "password": "sams own password"}}); res.StatusCode != 401 {
		t.Fatalf("disabled sign-in: %d", res.StatusCode)
	}
	if code, _ := patch(samID, map[string]any{"disabled": false}); code != 200 {
		t.Fatalf("enable: %d", code)
	}

	// Reset password and 2FA.
	res, out = ts.do(t, nil, req{method: "POST", path: "/api/v1/admin/users/" + samID + "/reset-password", token: admin})
	if res.StatusCode != 200 || len(out["temporary_password"].(string)) != 19 {
		t.Fatalf("reset password: %d %v", res.StatusCode, out)
	}
	if _, err := ts.acc.Authenticate(ctx, "sam", out["temporary_password"].(string)); err != nil {
		t.Fatalf("temporary password works: %v", err)
	}
	if res, _ := ts.do(t, nil, req{method: "POST", path: "/api/v1/admin/users/" + samID + "/reset-2fa", token: admin}); res.StatusCode != 204 {
		t.Fatalf("reset 2fa: %d", res.StatusCode)
	}

	// Delete.
	if res, _ := ts.do(t, nil, req{method: "DELETE", path: "/api/v1/admin/users/" + alex.ID, token: admin}); res.StatusCode != 409 {
		t.Fatalf("delete self: %d", res.StatusCode)
	}
	if res, _ := ts.do(t, nil, req{method: "DELETE", path: "/api/v1/admin/users/" + samID, token: admin}); res.StatusCode != 204 {
		t.Fatalf("delete: %d", res.StatusCode)
	}

	// Every admin action is in the audit log.
	res, out = ts.do(t, nil, req{method: "GET", path: "/api/v1/admin/audit?action=user.", token: admin})
	seen := map[string]bool{}
	for _, e := range out["events"].([]any) {
		seen[e.(map[string]any)["action"].(string)] = true
	}
	for _, want := range []string{"user.create", "user.admin_grant", "user.admin_revoke", "user.disable", "user.enable",
		"user.password_reset", "user.totp_reset", "user.delete"} {
		if !seen[want] {
			t.Errorf("audit misses %s (%d %v)", want, res.StatusCode, seen)
		}
	}
}

func TestAdminSettings(t *testing.T) {
	ts := newTestServer(t, "")
	admin := appSignin(t, ts)
	res, out := ts.do(t, nil, req{method: "GET", path: "/api/v1/admin/settings", token: admin})
	if res.StatusCode != 200 || out["table_creation"] != "everyone" || out["max_upload_bytes"].(float64) != accounts.DefaultMaxUpload {
		t.Fatalf("defaults: %d %v", res.StatusCode, out)
	}
	for _, bad := range []map[string]any{{"table_creation": "nobody"}, {"max_upload_bytes": 10}, {"max_upload_bytes": 1 << 30}} {
		if res, _ := ts.do(t, nil, req{method: "PATCH", path: "/api/v1/admin/settings", token: admin, body: bad}); res.StatusCode != 400 {
			t.Errorf("%v: %d", bad, res.StatusCode)
		}
	}
	res, out = ts.do(t, nil, req{method: "PATCH", path: "/api/v1/admin/settings", token: admin,
		body: map[string]any{"table_creation": "admins", "max_upload_bytes": 512 << 10}})
	if res.StatusCode != 200 || out["table_creation"] != "admins" || out["max_upload_bytes"].(float64) != 512<<10 {
		t.Fatalf("patch: %d %v", res.StatusCode, out)
	}
	// The new cap applies to uploads at once.
	hr, _ := http.NewRequest("PUT", ts.URL+"/api/v1/me/avatar", bytes.NewReader(make([]byte, 600<<10)))
	hr.Header.Set("Authorization", "Bearer "+admin)
	r2, err := http.DefaultClient.Do(hr)
	if err != nil {
		t.Fatal(err)
	}
	r2.Body.Close()
	if r2.StatusCode != 413 {
		t.Fatalf("upload over the new cap: %d", r2.StatusCode)
	}
}
