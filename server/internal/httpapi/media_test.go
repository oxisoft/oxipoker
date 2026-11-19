package httpapi

import (
	"context"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/coder/websocket"

	"github.com/oxisoft/oxipoker/server/internal/media"
)

var testLiveKit = media.Config{URL: "wss://poker.example.com/livekit", Key: "APItest", Secret: "test-secret-test-secret-test-secret-0123"}

func TestMediaToken(t *testing.T) {
	// Minimal option: no media.
	plain := newGameServer(t)
	tok := signinAs(t, plain, "bob", "bob long password")
	_, tb := plain.do(t, nil, req{method: "POST", path: "/api/v1/tables", token: tok, body: tableBody("Plain")})
	if res, out := plain.do(t, nil, req{method: "POST", path: "/api/v1/tables/" + tb["id"].(string) + "/media-token", token: tok}); res.StatusCode != 404 || out["error"] != "media_off" {
		t.Fatalf("media off: %d %v", res.StatusCode, out)
	}

	ts := newGameServer(t, func(o *Options) { o.Media, o.LiveKit = true, testLiveKit })
	admin := signinAs(t, ts, "alex", "long enough pw")
	bob := signinAs(t, ts, "bob", "bob long password")
	_, me := ts.do(t, nil, req{method: "GET", path: "/api/v1/me", token: bob})
	bobID := me["id"].(string)
	_, tb = ts.do(t, nil, req{method: "POST", path: "/api/v1/tables", token: admin, body: tableBody("Video")})
	tid := tb["id"].(string)
	path := "/api/v1/tables/" + tid + "/media-token"

	if res, _ := ts.do(t, nil, req{method: "POST", path: path}); res.StatusCode != 401 && res.StatusCode != 403 {
		t.Fatalf("anonymous: %d", res.StatusCode)
	}
	if res, out := ts.do(t, nil, req{method: "POST", path: "/api/v1/tables/nope/media-token", token: bob}); res.StatusCode != 404 || out["error"] != "not_found" {
		t.Fatalf("unknown table: %d %v", res.StatusCode, out)
	}
	if res, out := ts.do(t, nil, req{method: "POST", path: path, token: bob}); res.StatusCode != 403 || out["error"] != "not_at_table" {
		t.Fatalf("not watching: %d %v", res.StatusCode, out)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	dial := func(token string) *websocket.Conn {
		ws, _, err := websocket.Dial(ctx, wsURL(ts), &websocket.DialOptions{HTTPHeader: map[string][]string{
			"Authorization": {"Bearer " + token}, "Origin": {ts.URL}}})
		if err != nil {
			t.Fatal(err)
		}
		t.Cleanup(func() { ws.Close(websocket.StatusNormalClosure, "") })
		go func() { // drain
			for {
				if _, _, err := ws.Read(ctx); err != nil {
					return
				}
			}
		}()
		return ws
	}
	send := func(ws *websocket.Conn, m string) {
		if err := ws.Write(ctx, websocket.MessageText, []byte(m)); err != nil {
			t.Fatal(err)
		}
	}
	waitFor := func(code int) map[string]any {
		t.Helper()
		for {
			res, out := ts.do(t, nil, req{method: "POST", path: path, token: bob})
			if res.StatusCode == code {
				return out
			}
			if ctx.Err() != nil {
				t.Fatalf("want %d, last %d %v", code, res.StatusCode, out)
			}
			time.Sleep(20 * time.Millisecond)
		}
	}

	bws := dial(bob)
	send(bws, `{"type":"watch","table":"`+tid+`"}`)
	out := waitFor(200)
	if out["url"] != testLiveKit.URL || out["room"] != "table-"+tid {
		t.Fatalf("token body: %v", out)
	}
	cl, err := testLiveKit.Verify(out["token"].(string), time.Now())
	if err != nil {
		t.Fatal(err)
	}
	if cl.Subject != bobID || cl.Name != "bob" || cl.Video.Room != "table-"+tid || !cl.Video.RoomJoin || cl.Video.RoomAdmin {
		t.Fatalf("claims: %+v", cl)
	}

	// Removed by the host: no new token while the table is open.
	aws := dial(admin)
	send(aws, `{"type":"watch","table":"`+tid+`"}`)
	send(aws, `{"id":1,"type":"remove","user":"`+bobID+`"}`)
	if out := waitFor(403); out["error"] != "not_at_table" {
		t.Fatalf("removed: %v", out)
	}
}

func TestAdminMediaCheck(t *testing.T) {
	plain := newGameServer(t)
	admin := signinAs(t, plain, "alex", "long enough pw")
	if res, out := plain.do(t, nil, req{method: "GET", path: "/api/v1/admin/media-check", token: admin}); res.StatusCode != 200 || out["enabled"] != false {
		t.Fatalf("media off: %d %v", res.StatusCode, out)
	}

	lk := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		cfg := media.Config{URL: "ws://x", Key: "APItest", Secret: "test-secret-test-secret-test-secret-0123"}
		if r.URL.Path == "/rtc/validate" {
			if _, err := cfg.Verify(r.URL.Query().Get("access_token"), time.Now()); err != nil {
				http.Error(w, "invalid", http.StatusUnauthorized)
				return
			}
			_, _ = w.Write([]byte("success"))
			return
		}
		_, _ = w.Write([]byte("OK"))
	}))
	defer lk.Close()
	cfg := media.Config{URL: "ws" + strings.TrimPrefix(lk.URL, "http"), Key: "APItest", Secret: "test-secret-test-secret-test-secret-0123"}
	ts := newGameServer(t, func(o *Options) { o.Media, o.LiveKit = true, cfg })
	admin = signinAs(t, ts, "alex", "long enough pw")
	bob := signinAs(t, ts, "bob", "bob long password")
	if res, _ := ts.do(t, nil, req{method: "GET", path: "/api/v1/admin/media-check", token: bob}); res.StatusCode != 403 {
		t.Fatalf("player runs the check: %d", res.StatusCode)
	}
	res, out := ts.do(t, nil, req{method: "GET", path: "/api/v1/admin/media-check", token: admin})
	if res.StatusCode != 200 || out["enabled"] != true || res.Header.Get("Cache-Control") != "no-store" {
		t.Fatalf("check: %d %v", res.StatusCode, out)
	}
	got := map[string]string{}
	for _, c := range out["checks"].([]any) {
		m := c.(map[string]any)
		got[m["name"].(string)] = m["status"].(string)
	}
	if got["signalling"] != "ok" || got["token"] != "ok" || got["turn_tls"] != "skipped" {
		t.Fatalf("checks: %v", got)
	}
}
