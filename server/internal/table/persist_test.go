package table

import (
	"encoding/json"
	"sync"
	"testing"
	"time"

	"github.com/oxisoft/oxipoker/server/internal/engine"
)

// saves records what a table hands to OnSave.
type saves struct {
	mu  sync.Mutex
	all []Saved
}

func (s *saves) add(v Saved) {
	s.mu.Lock()
	s.all = append(s.all, v)
	s.mu.Unlock()
}

func (s *saves) n() int {
	s.mu.Lock()
	defer s.mu.Unlock()
	return len(s.all)
}

func (s *saves) last() Saved {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.all[len(s.all)-1]
}

// roundTrip passes a Saved through JSON as the store does.
func roundTrip(t *testing.T, v Saved) Saved {
	t.Helper()
	b, err := json.Marshal(v)
	if err != nil {
		t.Fatal(err)
	}
	var out Saved
	if err := json.Unmarshal(b, &out); err != nil {
		t.Fatal(err)
	}
	return out
}

// foldToBB lets everyone fold until the hand is over.
func foldToEnd(t *testing.T, tb *Table, users map[int]string) {
	t.Helper()
	for {
		s, _ := tb.Snapshot()
		if s.Hand == nil || s.Hand.Done() {
			return
		}
		if err := tb.Act(users[s.Hand.ToAct()], engine.Action{Kind: engine.Fold}); err != nil {
			t.Fatal(err)
		}
	}
}

func TestStopVoidsTheRunningHand(t *testing.T) {
	var sv saves
	s := settings()
	s.Seats = 3
	tb := newTable(t, s, Options{Pause: time.Hour, OnSave: sv.add})
	users := map[int]string{0: "a", 1: "b", 2: "c"}
	for i := range 3 {
		if err := tb.Sit(users[i], users[i], i); err != nil {
			t.Fatal(err)
		}
	}
	// Hand 1 is played out: the blinds move chips.
	waitFor(t, tb, "hand 1", handRunning)
	foldToEnd(t, tb, users)
	after1, _ := tb.Snapshot()
	tb.Close() // stops the pause timer of the test table; replaced below
	saved1 := sv.last()
	if !saved1.Closed {
		t.Fatal("Close did not hand over a closed state")
	}
	// Restore from the state after hand 1, play into hand 2 and stop mid-hand.
	saved1.Closed = false
	var sv2 saves
	tb2, err := Restore(roundTrip(t, saved1), Options{StartDelay: 5 * time.Millisecond, Pause: time.Hour, OnSave: sv2.add})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(tb2.Close)
	mid := waitFor(t, tb2, "hand 2", func(s State) bool { return handRunning(s) && s.HandNo == 2 })
	voidedPos := *mid.Pos
	l, _ := mid.Hand.Legal()
	if err := tb2.Act(users[l.Seat], engine.Action{Kind: engine.Raise, To: l.MinTo}); err != nil {
		t.Fatal(err)
	}
	tb2.Stop()
	if _, err := tb2.Snapshot(); err != ErrClosed {
		t.Fatalf("stopped table still answers: %v", err)
	}
	st := roundTrip(t, sv2.last())
	if st.Closed || st.HandNo != 1 || st.TurnTimeMS != s.TurnTime.Milliseconds() {
		t.Fatalf("stored state: closed %v hand %d turn %d", st.Closed, st.HandNo, st.TurnTimeMS)
	}
	for i, p := range st.Seats {
		if p.Stack != after1.Seats[i].Stack {
			t.Errorf("seat %d stored stack %d, want the hand-start stack %d", i, p.Stack, after1.Seats[i].Stack)
		}
	}
	if *st.Pos != *after1.Pos {
		t.Errorf("stored positions %+v, want those of hand 1 %+v", *st.Pos, *after1.Pos)
	}

	// The restarted table deals hand 2 again with the same button and plays on.
	tb3, err := Restore(st, Options{StartDelay: 5 * time.Millisecond, Pause: time.Hour})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(tb3.Close)
	again := waitFor(t, tb3, "hand 2 again", func(s State) bool { return handRunning(s) })
	if again.HandNo != 2 || *again.Pos != voidedPos {
		t.Fatalf("restarted hand %d at %+v, want hand 2 at %+v", again.HandNo, *again.Pos, voidedPos)
	}
	var total int64
	for _, p := range again.Hand.Players() {
		total += p.Stack + p.Bet
	}
	if total != 3*s.StartingStack {
		t.Fatalf("chips after restore %d, want %d", total, 3*s.StartingStack)
	}
	foldToEnd(t, tb3, users)
}

func TestSavesBetweenHandsOnly(t *testing.T) {
	var sv saves
	tb := newTable(t, settings(), Options{Pause: time.Hour, OnSave: sv.add})
	if err := tb.Sit("a", "A", 0); err != nil {
		t.Fatal(err)
	}
	if v := sv.last(); v.Seats[0] == nil || v.Seats[0].User != "a" {
		t.Fatal("sitting down was not stored")
	}
	if err := tb.Sit("b", "B", 3); err != nil {
		t.Fatal(err)
	}
	waitFor(t, tb, "hand", handRunning)
	n := sv.n()
	s, _ := tb.Snapshot()
	l, _ := s.Hand.Legal()
	user := map[int]string{0: "a", 3: "b"}[l.Seat]
	if err := tb.Act(user, engine.Action{Kind: engine.Call}); err != nil {
		t.Fatal(err)
	}
	if sv.n() != n {
		t.Fatal("a running hand was stored")
	}
	foldToEnd(t, tb, map[int]string{0: "a", 3: "b"})
	waitFor(t, tb, "hand end", func(s State) bool { return s.Hand != nil && s.Hand.Done() })
	if v := sv.last(); v.HandNo != 1 || v.Seats[0].Stack+v.Seats[3].Stack != 200 {
		t.Fatalf("after the hand: stored hand %d", v.HandNo)
	}
}

func TestRestoreSngKeepsClockAndPlaces(t *testing.T) {
	var sv saves
	tb := newTable(t, sngSettings(3), Options{Pause: time.Hour, LevelTime: time.Minute, OnSave: sv.add})
	for i, u := range []string{"a", "b", "c"} {
		if err := tb.Sit(u, u, i); err != nil {
			t.Fatal(err)
		}
	}
	running := waitFor(t, tb, "first hand", handRunning)
	tb.Stop()
	st := roundTrip(t, sv.last())
	if st.Sng == nil || st.Sng.Phase != PhaseRunning || st.HandNo != 0 {
		t.Fatalf("stored sit-and-go %+v hand %d", st.Sng, st.HandNo)
	}
	left := time.Until(running.Sng.LevelEnds)
	time.Sleep(30 * time.Millisecond)
	tb2, err := Restore(st, Options{StartDelay: 5 * time.Millisecond, Pause: time.Hour, LevelTime: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(tb2.Close)
	s := waitFor(t, tb2, "first hand again", handRunning)
	if got := time.Until(s.Sng.LevelEnds); got < left-25*time.Millisecond {
		t.Fatalf("level time left %v after the restart, had %v", got, left)
	}
	if s.HandNo != 1 || s.Sng.Level != 0 || s.Settings.Kind != KindSng {
		t.Fatalf("restored hand %d level %d kind %s", s.HandNo, s.Sng.Level, s.Settings.Kind)
	}
}

func TestRestoreRejectsBrokenState(t *testing.T) {
	good := Saved{ID: "x", Settings: settings(), TurnTimeMS: 1000, Seats: make([]*Player, 6)}
	bad := []func(*Saved){
		func(s *Saved) { s.ID = "" },
		func(s *Saved) { s.Closed = true },
		func(s *Saved) { s.TurnTimeMS = 0 },
		func(s *Saved) { s.Seats = s.Seats[:2] },
		func(s *Saved) { s.Sng = &Sng{Phase: PhaseRunning} },
	}
	for i, f := range bad {
		s := good
		f(&s)
		if tb, err := Restore(s, Options{}); err == nil {
			tb.Close()
			t.Errorf("case %d restored", i)
		}
	}
	tb, err := Restore(good, Options{})
	if err != nil {
		t.Fatal(err)
	}
	tb.Close()
}

func TestManagerShutdownAndRestore(t *testing.T) {
	var sv saves
	m := NewManager(time.Hour, func(string) Options {
		return Options{StartDelay: 5 * time.Millisecond, Pause: time.Hour, OnSave: sv.add}
	})
	tb, err := m.Create("host", settings())
	if err != nil {
		t.Fatal(err)
	}
	if err := tb.Sit("a", "A", 1); err != nil {
		t.Fatal(err)
	}
	m.Shutdown()
	stored := map[string]Saved{}
	for _, v := range sv.all {
		if v.Closed {
			delete(stored, v.ID)
		} else {
			stored[v.ID] = v
		}
	}
	if len(stored) != 1 {
		t.Fatalf("%d tables stored after shutdown", len(stored))
	}
	m2 := NewManager(time.Hour, nil)
	defer m2.Shutdown()
	n, errs := m2.Restore([]Saved{stored[tb.ID()], {ID: "broken"}})
	if n != 1 || len(errs) != 1 {
		t.Fatalf("restored %d, errors %v", n, errs)
	}
	got, err := m2.Get(tb.ID())
	if err != nil {
		t.Fatal(err)
	}
	s, _ := got.Snapshot()
	if s.Host != "host" || s.Seats[1] == nil || s.Seats[1].User != "a" {
		t.Fatalf("restored table %+v", s)
	}
}
