package table

import (
	"errors"
	"time"

	"github.com/oxisoft/oxipoker/server/internal/engine"
)

// Saved is the stored form of an open table: what a restarted server needs
// to put the table back. A hand that runs while the table is saved is not
// part of it: the stacks, positions and hand number are those from before
// that hand, so a hand cut off by a restart is voided.
type Saved struct {
	ID         string            `json:"id"`
	Host       string            `json:"host"`
	Created    time.Time         `json:"created"`
	Settings   Settings          `json:"settings"`
	TurnTimeMS int64             `json:"turn_time_ms"`
	Seats      []*Player         `json:"seats"`
	HandNo     int               `json:"hand_no"`
	Pos        *engine.Positions `json:"positions,omitempty"`
	Sng        *Sng              `json:"sng,omitempty"`
	At         time.Time         `json:"at"`
	// Closed: the table is gone and its stored state can be deleted.
	Closed bool `json:"closed,omitempty"`
}

// saved builds the stored form of the table now.
func (a *actor) saved() Saved {
	s := Saved{ID: a.st.ID, Host: a.st.Host, Created: a.created, Settings: a.st.Settings,
		TurnTimeMS: a.st.Settings.TurnTime.Milliseconds(), HandNo: a.st.HandNo, Sng: a.st.Sng.clone(),
		At: time.Now(), Closed: a.st.Closed, Seats: make([]*Player, len(a.st.Seats))}
	running := a.st.Hand != nil && !a.st.Hand.Done()
	start := map[int]int64{}
	if running {
		for _, seat := range a.cfg.Seats {
			if a.users[seat.Seat] != "" {
				start[seat.Seat] = seat.Stack
			}
		}
		s.HandNo--
		if a.prevPos != nil {
			p := *a.prevPos
			s.Pos = &p
		}
	} else if a.st.Pos != nil {
		p := *a.st.Pos
		s.Pos = &p
	}
	for i, p := range a.st.Seats {
		if p == nil {
			continue
		}
		c := *p
		c.Missed = 0
		if st, ok := start[i]; ok && a.users[i] == p.User {
			c.Stack = st
		}
		if c.Leaving { // wanted to leave when the hand ended: the hand is voided, the seat is freed
			continue
		}
		s.Seats[i] = &c
	}
	return s
}

// save hands the stored form to the OnSave hook, unless a hand is running:
// a running hand is never stored, the state before it is.
func (a *actor) save() {
	if a.opt.OnSave == nil || (a.st.Hand != nil && !a.st.Hand.Done() && !a.st.Closed) {
		return
	}
	a.opt.OnSave(a.saved())
}

// Restore starts a table from its stored form. The sit-and-go blind clock
// keeps the time that was left in the level when the table was stored.
func Restore(s Saved, opt Options) (*Table, error) {
	if s.ID == "" || s.Closed {
		return nil, errors.New("table: nothing to restore")
	}
	set := s.Settings
	set.TurnTime = time.Duration(s.TurnTimeMS) * time.Millisecond
	if err := set.Validate(); err != nil {
		return nil, err
	}
	if len(s.Seats) != set.Seats {
		return nil, errors.New("table: stored seats do not match the settings")
	}
	if (set.Kind == KindSng) != (s.Sng != nil) {
		return nil, errors.New("table: stored sit-and-go state does not match the kind")
	}
	t, a := newActor(s.ID, s.Host, set, opt)
	if !s.Created.IsZero() {
		a.created = s.Created
	}
	for i, p := range s.Seats {
		if p != nil {
			c := *p
			a.st.Seats[i] = &c
		}
	}
	a.st.HandNo = s.HandNo
	if s.Pos != nil {
		p := *s.Pos
		a.st.Pos = &p
	}
	if s.Sng != nil {
		a.st.Sng = s.Sng.clone()
		if a.st.Sng.Places == nil {
			a.st.Sng.Places = []Place{}
		}
		if g := a.st.Sng; g.Phase == PhaseRunning && !g.LevelEnds.IsZero() && !s.At.IsZero() {
			g.LevelEnds = g.LevelEnds.Add(max(time.Since(s.At), 0))
		}
	}
	go a.run()
	t.post(func(a *actor) {
		a.changed()
		a.maybeStart()
	})
	return t, nil
}

// Stop ends the table for a server shutdown: the state goes to the OnSave
// hook (a running hand voided) and nothing is published, so watchers do
// not see the table close. Stop waits until the table goroutine is gone.
func (t *Table) Stop() {
	t.close.Do(func() {
		_ = t.do(func(a *actor) error {
			if a.opt.OnSave != nil {
				a.opt.OnSave(a.saved())
			}
			a.halt = true
			return nil
		})
	})
	<-t.done
}

// Created is when the table was opened.
func (t *Table) Created() time.Time {
	var c time.Time
	_ = t.do(func(a *actor) error { c = a.created; return nil })
	return c
}
