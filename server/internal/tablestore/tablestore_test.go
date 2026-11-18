package tablestore_test

import (
	"context"
	"testing"
	"time"

	"github.com/oxisoft/oxipoker/server/internal/engine"
	"github.com/oxisoft/oxipoker/server/internal/store"
	"github.com/oxisoft/oxipoker/server/internal/table"
	"github.com/oxisoft/oxipoker/server/internal/tablestore"
)

func openStore(t *testing.T, dir string) *store.Store {
	t.Helper()
	st, err := store.Open(context.Background(), dir)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { st.Close() })
	return st
}

func settings() table.Settings {
	return table.Settings{Name: "Friday", Seats: 4, SmallBlind: 5, BigBlind: 10, StartingStack: 1000, TurnTime: time.Minute}
}

func TestWriteLoadDelete(t *testing.T) {
	ctx := context.Background()
	st := openStore(t, t.TempDir())
	ts := tablestore.New(st.DB(), nil)
	defer ts.Close()
	now := time.Now()
	a := table.Saved{ID: "A", Host: "h", Created: now, Settings: settings(), TurnTimeMS: 60000,
		Seats: []*table.Player{{User: "u", Name: "U", Stack: 990}, nil, nil, nil}, HandNo: 7,
		Pos: &engine.Positions{Button: 0, SB: 0, BB: 0}}
	b := a
	b.ID, b.Created = "B", now.Add(-time.Hour)
	for _, v := range []table.Saved{a, b, a} {
		if err := ts.Write(ctx, v); err != nil {
			t.Fatal(err)
		}
	}
	if _, err := st.DB().ExecContext(ctx, `INSERT INTO open_tables (id, state, saved_at) VALUES ('C', 'not json', 0)`); err != nil {
		t.Fatal(err)
	}
	got, err := ts.Load(ctx)
	if err != nil {
		t.Fatal(err)
	}
	if len(got) != 2 || got[0].ID != "B" || got[1].ID != "A" {
		t.Fatalf("loaded %d tables (want B then A)", len(got))
	}
	if g := got[1]; g.HandNo != 7 || g.Seats[0].Stack != 990 || g.TurnTimeMS != 60000 || g.Settings.Name != "Friday" {
		t.Fatalf("loaded %+v", g)
	}
	var n int
	_ = st.DB().QueryRow(`SELECT COUNT(*) FROM open_tables WHERE id = 'C'`).Scan(&n)
	if n != 0 {
		t.Fatal("broken row kept")
	}
	if err := ts.Write(ctx, table.Saved{ID: "A", Closed: true}); err != nil {
		t.Fatal(err)
	}
	if got, _ := ts.Load(ctx); len(got) != 1 {
		t.Fatalf("%d tables after delete", len(got))
	}
}

// A crash mid-hand: the server dies without shutdown. The stored state is
// the one from before the hand, so the restarted server voids it.
func TestCrashMidHandRestoresHandStart(t *testing.T) {
	ctx := context.Background()
	dir := t.TempDir()
	st := openStore(t, dir)
	ts := tablestore.New(st.DB(), nil)
	opt := func(string) table.Options {
		return table.Options{StartDelay: 5 * time.Millisecond, Pause: 20 * time.Millisecond, OnSave: ts.Save}
	}
	m := table.NewManager(time.Hour, opt)
	tb, err := m.Create("host", settings())
	if err != nil {
		t.Fatal(err)
	}
	users := map[int]string{0: "a", 2: "b", 3: "c"}
	for seat, u := range users {
		if err := tb.Sit(u, u, seat); err != nil {
			t.Fatal(err)
		}
	}
	wait := func(tb *table.Table, what string, cond func(table.State) bool) table.State {
		t.Helper()
		end := time.Now().Add(5 * time.Second)
		for time.Now().Before(end) {
			if s, err := tb.Snapshot(); err == nil && cond(s) {
				return s
			}
			time.Sleep(2 * time.Millisecond)
		}
		t.Fatalf("timed out waiting for %s", what)
		return table.State{}
	}
	// Play hand 1 to the end, then catch hand 2 and bet into it.
	for hand := 1; hand <= 2; hand++ {
		s := wait(tb, "a hand", func(s table.State) bool { return s.HandNo == hand && s.Hand != nil && !s.Hand.Done() })
		if hand == 2 {
			l, _ := s.Hand.Legal()
			if err := tb.Act(users[l.Seat], engine.Action{Kind: engine.Raise, To: l.MinTo}); err != nil {
				t.Fatal(err)
			}
			break
		}
		for s.Hand != nil && !s.Hand.Done() {
			if err := tb.Act(users[s.Hand.ToAct()], engine.Action{Kind: engine.Fold}); err != nil {
				t.Fatal(err)
			}
			s, _ = tb.Snapshot()
		}
	}
	mid, _ := tb.Snapshot()
	start := map[int]int64{}
	for _, p := range mid.Hand.Players() {
		start[p.Seat] = p.Stack + p.Bet
	}
	// Crash: what is queued reaches the disk, the tables just vanish.
	ts.Close()
	tb.Close() // only to stop its goroutine; its closing save goes to a closed writer
	if _, err := st.DB().ExecContext(ctx, `SELECT 1`); err != nil {
		t.Fatal(err)
	}

	st2 := openStore(t, dir)
	ts2 := tablestore.New(st2.DB(), nil)
	defer ts2.Close()
	saved, err := ts2.Load(ctx)
	if err != nil || len(saved) != 1 {
		t.Fatalf("loaded %d tables: %v", len(saved), err)
	}
	m2 := table.NewManager(time.Hour, func(string) table.Options {
		return table.Options{StartDelay: 5 * time.Millisecond, Pause: time.Hour, OnSave: ts2.Save}
	})
	defer m2.Shutdown()
	if n, errs := m2.Restore(saved); n != 1 {
		t.Fatalf("restored %d: %v", n, errs)
	}
	tb2, err := m2.Get(tb.ID())
	if err != nil {
		t.Fatal(err)
	}
	s := wait(tb2, "hand 2 again", func(s table.State) bool { return s.Hand != nil && !s.Hand.Done() })
	if s.HandNo != 2 {
		t.Fatalf("restarted at hand %d, want 2", s.HandNo)
	}
	for _, p := range s.Hand.Players() {
		if p.Stack+p.Bet != start[p.Seat] {
			t.Errorf("seat %d has %d after the restart, want the hand-start stack %d", p.Seat, p.Stack+p.Bet, start[p.Seat])
		}
	}
	// Play continues to the end of the hand.
	for s.Hand != nil && !s.Hand.Done() {
		if err := tb2.Act(users[s.Hand.ToAct()], engine.Action{Kind: engine.Fold}); err != nil {
			t.Fatal(err)
		}
		s, _ = tb2.Snapshot()
	}
	m.Shutdown()
}
