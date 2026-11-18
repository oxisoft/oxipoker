package engine

import (
	"errors"
	"slices"
)

// Positions are the button and blind seats of one hand. Seats are table seat
// numbers (0-based). Under the dead button rule the button can sit on an
// empty seat and the small blind can be dead (nobody posts it), so every
// player pays each blind once per orbit even when players leave or join.
type Positions struct {
	Button int  `json:"button"`
	SB     int  `json:"sb"`
	BB     int  `json:"bb"`
	SBDead bool `json:"sb_dead,omitempty"`
}

// circ is larger than any seat number, so (s-from+circ)%circ orders seats
// clockwise starting after from.
const circ = 1 << 16

func clockwise(from, s int) int { return (s - from + circ) % circ }

// nextSeat is the first seat of active (any order) clockwise after from.
func nextSeat(active []int, from int) int {
	best, bestD := -1, circ+1
	for _, s := range active {
		d := clockwise(from, s)
		if d == 0 {
			d = circ
		}
		if d < bestD {
			best, bestD = s, d
		}
	}
	return best
}

// NextPositions picks the positions for the next hand. active are the seats
// dealt in (at least two); prev is the last hand's positions, nil for the
// first hand at the table.
//
// Heads-up the button posts the small blind and acts first before the flop.
// With three or more players the big blind moves to the next active seat,
// the small blind goes to last hand's big blind seat (dead if that player is
// gone) and the button to last hand's small blind seat (dead if empty).
func NextPositions(active []int, prev *Positions) (Positions, error) {
	if len(active) < 2 {
		return Positions{}, errors.New("engine: a hand needs two players")
	}
	a := slices.Clone(active)
	slices.Sort(a)
	if prev == nil {
		if len(a) == 2 {
			return Positions{Button: a[0], SB: a[0], BB: a[1]}, nil
		}
		return Positions{Button: a[0], SB: a[1], BB: a[2]}, nil
	}
	bb := nextSeat(a, prev.BB)
	if len(a) == 2 {
		other := a[0]
		if other == bb {
			other = a[1]
		}
		return Positions{Button: other, SB: other, BB: bb}, nil
	}
	p := Positions{Button: prev.SB, SB: prev.BB, BB: bb}
	if !slices.Contains(a, p.SB) {
		p.SBDead = true
	}
	return p, nil
}
