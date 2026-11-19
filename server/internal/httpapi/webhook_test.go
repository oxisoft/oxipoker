package httpapi

import (
	"bytes"
	"context"
	"net/http"
	"slices"
	"sync"
	"testing"
	"time"

	"github.com/coder/websocket"
)

type removals struct {
	mu  sync.Mutex
	got []string
}

func (r *removals) Mute(context.Context, string, string, string) error { return nil }
func (r *removals) Close(context.Context, string) error                { return nil }
func (r *removals) Remove(_ context.Context, id, user string) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.got = append(r.got, id+" "+user)
	return nil
}
func (r *removals) list() []string {
	r.mu.Lock()
	defer r.mu.Unlock()
	return slices.Clone(r.got)
}

// F8: a call token cannot be revoked, so LiveKit's participant_joined
// webhook decides. Whoever joins a table's call while not at the table is
// sent out again; players at the table stay; unsigned hooks are refused.
func TestMediaWebhookRemovesJoinsFromAway(t *testing.T) {
	calls := &removals{}
	var hubOpt *Options
	ts := newGameServer(t, func(o *Options) {
		o.Media, o.LiveKit = true, testLiveKit
		o.Hub.SetCalls(calls)
		hubOpt = o
	})
	admin := signinAs(t, ts, "alex", "long enough pw")

	_, me := ts.do(t, nil, req{method: "GET", path: "/api/v1/me", token: admin})
	adminID := me["id"].(string)
	_, tb := ts.do(t, nil, req{method: "POST", path: "/api/v1/tables", token: admin, body: tableBody("Hook")})
	tid := tb["id"].(string)

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	ws, _, err := websocket.Dial(ctx, wsURL(ts), &websocket.DialOptions{HTTPHeader: map[string][]string{
		"Authorization": {"Bearer " + admin}, "Origin": {ts.URL}}})
	if err != nil {
		t.Fatal(err)
	}
	defer ws.Close(websocket.StatusNormalClosure, "")
	go func() {
		for {
			if _, _, err := ws.Read(ctx); err != nil {
				return
			}
		}
	}()
	if err := ws.Write(ctx, websocket.MessageText, []byte(`{"type":"watch","table":"`+tid+`"}`)); err != nil {
		t.Fatal(err)
	}
	for !hubOpt.Hub.Watching(tid, adminID) {
		if ctx.Err() != nil {
			t.Fatal("admin never watched the table")
		}
		time.Sleep(10 * time.Millisecond)
	}

	hook := func(body string, sign bool) int {
		t.Helper()
		r, _ := http.NewRequest(http.MethodPost, ts.URL+"/api/v1/media/webhook", bytes.NewBufferString(body))
		r.Header.Set("Content-Type", "application/webhook+json")
		if sign {
			tok, err := testLiveKit.SignWebhook([]byte(body), time.Now())
			if err != nil {
				t.Fatal(err)
			}
			r.Header.Set("Authorization", tok)
		}
		res, err := http.DefaultClient.Do(r)
		if err != nil {
			t.Fatal(err)
		}
		res.Body.Close()
		return res.StatusCode
	}
	joined := func(user string) string {
		return `{"event":"participant_joined","room":{"name":"table-` + tid + `"},"participant":{"identity":"` + user + `"}}`
	}

	// Unsigned or signed for another body: refused, nothing removed.
	if c := hook(joined("stranger"), false); c != 401 {
		t.Fatalf("unsigned hook: %d", c)
	}
	tok, _ := testLiveKit.SignWebhook([]byte(joined("someone")), time.Now())
	r, _ := http.NewRequest(http.MethodPost, ts.URL+"/api/v1/media/webhook", bytes.NewBufferString(joined("stranger")))
	r.Header.Set("Authorization", tok)
	if res, err := http.DefaultClient.Do(r); err != nil || res.StatusCode != 401 {
		t.Fatalf("hook with another body's signature: %v %v", res, err)
	}

	// The admin watches the table: stays. A user who is not there: removed.
	if c := hook(joined(adminID), true); c != 204 {
		t.Fatalf("hook: %d", c)
	}
	if c := hook(joined("stranger"), true); c != 204 {
		t.Fatalf("hook: %d", c)
	}
	// Other events and rooms are ignored.
	hook(`{"event":"room_started","room":{"name":"table-`+tid+`"}}`, true)
	hook(`{"event":"participant_joined","room":{"name":"other"},"participant":{"identity":"x"}}`, true)

	want := []string{tid + " stranger"}
	for !slices.Equal(calls.list(), want) {
		if ctx.Err() != nil {
			t.Fatalf("removals %v, want %v", calls.list(), want)
		}
		time.Sleep(10 * time.Millisecond)
	}
	time.Sleep(100 * time.Millisecond)
	if got := calls.list(); !slices.Equal(got, want) {
		t.Fatalf("removals %v, want %v", got, want)
	}
}
