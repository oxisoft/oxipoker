package engine

import (
	"errors"
	mathrand "math/rand/v2"
	"slices"
	"testing"
)

// deckFor builds a deck so that hole[i] goes to the i-th player clockwise
// from the first seat left of the button, then the board.
func deckFor(t *testing.T, hole []string, board string) *Deck {
	t.Helper()
	var hs [][]Card
	for _, h := range hole {
		hs = append(hs, MustCards(h))
	}
	var order []Card
	for k := range 2 {
		for _, h := range hs {
			order = append(order, h[k])
		}
	}
	order = append(order, MustCards(board)...)
	d, err := DeckFrom(order)
	if err != nil {
		t.Fatal(err)
	}
	return d
}

func mustHand(t *testing.T, cfg Config, d *Deck) *Hand {
	t.Helper()
	h, err := NewHand(cfg, d)
	if err != nil {
		t.Fatal(err)
	}
	return h
}

func act(t *testing.T, h *Hand, seat int, k ActionKind, to int64) {
	t.Helper()
	if err := h.Act(seat, Action{Kind: k, To: to}); err != nil {
		l, _ := h.Legal()
		t.Fatalf("seat %d %s %d: %v (legal %+v)", seat, k, to, err, l)
	}
}

func stacks(h *Hand) map[int]int64 {
	m := map[int]int64{}
	for _, p := range h.Players() {
		m[p.Seat] = p.Stack
	}
	return m
}

func TestHeadsUpOrder(t *testing.T) {
	cfg := Config{Seats: []Seat{{0, 100}, {1, 100}}, Positions: Positions{Button: 0, SB: 0, BB: 1}, SmallBlind: 1, BigBlind: 2}
	h := mustHand(t, cfg, nil)
	if h.ToAct() != 0 {
		t.Fatalf("heads-up: button/small blind acts first preflop, got seat %d", h.ToAct())
	}
	act(t, h, 0, Call, 0)
	if h.ToAct() != 1 {
		t.Fatal("big blind has the option")
	}
	l, _ := h.Legal()
	if !l.Check || l.BetKind != Raise || l.MinTo != 4 {
		t.Fatalf("big blind option: %+v", l)
	}
	act(t, h, 1, Check, 0)
	if h.Street() != Flop || len(h.Board()) != 3 {
		t.Fatal("flop expected")
	}
	if h.ToAct() != 1 {
		t.Fatalf("heads-up: big blind acts first after the flop, got %d", h.ToAct())
	}
}

func TestFoldToBigBlindReturnsUncalled(t *testing.T) {
	cfg := Config{Seats: []Seat{{0, 100}, {3, 100}, {5, 100}}, Positions: Positions{Button: 0, SB: 3, BB: 5}, SmallBlind: 1, BigBlind: 2}
	h := mustHand(t, cfg, nil)
	if h.ToAct() != 0 {
		t.Fatalf("three-handed the button acts first preflop, got %d", h.ToAct())
	}
	act(t, h, 0, Fold, 0)
	act(t, h, 3, Fold, 0)
	if !h.Done() {
		t.Fatal("hand should be over")
	}
	s := stacks(h)
	if s[0] != 100 || s[3] != 99 || s[5] != 101 {
		t.Fatalf("stacks %v", s)
	}
	evs := h.Events()
	if !slices.ContainsFunc(evs, func(e Event) bool { return e.Kind == EvReturn && e.Seat == 5 && e.Amount == 1 }) {
		t.Fatal("uncalled part of the big blind not returned")
	}
	if slices.ContainsFunc(evs, func(e Event) bool { return e.Kind == EvShow }) {
		t.Fatal("no cards shown when everybody folds")
	}
}

func TestMinRaise(t *testing.T) {
	cfg := Config{Seats: []Seat{{0, 1000}, {1, 1000}, {2, 1000}}, Positions: Positions{Button: 0, SB: 1, BB: 2}, SmallBlind: 5, BigBlind: 10}
	h := mustHand(t, cfg, nil)
	if err := h.Act(0, Action{Kind: Raise, To: 15}); !errors.Is(err, ErrAmount) {
		t.Fatalf("raise to 15 with BB 10 must fail, got %v", err)
	}
	act(t, h, 0, Raise, 30) // raise by 20
	l, _ := h.Legal()
	if l.MinTo != 50 || l.MaxTo != 1000 || l.Call != 25 {
		t.Fatalf("after raise to 30: %+v", l)
	}
	if err := h.Act(1, Action{Kind: Bet, To: 50}); !errors.Is(err, ErrIllegal) {
		t.Fatalf("bet when facing a bet must be illegal, got %v", err)
	}
	if err := h.Act(2, Action{Kind: Fold}); !errors.Is(err, ErrNotYourTurn) {
		t.Fatalf("out of turn must fail, got %v", err)
	}
}

// A short all-in does not reopen the betting for a player who already acted.
func TestShortAllInDoesNotReopen(t *testing.T) {
	// seats clockwise from left of the button: 1 (SB), 2 (BB), 0 (button)
	cfg := Config{Seats: []Seat{{0, 1000}, {1, 1000}, {2, 37}}, Positions: Positions{Button: 0, SB: 1, BB: 2}, SmallBlind: 5, BigBlind: 10}
	h := mustHand(t, cfg, nil)
	act(t, h, 0, Call, 0)
	act(t, h, 1, Call, 0)
	act(t, h, 2, Check, 0)
	// flop: SB first
	act(t, h, 1, Bet, 20)
	act(t, h, 2, Raise, 27) // all-in, raise by 7 < 20
	l, _ := h.Legal()
	if l.Seat != 0 || l.BetKind != Raise || l.MinTo != 47 {
		t.Fatalf("button has not acted yet and may raise: %+v", l)
	}
	act(t, h, 0, Call, 0)
	l, _ = h.Legal()
	if l.Seat != 1 || l.Call != 7 || l.BetKind != 0 {
		t.Fatalf("SB faces only a short all-in: call or fold, got %+v", l)
	}
	act(t, h, 1, Call, 0)
	if h.Street() != Turn {
		t.Fatalf("street %s", h.Street())
	}
}

// Two short all-ins that add up to a full raise reopen the betting.
func TestShortAllInsAddUpToFullRaise(t *testing.T) {
	cfg := Config{Seats: []Seat{{0, 1000}, {1, 1000}, {2, 35}, {3, 45}}, Positions: Positions{Button: 0, SB: 1, BB: 2}, SmallBlind: 5, BigBlind: 10}
	h := mustHand(t, cfg, nil)
	// preflop: 3 (UTG), 0, 1, 2
	act(t, h, 3, Call, 0)
	act(t, h, 0, Call, 0)
	act(t, h, 1, Call, 0)
	act(t, h, 2, Check, 0)
	// flop: 1, 2, 3, 0
	act(t, h, 1, Bet, 10)
	act(t, h, 2, Raise, 25) // all-in, +15 (full: min raise is 10)
	act(t, h, 3, Raise, 35) // all-in, +10 = full raise
	act(t, h, 0, Call, 0)
	l, _ := h.Legal()
	if l.Seat != 1 || l.BetKind != Raise {
		t.Fatalf("SB faced full raises and may raise again: %+v", l)
	}
}

func TestSidePots(t *testing.T) {
	// clockwise from left of button 0: 1, 2, 0
	cfg := Config{Seats: []Seat{{0, 200}, {1, 50}, {2, 100}}, Positions: Positions{Button: 0, SB: 1, BB: 2}, SmallBlind: 1, BigBlind: 2}
	d := deckFor(t, []string{"AsAh", "KsKh", "QsQh"}, "2c7d9cTd3h")
	h := mustHand(t, cfg, d)
	act(t, h, 0, Raise, 200)
	act(t, h, 1, Call, 0) // all-in 50
	act(t, h, 2, Call, 0) // all-in 100
	if !h.Done() {
		t.Fatal("all-in hand runs out to showdown")
	}
	s := stacks(h)
	if s[1] != 150 || s[2] != 100 || s[0] != 100 {
		t.Fatalf("stacks %v", s)
	}
	r := h.Results()
	if len(r) != 2 || r[0].Amount != 150 || r[1].Amount != 100 || !slices.Equal(r[1].Eligible, []int{2, 0}) {
		t.Fatalf("pots %+v", r)
	}
	if len(h.Board()) != 5 {
		t.Fatal("board not run out")
	}
}

func TestSplitPotOddChip(t *testing.T) {
	// SB folds after posting 1: pot 5 split between seats 2 and 0 (board plays)
	cfg := Config{Seats: []Seat{{0, 100}, {1, 100}, {2, 100}}, Positions: Positions{Button: 0, SB: 1, BB: 2}, SmallBlind: 1, BigBlind: 2}
	d := deckFor(t, []string{"2c3d", "4c5d", "2h3h"}, "AsKsQsJsTs")
	h := mustHand(t, cfg, d)
	act(t, h, 0, Call, 0)
	act(t, h, 1, Fold, 0)
	act(t, h, 2, Check, 0)
	for range 3 {
		act(t, h, 2, Check, 0)
		act(t, h, 0, Check, 0)
	}
	s := stacks(h)
	if s[2] != 101 || s[0] != 100 || s[1] != 99 {
		t.Fatalf("odd chip goes to the first seat left of the button: %v", s)
	}
}

func TestShowdownOrder(t *testing.T) {
	cfg := Config{Seats: []Seat{{0, 100}, {1, 100}, {2, 100}}, Positions: Positions{Button: 0, SB: 1, BB: 2}, SmallBlind: 1, BigBlind: 2}
	h := mustHand(t, cfg, nil)
	act(t, h, 0, Call, 0)
	act(t, h, 1, Call, 0)
	act(t, h, 2, Check, 0)
	for range 2 {
		act(t, h, 1, Check, 0)
		act(t, h, 2, Check, 0)
		act(t, h, 0, Check, 0)
	}
	act(t, h, 1, Check, 0)
	act(t, h, 2, Bet, 10)
	act(t, h, 0, Call, 0)
	act(t, h, 1, Call, 0)
	if got := h.Shown(); !slices.Equal(got, []int{2, 0, 1}) {
		t.Fatalf("river bettor shows first, then clockwise: %v", got)
	}

	h = mustHand(t, cfg, nil)
	act(t, h, 0, Call, 0)
	act(t, h, 1, Fold, 0)
	act(t, h, 2, Check, 0)
	for range 3 {
		act(t, h, 2, Check, 0)
		act(t, h, 0, Check, 0)
	}
	if got := h.Shown(); !slices.Equal(got, []int{2, 0}) {
		t.Fatalf("no bet: first live seat left of the button shows first: %v", got)
	}
}

func TestShortBigBlindAllIn(t *testing.T) {
	cfg := Config{Seats: []Seat{{0, 100}, {1, 1}}, Positions: Positions{Button: 0, SB: 0, BB: 1}, SmallBlind: 1, BigBlind: 2}
	h := mustHand(t, cfg, nil)
	l, _ := h.Legal()
	if l.Seat != 0 || l.Call != 1 || l.BetKind != 0 {
		t.Fatalf("against an all-in big blind only call or fold: %+v", l)
	}
	act(t, h, 0, Call, 0)
	if !h.Done() || h.PotTotal() != 2 {
		t.Fatalf("done %v pot %d", h.Done(), h.PotTotal())
	}
}

func TestNextPositions(t *testing.T) {
	p, _ := NextPositions([]int{2, 5, 7}, nil)
	if p != (Positions{Button: 2, SB: 5, BB: 7}) {
		t.Fatalf("first hand %+v", p)
	}
	p, _ = NextPositions([]int{2, 5, 7}, &p)
	if p != (Positions{Button: 5, SB: 7, BB: 2}) {
		t.Fatalf("moves one seat %+v", p)
	}
	// the small blind of the next hand (seat 2, last BB) leaves: dead small blind
	p, _ = NextPositions([]int{5, 7, 8}, &Positions{Button: 5, SB: 7, BB: 2})
	if p != (Positions{Button: 7, SB: 2, BB: 5, SBDead: true}) {
		t.Fatalf("dead small blind %+v", p)
	}
	// button on an empty seat (dead button)
	p, _ = NextPositions([]int{2, 5, 8}, &Positions{Button: 5, SB: 7, BB: 2})
	if p != (Positions{Button: 7, SB: 2, BB: 5}) {
		t.Fatalf("dead button %+v", p)
	}
	// heads-up: button is the small blind, big blind alternates
	p, _ = NextPositions([]int{3, 6}, &Positions{Button: 1, SB: 3, BB: 6})
	if p != (Positions{Button: 6, SB: 6, BB: 3}) {
		t.Fatalf("heads-up %+v", p)
	}
	if _, err := NextPositions([]int{1}, nil); err == nil {
		t.Fatal("one player cannot play")
	}
	// a hand with a dead small blind plays: BB posts alone, UTG acts first
	h := mustHand(t, Config{Seats: []Seat{{5, 100}, {7, 100}, {8, 100}}, Positions: Positions{Button: 7, SB: 2, BB: 5, SBDead: true}, SmallBlind: 1, BigBlind: 2}, nil)
	if h.PotTotal() != 2 || h.ToAct() != 7 {
		t.Fatalf("dead small blind hand: pot %d to act %d", h.PotTotal(), h.ToAct())
	}
}

// randomHand plays one hand with random legal (and some illegal) actions and
// checks the invariants after every step. pick returns a number in [0,n).
func randomHand(t testing.TB, pick func(n int) int) {
	nSeats := 2 + pick(8)
	var seats []Seat
	var total int64
	used := map[int]bool{}
	for len(seats) < nSeats {
		s := pick(9)
		if used[s] {
			continue
		}
		used[s] = true
		st := int64(1 + pick(400))
		seats = append(seats, Seat{s, st})
		total += st
	}
	var active []int
	for _, s := range seats {
		active = append(active, s.Seat)
	}
	pos, err := NextPositions(active, nil)
	if err != nil {
		t.Fatal(err)
	}
	for range pick(4) {
		pos, _ = NextPositions(active, &pos)
	}
	bb := int64(1 + pick(20))
	sb := bb / 2
	deck := NewDeck(mathrand.New(mathrand.NewPCG(uint64(pick(1<<30)), 7)))
	h, err := NewHand(Config{Seats: seats, Positions: pos, SmallBlind: sb, BigBlind: bb}, deck)
	if err != nil {
		t.Fatal(err)
	}
	type step struct {
		seat int
		a    Action
	}
	var played []step
	check := func() {
		var sum int64
		for _, p := range h.Players() {
			if p.Stack < 0 || p.Bet < 0 || p.Committed < p.Bet {
				t.Fatalf("bad player %+v", p)
			}
			sum += p.Stack + p.Committed
		}
		if h.Done() {
			sum = 0
			for _, p := range h.Players() {
				sum += p.Stack
			}
		}
		if sum != total {
			t.Fatalf("chips changed: %d != %d", sum, total)
		}
	}
	check()
	for steps := 0; !h.Done(); steps++ {
		if steps > 200 {
			t.Fatal("hand does not end")
		}
		l, ok := h.Legal()
		if !ok {
			t.Fatal("hand not done but nobody to act")
		}
		// an illegal intent never changes anything
		before, evs := h.Players(), len(h.Events())
		bad := []Action{{Kind: Check}, {Kind: Call}, {Kind: Bet, To: l.MaxTo + 1}, {Kind: Raise, To: l.MinTo - 1}, {Kind: 99}}
		b := bad[pick(len(bad))]
		legalBad := (b.Kind == Check && l.Check) || (b.Kind == Call && l.Call > 0) ||
			(b.Kind == l.BetKind && b.Kind != 0 && b.To >= l.MinTo && b.To <= l.MaxTo)
		if !legalBad {
			if err := h.Act(l.Seat, b); err == nil {
				t.Fatalf("illegal %+v accepted (legal %+v)", b, l)
			}
			if !slices.EqualFunc(before, h.Players(), func(a, b Player) bool {
				return a.Stack == b.Stack && a.Bet == b.Bet && a.Folded == b.Folded
			}) || len(h.Events()) != evs {
				t.Fatal("rejected action changed the hand")
			}
		}
		if err := h.Act((l.Seat+1)%circ, Action{Kind: Fold}); err == nil {
			t.Fatal("out of turn fold accepted")
		}
		var a Action
		switch r := pick(10); {
		case r == 0:
			a = Action{Kind: Fold}
		case r < 4 && l.BetKind != 0:
			a = Action{Kind: l.BetKind, To: l.MinTo + int64(pick(int(l.MaxTo-l.MinTo)+1))}
		case r < 5 && l.BetKind != 0:
			a = Action{Kind: l.BetKind, To: l.MaxTo}
		case l.Check:
			a = Action{Kind: Check}
		default:
			a = Action{Kind: Call}
		}
		if err := h.Act(l.Seat, a); err != nil {
			t.Fatalf("legal %+v refused: %v (legal %+v)", a, err, l)
		}
		played = append(played, step{l.Seat, a})
		check()
	}
	var won int64
	for _, r := range h.Results() {
		var s int64
		for _, x := range r.Shares {
			s += x
		}
		if s != r.Amount {
			t.Fatalf("pot %d paid %d", r.Amount, s)
		}
		won += s
	}
	if won != h.PotTotal() {
		t.Fatalf("paid %d of %d", won, h.PotTotal())
	}
	// replay from the stored deck and actions gives the same history
	d2, err := DeckFrom(h.Dealt())
	if err != nil {
		t.Fatal(err)
	}
	h2, err := NewHand(Config{Seats: seats, Positions: pos, SmallBlind: sb, BigBlind: bb}, d2)
	if err != nil {
		t.Fatal(err)
	}
	for _, s := range played {
		if err := h2.Act(s.seat, s.a); err != nil {
			t.Fatalf("replay: %v", err)
		}
	}
	if !slices.EqualFunc(h.Events(), h2.Events(), func(a, b Event) bool {
		return a.Kind == b.Kind && a.Seat == b.Seat && a.Amount == b.Amount && slices.Equal(a.Cards, b.Cards)
	}) {
		t.Fatal("replay differs")
	}
}

func TestRandomHandsProperties(t *testing.T) {
	r := mathrand.New(mathrand.NewPCG(1, 2))
	n := 20000
	if testing.Short() {
		n = 2000
	}
	for range n {
		randomHand(t, r.IntN)
	}
}

func FuzzHand(f *testing.F) {
	f.Add([]byte{1, 2, 3, 4, 5, 6, 7, 8})
	f.Add([]byte{7, 0, 200, 13, 99, 1, 1, 1, 250, 4})
	f.Fuzz(func(t *testing.T, data []byte) {
		i := 0
		pick := func(n int) int {
			if n <= 1 {
				return 0
			}
			if i >= len(data) {
				i++
				return i % n
			}
			v := int(data[i])
			if i+1 < len(data) {
				v = v<<8 | int(data[i+1])
			}
			i += 2
			return v % n
		}
		randomHand(t, pick)
	})
}
