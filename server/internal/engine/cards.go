// Package engine is the pure game logic of Oxi Poker: cards, shuffle, hand
// evaluation and the hand state machine. It does no I/O, keeps no clock and
// talks to no database, so every hand can be replayed from its history.
package engine

import (
	"crypto/rand"
	"encoding/binary"
	"fmt"
	mathrand "math/rand/v2"
)

// Rank is a card rank from Two (0) to Ace (12).
type Rank uint8

// Suit is one of the four suits.
type Suit uint8

const (
	Two Rank = iota
	Three
	Four
	Five
	Six
	Seven
	Eight
	Nine
	Ten
	Jack
	Queen
	King
	Ace
)

const (
	Clubs Suit = iota
	Diamonds
	Hearts
	Spades
)

const rankChars = "23456789TJQKA"
const suitChars = "cdhs"

// Card packs rank and suit into one byte: rank*4 + suit. The zero value is the
// two of clubs, so "no card" is never represented by a Card; use a slice length.
type Card uint8

// NewCard builds a card from rank and suit.
func NewCard(r Rank, s Suit) Card { return Card(uint8(r)*4 + uint8(s)) }

// Rank of the card.
func (c Card) Rank() Rank { return Rank(c / 4) }

// Suit of the card.
func (c Card) Suit() Suit { return Suit(c % 4) }

// Valid reports whether c is one of the 52 cards.
func (c Card) Valid() bool { return c < 52 }

// String is the two-letter form used in hand histories and the protocol, e.g. "As", "Td".
func (c Card) String() string {
	if !c.Valid() {
		return "??"
	}
	return string([]byte{rankChars[c.Rank()], suitChars[c.Suit()]})
}

// MarshalText makes cards appear as "As" in JSON.
func (c Card) MarshalText() ([]byte, error) {
	if !c.Valid() {
		return nil, fmt.Errorf("invalid card %d", uint8(c))
	}
	return []byte(c.String()), nil
}

// UnmarshalText parses "As".
func (c *Card) UnmarshalText(b []byte) error {
	p, err := ParseCard(string(b))
	if err != nil {
		return err
	}
	*c = p
	return nil
}

// ParseCard parses the two-letter form ("As", "td" is accepted too).
func ParseCard(s string) (Card, error) {
	if len(s) != 2 {
		return 0, fmt.Errorf("card %q: want two letters", s)
	}
	r, s2 := -1, -1
	for i := 0; i < len(rankChars); i++ {
		if rankChars[i] == upper(s[0]) {
			r = i
		}
	}
	for i := 0; i < len(suitChars); i++ {
		if suitChars[i] == lower(s[1]) {
			s2 = i
		}
	}
	if r < 0 || s2 < 0 {
		return 0, fmt.Errorf("card %q: unknown rank or suit", s)
	}
	return NewCard(Rank(r), Suit(s2)), nil
}

// MustCards parses space-separated cards and panics on error (tests and fixtures).
func MustCards(s string) []Card {
	var out []Card
	for i := 0; i < len(s); {
		if s[i] == ' ' {
			i++
			continue
		}
		if i+2 > len(s) {
			panic("MustCards: dangling " + s[i:])
		}
		c, err := ParseCard(s[i : i+2])
		if err != nil {
			panic(err)
		}
		out = append(out, c)
		i += 2
	}
	return out
}

func upper(b byte) byte {
	if b >= 'a' && b <= 'z' {
		return b - 32
	}
	return b
}

func lower(b byte) byte {
	if b >= 'A' && b <= 'Z' {
		return b + 32
	}
	return b
}

// Deck is the 52 cards in dealing order.
type Deck struct {
	cards [52]Card
	next  int
}

// Shuffler picks uniform random integers in [0, n). The table uses
// CryptoShuffler; tests pass a seeded math/rand/v2 generator.
type Shuffler interface {
	IntN(n int) int
}

// cryptoSource feeds math/rand/v2's unbiased IntN from crypto/rand.
type cryptoSource struct{}

func (cryptoSource) Uint64() uint64 {
	var b [8]byte
	_, _ = rand.Read(b[:]) // crypto/rand.Read never fails (Go 1.24+): it crashes the program instead
	return binary.LittleEndian.Uint64(b[:])
}

// CryptoShuffler draws every shuffle decision from the operating system's
// cryptographic random source.
func CryptoShuffler() Shuffler { return mathrand.New(cryptoSource{}) }

// NewDeck returns a deck shuffled with a Fisher-Yates shuffle driven by r.
func NewDeck(r Shuffler) *Deck {
	d := &Deck{}
	for i := range d.cards {
		d.cards[i] = Card(i)
	}
	for i := len(d.cards) - 1; i > 0; i-- {
		j := r.IntN(i + 1)
		d.cards[i], d.cards[j] = d.cards[j], d.cards[i]
	}
	return d
}

// DeckFrom builds a deck that deals the given cards first, in order, and then
// the remaining cards in rank order. Used to replay a stored hand and in tests.
func DeckFrom(first []Card) (*Deck, error) {
	d := &Deck{}
	var seen [52]bool
	n := 0
	for _, c := range first {
		if !c.Valid() || seen[c] {
			return nil, fmt.Errorf("deck: card %s invalid or repeated", c)
		}
		seen[c] = true
		d.cards[n] = c
		n++
	}
	for c := Card(0); c < 52; c++ {
		if !seen[c] {
			d.cards[n] = c
			n++
		}
	}
	return d, nil
}

// Deal takes the next card. Dealing more than 52 cards is a programming error.
func (d *Deck) Deal() Card {
	if d.next >= len(d.cards) {
		panic("engine: deck exhausted")
	}
	c := d.cards[d.next]
	d.next++
	return c
}

// Remaining is the number of cards not dealt yet.
func (d *Deck) Remaining() int { return len(d.cards) - d.next }
