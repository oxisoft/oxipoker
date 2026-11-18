// Package tablestore keeps the open tables in SQLite so a restarted server
// puts them back. Tables hand their state over from their own goroutine;
// one writer stores it in the background, the newest state of each table
// winning, and Close writes what is left.
package tablestore

import (
	"context"
	"database/sql"
	"encoding/json"
	"log/slog"
	"slices"
	"sync"
	"time"

	"github.com/oxisoft/oxipoker/server/internal/table"
)

// Store writes and loads open tables.
type Store struct {
	db  *sql.DB
	log *slog.Logger

	mu      sync.Mutex
	pending map[string]table.Saved
	order   []string
	wake    chan struct{}
	stop    chan struct{}
	done    chan struct{}
	once    sync.Once
}

// New starts the writer.
func New(db *sql.DB, log *slog.Logger) *Store {
	s := &Store{db: db, log: log, pending: map[string]table.Saved{}, wake: make(chan struct{}, 1),
		stop: make(chan struct{}), done: make(chan struct{})}
	go s.run()
	return s
}

// Save queues the state of a table; use it as table.Options.OnSave. It
// never blocks.
func (s *Store) Save(v table.Saved) {
	s.mu.Lock()
	if _, ok := s.pending[v.ID]; !ok {
		s.order = append(s.order, v.ID)
	}
	s.pending[v.ID] = v
	s.mu.Unlock()
	select {
	case s.wake <- struct{}{}:
	default:
	}
}

// Close writes everything queued and stops the writer.
func (s *Store) Close() {
	s.once.Do(func() { close(s.stop) })
	<-s.done
}

func (s *Store) run() {
	defer close(s.done)
	for {
		select {
		case <-s.wake:
			s.flush()
		case <-s.stop:
			s.flush()
			return
		}
	}
}

func (s *Store) flush() {
	s.mu.Lock()
	pending, order := s.pending, s.order
	s.pending, s.order = map[string]table.Saved{}, nil
	s.mu.Unlock()
	for _, id := range order {
		if err := s.Write(context.Background(), pending[id]); err != nil && s.log != nil {
			s.log.Error("store table", "table", id, "err", err)
		}
	}
}

// Write stores one table now; a closed table is deleted.
func (s *Store) Write(ctx context.Context, v table.Saved) error {
	if v.Closed {
		_, err := s.db.ExecContext(ctx, `DELETE FROM open_tables WHERE id = ?`, v.ID)
		return err
	}
	b, err := json.Marshal(v)
	if err != nil {
		return err
	}
	at := v.At
	if at.IsZero() {
		at = time.Now()
	}
	_, err = s.db.ExecContext(ctx, `INSERT INTO open_tables (id, state, saved_at) VALUES (?, ?, ?)
		ON CONFLICT (id) DO UPDATE SET state = excluded.state, saved_at = excluded.saved_at`,
		v.ID, string(b), at.UnixMilli())
	return err
}

// Load returns the stored tables, oldest first. Rows that do not decode
// are deleted and logged.
func (s *Store) Load(ctx context.Context) ([]table.Saved, error) {
	rows, err := s.db.QueryContext(ctx, `SELECT id, state FROM open_tables`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []table.Saved
	var bad []string
	for rows.Next() {
		var id, state string
		if err := rows.Scan(&id, &state); err != nil {
			return nil, err
		}
		var v table.Saved
		if err := json.Unmarshal([]byte(state), &v); err != nil || v.ID != id {
			bad = append(bad, id)
			continue
		}
		out = append(out, v)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	for _, id := range bad {
		if s.log != nil {
			s.log.Warn("stored table does not decode, dropped", "table", id)
		}
		if _, err := s.db.ExecContext(ctx, `DELETE FROM open_tables WHERE id = ?`, id); err != nil {
			return nil, err
		}
	}
	slices.SortStableFunc(out, func(a, b table.Saved) int { return a.Created.Compare(b.Created) })
	return out, nil
}
