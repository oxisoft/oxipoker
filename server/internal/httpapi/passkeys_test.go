package httpapi

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/oxisoft/oxipoker/server/internal/accounts"
	"github.com/oxisoft/oxipoker/server/internal/applinks"
	"github.com/oxisoft/oxipoker/server/internal/store"
	"github.com/oxisoft/oxipoker/server/internal/webauthntest"
)

const pkOrigin = "https://poker.example"

func newPasskeyServer(t *testing.T) *testServer {
	t.Helper()
	st, err := store.Open(context.Background(), t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	acc := accounts.New(st)
	acc.SetTOTPKey(bytes.Repeat([]byte{7}, 32))
	if _, err := acc.CreateUser(context.Background(), accounts.NewUser{Username: "alex", Password: "long enough pw", IsAdmin: true}); err != nil {
		t.Fatal(err)
	}
	pk, err := accounts.NewPasskeys(acc, pkOrigin, applinks.Official.Origin())
	if err != nil {
		t.Fatal(err)
	}
	srv := httptest.NewServer(NewRouter(Options{Store: st, Accounts: acc, Passkeys: pk, PublicURL: pkOrigin}))
	t.Cleanup(func() { srv.Close(); st.Close() })
	return &testServer{Server: srv, acc: acc, st: st}
}

func optionsJSON(t *testing.T, out map[string]any) (string, []byte) {
	t.Helper()
	c, _ := out["ceremony"].(string)
	o, err := json.Marshal(out["options"])
	if c == "" || err != nil {
		t.Fatalf("no ceremony in %v", out)
	}
	return c, o
}

func addPasskey(t *testing.T, ts *testServer, auth *webauthntest.Authenticator, token, name string) (*http.Response, map[string]any) {
	t.Helper()
	res, out := ts.do(t, nil, req{method: "POST", path: "/api/v1/me/passkeys/begin", token: token})
	if res.StatusCode != 200 {
		t.Fatalf("register begin: %d %v", res.StatusCode, out)
	}
	c, o := optionsJSON(t, out)
	if sel := out["options"].(map[string]any)["publicKey"].(map[string]any)["authenticatorSelection"].(map[string]any); sel["residentKey"] != "required" || sel["userVerification"] != "required" {
		t.Fatalf("selection %v", sel)
	}
	cred, err := auth.Create(o, "")
	if err != nil {
		t.Fatal(err)
	}
	return ts.do(t, nil, req{method: "POST", path: "/api/v1/me/passkeys/finish", token: token,
		body: map[string]any{"ceremony": c, "credential": json.RawMessage(cred), "name": name}})
}

func passkeySignin(t *testing.T, ts *testServer, auth *webauthntest.Authenticator, step uint32) (*http.Response, map[string]any) {
	t.Helper()
	res, out := ts.do(t, nil, req{method: "POST", path: "/api/v1/auth/passkey/begin"})
	if res.StatusCode != 200 {
		t.Fatalf("login begin: %d %v", res.StatusCode, out)
	}
	c, o := optionsJSON(t, out)
	cred, err := auth.Get(o, step)
	if err != nil {
		t.Fatal(err)
	}
	return ts.do(t, nil, req{method: "POST", path: "/api/v1/auth/passkey/finish",
		body: map[string]any{"ceremony": c, "credential": json.RawMessage(cred), "client": "app"}})
}

func TestPasskeyRegisterAndSignin(t *testing.T) {
	ts := newPasskeyServer(t)
	token := appSignin(t, ts)
	auth := webauthntest.New(pkOrigin, "poker.example")
	auth.Synced = true

	res, out := addPasskey(t, ts, auth, token, "  Laptop  ")
	if res.StatusCode != 201 || out["name"] != "Laptop" || out["synced"] != true {
		t.Fatalf("register: %d %v", res.StatusCode, out)
	}
	pkID := out["id"].(string)

	res, out = ts.do(t, nil, req{method: "GET", path: "/api/v1/me/passkeys", token: token})
	if list := out["passkeys"].([]any); res.StatusCode != 200 || len(list) != 1 {
		t.Fatalf("list: %d %v", res.StatusCode, out)
	}

	res, out = passkeySignin(t, ts, auth, 0)
	if res.StatusCode != 200 || out["token"] == nil || out["user"].(map[string]any)["username"] != "alex" {
		t.Fatalf("passkey signin: %d %v", res.StatusCode, out)
	}
	res, out = ts.do(t, nil, req{method: "GET", path: "/api/v1/me", token: out["token"].(string)})
	if res.StatusCode != 200 || out["username"] != "alex" {
		t.Fatalf("me via passkey session: %d %v", res.StatusCode, out)
	}
	_, out = ts.do(t, nil, req{method: "GET", path: "/api/v1/me/passkeys", token: token})
	if out["passkeys"].([]any)[0].(map[string]any)["last_used_at"] == nil {
		t.Fatal("last_used_at not set")
	}

	res, _ = ts.do(t, nil, req{method: "PATCH", path: "/api/v1/me/passkeys/" + pkID, token: token, body: map[string]string{"name": "Phone"}})
	if res.StatusCode != 204 {
		t.Fatalf("rename: %d", res.StatusCode)
	}
	res, _ = ts.do(t, nil, req{method: "PATCH", path: "/api/v1/me/passkeys/nope", token: token, body: map[string]string{"name": "x"}})
	if res.StatusCode != 404 {
		t.Fatalf("rename unknown: %d", res.StatusCode)
	}
	// alex has a password, so the only passkey may go.
	res, _ = ts.do(t, nil, req{method: "DELETE", path: "/api/v1/me/passkeys/" + pkID, token: token})
	if res.StatusCode != 204 {
		t.Fatalf("remove: %d", res.StatusCode)
	}
	res, _ = passkeySignin(t, ts, auth, 0)
	if res.StatusCode != 401 {
		t.Fatalf("signin with removed passkey: %d", res.StatusCode)
	}
}

func TestPasskeyNegative(t *testing.T) {
	ts := newPasskeyServer(t)
	token := appSignin(t, ts)
	auth := webauthntest.New(pkOrigin, "poker.example")

	// Response made for another origin.
	res, out := ts.do(t, nil, req{method: "POST", path: "/api/v1/me/passkeys/begin", token: token})
	c, o := optionsJSON(t, out)
	cred, _ := auth.Create(o, "https://evil.example")
	res, _ = ts.do(t, nil, req{method: "POST", path: "/api/v1/me/passkeys/finish", token: token,
		body: map[string]any{"ceremony": c, "credential": json.RawMessage(cred)}})
	if res.StatusCode != 400 {
		t.Fatalf("foreign origin accepted: %d", res.StatusCode)
	}
	// The ceremony is single use, also after a failure.
	cred, _ = auth.Create(o, "")
	res, _ = ts.do(t, nil, req{method: "POST", path: "/api/v1/me/passkeys/finish", token: token,
		body: map[string]any{"ceremony": c, "credential": json.RawMessage(cred)}})
	if res.StatusCode != 400 {
		t.Fatalf("ceremony reused: %d", res.StatusCode)
	}

	if res, _ := addPasskey(t, ts, auth, token, ""); res.StatusCode != 201 {
		t.Fatalf("register: %d", res.StatusCode)
	}
	// Counter goes 0 -> 5, then a copy shows 1: possible clone, refused.
	if res, _ := passkeySignin(t, ts, auth, 5); res.StatusCode != 200 {
		t.Fatalf("signin: %d", res.StatusCode)
	}
	auth.SetCounter(0)
	if res, _ := passkeySignin(t, ts, auth, 1); res.StatusCode != 401 {
		t.Fatalf("cloned authenticator accepted: %d", res.StatusCode)
	}

	// A login ceremony cannot be replayed.
	res, out = ts.do(t, nil, req{method: "POST", path: "/api/v1/auth/passkey/begin"})
	c, o = optionsJSON(t, out)
	auth.SetCounter(10)
	cred, _ = auth.Get(o, 1)
	body := map[string]any{"ceremony": c, "credential": json.RawMessage(cred), "client": "app"}
	if res, _ := ts.do(t, nil, req{method: "POST", path: "/api/v1/auth/passkey/finish", body: body}); res.StatusCode != 200 {
		t.Fatalf("signin: %d", res.StatusCode)
	}
	if res, _ := ts.do(t, nil, req{method: "POST", path: "/api/v1/auth/passkey/finish", body: body}); res.StatusCode != 401 {
		t.Fatalf("replay accepted: %d", res.StatusCode)
	}
	// Browser call from a foreign page.
	if res, _ := ts.do(t, nil, req{method: "POST", path: "/api/v1/auth/passkey/begin", origin: "https://evil.example"}); res.StatusCode != 403 {
		t.Fatalf("foreign origin begin: %d", res.StatusCode)
	}
	// Signed out callers cannot manage passkeys.
	if res, _ := ts.do(t, nil, req{method: "GET", path: "/api/v1/me/passkeys"}); res.StatusCode != 401 {
		t.Fatalf("list signed out: %d", res.StatusCode)
	}
}

func TestPasskeyOnlyAccountKeepsLastPasskey(t *testing.T) {
	ts := newPasskeyServer(t)
	ctx := context.Background()
	u, err := ts.acc.CreateUser(ctx, accounts.NewUser{Username: "nopass"})
	if err != nil {
		t.Fatal(err)
	}
	token, _, err := ts.acc.CreateSession(ctx, u.ID, accounts.KindApp, "", "")
	if err != nil {
		t.Fatal(err)
	}
	auth := webauthntest.New(pkOrigin, "poker.example")
	_, a := addPasskey(t, ts, auth, token, "one")
	_, b := addPasskey(t, ts, auth, token, "two")
	if res, _ := ts.do(t, nil, req{method: "DELETE", path: "/api/v1/me/passkeys/" + a["id"].(string), token: token}); res.StatusCode != 204 {
		t.Fatalf("remove first: %d", res.StatusCode)
	}
	if res, out := ts.do(t, nil, req{method: "DELETE", path: "/api/v1/me/passkeys/" + b["id"].(string), token: token}); res.StatusCode != 409 || out["error"] != "last_sign_in_method" {
		t.Fatalf("remove last: %d %v", res.StatusCode, out)
	}
}

func TestPasskeysOffWithoutPublicURL(t *testing.T) {
	ts := newTestServer(t, "")
	if res, _ := ts.do(t, nil, req{method: "POST", path: "/api/v1/auth/passkey/begin"}); res.StatusCode != 404 {
		t.Fatalf("passkeys without PUBLIC_URL: %d", res.StatusCode)
	}
}

func TestPasskeyFromAndroidApp(t *testing.T) {
	ts := newPasskeyServer(t)
	token := appSignin(t, ts)
	app := webauthntest.New(applinks.Official.Origin(), "poker.example")
	if res, out := addPasskey(t, ts, app, token, "Phone"); res.StatusCode != 201 {
		t.Fatalf("register from the app: %d %v", res.StatusCode, out)
	}
	if res, out := passkeySignin(t, ts, app, 1); res.StatusCode != 200 || out["token"] == nil {
		t.Fatalf("signin from the app: %d %v", res.StatusCode, out)
	}
	// Another signing certificate (a repackaged app) is refused.
	fake := webauthntest.New("android:apk-key-hash:AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHv8", "poker.example")
	if res, _ := addPasskey(t, ts, fake, token, "Fake"); res.StatusCode == 201 {
		t.Fatal("passkey from an unknown app accepted")
	}

	res, err := http.Get(ts.URL + "/.well-known/assetlinks.json")
	if err != nil {
		t.Fatal(err)
	}
	defer res.Body.Close()
	var list []map[string]any
	if err := json.NewDecoder(res.Body).Decode(&list); err != nil || res.StatusCode != 200 || len(list) != 1 ||
		list[0]["target"].(map[string]any)["package_name"] != applinks.Official.Package {
		t.Fatalf("assetlinks: %d %v %v", res.StatusCode, list, err)
	}
}
