// Package table runs cash game tables. Each table is an actor: one goroutine
// owns all of its state and every change goes through it, so a table never
// needs locks and hands are played strictly in order.
package table

import (
	"encoding/json"
	"errors"
	"fmt"
	"maps"
	"slices"
	"sync"
	"time"

	"github.com/oxisoft/oxipoker/server/internal/engine"
)

// Settings chosen by the host when the table is created.
type Settings struct {
	Name          string        `json:"name"`
	Seats         int           `json:"seats"` // 2..9
	SmallBlind    int64         `json:"small_blind"`
	BigBlind      int64         `json:"big_blind"`
	StartingStack int64         `json:"starting_stack"`
	TurnTime      time.Duration `json:"turn_time"`
	Spectators    bool          `json:"spectators"`
	// Kind is KindCash (default) or KindSng; Structure names the blind
	// structure of a sit-and-go (see Structures).
	Kind      string `json:"kind"`
	Structure string `json:"structure,omitempty"`
}

// MarshalJSON sends the turn time in whole seconds.
func (s Settings) MarshalJSON() ([]byte, error) {
	type plain Settings
	return json.Marshal(struct {
		plain
		TurnTime int64 `json:"turn_time"`
	}{plain(s), int64(s.TurnTime / time.Second)})
}

// Limits of the table settings.
const (
	MinSeats    = 2
	MaxSeats    = 9
	MinTurnTime = 5 * time.Second
	MaxTurnTime = 5 * time.Minute
	MaxChips    = 1_000_000_000
)

// Validate checks the settings. Turn time limits are not checked here so
// tests can run with short timers; the API applies them.
func (s Settings) Validate() error {
	switch {
	case s.Seats < MinSeats || s.Seats > MaxSeats:
		return fmt.Errorf("seats must be %d to %d", MinSeats, MaxSeats)
	case s.BigBlind < 1 || s.SmallBlind < 0 || s.SmallBlind > s.BigBlind:
		return errors.New("blinds: big blind at least 1, small blind not above it")
	case s.StartingStack < s.BigBlind*2 || s.StartingStack > MaxChips:
		return errors.New("starting stack must be at least two big blinds")
	case s.TurnTime <= 0:
		return errors.New("turn time must be positive")
	case s.Kind != "" && s.Kind != KindCash && s.Kind != KindSng:
		return errors.New("kind must be cash or sng")
	case s.Kind == KindSng && Structures[s.Structure].LevelTime == 0:
		return ErrNoStructure
	case s.Kind != KindSng && s.Structure != "":
		return errors.New("a blind structure is only for a sit-and-go")
	}
	return nil
}

// Errors of table commands.
var (
	ErrClosed    = errors.New("table is closed")
	ErrSeatTaken = errors.New("seat is taken")
	ErrBadSeat   = errors.New("no such seat")
	ErrSeated    = errors.New("already seated at this table")
	ErrNotSeated = errors.New("not seated at this table")
	ErrNotInHand = errors.New("not in the current hand")
)

// Player is someone sitting at the table.
type Player struct {
	User       string `json:"user"`
	Name       string `json:"name"`
	Stack      int64  `json:"stack"`
	SittingOut bool   `json:"sitting_out,omitempty"`
	Missed     int    `json:"-"` // turns timed out in a row
	Leaving    bool   `json:"-"` // leaves when the current hand ends
}

// State is a snapshot of the whole table, hidden cards included. It never
// leaves the server as is: the realtime layer builds per-viewer views from it.
type State struct {
	ID       string       `json:"id"`
	Host     string       `json:"host"`
	Settings Settings     `json:"settings"`
	Seats    []*Player    `json:"seats"` // index = seat number, nil = empty
	Hand     *engine.Hand `json:"-"`
	// HandUsers is the user dealt into each seat of Hand.
	HandUsers map[int]string    `json:"-"`
	HandNo    int               `json:"hand_no"`
	Pos       *engine.Positions `json:"positions,omitempty"`
	Deadline  time.Time         `json:"deadline,omitzero"` // turn timer of the player to act
	Version   uint64            `json:"version"`
	Closed    bool              `json:"closed,omitempty"`
	Sng       *Sng              `json:"sng,omitempty"` // only on sit-and-go tables
}

// HandDone is passed to the OnHandDone hook when a hand is over.
type HandDone struct {
	TableID   string
	TableName string
	HandNo    int
	Hand      *engine.Hand
	Users     map[int]string // seat -> user at the time of the hand
	Names     map[int]string // seat -> display name
	Config    engine.Config
}

// Options tune a table; zero values are production defaults.
type Options struct {
	// Pause between two hands so players can see the result.
	Pause time.Duration
	// StartDelay before the first hand once two players are ready, so
	// others can still sit down.
	StartDelay time.Duration
	// Deck for each hand; nil = crypto/rand shuffle.
	Deck func() *engine.Deck
	// OnChange is called after every change, from the table goroutine. It
	// must not block or call back into the table.
	OnChange func(State)
	// OnHandDone is called when a hand is finished, from the table goroutine.
	OnHandDone func(HandDone)
	// OnGameDone is called when a sit-and-go has its winner, from the table
	// goroutine.
	OnGameDone func(GameDone)
	// LevelTime overrides the blind level length of a sit-and-go (tests).
	LevelTime time.Duration
	// OnSave gets the stored form of the table after every change between
	// hands, when the table closes (Saved.Closed) and on Stop. It is called
	// from the table goroutine and must not block.
	OnSave func(Saved)
}

// Table is the handle to a running table actor.
type Table struct {
	id    string
	cmds  chan func(*actor)
	done  chan struct{}
	close sync.Once
}

type actor struct {
	st        State
	opt       Options
	turnTimer *time.Timer
	nextHand  *time.Timer
	timerGen  uint64 // invalidates timers that fired after the turn moved on
	cfg       engine.Config
	users     map[int]string
	t         *Table
	created   time.Time
	prevPos   *engine.Positions // positions before the running hand
	halt      bool              // stopped for a shutdown
}

// New starts a table. host is the user who created it.
func New(id, host string, s Settings, opt Options) (*Table, error) {
	if err := s.Validate(); err != nil {
		return nil, err
	}
	t, a := newActor(id, host, s, opt)
	if s.Kind == KindSng {
		a.st.Sng = &Sng{Phase: PhaseRegistering, Places: []Place{}}
		a.st.Sng.SmallBlind, a.st.Sng.BigBlind = s.SmallBlind, s.BigBlind
	}
	go a.run()
	return t, nil
}

func newActor(id, host string, s Settings, opt Options) (*Table, *actor) {
	if opt.Pause == 0 {
		opt.Pause = 4 * time.Second
	}
	if opt.StartDelay == 0 {
		opt.StartDelay = 3 * time.Second
	}
	if s.Kind == "" {
		s.Kind = KindCash
	}
	t := &Table{id: id, cmds: make(chan func(*actor), 64), done: make(chan struct{})}
	a := &actor{st: State{ID: id, Host: host, Settings: s, Seats: make([]*Player, s.Seats)}, opt: opt, t: t,
		created: time.Now()}
	return t, a
}

// ID of the table.
func (t *Table) ID() string { return t.id }

func (a *actor) run() {
	defer close(a.t.done)
	for f := range a.t.cmds {
		f(a)
		if a.st.Closed || a.halt {
			a.stopTimers()
			return
		}
	}
}

// do runs f inside the table goroutine and waits for its result.
func (t *Table) do(f func(a *actor) error) error {
	res := make(chan error, 1)
	select {
	case t.cmds <- func(a *actor) { res <- f(a) }:
	case <-t.done:
		return ErrClosed
	}
	select {
	case err := <-res:
		return err
	case <-t.done:
		return ErrClosed
	}
}

// post queues f without waiting (timers use it).
func (t *Table) post(f func(a *actor)) {
	select {
	case t.cmds <- f:
	case <-t.done:
	}
}

// Snapshot returns a deep copy of the state, the hand included.
func (t *Table) Snapshot() (State, error) {
	var s State
	err := t.do(func(a *actor) error { s = a.snapshot(); return nil })
	return s, err
}

func (a *actor) snapshot() State {
	s := a.st
	s.Seats = make([]*Player, len(a.st.Seats))
	for i, p := range a.st.Seats {
		if p != nil {
			c := *p
			s.Seats[i] = &c
		}
	}
	if a.st.Hand != nil {
		s.Hand = a.st.Hand.Clone()
		s.HandUsers = maps.Clone(a.users)
	}
	if a.st.Pos != nil {
		p := *a.st.Pos
		s.Pos = &p
	}
	s.Sng = a.st.Sng.clone()
	return s
}

func (a *actor) changed() {
	a.st.Version++
	if a.opt.OnChange != nil {
		a.opt.OnChange(a.snapshot())
	}
	a.save()
}

func (a *actor) seatOf(user string) int {
	return slices.IndexFunc(a.st.Seats, func(p *Player) bool { return p != nil && p.User == user })
}

// Sit takes an empty seat with the table's starting stack.
func (t *Table) Sit(user, name string, seat int) error {
	return t.do(func(a *actor) error {
		if seat < 0 || seat >= len(a.st.Seats) {
			return ErrBadSeat
		}
		if a.seatOf(user) >= 0 {
			return ErrSeated
		}
		if a.st.Seats[seat] != nil {
			return ErrSeatTaken
		}
		if a.isSng() && a.st.Sng.Phase != PhaseRegistering {
			return ErrStarted
		}
		a.st.Seats[seat] = &Player{User: user, Name: name, Stack: a.st.Settings.StartingStack}
		if a.isSng() && a.seated() == len(a.st.Seats) {
			a.startSng() // every seat taken
			return nil
		}
		a.changed()
		a.maybeStart()
		return nil
	})
}

// SitOut keeps the seat but skips the player's hands. In a running hand the
// player folds (or checks) when the turn comes.
func (t *Table) SitOut(user string) error {
	return t.do(func(a *actor) error {
		i := a.seatOf(user)
		if i < 0 {
			return ErrNotSeated
		}
		a.st.Seats[i].SittingOut = true
		a.changed()
		a.autoActIfTurn(i)
		return nil
	})
}

// ComeBack ends sitting out; a player with no chips buys in again with the
// starting stack.
func (t *Table) ComeBack(user string) error {
	return t.do(func(a *actor) error {
		i := a.seatOf(user)
		if i < 0 {
			return ErrNotSeated
		}
		p := a.st.Seats[i]
		p.SittingOut, p.Missed = false, 0
		if p.Stack == 0 && !a.inHand(i) && !a.isSng() {
			p.Stack = a.st.Settings.StartingStack
		}
		a.changed()
		a.maybeStart()
		return nil
	})
}

// Leave gives up the seat. In a running hand the player folds and the seat
// is freed when the hand ends.
func (t *Table) Leave(user string) error {
	return t.do(func(a *actor) error {
		i := a.seatOf(user)
		if i < 0 {
			return ErrNotSeated
		}
		if a.isSng() && a.st.Sng.Phase == PhaseRunning {
			// A running sit-and-go keeps the seat: the player is blinded
			// out (posts blinds, folds) so the game always ends.
			a.st.Seats[i].SittingOut = true
			a.changed()
			a.autoActIfTurn(i)
			return nil
		}
		if a.inHand(i) {
			a.st.Seats[i].Leaving = true
			a.st.Seats[i].SittingOut = true
			a.changed()
			a.autoActIfTurn(i)
			return nil
		}
		a.st.Seats[i] = nil
		a.changed()
		return nil
	})
}

// Act applies a player's betting action to the current hand.
func (t *Table) Act(user string, act engine.Action) error {
	return t.do(func(a *actor) error {
		i := a.seatOf(user)
		if i < 0 {
			return ErrNotSeated
		}
		if !a.inHand(i) {
			return ErrNotInHand
		}
		if err := a.st.Hand.Act(i, act); err != nil {
			return err
		}
		a.st.Seats[i].Missed = 0
		a.afterAction()
		return nil
	})
}

// Close stops the table; a running hand is abandoned and every stack stays
// as it was before that hand.
func (t *Table) Close() {
	t.close.Do(func() {
		_ = t.do(func(a *actor) error {
			a.st.Closed = true
			if h := a.st.Hand; h != nil && !h.Done() {
				for _, s := range a.cfg.Seats {
					if p := a.st.Seats[s.Seat]; p != nil && p.User == a.users[s.Seat] {
						p.Stack = s.Stack
					}
				}
			}
			a.st.Hand = nil
			a.changed()
			return nil
		})
	})
}

// Done is closed when the table goroutine has stopped.
func (t *Table) Done() <-chan struct{} { return t.done }

// inHand reports whether seat i holds live cards in the running hand.
func (a *actor) inHand(i int) bool {
	h := a.st.Hand
	if h == nil || h.Done() {
		return false
	}
	for _, p := range h.Players() {
		if p.Seat == i {
			return !p.Folded
		}
	}
	return false
}

func (a *actor) stopTimers() {
	a.timerGen++
	if a.turnTimer != nil {
		a.turnTimer.Stop()
	}
	if a.nextHand != nil {
		a.nextHand.Stop()
	}
}

// ready lists the seats that will be dealt into the next hand.
func (a *actor) ready() []int {
	var s []int
	sng := a.isSng()
	if sng && a.st.Sng.Phase != PhaseRunning {
		return nil
	}
	for i, p := range a.st.Seats {
		if p != nil && (sng || !p.SittingOut) && !p.Leaving && p.Stack > 0 {
			s = append(s, i)
		}
	}
	return s
}

// maybeStart schedules a new hand when none runs or is scheduled and two
// players are ready.
func (a *actor) maybeStart() {
	if a.st.Hand != nil || a.nextHand != nil || len(a.ready()) < 2 {
		return
	}
	gen := a.timerGen
	a.nextHand = time.AfterFunc(a.opt.StartDelay, func() {
		a.t.post(func(a *actor) {
			if a.timerGen != gen {
				return
			}
			a.nextHand = nil
			a.startHand()
		})
	})
}

func (a *actor) startHand() {
	active := a.ready()
	if len(active) < 2 {
		return
	}
	pos, err := engine.NextPositions(active, a.st.Pos)
	if err != nil {
		return
	}
	cfg := engine.Config{SmallBlind: a.st.Settings.SmallBlind, BigBlind: a.st.Settings.BigBlind, Positions: pos}
	if a.isSng() {
		a.advanceClock(time.Now())
		cfg.SmallBlind, cfg.BigBlind = a.st.Sng.SmallBlind, a.st.Sng.BigBlind
	}
	a.users = map[int]string{}
	for _, i := range active {
		cfg.Seats = append(cfg.Seats, engine.Seat{Seat: i, Stack: a.st.Seats[i].Stack})
		a.users[i] = a.st.Seats[i].User
	}
	var deck *engine.Deck
	if a.opt.Deck != nil {
		deck = a.opt.Deck()
	}
	h, err := engine.NewHand(cfg, deck)
	if err != nil {
		return
	}
	a.cfg = cfg
	a.prevPos = a.st.Pos
	a.st.Hand, a.st.Pos = h, &pos
	a.st.HandNo++
	a.afterAction()
}

// afterAction syncs stacks, restarts the turn timer and ends the hand when
// it is over.
func (a *actor) afterAction() {
	h := a.st.Hand
	for _, p := range h.Players() {
		if s := a.st.Seats[p.Seat]; s != nil && s.User == a.users[p.Seat] {
			s.Stack = p.Stack
		}
	}
	a.timerGen++
	if a.turnTimer != nil {
		a.turnTimer.Stop()
		a.turnTimer = nil
	}
	a.st.Deadline = time.Time{}
	if h.Done() {
		a.endHand()
		return
	}
	seat := h.ToAct()
	if p := a.st.Seats[seat]; p != nil && p.SittingOut {
		a.changed()
		a.autoAct(seat)
		return
	}
	d := a.st.Settings.TurnTime
	a.st.Deadline = time.Now().Add(d)
	gen := a.timerGen
	a.turnTimer = time.AfterFunc(d, func() {
		a.t.post(func(a *actor) {
			if a.timerGen == gen {
				a.timeout(seat)
			}
		})
	})
	a.changed()
}

// timeout: check if possible, else fold; two missed turns in a row sit the
// player out.
func (a *actor) timeout(seat int) {
	if a.st.Hand == nil || a.st.Hand.ToAct() != seat {
		return
	}
	if p := a.st.Seats[seat]; p != nil {
		p.Missed++
		if p.Missed >= 2 {
			p.SittingOut = true
		}
	}
	a.autoAct(seat)
}

func (a *actor) autoActIfTurn(seat int) {
	if a.st.Hand != nil && !a.st.Hand.Done() && a.st.Hand.ToAct() == seat {
		a.autoAct(seat)
	}
}

func (a *actor) autoAct(seat int) {
	l, ok := a.st.Hand.Legal()
	if !ok || l.Seat != seat {
		return
	}
	act := engine.Action{Kind: engine.Fold}
	if l.Check {
		act.Kind = engine.Check
	}
	if err := a.st.Hand.Act(seat, act); err != nil {
		return
	}
	a.afterAction()
}

func (a *actor) endHand() {
	if a.opt.OnHandDone != nil {
		names := map[int]string{}
		for seat, u := range a.users {
			if p := a.st.Seats[seat]; p != nil && p.User == u {
				names[seat] = p.Name
			}
		}
		a.opt.OnHandDone(HandDone{TableID: a.st.ID, TableName: a.st.Settings.Name, HandNo: a.st.HandNo,
			Hand: a.st.Hand.Clone(), Users: maps.Clone(a.users), Names: names, Config: a.cfg})
	}
	for i, p := range a.st.Seats {
		if p == nil {
			continue
		}
		if p.Leaving {
			a.st.Seats[i] = nil
		} else if p.Stack == 0 && !a.isSng() {
			p.SittingOut = true // busted: comes back with a new buy-in
		}
	}
	if a.isSng() {
		a.eliminate()
		if a.st.Sng.Phase == PhaseFinished {
			a.changed() // the last hand stays on the table, no next hand
			return
		}
	}
	a.changed()
	gen := a.timerGen
	a.nextHand = time.AfterFunc(a.opt.Pause, func() {
		a.t.post(func(a *actor) {
			if a.timerGen != gen {
				return
			}
			a.nextHand = nil
			a.st.Hand = nil
			a.changed()
			a.startHand()
		})
	})
}
