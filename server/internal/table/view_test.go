package table

import (
	"encoding/json"
	mathrand "math/rand/v2"
	"strings"
	"testing"
	"time"

	"github.com/oxisoft/oxipoker/server/internal/engine"
)

// checkViews proves that no viewer's JSON carries a hidden card of another
// player: only the viewer's own hole cards and cards shown at showdown.
func checkViews(t *testing.T, s State, viewers []string) {
	t.Helper()
	if s.Hand == nil {
		return
	}
	shown := map[int]bool{}
	for _, e := range s.Hand.Events() {
		if e.Kind == engine.EvShow {
			shown[e.Seat] = true
		}
	}
	for _, u := range viewers {
		v := s.ViewFor(u)
		b, err := json.Marshal(v)
		if err != nil {
			t.Fatal(err)
		}
		js := string(b)
		for _, p := range s.Hand.Players() {
			if s.HandUsers[p.Seat] == u || shown[p.Seat] {
				continue
			}
			for _, c := range p.Hole {
				if strings.Contains(js, `"`+c.String()+`"`) {
					t.Fatalf("viewer %s sees %s of seat %d: %s", u, c, p.Seat, js)
				}
			}
		}
		if v.Hand != nil && v.Hand.Legal != nil && v.Hand.Legal.Seat != v.YourSeat {
			t.Fatalf("viewer %s got another seat's legal actions", u)
		}
		if v.YourSeat >= 0 && s.Seats[v.YourSeat].User != u {
			t.Fatal("wrong own seat")
		}
		if v.YourSeat >= 0 && v.Hand != nil && !v.Hand.Done {
			if sv := v.Seats[v.YourSeat]; sv.InHand && len(sv.Cards) != 2 {
				t.Fatalf("own cards missing for %s", u)
			}
		}
	}
}

func TestViewsNeverLeakHiddenCards(t *testing.T) {
	tb := newTable(t, settings(), Options{Pause: time.Millisecond})
	users := []string{"a", "b", "c", "d"}
	for i, u := range users {
		_ = tb.Sit(u, u, i*2)
	}
	viewers := append(users, "spectator")
	r := mathrand.New(mathrand.NewPCG(3, 4))
	showdowns := 0
	lastHand := 0
	deadline := time.Now().Add(20 * time.Second)
	for {
		s, err := tb.Snapshot()
		if err != nil {
			t.Fatal(err)
		}
		checkViews(t, s, viewers)
		if s.HandNo >= 200 {
			break
		}
		if time.Now().After(deadline) {
			t.Fatalf("only %d hands", s.HandNo)
		}
		for i, p := range s.Seats {
			if p != nil && p.SittingOut {
				_ = tb.ComeBack(users[i/2])
			}
		}
		if s.Hand == nil || s.Hand.Done() {
			if s.Hand != nil && s.HandNo != lastHand && len(s.Hand.Shown()) > 0 {
				showdowns++
				lastHand = s.HandNo
			}
			time.Sleep(200 * time.Microsecond)
			continue
		}
		l, ok := s.Hand.Legal()
		if !ok {
			continue
		}
		a := engine.Action{Kind: engine.Call}
		switch {
		case l.BetKind != 0 && r.IntN(5) == 0:
			a = engine.Action{Kind: l.BetKind, To: l.MinTo + r.Int64N(l.MaxTo-l.MinTo+1)}
		case r.IntN(10) == 0:
			a.Kind = engine.Fold
		case l.Check:
			a.Kind = engine.Check
		}
		_ = tb.Act(s.HandUsers[l.Seat], a)
	}
	if showdowns < 20 {
		t.Fatalf("only %d showdowns checked", showdowns)
	}
}

func TestSpectatorView(t *testing.T) {
	tb := newTable(t, settings(), Options{Pause: time.Hour})
	_ = tb.Sit("a", "Ann", 0)
	_ = tb.Sit("b", "Bob", 1)
	s := waitFor(t, tb, "hand", handRunning)
	v := s.ViewFor("someone")
	if v.YourSeat != -1 || v.Hand.Legal != nil {
		t.Fatal("spectator has a seat or actions")
	}
	for _, sv := range v.Seats[:2] {
		if len(sv.Cards) != 0 || !sv.HasCards {
			t.Fatalf("spectator seat view %+v", sv)
		}
	}
	for _, e := range v.Hand.Events {
		if e.Kind == engine.EvHole {
			t.Fatal("hole event sent to a spectator")
		}
	}
	va := s.ViewFor("a")
	if len(va.Seats[0].Cards) != 2 || len(va.Seats[1].Cards) != 0 || va.Hand.Legal == nil {
		t.Fatalf("player view %+v", va.Seats)
	}
}
