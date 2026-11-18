package table

import (
	"errors"
	mathrand "math/rand/v2"
	"testing"
	"time"

	"github.com/oxisoft/oxipoker/server/internal/engine"
)

func settings() Settings {
	return Settings{Name: "Friday", Seats: 6, SmallBlind: 1, BigBlind: 2, StartingStack: 100, TurnTime: time.Minute}
}

func newTable(t *testing.T, s Settings, opt Options) *Table {
	t.Helper()
	if opt.Pause == 0 {
		opt.Pause = 5 * time.Millisecond
	}
	if opt.StartDelay == 0 {
		opt.StartDelay = 5 * time.Millisecond
	}
	tb, err := New("t1", "host", s, opt)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(tb.Close)
	return tb
}

// waitFor polls the table until cond holds.
func waitFor(t *testing.T, tb *Table, what string, cond func(State) bool) State {
	t.Helper()
	deadline := time.Now().Add(5 * time.Second)
	for {
		s, err := tb.Snapshot()
		if err != nil {
			t.Fatal(err)
		}
		if cond(s) {
			return s
		}
		if time.Now().After(deadline) {
			t.Fatalf("timed out waiting for %s (state %+v)", what, s)
		}
		time.Sleep(2 * time.Millisecond)
	}
}

func handRunning(s State) bool { return s.Hand != nil && !s.Hand.Done() }

func TestSettingsValidate(t *testing.T) {
	bad := []func(*Settings){
		func(s *Settings) { s.Seats = 1 },
		func(s *Settings) { s.Seats = 10 },
		func(s *Settings) { s.BigBlind = 0 },
		func(s *Settings) { s.SmallBlind = 3 },
		func(s *Settings) { s.StartingStack = 3 },
		func(s *Settings) { s.TurnTime = 0 },
	}
	for i, f := range bad {
		s := settings()
		f(&s)
		if s.Validate() == nil {
			t.Errorf("case %d accepted", i)
		}
	}
	if err := settings().Validate(); err != nil {
		t.Fatal(err)
	}
}

func TestSitAndPlay(t *testing.T) {
	tb := newTable(t, settings(), Options{})
	if err := tb.Sit("a", "Ann", 0); err != nil {
		t.Fatal(err)
	}
	for _, c := range []struct {
		user string
		seat int
		want error
	}{{"a", 2, ErrSeated}, {"b", 0, ErrSeatTaken}, {"b", 6, ErrBadSeat}, {"b", -1, ErrBadSeat}} {
		if err := tb.Sit(c.user, "x", c.seat); !errors.Is(err, c.want) {
			t.Fatalf("sit %s %d: %v, want %v", c.user, c.seat, err, c.want)
		}
	}
	s, _ := tb.Snapshot()
	if s.Hand != nil {
		t.Fatal("one player cannot start a hand")
	}
	if err := tb.Sit("b", "Bob", 3); err != nil {
		t.Fatal(err)
	}
	s = waitFor(t, tb, "first hand", handRunning)
	if s.HandNo != 1 || s.Pos.Button != 0 || s.Pos.BB != 3 {
		t.Fatalf("hand %d positions %+v", s.HandNo, s.Pos)
	}
	if err := tb.Act("b", engine.Action{Kind: engine.Fold}); !errors.Is(err, engine.ErrNotYourTurn) {
		t.Fatalf("out of turn: %v", err)
	}
	if err := tb.Act("zed", engine.Action{Kind: engine.Fold}); !errors.Is(err, ErrNotSeated) {
		t.Fatalf("not seated: %v", err)
	}
	if err := tb.Act("a", engine.Action{Kind: engine.Fold}); err != nil {
		t.Fatal(err)
	}
	s = waitFor(t, tb, "second hand", func(s State) bool { return s.HandNo == 2 && handRunning(s) })
	if s.Pos.Button != 3 || s.Pos.BB != 0 {
		t.Fatalf("heads-up button moves: %+v", s.Pos)
	}
	if s.Seats[0].Stack+s.Seats[3].Stack+s.Hand.PotTotal() != 200 {
		t.Fatal("chips lost between hands")
	}
}

func TestTurnTimer(t *testing.T) {
	s := settings()
	s.TurnTime = 20 * time.Millisecond
	tb := newTable(t, s, Options{})
	_ = tb.Sit("a", "Ann", 0)
	_ = tb.Sit("b", "Bob", 1)
	// nobody acts: every turn times out (check or fold); after two missed
	// turns a player sits out and the table stops dealing
	st := waitFor(t, tb, "both sitting out or one out", func(s State) bool {
		return !handRunning(s) && (s.Seats[0].SittingOut || s.Seats[1].SittingOut)
	})
	if st.HandNo < 1 {
		t.Fatal("no hand played")
	}
	time.Sleep(60 * time.Millisecond)
	st2, _ := tb.Snapshot()
	if handRunning(st2) {
		t.Fatal("a hand started with a player sitting out")
	}
	if err := tb.ComeBack("a"); err != nil {
		t.Fatal(err)
	}
	if err := tb.ComeBack("b"); err != nil {
		t.Fatal(err)
	}
	waitFor(t, tb, "dealing again", func(s State) bool { return s.HandNo > st2.HandNo })
}

func TestLeaveDuringHand(t *testing.T) {
	tb := newTable(t, settings(), Options{Pause: time.Hour, StartDelay: 50 * time.Millisecond})
	_ = tb.Sit("a", "Ann", 0)
	_ = tb.Sit("b", "Bob", 1)
	_ = tb.Sit("c", "Cat", 2)
	waitFor(t, tb, "hand", handRunning)
	// three-handed the button (seat 0) acts first; seat 2 leaves out of turn
	if err := tb.Leave("c"); err != nil {
		t.Fatal(err)
	}
	s, _ := tb.Snapshot()
	if s.Seats[2] == nil || !s.Seats[2].Leaving {
		t.Fatal("seat is kept until the hand ends")
	}
	_ = tb.Act("a", engine.Action{Kind: engine.Fold})
	_ = tb.Act("b", engine.Action{Kind: engine.Call})
	// c (big blind) has the option but left: checks automatically, hand goes on
	s = waitFor(t, tb, "flop", func(s State) bool { return s.Hand.Street() == engine.Flop })
	if err := tb.Act("b", engine.Action{Kind: engine.Bet, To: 10}); err != nil {
		t.Fatal(err)
	}
	s = waitFor(t, tb, "hand over", func(s State) bool { return s.Hand.Done() })
	if s.Seats[2] != nil {
		t.Fatal("seat not freed after the hand")
	}
	if s.Seats[1].Stack != 102 || s.Seats[0].Stack != 100 {
		t.Fatalf("stacks a=%d b=%d", s.Seats[0].Stack, s.Seats[1].Stack)
	}
	if err := tb.Sit("d", "Dan", 2); err != nil {
		t.Fatal(err)
	}
}

func TestBustAndRebuy(t *testing.T) {
	// first hand: seats 1 (BB) then 0 (button/SB) get cards alternately
	order := engine.MustCards("7c As 2d Ah 3h 8s 9d Jc 4c")
	deck := func() *engine.Deck { d, _ := engine.DeckFrom(order); return d }
	var done []HandDone
	tb := newTable(t, settings(), Options{Pause: time.Hour, Deck: deck, OnHandDone: func(h HandDone) { done = append(done, h) }})
	_ = tb.Sit("a", "Ann", 0)
	_ = tb.Sit("b", "Bob", 1)
	waitFor(t, tb, "hand", handRunning)
	if err := tb.Act("a", engine.Action{Kind: engine.Raise, To: 100}); err != nil {
		t.Fatal(err)
	}
	if err := tb.Act("b", engine.Action{Kind: engine.Call}); err != nil {
		t.Fatal(err)
	}
	s := waitFor(t, tb, "showdown", func(s State) bool { return s.Hand.Done() })
	if s.Seats[0].Stack != 200 || s.Seats[1].Stack != 0 || !s.Seats[1].SittingOut {
		t.Fatalf("a=%+v b=%+v", s.Seats[0], s.Seats[1])
	}
	if len(done) != 1 || done[0].Users[1] != "b" || done[0].HandNo != 1 {
		t.Fatalf("hand done hook %+v", done)
	}
	if err := tb.ComeBack("b"); err != nil {
		t.Fatal(err)
	}
	s, _ = tb.Snapshot()
	if s.Seats[1].Stack != 100 || s.Seats[1].SittingOut {
		t.Fatalf("rebuy: %+v", s.Seats[1])
	}
}

func TestClose(t *testing.T) {
	tb := newTable(t, settings(), Options{})
	_ = tb.Sit("a", "Ann", 0)
	_ = tb.Sit("b", "Bob", 1)
	waitFor(t, tb, "hand", handRunning)
	tb.Close()
	<-tb.Done()
	if err := tb.Sit("c", "Cat", 2); !errors.Is(err, ErrClosed) {
		t.Fatalf("after close: %v", err)
	}
	if _, err := tb.Snapshot(); !errors.Is(err, ErrClosed) {
		t.Fatal(err)
	}
}

// Many hands with random actions from several goroutines: chips are
// conserved and nothing races.
func TestRandomPlayConservesChips(t *testing.T) {
	tb := newTable(t, settings(), Options{Pause: time.Millisecond})
	users := []string{"a", "b", "c", "d"}
	for i, u := range users {
		if err := tb.Sit(u, u, i); err != nil {
			t.Fatal(err)
		}
	}
	stop := make(chan struct{})
	errs := make(chan error, len(users))
	for k, u := range users {
		go func() {
			r := mathrand.New(mathrand.NewPCG(uint64(k), 9))
			for {
				select {
				case <-stop:
					errs <- nil
					return
				default:
				}
				s, err := tb.Snapshot()
				if err != nil {
					errs <- err
					return
				}
				if s.Seats[k] != nil && s.Seats[k].SittingOut {
					_ = tb.ComeBack(u)
				}
				if !handRunning(s) {
					time.Sleep(time.Millisecond)
					continue
				}
				l, ok := s.Hand.Legal()
				if !ok || l.Seat != k {
					time.Sleep(100 * time.Microsecond)
					continue
				}
				a := engine.Action{Kind: engine.Call}
				switch {
				case l.BetKind != 0 && r.IntN(4) == 0:
					a = engine.Action{Kind: l.BetKind, To: l.MinTo + r.Int64N(l.MaxTo-l.MinTo+1)}
				case r.IntN(8) == 0:
					a.Kind = engine.Fold
				case l.Check:
					a.Kind = engine.Check
				}
				_ = tb.Act(u, a) // may race with the turn moving on: errors are fine
			}
		}()
	}
	waitFor(t, tb, "50 hands", func(s State) bool { return s.HandNo >= 50 })
	close(stop)
	for range users {
		if err := <-errs; err != nil {
			t.Fatal(err)
		}
	}
	// stacks plus chips in the running hand equal the buy-ins; rebuys add
	// a starting stack each, so compare against hands of a fresh snapshot
	s, _ := tb.Snapshot()
	var total int64
	for _, p := range s.Seats {
		if p != nil {
			total += p.Stack
		}
	}
	if s.Hand != nil && !s.Hand.Done() {
		total += s.Hand.PotTotal()
	}
	if total%100 != 0 || total < 400 {
		t.Fatalf("chips not a multiple of buy-ins: %d", total)
	}
}
