package realtime

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/coder/websocket"

	"github.com/oxisoft/oxipoker/server/internal/table"
)

type rig struct {
	hub    *Hub
	tables *table.Manager
	url    string
}

func newRig(t *testing.T) *rig {
	t.Helper()
	hub := NewHub()
	mgr := table.NewManager(time.Hour, func(string) table.Options {
		return table.Options{OnChange: hub.Publish, StartDelay: 20 * time.Millisecond, Pause: 20 * time.Millisecond}
	})
	srv := &Server{Hub: hub, Tables: mgr, PingEvery: 50 * time.Millisecond}
	hs := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		c, err := websocket.Accept(w, r, nil)
		if err != nil {
			return
		}
		u := r.URL.Query().Get("u")
		_ = srv.Serve(context.WithoutCancel(r.Context()), c, User{ID: u, Name: strings.ToUpper(u)})
	}))
	t.Cleanup(func() { hs.Close(); mgr.Shutdown() })
	return &rig{hub: hub, tables: mgr, url: "ws" + strings.TrimPrefix(hs.URL, "http")}
}

func (r *rig) table(t *testing.T, spectators bool) string {
	t.Helper()
	tb, err := r.tables.Create("a", table.Settings{Name: "Friday", Seats: 6, SmallBlind: 5, BigBlind: 10,
		StartingStack: 1000, TurnTime: time.Minute, Spectators: spectators})
	if err != nil {
		t.Fatal(err)
	}
	return tb.ID()
}

type msg struct {
	Type   string          `json:"type"`
	ID     int64           `json:"id"`
	Error  string          `json:"error"`
	View   *table.View     `json:"view"`
	Tables []LobbyTable    `json:"tables"`
	Text   string          `json:"text"`
	Name   string          `json:"name"`
	Raw    json.RawMessage `json:"-"`
}

type client struct {
	t       *testing.T
	ws      *websocket.Conn
	in      chan msg
	next    int64
	last    *table.View
	pending []msg
}

func (r *rig) dial(t *testing.T, user string) *client {
	t.Helper()
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	ws, _, err := websocket.Dial(ctx, r.url+"?u="+user, nil)
	if err != nil {
		t.Fatal(err)
	}
	c := &client{t: t, ws: ws, in: make(chan msg, 1024)}
	go func() {
		defer close(c.in)
		for {
			_, b, err := ws.Read(context.Background())
			if err != nil {
				return
			}
			var m msg
			if err := json.Unmarshal(b, &m); err != nil {
				t.Errorf("bad server message %s: %v", b, err)
				return
			}
			m.Raw = b
			c.in <- m
		}
	}()
	t.Cleanup(func() { ws.Close(websocket.StatusNormalClosure, "") })
	if m := c.wait(func(m msg) bool { return m.Type == "hello" }); m.Name != strings.ToUpper(user) {
		t.Fatalf("hello: %+v", m)
	}
	return c
}

func (c *client) send(v map[string]any) int64 {
	c.t.Helper()
	c.next++
	v["id"] = c.next
	b, _ := json.Marshal(v)
	if err := c.ws.Write(context.Background(), websocket.MessageText, b); err != nil {
		c.t.Fatal(err)
	}
	return c.next
}

// wait returns the first message (read earlier or now) that matches; views
// update c.last on the way. Messages that do not match are kept for later.
func (c *client) wait(match func(msg) bool) msg {
	c.t.Helper()
	for i, m := range c.pending {
		if match(m) {
			c.pending = append(c.pending[:i:i], c.pending[i+1:]...)
			return m
		}
	}
	timeout := time.After(5 * time.Second)
	for {
		select {
		case m, ok := <-c.in:
			if !ok {
				c.t.Fatal("connection closed")
			}
			if m.View != nil {
				c.last = m.View
			}
			if match(m) {
				return m
			}
			c.pending = append(c.pending, m)
		case <-timeout:
			c.t.Fatal("timed out waiting for a message")
		}
	}
}

// waitView returns the latest view matching, maybe one already received.
func (c *client) waitView(match func(*table.View) bool) *table.View {
	c.t.Helper()
	if c.last != nil && match(c.last) {
		return c.last
	}
	return c.wait(func(m msg) bool { return m.View != nil && match(m.View) }).View
}

// do sends an intent and returns the reply's error code ("" = ok).
func (c *client) do(v map[string]any) string {
	c.t.Helper()
	id := c.send(v)
	m := c.wait(func(m msg) bool { return (m.Type == "ok" || m.Type == "error") && m.ID == id })
	return m.Error
}

func TestWatchSitAndPlayOverWebSocket(t *testing.T) {
	r := newRig(t)
	id := r.table(t, true)
	a, b, s := r.dial(t, "a"), r.dial(t, "b"), r.dial(t, "s")
	for _, c := range []*client{a, b, s} {
		if e := c.do(map[string]any{"type": "watch", "table": id}); e != "" {
			t.Fatal(e)
		}
		c.wait(func(m msg) bool { return m.View != nil && m.View.ID == id })
	}
	if e := a.do(map[string]any{"type": "sit", "seat": 0}); e != "" {
		t.Fatal(e)
	}
	if e := b.do(map[string]any{"type": "sit", "seat": 0}); e != "seat_taken" {
		t.Fatalf("second sit on seat 0: %q", e)
	}
	if e := b.do(map[string]any{"type": "sit", "seat": 3}); e != "" {
		t.Fatal(e)
	}

	// Play five hands: each player checks or calls when it is their turn.
	players := map[string]*client{"a": a, "b": b}
	seatOf := map[int]string{0: "a", 3: "b"}
	for r.handsDone(a) < 5 {
		for _, c := range players {
			select {
			case m := <-c.in:
				if m.View != nil {
					c.last = m.View
				}
			case <-time.After(5 * time.Millisecond):
			}
			v := c.last
			if v == nil || v.Hand == nil || v.Hand.Legal == nil || v.Hand.Done {
				continue
			}
			kind := "call"
			if v.Hand.Legal.Check {
				kind = "check"
			}
			id := c.send(map[string]any{"type": "act", "action": kind})
			m := c.wait(func(m msg) bool { return (m.Type == "ok" || m.Type == "error") && m.ID == id })
			if m.Error != "" && m.Error != "not_your_turn" { // a stale view may race the next street
				t.Fatalf("act %s: %s", kind, m.Error)
			}
		}
	}

	// Spectator: drain and check every view it got.
	drain(s)
	for _, c := range []*client{a, b, s} {
		drain(c)
	}
	checkNoHiddenCards(t, s, -1, seatOf)
}

func (r *rig) handsDone(c *client) int {
	if c.last == nil {
		return 0
	}
	n := c.last.HandNo
	if c.last.Hand != nil && !c.last.Hand.Done {
		n--
	}
	return n
}

var seen = map[*client][]msg{}

func drain(c *client) {
	for {
		select {
		case m, ok := <-c.in:
			if !ok {
				return
			}
			seen[c] = append(seen[c], m)
		case <-time.After(100 * time.Millisecond):
			return
		}
	}
}

func checkNoHiddenCards(t *testing.T, c *client, mySeat int, _ map[int]string) {
	t.Helper()
	for _, m := range seen[c] {
		v := m.View
		if v == nil || v.Hand == nil {
			continue
		}
		for _, e := range v.Hand.Events {
			if e.Kind == "hole" && e.Seat != mySeat {
				t.Fatalf("hole cards of seat %d sent to seat %d: %s", e.Seat, mySeat, m.Raw)
			}
		}
		showdown := v.Hand.Done || v.Hand.Street == "showdown"
		for i, sv := range v.Seats {
			if sv != nil && len(sv.Cards) > 0 && i != mySeat && !showdown {
				t.Fatalf("cards of seat %d visible before showdown: %s", i, m.Raw)
			}
		}
	}
}

func TestPlayersOnlyEverGetTheirOwnHoleCards(t *testing.T) {
	r := newRig(t)
	id := r.table(t, true)
	a, b := r.dial(t, "a"), r.dial(t, "b")
	for i, c := range []*client{a, b} {
		c.do(map[string]any{"type": "watch", "table": id})
		if e := c.do(map[string]any{"type": "sit", "seat": i * 2}); e != "" {
			t.Fatal(e)
		}
	}
	// The player to act folds, once per view, until three hands are over.
	acted := map[*client]uint64{}
	for r.handsDone(a) < 3 {
		for _, c := range []*client{a, b} {
			select {
			case m := <-c.in:
				seen[c] = append(seen[c], m)
				if m.View != nil {
					c.last = m.View
				}
			case <-time.After(5 * time.Millisecond):
			}
			if v := c.last; v != nil && v.Hand != nil && v.Hand.Legal != nil && !v.Hand.Done && acted[c] != v.Version {
				acted[c] = v.Version
				c.send(map[string]any{"type": "act", "action": "fold"})
			}
		}
	}
	drain(a)
	drain(b)
	checkNoHiddenCards(t, a, 0, nil)
	checkNoHiddenCards(t, b, 2, nil)
}

func TestInvalidIntentsGetErrorsAndNoChange(t *testing.T) {
	r := newRig(t)
	id := r.table(t, true)
	a := r.dial(t, "a")
	if e := a.do(map[string]any{"type": "sit", "seat": 0}); e != "not_watching" {
		t.Fatalf("sit before watch: %q", e)
	}
	if e := a.do(map[string]any{"type": "watch", "table": "nope"}); e != "no_table" {
		t.Fatalf("watch unknown: %q", e)
	}
	a.do(map[string]any{"type": "watch", "table": id})
	v0 := a.wait(func(m msg) bool { return m.View != nil }).View.Version
	for _, in := range []map[string]any{
		{"type": "act", "action": "raise", "to": 100}, // not seated
		{"type": "sit", "seat": 9},
		{"type": "sit"},
		{"type": "dance"},
		{"type": "act", "action": "allin"},
		{"type": "chat", "text": "   "},
		{"type": "chat", "text": strings.Repeat("x", MaxChatRunes+1)},
		{"type": "chat", "text": "bell\a"},
	} {
		if e := a.do(in); e == "" {
			t.Fatalf("%v accepted", in)
		}
	}
	// Unknown fields and binary frames are rejected too.
	if err := a.ws.Write(context.Background(), websocket.MessageText, []byte(`{"type":"ping","evil":1}`)); err != nil {
		t.Fatal(err)
	}
	if m := a.wait(func(m msg) bool { return m.Type == "error" }); m.Error != "bad_intent" {
		t.Fatalf("unknown field: %+v", m)
	}
	st, _ := r.hub.State(id)
	if st.Version != v0 {
		t.Fatalf("state changed by invalid intents: %d -> %d", v0, st.Version)
	}
	if e := a.do(map[string]any{"type": "sit", "seat": 1}); e != "" {
		t.Fatal(e)
	}
	if e := a.do(map[string]any{"type": "act", "action": "check"}); e != "not_in_hand" {
		t.Fatalf("act without a hand: %q", e)
	}
}

func TestReconnectGetsTheViewAtOnce(t *testing.T) {
	r := newRig(t)
	id := r.table(t, true)
	a := r.dial(t, "a")
	a.do(map[string]any{"type": "watch", "table": id})
	a.do(map[string]any{"type": "sit", "seat": 2})
	v := a.waitView(func(v *table.View) bool { return v.YourSeat == 2 })
	a.ws.Close(websocket.StatusGoingAway, "phone slept")

	// The seat is kept and the new connection gets the same view right away.
	a2 := r.dial(t, "a")
	start := time.Now()
	a2.send(map[string]any{"type": "watch", "table": id})
	v2 := a2.wait(func(m msg) bool { return m.View != nil }).View
	if v2.YourSeat != 2 || v2.Version != v.Version || v2.Seats[2].Stack != 1000 {
		t.Fatalf("resumed view %+v, want seat 2 version %d", v2, v.Version)
	}
	if time.Since(start) > time.Second {
		t.Fatal("resume took too long")
	}
}

func TestChat(t *testing.T) {
	r := newRig(t)
	id := r.table(t, true)
	a, s := r.dial(t, "a"), r.dial(t, "s")
	a.do(map[string]any{"type": "watch", "table": id})
	s.do(map[string]any{"type": "watch", "table": id})
	a.do(map[string]any{"type": "sit", "seat": 0})
	cid := s.send(map[string]any{"type": "chat", "text": "  nice hand  "})
	for _, c := range []*client{a, s} {
		m := c.wait(func(m msg) bool { return m.Type == "chat" })
		if m.Text != "nice hand" || m.Name != "S" {
			t.Fatalf("chat: %+v", m)
		}
	}
	if m := s.wait(func(m msg) bool { return m.ID == cid }); m.Type != "ok" {
		t.Fatalf("chat reply: %+v", m)
	}
	for range ChatBurst - 1 {
		if e := s.do(map[string]any{"type": "chat", "text": "gg"}); e != "" {
			t.Fatal(e)
		}
	}
	if e := s.do(map[string]any{"type": "chat", "text": "spam"}); e != "rate_limited" {
		t.Fatalf("burst: %q", e)
	}

	// Without spectators an onlooker sees the seats but not the hand, and may not chat.
	id2 := r.table(t, false)
	p, q, o := r.dial(t, "p"), r.dial(t, "q"), r.dial(t, "o")
	for i, c := range []*client{p, q} {
		c.do(map[string]any{"type": "watch", "table": id2})
		c.do(map[string]any{"type": "sit", "seat": i})
	}
	o.do(map[string]any{"type": "watch", "table": id2})
	p.waitView(func(v *table.View) bool { return v.Hand != nil })
	time.Sleep(50 * time.Millisecond)
	o.do(map[string]any{"type": "unwatch"})
	o.do(map[string]any{"type": "watch", "table": id2})
	ov := o.wait(func(m msg) bool { return m.View != nil && m.View.ID == id2 }).View
	if ov.Hand != nil || ov.Seats[0] == nil || ov.Seats[0].HasCards {
		t.Fatalf("onlooker view without spectators: %+v", ov)
	}
	if e := o.do(map[string]any{"type": "chat", "text": "hi"}); e != "spectators_off" {
		t.Fatalf("onlooker chat: %q", e)
	}
}

func TestLobbyUpdates(t *testing.T) {
	r := newRig(t)
	a := r.dial(t, "a")
	a.do(map[string]any{"type": "lobby", "on": true})
	if m := a.wait(func(m msg) bool { return m.Type == "lobby" }); len(m.Tables) != 0 {
		t.Fatalf("lobby: %+v", m.Tables)
	}
	id := r.table(t, true)
	tb, _ := r.tables.Get(id)
	st, _ := tb.Snapshot()
	r.hub.Publish(st)
	m := a.wait(func(m msg) bool { return m.Type == "lobby" && len(m.Tables) == 1 })
	if m.Tables[0].Settings.Name != "Friday" {
		t.Fatalf("lobby entry: %+v", m.Tables[0])
	}
	if !strings.Contains(string(m.Raw), `"turn_time":60`) {
		t.Fatalf("turn time not in seconds: %s", m.Raw)
	}
	b := r.dial(t, "b")
	b.do(map[string]any{"type": "watch", "table": id})
	b.do(map[string]any{"type": "sit", "seat": 4})
	m = a.wait(func(m msg) bool { return m.Type == "lobby" && len(m.Tables) == 1 && m.Tables[0].Taken == 1 })
	if m.Tables[0].Players[0] != "B" {
		t.Fatalf("players: %+v", m.Tables[0])
	}
	if err := r.tables.Close(id, "a", false); err != nil {
		t.Fatal(err)
	}
	a.wait(func(m msg) bool { return m.Type == "lobby" && len(m.Tables) == 0 })
	if v := b.wait(func(m msg) bool { return m.View != nil && m.View.Closed }).View; !v.Closed {
		t.Fatal("watcher did not get the closed view")
	}
}

func TestConnectionCapPerUser(t *testing.T) {
	r := newRig(t)
	for range MaxConnsPerUser {
		r.dial(t, "a")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	ws, _, err := websocket.Dial(ctx, r.url+"?u=a", nil)
	if err != nil {
		t.Fatal(err)
	}
	_, _, err = ws.Read(ctx)
	if websocket.CloseStatus(err) != websocket.StatusPolicyViolation {
		t.Fatalf("11th connection: %v", err)
	}
}

func TestSitAndGoStartIntent(t *testing.T) {
	r := newRig(t)
	tb, err := r.tables.Create("a", table.Settings{Name: "SNG", Seats: 6, SmallBlind: 5, BigBlind: 10,
		StartingStack: 1000, TurnTime: time.Minute, Spectators: true, Kind: table.KindSng, Structure: "turbo"})
	if err != nil {
		t.Fatal(err)
	}
	a, b := r.dial(t, "a"), r.dial(t, "b")
	for _, c := range []*client{a, b} {
		if e := c.do(map[string]any{"type": "watch", "table": tb.ID()}); e != "" {
			t.Fatal(e)
		}
	}
	if e := a.do(map[string]any{"type": "start"}); e != "too_few_players" {
		t.Fatalf("start alone: %q", e)
	}
	for i, c := range []*client{a, b} {
		if e := c.do(map[string]any{"type": "sit", "seat": i}); e != "" {
			t.Fatal(e)
		}
	}
	if e := b.do(map[string]any{"type": "start"}); e != "host_or_admin_only" {
		t.Fatalf("start by a guest: %q", e)
	}
	if e := a.do(map[string]any{"type": "start"}); e != "" {
		t.Fatal(e)
	}
	v := b.waitView(func(v *table.View) bool { return v.Sng != nil && v.Sng.Phase == table.PhaseRunning && v.Hand != nil })
	if v.Sng.BigBlind != 10 || v.Settings.Kind != table.KindSng {
		t.Fatalf("sng view %+v", v.Sng)
	}
	if e := a.do(map[string]any{"type": "start"}); e != "sng_started" {
		t.Fatalf("second start: %q", e)
	}
}

func TestRestartingTellsClientsAndCloses(t *testing.T) {
	r := newRig(t)
	id := r.table(t, true)
	c := r.dial(t, "a")
	c.send(map[string]any{"type": "watch", "table": id})
	c.waitView(func(v *table.View) bool { return v.ID == id })
	r.tables.Shutdown()
	r.hub.Restarting(time.Second)
	c.wait(func(m msg) bool { return m.Type == "restarting" })
	select {
	case _, ok := <-c.in:
		for ok {
			_, ok = <-c.in
		}
	case <-time.After(5 * time.Second):
		t.Fatal("connection stayed open")
	}
	for _, m := range c.pending {
		if m.View != nil && m.View.Closed {
			t.Fatal("a restart showed the table as closed")
		}
	}
}
