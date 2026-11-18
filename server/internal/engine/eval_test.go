package engine

import (
	mathrand "math/rand/v2"
	"slices"
	"testing"
)

// slowEvaluate5 is an independent, deliberately plain evaluator for exactly
// five cards: sort ranks by (count, rank), then classify. Only for tests.
func slowEvaluate5(cs []Card) Value {
	cnt := map[int]int{}
	flush := true
	for _, c := range cs {
		cnt[int(c.Rank())]++
		if c.Suit() != cs[0].Suit() {
			flush = false
		}
	}
	ranks := make([]int, 0, 5)
	for r := range cnt {
		ranks = append(ranks, r)
	}
	slices.SortFunc(ranks, func(a, b int) int {
		if cnt[a] != cnt[b] {
			return cnt[b] - cnt[a]
		}
		return b - a
	})
	straight, high := false, 0
	if len(ranks) == 5 {
		if ranks[0]-ranks[4] == 4 {
			straight, high = true, ranks[0]
		} else if slices.Equal(ranks, []int{12, 3, 2, 1, 0}) {
			straight, high = true, 3
		}
	}
	switch {
	case straight && flush:
		return makeValue(StraightFlush, high)
	case cnt[ranks[0]] == 4:
		return makeValue(FourOfAKind, ranks...)
	case cnt[ranks[0]] == 3 && cnt[ranks[1]] == 2:
		return makeValue(FullHouse, ranks...)
	case flush:
		return makeValue(Flush, ranks...)
	case straight:
		return makeValue(Straight, high)
	case cnt[ranks[0]] == 3:
		return makeValue(ThreeOfAKind, ranks...)
	case cnt[ranks[0]] == 2 && cnt[ranks[1]] == 2:
		return makeValue(TwoPair, ranks...)
	case cnt[ranks[0]] == 2:
		return makeValue(OnePair, ranks...)
	}
	return makeValue(HighCard, ranks...)
}

// slowEvaluate tries every five-card subset.
func slowEvaluate(cs []Card) Value {
	best := Value(0)
	n := len(cs)
	for a := 0; a < n; a++ {
		for b := a + 1; b < n; b++ {
			for c := b + 1; c < n; c++ {
				for d := c + 1; d < n; d++ {
					for e := d + 1; e < n; e++ {
						if v := slowEvaluate5([]Card{cs[a], cs[b], cs[c], cs[d], cs[e]}); v > best {
							best = v
						}
					}
				}
			}
		}
	}
	return best
}

// TestAllFiveCardHands checks all 2,598,960 five-card hands: the textbook
// count per category, the 7,462 distinct hand values, and agreement with the
// independent evaluator.
func TestAllFiveCardHands(t *testing.T) {
	want := map[Category]int{
		StraightFlush: 40, FourOfAKind: 624, FullHouse: 3744, Flush: 5108, Straight: 10200,
		ThreeOfAKind: 54912, TwoPair: 123552, OnePair: 1098240, HighCard: 1302540,
	}
	got := map[Category]int{}
	distinct := map[Value]bool{}
	hand := make([]Card, 5)
	total := 0
	for a := Card(0); a < 52; a++ {
		for b := a + 1; b < 52; b++ {
			for c := b + 1; c < 52; c++ {
				for d := c + 1; d < 52; d++ {
					for e := d + 1; e < 52; e++ {
						hand[0], hand[1], hand[2], hand[3], hand[4] = a, b, c, d, e
						v := Evaluate(hand)
						got[v.Category()]++
						distinct[v] = true
						total++
						// The slow evaluator is checked on a fixed sample to keep -race fast.
						if total%97 == 0 {
							if s := slowEvaluate5(hand); s != v {
								t.Fatalf("%v: fast %x slow %x", hand, v, s)
							}
						}
					}
				}
			}
		}
	}
	if total != 2598960 {
		t.Fatalf("enumerated %d hands", total)
	}
	for cat, n := range want {
		if got[cat] != n {
			t.Errorf("%s: %d hands, want %d", cat, got[cat], n)
		}
	}
	if len(distinct) != 7462 {
		t.Errorf("%d distinct values, want 7462", len(distinct))
	}
}

func TestSevenCardsAgainstSlowEvaluator(t *testing.T) {
	r := mathrand.New(mathrand.NewPCG(3, 4))
	n := 200000
	if testing.Short() {
		n = 20000
	}
	for range n {
		d := NewDeck(r)
		k := 5 + r.IntN(3)
		hand := make([]Card, k)
		for i := range hand {
			hand[i] = d.Deal()
		}
		if f, s := Evaluate(hand), slowEvaluate(hand); f != s {
			t.Fatalf("%v: fast %x (%s) slow %x (%s)", hand, f, f.Category(), s, s.Category())
		}
	}
}

func TestEvaluateCases(t *testing.T) {
	cases := []struct {
		cards string
		cat   Category
	}{
		{"As 2d 3c 4h 5s 9d Kc", Straight},     // wheel
		{"As 2s 3s 4s 5s 9d Kc", StraightFlush}, // steel wheel
		{"Ah Kh Qh Jh Th 9h 8h", StraightFlush},
		{"Ks Kd Kh 7c 7d 7h 2s", FullHouse}, // two trips
		{"Ks Kd 7h 7c 2d 2h As", TwoPair},   // three pairs
		{"9s 9d 9h 9c As Ad Ah", FourOfAKind},
		{"2s 5s 9s Js Ks Qd Td", Flush},
		{"2c 3d 5h 7s 9c Jd Kh", HighCard},
	}
	for _, c := range cases {
		if got := Evaluate(MustCards(c.cards)).Category(); got != c.cat {
			t.Errorf("%s: %s, want %s", c.cards, got, c.cat)
		}
	}
	order := []string{ // each beats the next
		"Ah Kh Qh Jh Th 2c 3d",
		"5d 4d 3d 2d Ad Kc Qc",
		"Ks Kd Kh 7c 7d 7h 2s",
		"Ks Kd Kh 6c 6d 2h 3s",
		"6s 5d 4h 3c 2d 9h Ks",
		"As 2d 3c 4h 5s 9d Kc",
		"Ks Kd 7h 7c 2d 2h As",
		"Ks Kd 7h 7c 2d 3h Qs",
		"Ac Kd 9h 7s 4c 3d 2h",
		"Ac Kd 9h 6s 4c 3d 2h",
	}
	for i := 0; i+1 < len(order); i++ {
		if a, b := Evaluate(MustCards(order[i])), Evaluate(MustCards(order[i+1])); a <= b {
			t.Errorf("%q should beat %q", order[i], order[i+1])
		}
	}
	if Evaluate(MustCards("As Kd 9h 7s 4c 3d 2h")) != Evaluate(MustCards("Ac Kh 9d 7c 4s 2c 3h")) {
		t.Error("same ranks in other suits must tie")
	}
	if Category(99).String() != "unknown" || Flush.String() != "flush" {
		t.Error("category names")
	}
}

func BenchmarkEvaluate7(b *testing.B) {
	hand := MustCards("As Kd 9h 7s 4c 3d 2h")
	for b.Loop() {
		Evaluate(hand)
	}
}
