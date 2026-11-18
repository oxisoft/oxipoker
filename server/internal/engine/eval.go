package engine

import "math/bits"

// Category of a poker hand, from weakest to strongest.
type Category uint8

const (
	HighCard Category = iota
	OnePair
	TwoPair
	ThreeOfAKind
	Straight
	Flush
	FullHouse
	FourOfAKind
	StraightFlush
)

var categoryNames = [...]string{
	"high card", "one pair", "two pair", "three of a kind", "straight",
	"flush", "full house", "four of a kind", "straight flush",
}

func (c Category) String() string {
	if int(c) < len(categoryNames) {
		return categoryNames[c]
	}
	return "unknown"
}

// Value orders hands: a higher Value wins, equal Values split. Layout:
// category in bits 20-23, then up to five ranks of 4 bits each, most
// significant first (for a straight only the top card counts).
type Value uint32

// Category of the hand this value belongs to.
func (v Value) Category() Category { return Category(v >> 20) }

func makeValue(c Category, ranks ...int) Value {
	v := Value(c) << 20
	shift := 16
	for _, r := range ranks {
		v |= Value(r) << shift
		shift -= 4
	}
	return v
}

// Evaluate returns the value of the best five-card hand out of 5 to 7 cards.
// It works on rank bit masks and counts, no tables and no allocation.
func Evaluate(cards []Card) Value {
	var suitMask [4]uint16
	var count [13]uint8
	var all uint16
	for _, c := range cards {
		r := c.Rank()
		suitMask[c.Suit()] |= 1 << r
		count[r]++
		all |= 1 << r
	}

	flushMask := uint16(0)
	for _, m := range suitMask {
		if bits.OnesCount16(m) >= 5 {
			flushMask = m
		}
	}
	if flushMask != 0 {
		if hi := straightHigh(flushMask); hi >= 0 {
			return makeValue(StraightFlush, hi)
		}
	}

	quad := -1
	var trips, pairs [3]int
	nt, np := 0, 0
	for r := 12; r >= 0; r-- {
		switch count[r] {
		case 4:
			quad = r
		case 3:
			if nt < len(trips) {
				trips[nt] = r
				nt++
			}
		case 2:
			if np < len(pairs) {
				pairs[np] = r
				np++
			}
		}
	}

	if quad >= 0 {
		return makeValue(FourOfAKind, append([]int{quad}, topRanks(all&^(1<<quad), 1)...)...)
	}
	if nt >= 1 && (nt >= 2 || np >= 1) {
		pair := -1
		if np >= 1 {
			pair = pairs[0]
		}
		if nt >= 2 && trips[1] > pair {
			pair = trips[1]
		}
		return makeValue(FullHouse, trips[0], pair)
	}
	if flushMask != 0 {
		return makeValue(Flush, topRanks(flushMask, 5)...)
	}
	if hi := straightHigh(all); hi >= 0 {
		return makeValue(Straight, hi)
	}
	if nt == 1 {
		return makeValue(ThreeOfAKind, append([]int{trips[0]}, topRanks(all&^(1<<trips[0]), 2)...)...)
	}
	if np >= 2 {
		rest := all &^ (1<<pairs[0] | 1<<pairs[1])
		return makeValue(TwoPair, append([]int{pairs[0], pairs[1]}, topRanks(rest, 1)...)...)
	}
	if np == 1 {
		return makeValue(OnePair, append([]int{pairs[0]}, topRanks(all&^(1<<pairs[0]), 3)...)...)
	}
	return makeValue(HighCard, topRanks(all, 5)...)
}

// straightHigh returns the top rank of the highest straight in mask, or -1.
// The wheel (A-2-3-4-5) counts as five-high.
func straightHigh(mask uint16) int {
	for hi := 12; hi >= 4; hi-- {
		if (mask>>(hi-4))&0x1f == 0x1f {
			return hi
		}
	}
	const wheel = 1<<12 | 0xf
	if mask&wheel == wheel {
		return int(Five)
	}
	return -1
}

// topRanks lists the n highest ranks set in mask, highest first.
func topRanks(mask uint16, n int) []int {
	out := make([]int, 0, n)
	for r := 12; r >= 0 && len(out) < n; r-- {
		if mask&(1<<r) != 0 {
			out = append(out, r)
		}
	}
	return out
}
