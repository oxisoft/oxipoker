package table

import (
	"cmp"
	"errors"
	mathrand "math/rand/v2"
	"slices"
	"time"

	"github.com/oxisoft/oxipoker/server/internal/engine"
)

// Table kinds.
const (
	KindCash = "cash"
	KindSng  = "sng"
)

// Sit-and-go phases.
const (
	PhaseRegistering = "registering"
	PhaseRunning     = "running"
	PhaseFinished    = "finished"
)

// Errors of sit-and-go commands.
var (
	ErrNotSng      = errors.New("not a sit-and-go table")
	ErrStarted     = errors.New("the sit-and-go has started")
	ErrFewPlayers  = errors.New("a sit-and-go needs two players")
	ErrNoStructure = errors.New("unknown blind structure")
)

// Structure is a built-in blind structure: every level lasts LevelTime and
// multiplies the table's starting blinds by the level's factor.
type Structure struct {
	LevelTime time.Duration
}

// Structures are the presets a host picks from.
var Structures = map[string]Structure{
	"turbo":   {LevelTime: 3 * time.Minute},
	"regular": {LevelTime: 6 * time.Minute},
	"slow":    {LevelTime: 10 * time.Minute},
}

// levelFactors in tenths of the starting big blind: 1x, 1.5x, 2x, 3x ...
var levelFactors = []int64{10, 15, 20, 30, 40, 60, 80, 100, 150, 200, 300, 400, 600, 800, 1000,
	1500, 2000, 3000, 4000, 6000, 8000, 10000}

// Levels is the number of blind levels; the last one stays until the end.
var Levels = len(levelFactors)

// LevelBlinds are the blinds of level (0-based) for starting blinds sb/bb.
func LevelBlinds(level int, sb, bb int64) (int64, int64) {
	level = min(max(level, 0), len(levelFactors)-1)
	nbb := max(bb*levelFactors[level]/10, 1)
	nsb := sb * levelFactors[level] / 10
	if sb > 0 {
		nsb = max(nsb, 1)
	}
	return min(nsb, nbb), nbb
}

// Place is one finishing position of a sit-and-go.
type Place struct {
	Place int    `json:"place"`
	User  string `json:"user,omitempty"`
	Name  string `json:"name"`
}

// Sng is the sit-and-go part of a table's state.
type Sng struct {
	Phase      string    `json:"phase"`
	Level      int       `json:"level"` // 0-based
	SmallBlind int64     `json:"small_blind"`
	BigBlind   int64     `json:"big_blind"`
	NextSmall  int64     `json:"next_small_blind,omitempty"`
	NextBig    int64     `json:"next_big_blind,omitempty"`
	LevelEnds  time.Time `json:"level_ends,omitzero"` // zero on the last level
	Places     []Place   `json:"places"`              // best place first
	Started    time.Time `json:"started,omitzero"`
}

func (s *Sng) clone() *Sng {
	if s == nil {
		return nil
	}
	c := *s
	c.Places = slices.Clone(s.Places)
	return &c
}

// GameDone is passed to the OnGameDone hook when a sit-and-go has a winner.
type GameDone struct {
	TableID   string
	TableName string
	Started   time.Time
	Places    []Place // best place first
}

func (a *actor) isSng() bool { return a.st.Settings.Kind == KindSng }

func (a *actor) levelTime() time.Duration {
	if a.opt.LevelTime > 0 {
		return a.opt.LevelTime
	}
	return Structures[a.st.Settings.Structure].LevelTime
}

// setLevel sets the blinds of level and the next level.
func (a *actor) setLevel(level int, now time.Time) {
	g, s := a.st.Sng, a.st.Settings
	g.Level = min(level, Levels-1)
	g.SmallBlind, g.BigBlind = LevelBlinds(g.Level, s.SmallBlind, s.BigBlind)
	g.NextSmall, g.NextBig, g.LevelEnds = 0, 0, time.Time{}
	if g.Level < Levels-1 {
		g.NextSmall, g.NextBig = LevelBlinds(g.Level+1, s.SmallBlind, s.BigBlind)
		g.LevelEnds = now.Add(a.levelTime())
	}
}

// advanceClock moves to the next levels whose start time has passed. It is
// called only between hands: blinds never change inside a hand.
func (a *actor) advanceClock(now time.Time) {
	g := a.st.Sng
	for !g.LevelEnds.IsZero() && !now.Before(g.LevelEnds) {
		ends := g.LevelEnds
		a.setLevel(g.Level+1, ends)
	}
}

// Start begins a sit-and-go with the players seated now. Who may start
// (host or admin) is checked by the caller.
func (t *Table) Start() error {
	return t.do(func(a *actor) error {
		if !a.isSng() {
			return ErrNotSng
		}
		if a.st.Sng.Phase != PhaseRegistering {
			return ErrStarted
		}
		if a.seated() < 2 {
			return ErrFewPlayers
		}
		a.startSng()
		return nil
	})
}

func (a *actor) seated() int {
	n := 0
	for _, p := range a.st.Seats {
		if p != nil {
			n++
		}
	}
	return n
}

func (a *actor) startSng() {
	now := time.Now()
	g := a.st.Sng
	g.Phase, g.Started = PhaseRunning, now
	a.setLevel(0, now)
	for _, p := range a.st.Seats {
		if p != nil {
			p.SittingOut, p.Missed = false, 0
		}
	}
	// Random button: the first hand's positions follow a random seat.
	var occupied []int
	for i, p := range a.st.Seats {
		if p != nil {
			occupied = append(occupied, i)
		}
	}
	i := mathrand.IntN(len(occupied))
	a.st.Pos = &engine.Positions{Button: occupied[(i+len(occupied)-1)%len(occupied)], SB: occupied[i],
		BB: occupied[(i+1)%len(occupied)]}
	a.changed()
	a.maybeStart()
}

// eliminate removes the players busted in the hand that just ended and
// gives them their places; with one player left the game is over. Players
// busted in the same hand: the one who started the hand with more chips
// finishes higher.
func (a *actor) eliminate() {
	g := a.st.Sng
	start := map[int]int64{}
	for _, s := range a.cfg.Seats {
		start[s.Seat] = s.Stack
	}
	var out []int
	alive := 0
	for i, p := range a.st.Seats {
		if p == nil {
			continue
		}
		if p.Stack == 0 {
			out = append(out, i)
		} else {
			alive++
		}
	}
	slices.SortFunc(out, func(x, y int) int { return cmp.Compare(start[y], start[x]) })
	for k, i := range out {
		p := a.st.Seats[i]
		g.Places = append(g.Places, Place{Place: alive + k + 1, User: p.User, Name: p.Name})
		a.st.Seats[i] = nil
	}
	if alive == 1 {
		for _, p := range a.st.Seats {
			if p != nil {
				g.Places = append(g.Places, Place{Place: 1, User: p.User, Name: p.Name})
			}
		}
		g.Phase = PhaseFinished
		g.LevelEnds = time.Time{}
	}
	slices.SortFunc(g.Places, func(x, y Place) int { return cmp.Compare(x.Place, y.Place) })
	if g.Phase == PhaseFinished && a.opt.OnGameDone != nil {
		a.opt.OnGameDone(GameDone{TableID: a.st.ID, TableName: a.st.Settings.Name, Started: g.Started,
			Places: slices.Clone(g.Places)})
	}
}
