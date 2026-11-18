package engine

import (
	mathrand "math/rand/v2"
	"slices"
	"testing"
)

func TestCardStringParse(t *testing.T) {
	for c := Card(0); c < 52; c++ {
		p, err := ParseCard(c.String())
		if err != nil || p != c {
			t.Fatalf("round trip %s: got %v %v", c, p, err)
		}
	}
	if c, err := ParseCard("td"); err != nil || c != NewCard(Ten, Diamonds) {
		t.Fatalf("lower case: %v %v", c, err)
	}
	for _, bad := range []string{"", "A", "1s", "Ax", "Asx"} {
		if _, err := ParseCard(bad); err == nil {
			t.Errorf("ParseCard(%q) accepted", bad)
		}
	}
	if Card(52).Valid() || Card(52).String() != "??" {
		t.Error("card 52 must be invalid")
	}
	var c Card
	if err := c.UnmarshalText([]byte("Qh")); err != nil || c.String() != "Qh" {
		t.Fatalf("UnmarshalText: %v %v", c, err)
	}
	if _, err := Card(60).MarshalText(); err == nil {
		t.Error("MarshalText of invalid card")
	}
}

func TestDeckHasEveryCardOnce(t *testing.T) {
	for _, sh := range []Shuffler{CryptoShuffler(), mathrand.New(mathrand.NewPCG(1, 2))} {
		d := NewDeck(sh)
		var seen [52]bool
		for d.Remaining() > 0 {
			c := d.Deal()
			if seen[c] {
				t.Fatalf("card %s dealt twice", c)
			}
			seen[c] = true
		}
		func() {
			defer func() {
				if recover() == nil {
					t.Error("dealing from an empty deck must panic")
				}
			}()
			d.Deal()
		}()
	}
}

func TestShuffleIsRoughlyUniform(t *testing.T) {
	// Where does the ace of spades land? 52 positions, 52,000 shuffles: each
	// position expects 1,000; a fair shuffle stays well inside +-25%.
	sh := mathrand.New(mathrand.NewPCG(7, 9))
	var pos [52]int
	as := NewCard(Ace, Spades)
	for range 52000 {
		d := NewDeck(sh)
		for i := 0; i < 52; i++ {
			if d.Deal() == as {
				pos[i]++
				break
			}
		}
	}
	for i, n := range pos {
		if n < 750 || n > 1250 {
			t.Fatalf("position %d got %d of 52000", i, n)
		}
	}
}

func TestDeckFrom(t *testing.T) {
	d, err := DeckFrom(MustCards("As Kd 2c"))
	if err != nil {
		t.Fatal(err)
	}
	if got := []Card{d.Deal(), d.Deal(), d.Deal()}; !slices.Equal(got, MustCards("As Kd 2c")) {
		t.Fatalf("first cards %v", got)
	}
	if d.Remaining() != 49 {
		t.Fatalf("remaining %d", d.Remaining())
	}
	if _, err := DeckFrom(MustCards("As As")); err == nil {
		t.Error("repeated card accepted")
	}
}
