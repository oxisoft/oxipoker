package httpapi

import (
	"bytes"
	"context"
	"net/http"
	"net/http/cookiejar"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/coder/websocket"

	"github.com/oxisoft/oxipoker/server/internal/accounts"
	"github.com/oxisoft/oxipoker/server/internal/history"
	"github.com/oxisoft/oxipoker/server/internal/realtime"
	"github.com/oxisoft/oxipoker/server/internal/store"
	"github.com/oxisoft/oxipoker/server/internal/table"
)

func newGameServer(t *testing.T) *testServer {
	t.Helper()
	st, err := store.Open(context.Background(), t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	acc := accounts.New(st)
	acc.SetTOTPKey(bytes.Repeat([]byte{7}, 32))
	for _, u := range []accounts.NewUser{{Username: "alex", Password: "long enough pw", IsAdmin: true},
		{Username: "bob", Password: "bob long password"}} {
		if _, err := acc.CreateUser(context.Background(), u); err != nil {
			t.Fatal(err)
		}
	}
	hub := realtime.NewHub()
	hist := history.New(t.Context(), st.DB(), nil)
	mgr := table.NewManager(time.Hour, hub.TableOptions)
	srv := httptest.NewServer(NewRouter(Options{Store: st, Accounts: acc, Tables: mgr, Hub: hub, History: hist, PingEvery: 50 * time.Millisecond}))
	t.Cleanup(func() { srv.Close(); mgr.Shutdown(); st.Close() })
	return &testServer{Server: srv, acc: acc, st: st}
}

func signinAs(t *testing.T, ts *testServer, user, pw string) string {
	t.Helper()
	res, out := ts.do(t, nil, req{method: "POST", path: "/api/v1/auth/signin",
		body: map[string]string{"username": user, "password": pw, "client": "app"}})
	if res.StatusCode != 200 {
		t.Fatalf("signin %s: %d %v", user, res.StatusCode, out)
	}
	return out["token"].(string)
}

func tableBody(name string) map[string]any {
	return map[string]any{"name": name, "seats": 6, "small_blind": 5, "big_blind": 10,
		"starting_stack": 1000, "turn_time": 30, "spectators": true}
}

func TestTablesAPI(t *testing.T) {
	ts := newGameServer(t)
	alex := signinAs(t, ts, "alex", "long enough pw")
	bob := signinAs(t, ts, "bob", "bob long password")

	if res, _ := ts.do(t, nil, req{method: "GET", path: "/api/v1/tables"}); res.StatusCode != 401 {
		t.Fatalf("anonymous list: %d", res.StatusCode)
	}
	res, out := ts.do(t, nil, req{method: "POST", path: "/api/v1/tables", token: bob, body: tableBody("  Bob's  ")})
	if res.StatusCode != 201 || out["settings"].(map[string]any)["name"] != "Bob's" ||
		out["settings"].(map[string]any)["turn_time"] != float64(30) {
		t.Fatalf("create: %d %v", res.StatusCode, out)
	}
	bobTable := out["id"].(string)

	for _, bad := range []func(map[string]any){
		func(b map[string]any) { b["seats"] = 10 },
		func(b map[string]any) { b["seats"] = 1 },
		func(b map[string]any) { b["turn_time"] = 4 },
		func(b map[string]any) { b["turn_time"] = 301 },
		func(b map[string]any) { b["name"] = " " },
		func(b map[string]any) { b["name"] = strings.Repeat("n", MaxTableName+1) },
		func(b map[string]any) { b["big_blind"] = 0 },
		func(b map[string]any) { b["starting_stack"] = 15 },
		func(b map[string]any) { b["extra"] = true },
	} {
		b := tableBody("x")
		bad(b)
		if res, out := ts.do(t, nil, req{method: "POST", path: "/api/v1/tables", token: bob, body: b}); res.StatusCode != 400 {
			t.Fatalf("bad settings %v accepted: %d %v", b, res.StatusCode, out)
		}
	}

	// Admin-only table creation.
	if res, _ := ts.do(t, nil, req{method: "PATCH", path: "/api/v1/admin/settings", token: alex,
		body: map[string]any{"table_creation": "admins"}}); res.StatusCode != 200 {
		t.Fatalf("settings: %d", res.StatusCode)
	}
	if res, out := ts.do(t, nil, req{method: "POST", path: "/api/v1/tables", token: bob, body: tableBody("b2")}); res.StatusCode != 403 || out["error"] != "admins_only" {
		t.Fatalf("bob with admins-only: %d %v", res.StatusCode, out)
	}
	res, out = ts.do(t, nil, req{method: "POST", path: "/api/v1/tables", token: alex, body: tableBody("Alex")})
	if res.StatusCode != 201 {
		t.Fatalf("alex create: %d %v", res.StatusCode, out)
	}
	alexTable := out["id"].(string)

	res, out = ts.do(t, nil, req{method: "GET", path: "/api/v1/tables", token: bob})
	if tl := out["tables"].([]any); res.StatusCode != 200 || len(tl) != 2 || tl[0].(map[string]any)["id"] != bobTable {
		t.Fatalf("list: %d %v", res.StatusCode, out)
	}

	if res, out := ts.do(t, nil, req{method: "DELETE", path: "/api/v1/tables/" + alexTable, token: bob}); res.StatusCode != 403 {
		t.Fatalf("bob closes alex's table: %d %v", res.StatusCode, out)
	}
	if res, _ := ts.do(t, nil, req{method: "DELETE", path: "/api/v1/tables/" + bobTable, token: alex}); res.StatusCode != 204 {
		t.Fatalf("admin closes bob's table: %d", res.StatusCode)
	}
	if res, _ := ts.do(t, nil, req{method: "DELETE", path: "/api/v1/tables/" + bobTable, token: alex}); res.StatusCode != 404 {
		t.Fatalf("close twice: %d", res.StatusCode)
	}
	if res, _ := ts.do(t, nil, req{method: "DELETE", path: "/api/v1/tables/" + alexTable, token: alex}); res.StatusCode != 204 {
		t.Fatalf("host closes: %d", res.StatusCode)
	}
}

func wsURL(ts *testServer) string { return "ws" + strings.TrimPrefix(ts.URL, "http") + "/api/v1/ws" }

func TestOwnHistoryEndpoints(t *testing.T) {
	ts := newGameServer(t)
	bob := signinAs(t, ts, "bob", "bob long password")
	if res, out := ts.do(t, nil, req{method: "GET", path: "/api/v1/me/hands", token: bob}); res.StatusCode != 200 || len(out["hands"].([]any)) != 0 {
		t.Fatalf("hands: %d %v", res.StatusCode, out)
	}
	if res, out := ts.do(t, nil, req{method: "GET", path: "/api/v1/me/stats", token: bob}); res.StatusCode != 200 || out["hands_played"] != float64(0) {
		t.Fatalf("stats: %d %v", res.StatusCode, out)
	}
	for _, p := range []string{"/api/v1/me/hands/1", "/api/v1/me/hands/x"} {
		if res, _ := ts.do(t, nil, req{method: "GET", path: p, token: bob}); res.StatusCode != 404 {
			t.Fatalf("%s: %d", p, res.StatusCode)
		}
	}
	if res, _ := ts.do(t, nil, req{method: "GET", path: "/api/v1/me/stats"}); res.StatusCode != 401 {
		t.Fatalf("anonymous stats: %d", res.StatusCode)
	}
}

func TestWebSocketAuthAndOrigin(t *testing.T) {
	ts := newGameServer(t)
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// No session.
	if _, res, err := websocket.Dial(ctx, wsURL(ts), nil); err == nil || res == nil || res.StatusCode != 401 {
		t.Fatalf("anonymous: %v %v", res, err)
	}

	// Native app: bearer token, no Origin.
	tok := signinAs(t, ts, "bob", "bob long password")
	c, _, err := websocket.Dial(ctx, wsURL(ts), &websocket.DialOptions{HTTPHeader: http.Header{"Authorization": {"Bearer " + tok}}})
	if err != nil {
		t.Fatal(err)
	}
	if _, b, err := c.Read(ctx); err != nil || !strings.Contains(string(b), `"type":"hello"`) || !strings.Contains(string(b), `"name":"bob"`) {
		t.Fatalf("hello: %s %v", b, err)
	}

	// Browser: cookie from a web sign-in, Origin must be this server.
	jar, _ := cookiejar.New(nil)
	web := &http.Client{Jar: jar}
	if res, out := ts.do(t, web, req{method: "POST", path: "/api/v1/auth/signin",
		body: map[string]string{"username": "alex", "password": "long enough pw"}}); res.StatusCode != 200 {
		t.Fatalf("web signin: %d %v", res.StatusCode, out)
	}
	if _, res, err := websocket.Dial(ctx, wsURL(ts), &websocket.DialOptions{HTTPClient: web,
		HTTPHeader: http.Header{"Origin": {"https://evil.example"}}}); err == nil || res == nil || res.StatusCode != 403 {
		t.Fatalf("foreign origin: %v %v", res, err)
	}
	// A cookie without Origin (not a browser) is refused as well.
	if _, res, err := websocket.Dial(ctx, wsURL(ts), &websocket.DialOptions{HTTPClient: web}); err == nil || res == nil || res.StatusCode != 403 {
		t.Fatalf("cookie without origin: %v %v", res, err)
	}
	wc, _, err := websocket.Dial(ctx, wsURL(ts), &websocket.DialOptions{HTTPClient: web, HTTPHeader: http.Header{"Origin": {ts.URL}}})
	if err != nil {
		t.Fatal(err)
	}
	if _, b, err := wc.Read(ctx); err != nil || !strings.Contains(string(b), `"name":"alex"`) {
		t.Fatalf("web hello: %s %v", b, err)
	}

	// Signing out closes the open connection at the next keepalive.
	if res, _ := ts.do(t, nil, req{method: "POST", path: "/api/v1/auth/signout", token: tok}); res.StatusCode != 204 && res.StatusCode != 200 {
		t.Fatalf("signout: %d", res.StatusCode)
	}
	rctx, rcancel := context.WithTimeout(ctx, 2*time.Second)
	defer rcancel()
	for {
		if _, _, err := c.Read(rctx); err != nil {
			if rctx.Err() != nil {
				t.Fatal("connection still open after sign-out")
			}
			break
		}
	}
}
