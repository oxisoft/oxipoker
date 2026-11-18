package table

import (
	"time"

	"github.com/oxisoft/oxipoker/server/internal/engine"
)

// View is what one viewer may see of a table. It is built on the server for
// each viewer: the viewer's own hole cards, the cards shown at showdown, and
// nothing else hidden.
type View struct {
	ID       string      `json:"id"`
	Version  uint64      `json:"version"`
	Settings Settings    `json:"settings"`
	Host     string      `json:"host"`
	YourSeat int         `json:"your_seat"` // -1 for spectators
	Seats    []*SeatView `json:"seats"`     // index = seat number, nil = empty
	HandNo   int         `json:"hand_no"`
	Hand     *HandView   `json:"hand,omitempty"`
	Closed   bool        `json:"closed,omitempty"`
}

// SeatView is one occupied seat.
type SeatView struct {
	User       string        `json:"user"`
	Name       string        `json:"name"`
	Stack      int64         `json:"stack"`
	SittingOut bool          `json:"sitting_out,omitempty"`
	InHand     bool          `json:"in_hand,omitempty"`
	Folded     bool          `json:"folded,omitempty"`
	AllIn      bool          `json:"all_in,omitempty"`
	Bet        int64         `json:"bet,omitempty"`
	HasCards   bool          `json:"has_cards,omitempty"` // face down for others
	Cards      []engine.Card `json:"cards,omitempty"`     // own cards, or shown at showdown
}

// HandView is the running (or just finished) hand.
type HandView struct {
	Street     string             `json:"street"`
	Board      []engine.Card      `json:"board"`
	Pots       []engine.Pot       `json:"pots"`
	Button     int                `json:"button"`
	SB         int                `json:"sb"`
	BB         int                `json:"bb"`
	ToAct      int                `json:"to_act"` // -1 = nobody
	Deadline   time.Time          `json:"deadline,omitzero"`
	CurrentBet int64              `json:"current_bet"`
	Legal      *engine.Legal      `json:"legal,omitempty"` // only for the player to act
	Events     []engine.Event     `json:"events"`
	Results    []engine.PotResult `json:"results,omitempty"`
	Done       bool               `json:"done,omitempty"`
}

// ViewFor builds the view of user (a spectator when not seated).
func (s State) ViewFor(user string) View {
	v := View{ID: s.ID, Version: s.Version, Settings: s.Settings, Host: s.Host, YourSeat: -1,
		Seats: make([]*SeatView, len(s.Seats)), HandNo: s.HandNo, Closed: s.Closed}
	for i, p := range s.Seats {
		if p == nil {
			continue
		}
		if p.User == user {
			v.YourSeat = i
		}
		v.Seats[i] = &SeatView{User: p.User, Name: p.Name, Stack: p.Stack, SittingOut: p.SittingOut}
	}
	h := s.Hand
	if h == nil || s.Pos == nil {
		return v
	}
	shown := map[int][]engine.Card{}
	var events []engine.Event
	for _, e := range h.Events() {
		switch e.Kind {
		case engine.EvHole:
			if e.Seat != v.YourSeat {
				continue // another player's cards: never sent
			}
		case engine.EvShow:
			shown[e.Seat] = e.Cards
		}
		events = append(events, e)
	}
	for _, p := range h.Players() {
		sv := v.Seats[p.Seat]
		if sv == nil || sv.User != s.userOf(p.Seat) {
			continue // seat changed hands after its player left
		}
		sv.InHand, sv.Folded, sv.AllIn, sv.Bet = true, p.Folded, p.AllIn, p.Bet
		sv.Stack = p.Stack
		sv.HasCards = !p.Folded
		switch {
		case p.Seat == v.YourSeat:
			sv.Cards = p.Hole
		case shown[p.Seat] != nil:
			sv.Cards = shown[p.Seat]
		}
	}
	hv := &HandView{Street: h.Street().String(), Board: h.Board(), Pots: h.Pots(), Button: s.Pos.Button,
		SB: s.Pos.SB, BB: s.Pos.BB, ToAct: h.ToAct(), Deadline: s.Deadline, CurrentBet: h.CurrentBet(),
		Events: events, Results: h.Results(), Done: h.Done()}
	if s.Pos.SBDead {
		hv.SB = -1
	}
	if l, ok := h.Legal(); ok && l.Seat == v.YourSeat && v.YourSeat >= 0 {
		hv.Legal = &l
	}
	v.Hand = hv
	return v
}

// userOf is the user dealt into seat in the current hand.
func (s State) userOf(seat int) string {
	if s.HandUsers == nil {
		return ""
	}
	return s.HandUsers[seat]
}
