package table

import (
	"errors"
	mathrand "math/rand/v2"
	"sync"
	"testing"
	"time"

	"github.com/oxisoft/oxipoker/server/internal/engine"
)

func sngSettings(seats int) Settings {
	s := settings()
	s.Seats, s.Kind, s.Structure = seats, KindSng, "turbo"
	return s
}

func TestSngSettingsValidate(t *testing.T) {
	s := sngSettings(6)
	if err := s.Validate(); err != nil {
		t.Fatal(err)
	}
	s.Structure = "hyper"
	if !errors.Is(s.Validate(), ErrNoStructure) {
		t.Fatal("unknown structure accepted")
	}
	c := settings()
	c.Structure = "turbo"
	if c.Validate() == nil {
		t.Fatal("structure on a cash table accepted")
	}
	c.Structure, c.Kind = "", "mtt"
	if c.Validate() == nil {
		t.Fatal("unknown kind accepted")
	}
}

func TestLevelBlinds(t *testing.T) {
	for _, c := range []struct {
		level   int
		sb, bb  int64
		wsb, wb int64
	}{{0, 1, 2, 1, 2}, {1, 1, 2, 1, 3}, {2, 1, 2, 2, 4}, {3, 10, 20, 30, 60}, {99, 1, 2, 2000, 2000 * 1}, {0, 0, 2, 0, 2}} {
		sb, bb := LevelBlinds(c.level, c.sb, c.bb)
		if c.level == 99 {
			c.wsb, c.wb = LevelBlinds(Levels-1, c.sb, c.bb)
		}
		if sb != c.wsb || bb != c.wb || sb > bb {
			t.Errorf("level %d of %d/%d = %d/%d, want %d/%d", c.level, c.sb, c.bb, sb, bb, c.wsb, c.wb)
		}
	}
	prev := int64(0)
	for l := range Levels {
		_, bb := LevelBlinds(l, 1, 2)
		if bb <= prev {
			t.Fatalf("level %d big blind %d does not rise", l, bb)
		}
		prev = bb
	}
}

func TestSngRegistration(t *testing.T) {
	tb := newTable(t, sngSettings(6), Options{})
	if err := tb.Start(); !errors.Is(err, ErrFewPlayers) {
		t.Fatalf("start alone: %v", err)
	}
	for i, u := range []string{"a", "b", "c"} {
		if err := tb.Sit(u, u, i); err != nil {
			t.Fatal(err)
		}
	}
	time.Sleep(30 * time.Millisecond)
	s, _ := tb.Snapshot()
	if s.Hand != nil || s.Sng.Phase != PhaseRegistering {
		t.Fatal("a sit-and-go must wait for the start")
	}
	if err := tb.Leave("c"); err != nil {
		t.Fatal(err)
	}
	if s, _ = tb.Snapshot(); s.Seats[2] != nil {
		t.Fatal("leaving during registration frees the seat")
	}
	if err := tb.Start(); err != nil {
		t.Fatal(err)
	}
	if err := tb.Start(); !errors.Is(err, ErrStarted) {
		t.Fatalf("second start: %v", err)
	}
	if err := tb.Sit("d", "d", 4); !errors.Is(err, ErrStarted) {
		t.Fatalf("late join: %v", err)
	}
	s = waitFor(t, tb, "first hand", handRunning)
	if s.Sng.Phase != PhaseRunning || s.Sng.BigBlind != 2 || s.Sng.NextBig != 3 || s.Sng.LevelEnds.IsZero() {
		t.Fatalf("sng state %+v", s.Sng)
	}
	if v := s.ViewFor("x"); v.Sng == nil || v.Sng.Phase != PhaseRunning {
		t.Fatal("the view carries the sit-and-go state")
	}
	cash, _ := New("c1", "h", settings(), Options{})
	defer cash.Close()
	if err := cash.Start(); !errors.Is(err, ErrNotSng) {
		t.Fatalf("start on a cash table: %v", err)
	}
}

func TestSngFullTableStarts(t *testing.T) {
	tb := newTable(t, sngSettings(2), Options{})
	_ = tb.Sit("a", "a", 0)
	if err := tb.Sit("b", "b", 1); err != nil {
		t.Fatal(err)
	}
	waitFor(t, tb, "start when every seat is taken", handRunning)
}

// playSng plays random aggressive actions until the sit-and-go is over and
// returns the final state. Players in quit leave as soon as they can.
func playSng(t *testing.T, tb *Table, r *mathrand.Rand, quit map[string]bool) State {
	t.Helper()
	deadline := time.Now().Add(20 * time.Second)
	for time.Now().Before(deadline) {
		s, err := tb.Snapshot()
		if err != nil {
			t.Fatal(err)
		}
		if s.Sng.Phase == PhaseFinished {
			return s
		}
		for u := range quit {
			if quit[u] {
				if tb.Leave(u) == nil {
					quit[u] = false
				}
			}
		}
		if handRunning(s) {
			l, ok := s.Hand.Legal()
			if ok {
				u := s.HandUsers[l.Seat]
				act := engine.Action{Kind: engine.Fold}
				switch x := r.IntN(10); {
				case x < 4 && l.BetKind != 0:
					act = engine.Action{Kind: l.BetKind, To: l.MaxTo}
				case x < 8 && l.Call > 0:
					act.Kind = engine.Call
				case l.Check:
					act.Kind = engine.Check
				}
				_ = tb.Act(u, act)
				continue
			}
		}
		time.Sleep(time.Millisecond)
	}
	t.Fatal("sit-and-go did not finish")
	return State{}
}

func TestSngPlaysToOneWinner(t *testing.T) {
	for game := range 5 {
		var mu sync.Mutex
		var done []GameDone
		users := []string{"a", "b", "c", "d", "e"}
		tb := newTable(t, sngSettings(len(users)), Options{OnGameDone: func(g GameDone) {
			mu.Lock()
			done = append(done, g)
			mu.Unlock()
		}})
		for i, u := range users {
			if err := tb.Sit(u, "N"+u, i); err != nil {
				t.Fatal(err)
			}
		}
		r := mathrand.New(mathrand.NewPCG(uint64(game), 7))
		s := playSng(t, tb, r, map[string]bool{"e": game%2 == 0})
		places := s.Sng.Places
		if len(places) != len(users) {
			t.Fatalf("game %d: places %+v", game, places)
		}
		seen := map[string]bool{}
		for i, p := range places {
			if p.Place != i+1 || seen[p.User] {
				t.Fatalf("game %d: places %+v", game, places)
			}
			seen[p.User] = true
		}
		var winner *Player
		for _, p := range s.Seats {
			if p != nil {
				if winner != nil {
					t.Fatal("more than one player left")
				}
				winner = p
			}
		}
		if winner == nil || winner.User != places[0].User || winner.Stack != int64(len(users))*100 {
			t.Fatalf("game %d: winner %+v, places %+v", game, winner, places)
		}
		time.Sleep(20 * time.Millisecond)
		if s2, _ := tb.Snapshot(); s2.HandNo != s.HandNo {
			t.Fatal("no hand after the winner is known")
		}
		mu.Lock()
		if len(done) != 1 || len(done[0].Places) != len(users) {
			t.Fatalf("game done hook: %+v", done)
		}
		mu.Unlock()
		if err := tb.ComeBack(places[len(places)-1].User); !errors.Is(err, ErrNotSeated) {
			t.Fatalf("a busted player has no rebuy: %v", err)
		}
		tb.Close()
	}
}

func TestSngBlindClock(t *testing.T) {
	tb := newTable(t, sngSettings(4), Options{LevelTime: 25 * time.Millisecond})
	for i, u := range []string{"a", "b", "c"} {
		_ = tb.Sit(u, u, i)
	}
	if err := tb.Start(); err != nil {
		t.Fatal(err)
	}
	// Everyone folds to the big blind; the level must rise between hands
	// and the next hand must use the new blinds.
	deadline := time.Now().Add(5 * time.Second)
	for time.Now().Before(deadline) {
		s, _ := tb.Snapshot()
		if handRunning(s) && s.Sng.Level >= 2 {
			if got := s.Hand.CurrentBet(); got < s.Sng.BigBlind && got != 0 {
				t.Fatalf("hand bet %d below level big blind %d", got, s.Sng.BigBlind)
			}
			_, bb := LevelBlinds(s.Sng.Level, 1, 2)
			if s.Sng.BigBlind != bb {
				t.Fatalf("level %d big blind %d, want %d", s.Sng.Level, s.Sng.BigBlind, bb)
			}
			return
		}
		if handRunning(s) {
			if l, ok := s.Hand.Legal(); ok {
				k := engine.Fold
				if l.Check {
					k = engine.Check
				}
				_ = tb.Act(s.HandUsers[l.Seat], engine.Action{Kind: k})
				continue
			}
		}
		time.Sleep(2 * time.Millisecond)
	}
	t.Fatal("blind level never rose")
}

func TestSngLeaverIsBlindedOut(t *testing.T) {
	set := sngSettings(3)
	set.TurnTime = 10 * time.Millisecond
	tb := newTable(t, set, Options{})
	for i, u := range []string{"a", "b", "c"} {
		_ = tb.Sit(u, u, i)
	}
	_ = tb.Start()
	waitFor(t, tb, "first hand", handRunning)
	if err := tb.Leave("c"); err != nil {
		t.Fatal(err)
	}
	s, _ := tb.Snapshot()
	if s.Seats[2] == nil || !s.Seats[2].SittingOut {
		t.Fatal("a leaver keeps the seat in a running sit-and-go")
	}
	s = waitFor(t, tb, "a hand with the leaver dealt in", func(s State) bool {
		return handRunning(s) && s.HandNo >= 2 && s.HandUsers[2] == "c"
	})
	if s.Sng.Phase != PhaseRunning {
		t.Fatal(s.Sng.Phase)
	}
}
