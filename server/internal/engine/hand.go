package engine

import (
	"errors"
	"fmt"
	"slices"
)

// Street of a hand.
type Street uint8

const (
	Preflop Street = iota
	Flop
	Turn
	River
	Showdown // cards are being compared, the hand is over
)

var streetNames = [...]string{"preflop", "flop", "turn", "river", "showdown"}

func (s Street) String() string {
	if int(s) < len(streetNames) {
		return streetNames[s]
	}
	return "unknown"
}

// ActionKind is what a player does on their turn.
type ActionKind uint8

const (
	Fold ActionKind = iota + 1
	Check
	Call
	Bet   // first bet of a street, To is the street total
	Raise // raise, To is the street total
)

var actionNames = [...]string{"", "fold", "check", "call", "bet", "raise"}

func (k ActionKind) String() string {
	if int(k) < len(actionNames) {
		return actionNames[k]
	}
	return "unknown"
}

// Action is one player intent. To is used by Bet and Raise only and is the
// player's total for this street (raise "to", not "by").
type Action struct {
	Kind ActionKind `json:"kind"`
	To   int64      `json:"to,omitempty"`
}

// Errors returned by Act. An error never changes the hand.
var (
	ErrHandOver    = errors.New("engine: hand is over")
	ErrNotYourTurn = errors.New("engine: not your turn")
	ErrIllegal     = errors.New("engine: action not allowed now")
	ErrAmount      = errors.New("engine: bet amount out of range")
)

// Player is one seat dealt into the hand.
type Player struct {
	Seat      int    `json:"seat"`
	Stack     int64  `json:"stack"`     // chips behind
	Bet       int64  `json:"bet"`       // chips put in on this street
	Committed int64  `json:"committed"` // chips put in during the whole hand
	Hole      []Card `json:"-"`
	Folded    bool   `json:"folded,omitempty"`
	AllIn     bool   `json:"all_in,omitempty"`

	start    int64 // stack when the hand started
	needsAct bool  // has to act before the street ends
	acted    bool  // acted on this street
	facedAt  int64 // street bet level when this player last acted
}

// Start is the stack the player had when the hand began.
func (p *Player) Start() int64 { return p.start }

// EventKind names a hand history entry.
type EventKind string

const (
	EvPostSB EventKind = "post_sb"
	EvPostBB EventKind = "post_bb"
	EvHole   EventKind = "hole" // private: only the owner may see Cards
	EvFold   EventKind = "fold"
	EvCheck  EventKind = "check"
	EvCall   EventKind = "call"
	EvBet    EventKind = "bet"
	EvRaise  EventKind = "raise"
	EvReturn EventKind = "return" // uncalled bet given back
	EvBoard  EventKind = "board"
	EvShow   EventKind = "show"
	EvWin    EventKind = "win"
)

// Event is one entry of the hand history. Amount is the chips moved (for
// bets and raises the street total), Pot the pot index for wins.
type Event struct {
	Kind   EventKind `json:"kind"`
	Seat   int       `json:"seat"`
	Street Street    `json:"street"`
	Amount int64     `json:"amount,omitempty"`
	AllIn  bool      `json:"all_in,omitempty"`
	Cards  []Card    `json:"cards,omitempty"`
	Pot    int       `json:"pot,omitempty"`
	Value  Value     `json:"value,omitempty"`
}

// Seat is a player taking part in a new hand.
type Seat struct {
	Seat  int
	Stack int64
}

// Config starts a hand.
type Config struct {
	Rules      Rules // nil means NoLimitHoldem
	Seats      []Seat
	Positions  Positions
	SmallBlind int64
	BigBlind   int64
}

// Pot is a main or side pot: its chips and the seats that can win it.
type Pot struct {
	Amount   int64 `json:"amount"`
	Eligible []int `json:"eligible"`
}

// PotResult is how one pot was split.
type PotResult struct {
	Pot
	Winners []int   `json:"winners"`
	Shares  []int64 `json:"shares"`
	Value   Value   `json:"value,omitempty"` // 0 when nobody had to show
}

// Hand is one hand of poker. It is not safe for concurrent use: the table
// actor owns it.
type Hand struct {
	rules   Rules
	cfg     Config
	deck    *Deck
	dealt   []Card
	players []*Player // clockwise from the first seat left of the button
	board   []Card
	street  Street
	toAct   int // index into players, -1 when nobody
	curBet  int64
	minRais int64 // size of the last full bet or raise on this street
	aggr    int   // index of the last bettor/raiser on this street, -1
	lastAgg int   // aggressor of the last street that had a bet, -1
	events  []Event
	results []PotResult
	shown   []int // seats in showdown order
	done    bool
}

// NewHand posts the blinds, deals the hole cards and waits for the first
// action. deck nil means a fresh crypto/rand shuffle.
func NewHand(cfg Config, deck *Deck) (*Hand, error) {
	if cfg.Rules == nil {
		cfg.Rules = NoLimitHoldem{}
	}
	if len(cfg.Seats) < 2 {
		return nil, errors.New("engine: a hand needs two players")
	}
	if cfg.BigBlind <= 0 || cfg.SmallBlind < 0 || cfg.SmallBlind > cfg.BigBlind {
		return nil, errors.New("engine: bad blinds")
	}
	if deck == nil {
		deck = NewDeck(CryptoShuffler())
	}
	seen := map[int]bool{}
	seats := make([]int, 0, len(cfg.Seats))
	for _, s := range cfg.Seats {
		if s.Stack <= 0 || s.Seat < 0 || s.Seat >= circ || seen[s.Seat] {
			return nil, fmt.Errorf("engine: bad seat %d", s.Seat)
		}
		seen[s.Seat] = true
		seats = append(seats, s.Seat)
	}
	pos := cfg.Positions
	if !seen[pos.BB] || (!pos.SBDead && !seen[pos.SB]) || pos.SB == pos.BB {
		return nil, errors.New("engine: blind seats are not in the hand")
	}
	h := &Hand{rules: cfg.Rules, cfg: cfg, deck: deck, toAct: -1, aggr: -1, lastAgg: -1}
	order := slices.Clone(cfg.Seats)
	slices.SortFunc(order, func(a, b Seat) int {
		da, db := clockwise(pos.Button, a.Seat), clockwise(pos.Button, b.Seat)
		if da == 0 {
			da = circ
		}
		if db == 0 {
			db = circ
		}
		return da - db
	})
	for _, s := range order {
		h.players = append(h.players, &Player{Seat: s.Seat, Stack: s.Stack, start: s.Stack})
	}
	if !pos.SBDead {
		h.post(h.bySeat(pos.SB), cfg.SmallBlind, EvPostSB)
	}
	h.post(h.bySeat(pos.BB), cfg.BigBlind, EvPostBB)
	h.curBet = cfg.BigBlind
	h.minRais = cfg.BigBlind
	n := cfg.Rules.HoleCards()
	for range n {
		for _, p := range h.players {
			p.Hole = append(p.Hole, h.deal())
		}
	}
	for _, p := range h.players {
		h.events = append(h.events, Event{Kind: EvHole, Seat: p.Seat, Cards: slices.Clone(p.Hole)})
	}
	h.startRound(nextSeat(seats, pos.BB))
	return h, nil
}

func (h *Hand) deal() Card {
	c := h.deck.Deal()
	h.dealt = append(h.dealt, c)
	return c
}

func (h *Hand) bySeat(seat int) *Player {
	for _, p := range h.players {
		if p.Seat == seat {
			return p
		}
	}
	return nil
}

func (h *Hand) index(seat int) int {
	for i, p := range h.players {
		if p.Seat == seat {
			return i
		}
	}
	return -1
}

func (h *Hand) post(p *Player, amount int64, kind EventKind) {
	amount = min(amount, p.Stack)
	h.put(p, amount)
	h.events = append(h.events, Event{Kind: kind, Seat: p.Seat, Street: Preflop, Amount: amount, AllIn: p.AllIn})
}

// put moves chips from the stack to the street bet.
func (h *Hand) put(p *Player, amount int64) {
	p.Stack -= amount
	p.Bet += amount
	p.Committed += amount
	if p.Stack == 0 {
		p.AllIn = true
	}
}

// startRound opens a betting round; first is the seat that acts first if it
// can act, else the next one clockwise that can.
func (h *Hand) startRound(firstSeat int) {
	for _, p := range h.players {
		p.acted = false
		p.facedAt = 0
		p.needsAct = !p.Folded && !p.AllIn
	}
	// Nobody has to act when at most one player can still bet and that one
	// already matches the bet.
	canAct := 0
	for _, p := range h.players {
		if p.needsAct {
			canAct++
		}
	}
	if canAct <= 1 {
		for _, p := range h.players {
			if p.needsAct && p.Bet >= h.curBet {
				p.needsAct = false
			}
		}
	}
	h.toAct = h.nextToAct(h.index(firstSeat) - 1)
	if h.toAct < 0 {
		h.endRound()
	}
}

// nextToAct is the first player after index i (clockwise) who must act.
func (h *Hand) nextToAct(i int) int {
	n := len(h.players)
	for k := 1; k <= n; k++ {
		j := ((i+k)%n + n) % n
		if h.players[j].needsAct {
			return j
		}
	}
	return -1
}

// Legal describes what the player to act may do.
type Legal struct {
	Seat    int        `json:"seat"`
	Fold    bool       `json:"fold"`
	Check   bool       `json:"check"`
	Call    int64      `json:"call,omitempty"`     // chips to call, 0 = no call
	BetKind ActionKind `json:"bet_kind,omitempty"` // Bet or Raise, 0 = no bet
	MinTo   int64      `json:"min_to,omitempty"`
	MaxTo   int64      `json:"max_to,omitempty"`
}

// ToAct is the seat whose turn it is, -1 when nobody's.
func (h *Hand) ToAct() int {
	if h.toAct < 0 {
		return -1
	}
	return h.players[h.toAct].Seat
}

// Legal returns the legal actions of the player to act (ok false when the
// hand waits for nobody).
func (h *Hand) Legal() (Legal, bool) {
	if h.done || h.toAct < 0 {
		return Legal{}, false
	}
	p := h.players[h.toAct]
	l := Legal{Seat: p.Seat, Fold: true}
	toCall := h.curBet - p.Bet
	if toCall <= 0 {
		l.Check = true
	} else {
		l.Call = min(toCall, p.Stack)
	}
	if p.Stack <= toCall || !h.canRaise(p) {
		return l, true
	}
	others := 0
	for _, q := range h.players {
		if q != p && !q.Folded && !q.AllIn {
			others++
		}
	}
	if others == 0 {
		return l, true // everybody else is all-in: nobody to bet against
	}
	maxTo := min(h.rules.MaxBetTo(h, p), p.Bet+p.Stack)
	minTo := h.curBet + h.minRais
	if minTo > maxTo {
		minTo = maxTo // all-in for less than a full raise
	}
	if maxTo <= h.curBet {
		return l, true
	}
	l.BetKind = Raise
	if h.curBet == 0 {
		l.BetKind = Bet
	}
	l.MinTo, l.MaxTo = minTo, maxTo
	return l, true
}

// canRaise: a player who already acted on this street may raise again only
// when the bet grew by at least a full raise since; an all-in for less than a
// full raise does not reopen the betting (several of them adding up to a full
// raise do).
func (h *Hand) canRaise(p *Player) bool {
	return !p.acted || h.curBet-p.facedAt >= h.minRais
}

// Act applies the intent of the player in seat. Any error leaves the hand
// unchanged.
func (h *Hand) Act(seat int, a Action) error {
	if h.done {
		return ErrHandOver
	}
	if h.toAct < 0 || h.players[h.toAct].Seat != seat {
		return ErrNotYourTurn
	}
	l, _ := h.Legal()
	p := h.players[h.toAct]
	ev := Event{Seat: seat, Street: h.street}
	switch a.Kind {
	case Fold:
		p.Folded = true
		ev.Kind = EvFold
	case Check:
		if !l.Check {
			return ErrIllegal
		}
		ev.Kind = EvCheck
	case Call:
		if l.Call == 0 {
			return ErrIllegal
		}
		h.put(p, l.Call)
		ev.Kind, ev.Amount = EvCall, l.Call
	case Bet, Raise:
		if l.BetKind != a.Kind {
			return ErrIllegal
		}
		if a.To < l.MinTo || a.To > l.MaxTo {
			return ErrAmount
		}
		by := a.To - h.curBet
		h.put(p, a.To-p.Bet)
		if by >= h.minRais {
			h.minRais = by // full raise: sets the new minimum
		}
		h.curBet = a.To
		h.aggr = h.toAct
		for _, q := range h.players {
			if q != p && !q.Folded && !q.AllIn {
				q.needsAct = true
			}
		}
		ev.Kind, ev.Amount = EvBet, a.To
		if a.Kind == Raise {
			ev.Kind = EvRaise
		}
	default:
		return ErrIllegal
	}
	ev.AllIn = p.AllIn
	h.events = append(h.events, ev)
	p.acted = true
	p.facedAt = h.curBet
	p.needsAct = false

	if h.live() == 1 {
		h.toAct = -1
		h.endRound() // returns an uncalled bet, then pays the last player
		return nil
	}
	h.toAct = h.nextToAct(h.toAct)
	if h.toAct < 0 {
		h.endRound()
	}
	return nil
}

// live counts players who have not folded.
func (h *Hand) live() int {
	n := 0
	for _, p := range h.players {
		if !p.Folded {
			n++
		}
	}
	return n
}

// endRound closes the betting round: returns an uncalled bet, then deals the
// next street or goes to showdown.
func (h *Hand) endRound() {
	h.returnUncalled()
	if h.aggr >= 0 {
		h.lastAgg = h.aggr
	}
	for _, p := range h.players {
		p.Bet = 0
	}
	h.curBet = 0
	h.minRais = h.cfg.BigBlind
	h.aggr = -1
	if h.live() == 1 || h.street == River {
		h.finish()
		return
	}
	h.street++
	cards := 3
	if h.street != Flop {
		cards = 1
	}
	var dealtNow []Card
	for range cards {
		c := h.deal()
		h.board = append(h.board, c)
		dealtNow = append(dealtNow, c)
	}
	h.events = append(h.events, Event{Kind: EvBoard, Seat: -1, Street: h.street, Cards: dealtNow})
	h.startRound(nextSeat(h.liveSeats(), h.cfg.Positions.Button))
}

func (h *Hand) liveSeats() []int {
	var s []int
	for _, p := range h.players {
		if !p.Folded {
			s = append(s, p.Seat)
		}
	}
	return s
}

// returnUncalled gives back the part of the highest street bet that nobody
// matched.
func (h *Hand) returnUncalled() {
	var top, second *Player
	for _, p := range h.players {
		if top == nil || p.Bet > top.Bet {
			top, second = p, top
		} else if second == nil || p.Bet > second.Bet {
			second = p
		}
	}
	if top == nil || second == nil || top.Bet <= second.Bet {
		return
	}
	back := top.Bet - second.Bet
	top.Bet -= back
	top.Committed -= back
	top.Stack += back
	if top.Stack > 0 {
		top.AllIn = false
	}
	h.events = append(h.events, Event{Kind: EvReturn, Seat: top.Seat, Street: h.street, Amount: back})
}

// Pots returns the pots built from the chips of finished streets (the bets
// of the current street are still in front of the players).
func (h *Hand) Pots() []Pot {
	amounts := make([]int64, len(h.players))
	for i, p := range h.players {
		amounts[i] = p.Committed - p.Bet
	}
	return h.buildPots(amounts)
}

// buildPots slices the committed chips into a main pot and side pots. Each
// all-in level of a live player closes a pot; folded players' chips go in but
// they are not eligible. Pots with the same eligible seats are merged.
func (h *Hand) buildPots(amounts []int64) []Pot {
	var levels []int64
	for i, p := range h.players {
		if amounts[i] > 0 && !p.Folded {
			levels = append(levels, amounts[i])
		}
	}
	slices.Sort(levels)
	levels = slices.Compact(levels)
	var pots []Pot
	prev := int64(0)
	for li, lv := range levels {
		if li == len(levels)-1 {
			lv = 1 << 62 // the top pot takes everything above, folded chips too
		}
		pot := Pot{}
		for i, p := range h.players {
			c := amounts[i]
			pot.Amount += min(c, lv) - min(c, prev)
			if !p.Folded && c >= min(lv, levels[len(levels)-1]) {
				pot.Eligible = append(pot.Eligible, p.Seat)
			}
		}
		prev = lv
		if pot.Amount == 0 {
			continue
		}
		if n := len(pots); n > 0 && slices.Equal(pots[n-1].Eligible, pot.Eligible) {
			pots[n-1].Amount += pot.Amount
			continue
		}
		pots = append(pots, pot)
	}
	if len(levels) == 0 { // only possible before anyone put chips in
		return nil
	}
	return pots
}

// finish runs out the board when needed, shows the cards and pays the pots.
func (h *Hand) finish() {
	h.toAct = -1
	amounts := make([]int64, len(h.players))
	for i, p := range h.players {
		amounts[i] = p.Committed
	}
	pots := h.buildPots(amounts)
	if h.live() == 1 {
		w := h.players[slices.IndexFunc(h.players, func(p *Player) bool { return !p.Folded })]
		for i, pot := range pots {
			w.Stack += pot.Amount
			h.results = append(h.results, PotResult{Pot: pot, Winners: []int{w.Seat}, Shares: []int64{pot.Amount}})
			h.events = append(h.events, Event{Kind: EvWin, Seat: w.Seat, Street: h.street, Amount: pot.Amount, Pot: i})
		}
		h.done = true
		return
	}
	for len(h.board) < 5 {
		var now []Card
		k := 3
		if len(h.board) >= 3 {
			k = 1
		}
		for range k {
			c := h.deal()
			h.board = append(h.board, c)
			now = append(now, c)
		}
		if h.street < River {
			h.street++
		}
		h.events = append(h.events, Event{Kind: EvBoard, Seat: -1, Street: h.street, Cards: now})
	}
	h.street = Showdown
	values := map[int]Value{}
	for _, seat := range h.showOrder() {
		p := h.bySeat(seat)
		v := h.rules.Best(p.Hole, h.board)
		values[seat] = v
		h.shown = append(h.shown, seat)
		h.events = append(h.events, Event{Kind: EvShow, Seat: seat, Street: Showdown, Cards: slices.Clone(p.Hole), Value: v})
	}
	for i, pot := range pots {
		var best Value
		var winners []int
		for _, s := range pot.Eligible {
			switch v := values[s]; {
			case v > best:
				best, winners = v, []int{s}
			case v == best:
				winners = append(winners, s)
			}
		}
		// winners are in clockwise order from the first seat left of the
		// button (pot.Eligible follows h.players), so the odd chips go there first
		share := pot.Amount / int64(len(winners))
		odd := pot.Amount % int64(len(winners))
		res := PotResult{Pot: pot, Winners: winners, Value: best}
		for k, s := range winners {
			amt := share
			if int64(k) < odd {
				amt++
			}
			h.bySeat(s).Stack += amt
			res.Shares = append(res.Shares, amt)
			h.events = append(h.events, Event{Kind: EvWin, Seat: s, Street: Showdown, Amount: amt, Pot: i, Value: best})
		}
		h.results = append(h.results, res)
	}
	h.done = true
}

// showOrder: the last bettor of the final betting round shows first, then
// clockwise; with no bet, the first live seat left of the button starts.
func (h *Hand) showOrder() []int {
	start := 0
	if h.lastAgg >= 0 && !h.players[h.lastAgg].Folded {
		start = h.lastAgg
	}
	var out []int
	n := len(h.players)
	for k := range n {
		p := h.players[(start+k)%n]
		if !p.Folded {
			out = append(out, p.Seat)
		}
	}
	return out
}

// Done reports whether the hand is over.
func (h *Hand) Done() bool { return h.done }

// Street is the current street (Showdown once cards were compared).
func (h *Hand) Street() Street { return h.street }

// Board is the community cards dealt so far.
func (h *Hand) Board() []Card { return slices.Clone(h.board) }

// Players are the seats in the hand, clockwise from the first seat left of
// the button. The returned values are copies.
func (h *Hand) Players() []Player {
	out := make([]Player, len(h.players))
	for i, p := range h.players {
		out[i] = *p
		out[i].Hole = slices.Clone(p.Hole)
	}
	return out
}

// CurrentBet is the highest street total so far.
func (h *Hand) CurrentBet() int64 { return h.curBet }

// Events is the hand history so far (EvHole entries are private).
func (h *Hand) Events() []Event { return slices.Clone(h.events) }

// Results is how the pots were paid, set when the hand is done.
func (h *Hand) Results() []PotResult { return slices.Clone(h.results) }

// Shown is the seats that showed their cards, in showdown order.
func (h *Hand) Shown() []int { return slices.Clone(h.shown) }

// Dealt is every card dealt in order; DeckFrom(Dealt()) replays the hand.
func (h *Hand) Dealt() []Card { return slices.Clone(h.dealt) }

// PotTotal is every chip in the middle including current street bets.
func (h *Hand) PotTotal() int64 {
	var t int64
	for _, p := range h.players {
		t += p.Committed
	}
	return t
}
