package httpapi

import (
	"context"
	"strconv"
	"strings"
	"testing"
	"time"

	"github.com/coder/websocket"
)

func TestBlocksAndReports(t *testing.T) {
	ts := newGameServer(t)
	admin := signinAs(t, ts, "alex", "long enough pw")
	bob := signinAs(t, ts, "bob", "bob long password")
	_, me := ts.do(t, nil, req{method: "GET", path: "/api/v1/me", token: admin})
	alexID := me["id"].(string)
	_, me = ts.do(t, nil, req{method: "GET", path: "/api/v1/me", token: bob})
	bobID := me["id"].(string)

	// Block list.
	if res, _ := ts.do(t, nil, req{method: "PUT", path: "/api/v1/me/blocks/" + bobID, token: bob}); res.StatusCode != 400 {
		t.Fatalf("block self: %d", res.StatusCode)
	}
	if res, _ := ts.do(t, nil, req{method: "PUT", path: "/api/v1/me/blocks/nobody", token: bob}); res.StatusCode != 404 {
		t.Fatalf("block unknown: %d", res.StatusCode)
	}
	for range 2 {
		if res, _ := ts.do(t, nil, req{method: "PUT", path: "/api/v1/me/blocks/" + alexID, token: bob}); res.StatusCode != 204 {
			t.Fatalf("block: %d", res.StatusCode)
		}
	}
	_, out := ts.do(t, nil, req{method: "GET", path: "/api/v1/me/blocks", token: bob})
	if bs := out["blocks"].([]any); len(bs) != 1 || bs[0].(map[string]any)["username"] != "alex" {
		t.Fatalf("blocks: %v", out)
	}
	ts.do(t, nil, req{method: "DELETE", path: "/api/v1/me/blocks/" + alexID, token: bob})
	_, out = ts.do(t, nil, req{method: "GET", path: "/api/v1/me/blocks", token: bob})
	if len(out["blocks"].([]any)) != 0 {
		t.Fatalf("after unblock: %v", out)
	}

	// A table with chat: the report carries its last lines, added by the server.
	_, tb := ts.do(t, nil, req{method: "POST", path: "/api/v1/tables", token: admin, body: tableBody("Friday")})
	tid := tb["id"].(string)
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	ws, _, err := websocket.Dial(ctx, wsURL(ts), &websocket.DialOptions{HTTPHeader: map[string][]string{
		"Authorization": {"Bearer " + admin}, "Origin": {ts.URL}}})
	if err != nil {
		t.Fatal(err)
	}
	defer ws.Close(websocket.StatusNormalClosure, "")
	for _, m := range []string{`{"type":"watch","table":"` + tid + `"}`, `{"id":7,"type":"chat","text":"rude words"}`} {
		if err := ws.Write(ctx, websocket.MessageText, []byte(m)); err != nil {
			t.Fatal(err)
		}
	}
	for { // until the chat reply
		_, b, err := ws.Read(ctx)
		if err != nil {
			t.Fatal(err)
		}
		if strings.Contains(string(b), `"id":7`) {
			break
		}
	}

	bad := []map[string]any{{"user": alexID, "reason": "spam"}, {"user": bobID, "reason": "chat"}, {"user": "nobody", "reason": "chat"}}
	for i, code := range []int{400, 400, 404} {
		if res, _ := ts.do(t, nil, req{method: "POST", path: "/api/v1/reports", token: bob, body: bad[i]}); res.StatusCode != code {
			t.Fatalf("bad report %d: %d", i, res.StatusCode)
		}
	}
	res, _ := ts.do(t, nil, req{method: "POST", path: "/api/v1/reports", token: bob,
		body: map[string]any{"user": alexID, "table": tid, "reason": "chat", "note": "  see chat  "}})
	if res.StatusCode != 201 {
		t.Fatalf("report: %d", res.StatusCode)
	}

	if res, _ := ts.do(t, nil, req{method: "GET", path: "/api/v1/admin/reports", token: bob}); res.StatusCode != 403 {
		t.Fatalf("reports by non-admin: %d", res.StatusCode)
	}
	_, out = ts.do(t, nil, req{method: "GET", path: "/api/v1/admin/reports", token: admin})
	rs := out["reports"].([]any)
	if len(rs) != 1 {
		t.Fatalf("reports: %v", out)
	}
	rp := rs[0].(map[string]any)
	chat := rp["chat"].([]any)
	if rp["reporter"] != "bob" || rp["reported"] != "alex" || rp["note"] != "see chat" || rp["table_name"] != "Friday" ||
		len(chat) != 1 || chat[0].(map[string]any)["text"] != "rude words" {
		t.Fatalf("report: %v", rp)
	}
	path := "/api/v1/admin/reports/" + strconv.FormatInt(int64(rp["id"].(float64)), 10) + "/resolve"
	if res, _ := ts.do(t, nil, req{method: "POST", path: path, token: admin}); res.StatusCode != 204 {
		t.Fatalf("resolve: %d", res.StatusCode)
	}
	if res, _ := ts.do(t, nil, req{method: "POST", path: path, token: admin}); res.StatusCode != 404 {
		t.Fatalf("resolve twice: %d", res.StatusCode)
	}
	_, out = ts.do(t, nil, req{method: "GET", path: "/api/v1/admin/reports", token: admin})
	if len(out["reports"].([]any)) != 0 {
		t.Fatalf("open after resolve: %v", out)
	}
	_, out = ts.do(t, nil, req{method: "GET", path: "/api/v1/admin/reports?all=1", token: admin})
	if len(out["reports"].([]any)) != 1 {
		t.Fatalf("all: %v", out)
	}
}
