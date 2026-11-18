package history_test

import (
	"context"
	"encoding/json"
	"slices"
	"strings"
	"testing"
	"time"

	"github.com/oxisoft/oxipoker/server/internal/accounts"
	"github.com/oxisoft/oxipoker/server/internal/engine"
	"github.com/oxisoft/oxipoker/server/internal/history"
	"github.com/oxisoft/oxipoker/server/internal/store"
	"github.com/oxisoft/oxipoker/server/internal/table"
)

// playHand runs one hand on a real table and returns what the hook got.
func playHand(t *testing.T, acts func(tb *table.Table, s table.State) bool) (table.HandDone, []string) {
	t.Helper()
	done := make(chan table.HandDone, 4)
	tb, err := table.New("T1", "u1", table.Settings{Name: "Friday", Seats: 3, SmallBlind: 5, BigBlind: 10,
		StartingStack: 1000, TurnTime: time.Minute, Spectators: true},
		table.Options{StartDelay: time.Millisecond, Pause: time.Hour, OnHandDone: func(d table.HandDone) { done <- d }})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(tb.Close)
	users := []string{"u1", "u2", "u3"}
	for i, u := range users {
		if err := tb.Sit(u, strings.ToUpper(u), i); err != nil {
			t.Fatal(err)
		}
	}
	deadline := time.After(5 * time.Second)
	for {
		select {
		case d := <-done:
			return d, users
		case <-deadline:
			t.Fatal("hand did not finish")
		case <-time.After(2 * time.Millisecond):
			s, _ := tb.Snapshot()
			if s.Hand != nil && !s.Hand.Done() {
				acts(tb, s)
			}
		}
	}
}

func TestStoreListGetStats(t *testing.T) {
	ctx := context.Background()
	st, err := store.Open(ctx, t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	defer st.Close()
	acc := accounts.New(st)
	ids := map[string]string{}
	for _, u := range []string{"u1", "u2", "u3", "u4"} {
		usr, err := acc.CreateUser(ctx, accounts.NewUser{Username: "player-" + u, Password: "long enough pw"})
		if err != nil {
			t.Fatal(err)
		}
		ids[u] = usr.ID
	}

	// Everybody calls or checks to showdown.
	d, users := playHand(t, func(tb *table.Table, s table.State) bool {
		l, ok := s.Hand.Legal()
		if !ok {
			return false
		}
		a := engine.Action{Kind: engine.Call}
		if l.Check {
			a.Kind = engine.Check
		}
		return tb.Act(s.HandUsers[l.Seat], a) == nil
	})
	// Map the table's user names to the account ids.
	for seat, u := range d.Users {
		d.Users[seat] = ids[u]
	}
	hs := history.New(ctx, st.DB(), nil)
	if err := hs.Write(ctx, d); err != nil {
		t.Fatal(err)
	}

	hole := map[int][]engine.Card{}
	for _, p := range d.Hand.Players() {
		hole[p.Seat] = p.Hole
	}
	shown := map[int]bool{}
	for _, s := range d.Hand.Shown() {
		shown[s] = true
	}

	for seat, u := range users {
		list, err := hs.List(ctx, ids[u], 0, 0)
		if err != nil || len(list) != 1 {
			t.Fatalf("%s list: %v %v", u, list, err)
		}
		if !slices.Equal(list[0].Cards, hole[seat]) || list[0].TableName != "Friday" || list[0].Pot != 30 {
			t.Fatalf("%s summary: %+v", u, list[0])
		}
		h, err := hs.Get(ctx, ids[u], list[0].ID)
		if err != nil {
			t.Fatal(err)
		}
		if h.YourSeat != seat || !slices.Equal(h.YourCards, hole[seat]) || len(h.Seats) != 3 || h.Seats[seat].Name != strings.ToUpper(u) {
			t.Fatalf("%s hand: %+v", u, h)
		}
		// The stored replay holds no hole event and no card of a player
		// who did not show.
		b, _ := json.Marshal(h)
		for other, cards := range hole {
			if other == seat || shown[other] {
				continue
			}
			for _, e := range h.Events {
				if e.Kind == engine.EvHole {
					t.Fatalf("hole event stored: %s", b)
				}
				if e.Seat == other && len(e.Cards) > 0 {
					t.Fatalf("cards of seat %d (not shown) in replay of %s: %s", other, u, b)
				}
			}
			_ = cards
		}
	}

	// Someone who did not play cannot open the hand.
	list, _ := hs.List(ctx, ids["u1"], 0, 0)
	if _, err := hs.Get(ctx, ids["u4"], list[0].ID); err != history.ErrNotFound {
		t.Fatalf("outsider: %v", err)
	}

	// Stats: the winners' shares add up to the pot.
	var won int64
	var winners int
	for _, u := range users {
		s, err := hs.StatsOf(ctx, ids[u])
		if err != nil || s.HandsPlayed != 1 {
			t.Fatalf("%s stats: %+v %v", u, s, err)
		}
		won += s.BiggestPot
		winners += s.HandsWon
	}
	if won != 30 || winners < 1 {
		t.Fatalf("pot shares %d, winners %d", won, winners)
	}
	if s, _ := hs.StatsOf(ctx, ids["u4"]); s != (history.Stats{}) {
		t.Fatalf("u4 stats: %+v", s)
	}
}

func TestGamesAndSngStats(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	st, err := store.Open(ctx, t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	defer st.Close()
	acc := accounts.New(st)
	ids := map[string]string{}
	for _, n := range []string{"ann", "bob", "cat"} {
		u, err := acc.CreateUser(ctx, accounts.NewUser{Username: n, Password: "long enough pw"})
		if err != nil {
			t.Fatal(err)
		}
		ids[n] = u.ID
	}
	hs := history.New(ctx, st.DB(), nil)
	started := time.Now().Add(-20 * time.Minute)
	g1 := table.GameDone{TableID: "T1", TableName: "Friday SNG", Started: started, Places: []table.Place{
		{Place: 1, User: ids["ann"], Name: "Ann"}, {Place: 2, User: ids["bob"], Name: "Bob"},
		{Place: 3, User: ids["cat"], Name: "Cat"}, {Place: 4, User: "gone", Name: "Deleted"}}}
	g2 := table.GameDone{TableID: "T2", TableName: "Rematch", Started: started, Places: []table.Place{
		{Place: 1, User: ids["bob"], Name: "Bob"}, {Place: 2, User: ids["ann"], Name: "Ann"}}}
	for _, g := range []table.GameDone{g1, g2} {
		if err := hs.WriteGame(ctx, g); err != nil {
			t.Fatal(err)
		}
	}
	if err := hs.WriteGame(ctx, table.GameDone{TableID: "T3"}); err == nil {
		t.Fatal("game without places was stored")
	}

	want := map[string]history.Stats{
		"ann": {SngGames: 2, SngWins: 1, SngBest: 1},
		"bob": {SngGames: 2, SngWins: 1, SngBest: 1},
		"cat": {SngGames: 1, SngWins: 0, SngBest: 3},
	}
	for n, w := range want {
		got, err := hs.StatsOf(ctx, ids[n])
		if err != nil || got != w {
			t.Fatalf("%s stats %+v (%v), want %+v", n, got, err, w)
		}
	}

	gs, err := hs.Games(ctx, ids["ann"], 0)
	if err != nil || len(gs) != 2 {
		t.Fatalf("ann games %+v (%v)", gs, err)
	}
	if gs[0].TableName != "Rematch" || gs[0].YourPlace != 2 || gs[1].YourPlace != 1 {
		t.Fatalf("order or places: %+v", gs)
	}
	// The deleted account is skipped; the list shows names only, never account ids.
	if gs[1].Players != 4 || len(gs[1].Places) != 3 || gs[1].Places[2].Name != "Cat" {
		t.Fatalf("places of game 1: %+v", gs[1])
	}
	raw, _ := json.Marshal(gs)
	for _, id := range ids {
		if strings.Contains(string(raw), id) {
			t.Fatalf("games JSON leaks an account id: %s", raw)
		}
	}
	if gs, _ := hs.Games(ctx, "nobody", 0); len(gs) != 0 {
		t.Fatalf("stranger sees games: %+v", gs)
	}

	// RecordGame goes through the same background queue as hands.
	hs.RecordGame(table.GameDone{TableID: "T4", TableName: "Queued", Places: []table.Place{
		{Place: 1, User: ids["cat"], Name: "Cat"}, {Place: 2, User: ids["ann"], Name: "Ann"}}})
	deadline := time.Now().Add(3 * time.Second)
	for time.Now().Before(deadline) {
		if s, _ := hs.StatsOf(ctx, ids["cat"]); s.SngWins == 1 && s.SngBest == 1 {
			return
		}
		time.Sleep(10 * time.Millisecond)
	}
	t.Fatal("recorded game was not written")
}

func TestRecordWritesInTheBackground(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	st, err := store.Open(ctx, t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	defer st.Close()
	usr, _ := accounts.New(st).CreateUser(ctx, accounts.NewUser{Username: "solo", Password: "long enough pw"})

	// Everybody folds to the big blind.
	d, _ := playHand(t, func(tb *table.Table, s table.State) bool {
		l, ok := s.Hand.Legal()
		return ok && tb.Act(s.HandUsers[l.Seat], engine.Action{Kind: engine.Fold}) == nil
	})
	for seat := range d.Users {
		d.Users[seat] = usr.ID // one account in every seat is enough here
		break
	}
	hs := history.New(ctx, st.DB(), nil)
	hs.Record(d)
	deadline := time.Now().Add(3 * time.Second)
	for time.Now().Before(deadline) {
		if s, _ := hs.StatsOf(ctx, usr.ID); s.HandsPlayed == 1 {
			return
		}
		time.Sleep(10 * time.Millisecond)
	}
	t.Fatal("recorded hand was not written")
}
