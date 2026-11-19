package httpapi

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	mathrand "math/rand/v2"
	"net/http"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/coder/websocket"

	"github.com/oxisoft/oxipoker/server/internal/accounts"
	"github.com/oxisoft/oxipoker/server/internal/engine"
	"github.com/oxisoft/oxipoker/server/internal/realtime"
	"github.com/oxisoft/oxipoker/server/internal/table"
)

// handTruth is what the server knew about one finished hand: who sat where,
// every hole card, and which seats showed at the end.
type handTruth struct {
	users map[int]string
	hole  map[int][]string
	shown map[int]bool
}

// leakFrame is the part of a WebSocket message the leak test drives with.
type leakFrame struct {
	Type string `json:"type"`
	View *struct {
		Version  uint64 `json:"version"`
		YourSeat int    `json:"your_seat"`
		HandNo   int    `json:"hand_no"`
		Seats    []*struct {
			SittingOut bool `json:"sitting_out"`
		} `json:"seats"`
		Hand *struct {
			Done   bool `json:"done"`
			Events []struct {
				Kind string `json:"kind"`
				Seat int    `json:"seat"`
			} `json:"events"`
			Legal *struct {
				Seat    int    `json:"seat"`
				Check   bool   `json:"check"`
				BetKind string `json:"bet_kind"`
				MinTo   int64  `json:"min_to"`
				MaxTo   int64  `json:"max_to"`
			} `json:"legal"`
		} `json:"hand"`
	} `json:"view"`
}

type leakClient struct {
	user   string // user id
	ws     *websocket.Conn
	in     chan []byte
	frames [][]byte
	next   int64
	acted  uint64
	backAt int
}

func (c *leakClient) send(t *testing.T, v map[string]any) {
	t.Helper()
	c.next++
	v["id"] = c.next
	b, _ := json.Marshal(v)
	if err := c.ws.Write(context.Background(), websocket.MessageText, b); err != nil {
		t.Fatal(err)
	}
}

// containsCard reports whether a JSON document carries the card as a value.
func containsCard(js []byte, card string) bool {
	return strings.Contains(string(js), `"`+card+`"`)
}

// TestNoHiddenCardsAcrossAFullTable plays a full six-seat table with a
// spectator over the real HTTP and WebSocket API, with random bets, raises,
// folds, all-ins and showdowns, and proves that no WebSocket message and no
// history response ever gives one user a hole card of another player that
// was not shown at showdown.
func TestNoHiddenCardsAcrossAFullTable(t *testing.T) {
	// The bots answer every view at machine speed, far above the per-connection
	// message limit meant for people.
	rate, burst := realtime.IntentRate, realtime.IntentBurst
	realtime.IntentRate, realtime.IntentBurst = 1e6, 1e6
	t.Cleanup(func() { realtime.IntentRate, realtime.IntentBurst = rate, burst })
	var mu sync.Mutex
	truth := map[int]handTruth{}
	ts := newGameServer(t, func(o *Options) {
		hub, hist := o.Hub, o.History
		mgr := table.NewManager(time.Hour, func(id string) table.Options {
			to := hub.TableOptions(id)
			to.StartDelay, to.Pause = time.Millisecond, time.Millisecond
			to.OnHandDone = func(d table.HandDone) {
				ht := handTruth{users: d.Users, hole: map[int][]string{}, shown: map[int]bool{}}
				for _, p := range d.Hand.Players() {
					for _, c := range p.Hole {
						ht.hole[p.Seat] = append(ht.hole[p.Seat], c.String())
					}
				}
				for _, e := range d.Hand.Events() {
					if e.Kind == engine.EvShow {
						ht.shown[e.Seat] = true
					}
				}
				mu.Lock()
				truth[d.HandNo] = ht
				mu.Unlock()
				hist.Record(d)
			}
			return to
		})
		t.Cleanup(mgr.Shutdown)
		o.Tables = mgr
	})

	const players = 6
	ctx := context.Background()
	var clients []*leakClient
	tokens := map[string]string{}
	for i := range players + 1 {
		name := fmt.Sprintf("player%d", i)
		u, err := ts.acc.CreateUser(ctx, accounts.NewUser{Username: name, Password: name + " long password"})
		if err != nil {
			t.Fatal(err)
		}
		tok := signinAs(t, ts, name, name+" long password")
		tokens[u.ID] = tok
		dctx, cancel := context.WithTimeout(ctx, 5*time.Second)
		ws, _, err := websocket.Dial(dctx, wsURL(ts), &websocket.DialOptions{HTTPHeader: http.Header{"Authorization": {"Bearer " + tok}}})
		cancel()
		if err != nil {
			t.Fatal(err)
		}
		ws.SetReadLimit(1 << 22)
		c := &leakClient{user: u.ID, ws: ws, in: make(chan []byte, 4096), backAt: -1}
		go func() {
			defer close(c.in)
			for {
				_, b, err := ws.Read(context.Background())
				if err != nil {
					return
				}
				c.in <- b
			}
		}()
		t.Cleanup(func() { ws.Close(websocket.StatusNormalClosure, "") })
		clients = append(clients, c)
	}
	res, out := ts.do(t, nil, req{method: "POST", path: "/api/v1/tables", token: tokens[clients[0].user], body: tableBody("Leak check")})
	if res.StatusCode != 201 {
		t.Fatalf("create: %d %v", res.StatusCode, out)
	}
	id := out["id"].(string)
	for i, c := range clients {
		c.send(t, map[string]any{"type": "watch", "table": id})
		if i < players {
			c.send(t, map[string]any{"type": "sit", "seat": i})
		}
	}

	r := mathrand.New(mathrand.NewPCG(11, 17))
	const hands = 120
	deadline := time.Now().Add(90 * time.Second)
	for {
		mu.Lock()
		done := len(truth)
		mu.Unlock()
		if done >= hands {
			break
		}
		if time.Now().After(deadline) {
			t.Fatalf("only %d hands in time", done)
		}
		for i, c := range clients {
			var b []byte
			select {
			case b = <-c.in:
			case <-time.After(time.Millisecond):
				continue
			}
			c.frames = append(c.frames, b)
			if i >= players {
				continue // the spectator only watches
			}
			var f leakFrame
			if err := json.Unmarshal(b, &f); err != nil {
				t.Fatalf("bad message %s: %v", b, err)
			}
			v := f.View
			if v == nil || v.YourSeat < 0 {
				continue
			}
			if s := v.Seats[v.YourSeat]; s != nil && s.SittingOut && c.backAt != v.HandNo {
				c.backAt = v.HandNo // busted: buy in again
				c.send(t, map[string]any{"type": "comeback"})
			}
			h := v.Hand
			if h == nil || h.Done || h.Legal == nil || h.Legal.Seat != v.YourSeat || c.acted == v.Version {
				continue
			}
			c.acted = v.Version
			act := map[string]any{"type": "act", "action": "call"}
			l := h.Legal
			switch {
			case l.BetKind != "" && r.IntN(4) == 0:
				to := l.MinTo
				if span := l.MaxTo - l.MinTo; span > 0 {
					to += r.Int64N(span/3 + 1)
				}
				if r.IntN(12) == 0 {
					to = l.MaxTo // all in
				}
				act["action"], act["to"] = l.BetKind, to
			case r.IntN(8) == 0:
				act["action"] = "fold"
			case l.Check:
				act["action"] = "check"
			}
			c.send(t, act)
		}
	}
	for _, c := range clients {
		for {
			select {
			case b := <-c.in:
				c.frames = append(c.frames, b)
				continue
			case <-time.After(100 * time.Millisecond):
			}
			break
		}
	}

	mu.Lock()
	defer mu.Unlock()
	showdowns := 0
	for _, ht := range truth {
		if len(ht.shown) > 0 {
			showdowns++
		}
	}
	if showdowns < 20 {
		t.Fatalf("only %d of %d hands reached a showdown", showdowns, len(truth))
	}

	// Every WebSocket message: no hole card of another seat that this very
	// message does not show at showdown.
	checked := 0
	for _, c := range clients {
		for _, b := range c.frames {
			var f leakFrame
			_ = json.Unmarshal(b, &f)
			if f.View == nil || f.View.Hand == nil {
				continue
			}
			ht, ok := truth[f.View.HandNo]
			if !ok {
				continue // the hand still running at the end
			}
			shownHere := map[int]bool{}
			for _, e := range f.View.Hand.Events {
				if e.Kind == "show" {
					shownHere[e.Seat] = true
				}
				if e.Kind == "hole" && ht.users[e.Seat] != c.user {
					t.Fatalf("%s got the hole event of seat %d: %s", c.user, e.Seat, b)
				}
			}
			for seat, cards := range ht.hole {
				if ht.users[seat] == c.user || shownHere[seat] {
					continue
				}
				for _, card := range cards {
					if containsCard(b, card) {
						t.Fatalf("hand %d: %s sees %s of seat %d: %s", f.View.HandNo, c.user, card, seat, b)
					}
				}
			}
			checked++
		}
	}
	if checked < hands*players {
		t.Fatalf("only %d messages checked", checked)
	}

	// History: the list and every stored hand of every player.
	for _, c := range clients[:players] {
		tok := tokens[c.user]
		var ids []int64
		before := int64(0)
		for {
			path := "/api/v1/me/hands?limit=100"
			if before > 0 {
				path += fmt.Sprintf("&before=%d", before)
			}
			res, body := getRaw(t, ts, path, tok)
			if res.StatusCode != 200 {
				t.Fatalf("list: %d %s", res.StatusCode, body)
			}
			var list struct {
				Hands []json.RawMessage `json:"hands"`
			}
			if err := json.Unmarshal(body, &list); err != nil {
				t.Fatal(err)
			}
			if len(list.Hands) == 0 {
				break
			}
			for _, raw := range list.Hands {
				var s struct {
					ID     int64    `json:"id"`
					HandNo int      `json:"hand_no"`
					Cards  []string `json:"cards"`
				}
				_ = json.Unmarshal(raw, &s)
				ht := truth[s.HandNo]
				for seat, cards := range ht.hole {
					if ht.users[seat] == c.user {
						if strings.Join(cards, " ") != strings.Join(s.Cards, " ") {
							t.Fatalf("hand %d: own cards %v, want %v", s.HandNo, s.Cards, cards)
						}
						continue
					}
					for _, card := range cards {
						if containsCard(raw, card) {
							t.Fatalf("history list of %s carries %s of seat %d in hand %d: %s", c.user, card, seat, s.HandNo, raw)
						}
					}
				}
				ids = append(ids, s.ID)
				before = s.ID
			}
		}
		if len(ids) == 0 {
			t.Fatalf("%s has no history", c.user)
		}
		for _, hid := range ids {
			res, body := getRaw(t, ts, fmt.Sprintf("/api/v1/me/hands/%d", hid), tok)
			if res.StatusCode != 200 {
				t.Fatalf("hand %d: %d %s", hid, res.StatusCode, body)
			}
			var h struct {
				HandNo int `json:"hand_no"`
			}
			_ = json.Unmarshal(body, &h)
			ht := truth[h.HandNo]
			for seat, cards := range ht.hole {
				if ht.users[seat] == c.user || ht.shown[seat] {
					continue
				}
				for _, card := range cards {
					if containsCard(body, card) {
						t.Fatalf("history hand %d of %s carries %s of seat %d: %s", h.HandNo, c.user, card, seat, body)
					}
				}
			}
		}
	}
	// Another player's hand id is not readable.
	mine, _ := getRaw(t, ts, "/api/v1/me/hands?limit=1", tokens[clients[players].user])
	if mine.StatusCode != 200 {
		t.Fatalf("spectator list: %d", mine.StatusCode)
	}
	if res, _ := getRaw(t, ts, "/api/v1/me/hands/1", tokens[clients[players].user]); res.StatusCode != 404 {
		t.Fatalf("spectator read a hand it did not play: %d", res.StatusCode)
	}
}

func getRaw(t *testing.T, ts *testServer, path, token string) (*http.Response, []byte) {
	t.Helper()
	rq, _ := http.NewRequest("GET", ts.URL+path, nil)
	rq.Header.Set("Authorization", "Bearer "+token)
	res, err := http.DefaultClient.Do(rq)
	if err != nil {
		t.Fatal(err)
	}
	defer res.Body.Close()
	b, err := io.ReadAll(res.Body)
	if err != nil {
		t.Fatal(err)
	}
	return res, b
}
