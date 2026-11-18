package table

import (
	"crypto/rand"
	"encoding/base32"
	"errors"
	"slices"
	"sync"
	"time"
)

// Manager errors.
var (
	ErrNoTable   = errors.New("no such table")
	ErrForbidden = errors.New("only the host or an admin may do this")
	ErrTooMany   = errors.New("too many open tables")
)

// MaxTables is the limit of open tables per server.
const MaxTables = 100

// Manager owns the open tables of the server.
type Manager struct {
	mu      sync.Mutex
	tables  map[string]*entry
	idle    time.Duration
	opt     func(id string) Options
	stop    chan struct{}
	stopped sync.Once
}

type entry struct {
	t          *Table
	host       string
	created    time.Time
	emptySince time.Time // zero while someone sits at the table
}

// NewManager starts the idle sweeper: a table with nobody seated for idle
// is closed. opt builds the options of each new table (hooks for the
// realtime layer and the hand history); it may be nil.
func NewManager(idle time.Duration, opt func(id string) Options) *Manager {
	if opt == nil {
		opt = func(string) Options { return Options{} }
	}
	m := &Manager{tables: map[string]*entry{}, idle: idle, opt: opt, stop: make(chan struct{})}
	go m.sweep()
	return m
}

func newTableID() string {
	var b [10]byte
	_, _ = rand.Read(b[:])
	return base32.StdEncoding.WithPadding(base32.NoPadding).EncodeToString(b[:])
}

// Create opens a table hosted by host. Who may create tables is decided by
// the caller (admin setting "table creation").
func (m *Manager) Create(host string, s Settings) (*Table, error) {
	if err := s.Validate(); err != nil {
		return nil, err
	}
	m.mu.Lock()
	defer m.mu.Unlock()
	if len(m.tables) >= MaxTables {
		return nil, ErrTooMany
	}
	id := newTableID()
	t, err := New(id, host, s, m.opt(id))
	if err != nil {
		return nil, err
	}
	now := time.Now()
	m.tables[id] = &entry{t: t, host: host, created: now, emptySince: now}
	return t, nil
}

// Get returns an open table.
func (m *Manager) Get(id string) (*Table, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	e, ok := m.tables[id]
	if !ok {
		return nil, ErrNoTable
	}
	return e.t, nil
}

// List returns the open tables, oldest first.
func (m *Manager) List() []*Table {
	m.mu.Lock()
	es := make([]*entry, 0, len(m.tables))
	for _, e := range m.tables {
		es = append(es, e)
	}
	m.mu.Unlock()
	slices.SortFunc(es, func(a, b *entry) int { return a.created.Compare(b.created) })
	out := make([]*Table, len(es))
	for i, e := range es {
		out[i] = e.t
	}
	return out
}

// Close closes a table for its host or an admin.
func (m *Manager) Close(id, user string, admin bool) error {
	m.mu.Lock()
	e, ok := m.tables[id]
	if ok && !admin && e.host != user {
		m.mu.Unlock()
		return ErrForbidden
	}
	delete(m.tables, id)
	m.mu.Unlock()
	if !ok {
		return ErrNoTable
	}
	e.t.Close()
	return nil
}

// Shutdown closes every table and stops the sweeper.
func (m *Manager) Shutdown() {
	m.stopped.Do(func() { close(m.stop) })
	m.mu.Lock()
	es := m.tables
	m.tables = map[string]*entry{}
	m.mu.Unlock()
	for _, e := range es {
		e.t.Close()
	}
}

func (m *Manager) sweep() {
	every := min(max(m.idle/4, 10*time.Millisecond), time.Minute)
	tick := time.NewTicker(every)
	defer tick.Stop()
	for {
		select {
		case <-m.stop:
			return
		case <-tick.C:
			m.sweepOnce(time.Now())
		}
	}
}

func (m *Manager) sweepOnce(now time.Time) {
	m.mu.Lock()
	es := make(map[string]*entry, len(m.tables))
	for id, e := range m.tables {
		es[id] = e
	}
	m.mu.Unlock()
	for id, e := range es {
		s, err := e.t.Snapshot()
		if err != nil { // closed on its own
			m.mu.Lock()
			delete(m.tables, id)
			m.mu.Unlock()
			continue
		}
		empty := !slices.ContainsFunc(s.Seats, func(p *Player) bool { return p != nil }) ||
			(s.Sng != nil && s.Sng.Phase == PhaseFinished) // a finished sit-and-go closes like an empty table
		m.mu.Lock()
		switch {
		case !empty:
			e.emptySince = time.Time{}
		case e.emptySince.IsZero():
			e.emptySince = now
		case now.Sub(e.emptySince) >= m.idle:
			delete(m.tables, id)
			m.mu.Unlock()
			e.t.Close()
			continue
		}
		m.mu.Unlock()
	}
}
