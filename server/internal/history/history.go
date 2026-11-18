// Package history stores finished hands and serves each player's own hand
// history and stats. A stored hand holds what was seen at the table:
// public actions, the board and cards shown at showdown. A player's own hole
// cards are stored in their row and returned only to them.
package history

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"log/slog"
	"time"

	"github.com/oxisoft/oxipoker/server/internal/engine"
	"github.com/oxisoft/oxipoker/server/internal/table"
)

// ErrNotFound: no such hand, or the user did not play it.
var ErrNotFound = errors.New("history: hand not found")

// Store writes and reads hands.
type Store struct {
	db  *sql.DB
	log *slog.Logger
	q   chan any // table.HandDone or table.GameDone, in table order
	now func() time.Time
}

// New starts the writer. Hands are queued by Record (from table goroutines)
// and written in the background until ctx ends.
func New(ctx context.Context, db *sql.DB, log *slog.Logger) *Store {
	s := &Store{db: db, log: log, q: make(chan any, 1024), now: time.Now}
	go func() {
		for {
			select {
			case <-ctx.Done():
				return
			case v := <-s.q:
				switch d := v.(type) {
				case chan struct{}: // Close: everything before it is written
					close(d)
					return
				case table.HandDone:
					if err := s.Write(context.Background(), d); err != nil && s.log != nil {
						s.log.Error("hand history", "table", d.TableID, "hand", d.HandNo, "err", err)
					}
				case table.GameDone:
					if err := s.WriteGame(context.Background(), d); err != nil && s.log != nil {
						s.log.Error("sit-and-go result", "table", d.TableID, "err", err)
					}
				}
			}
		}
	}()
	return s
}

// Close writes the queued hands and games and stops the writer. Call it
// after the tables are stopped: nothing may be recorded afterwards.
func (s *Store) Close() {
	done := make(chan struct{})
	s.q <- done
	<-done
}

// Record queues a finished hand; use it as table.Options.OnHandDone.
func (s *Store) Record(d table.HandDone) { s.q <- d }

// RecordGame queues a finished sit-and-go; use it as table.Options.OnGameDone.
// It shares the queue with Record, so a game is written after its last hand.
func (s *Store) RecordGame(d table.GameDone) { s.q <- d }

// WriteGame stores the places of a finished sit-and-go.
func (s *Store) WriteGame(ctx context.Context, d table.GameDone) error {
	if len(d.Places) == 0 {
		return errors.New("history: game without places")
	}
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer func() { _ = tx.Rollback() }()
	started := d.Started
	if started.IsZero() {
		started = s.now()
	}
	res, err := tx.ExecContext(ctx, `INSERT INTO sng_games (table_id, table_name, players, started_at, finished_at)
		VALUES (?, ?, ?, ?, ?)`, d.TableID, d.TableName, len(d.Places), started.UnixMilli(), s.now().UnixMilli())
	if err != nil {
		return err
	}
	id, err := res.LastInsertId()
	if err != nil {
		return err
	}
	for _, p := range d.Places {
		// A player deleted meanwhile has no users row: skip, keep the game.
		if _, err := tx.ExecContext(ctx, `INSERT INTO sng_places (game_id, user_id, place, name)
			SELECT ?, ?, ?, ? WHERE EXISTS (SELECT 1 FROM users WHERE id = ?)`,
			id, p.User, p.Place, p.Name, p.User); err != nil {
			return err
		}
	}
	return tx.Commit()
}

// Game is one finished sit-and-go as one of its players sees it.
type Game struct {
	ID         int64         `json:"id"`
	TableName  string        `json:"table_name"`
	Players    int           `json:"players"`
	YourPlace  int           `json:"your_place"`
	Places     []table.Place `json:"places"` // best place first; names only, no user ids
	StartedAt  time.Time     `json:"started_at"`
	FinishedAt time.Time     `json:"finished_at"`
}

// Games returns the sit-and-go games the user played, newest first.
func (s *Store) Games(ctx context.Context, user string, limit int) ([]Game, error) {
	if limit <= 0 || limit > 100 {
		limit = 50
	}
	rows, err := s.db.QueryContext(ctx, `SELECT g.id, g.table_name, g.players, p.place, g.started_at, g.finished_at
		FROM sng_places p JOIN sng_games g ON g.id = p.game_id
		WHERE p.user_id = ? ORDER BY g.id DESC LIMIT ?`, user, limit)
	if err != nil {
		return nil, err
	}
	out := []Game{}
	for rows.Next() {
		var g Game
		var st, fin int64
		if err := rows.Scan(&g.ID, &g.TableName, &g.Players, &g.YourPlace, &st, &fin); err != nil {
			rows.Close()
			return nil, err
		}
		g.StartedAt, g.FinishedAt = time.UnixMilli(st).UTC(), time.UnixMilli(fin).UTC()
		out = append(out, g)
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return nil, err
	}
	for i := range out {
		if out[i].Places, err = s.places(ctx, out[i].ID); err != nil {
			return nil, err
		}
	}
	return out, nil
}

func (s *Store) places(ctx context.Context, game int64) ([]table.Place, error) {
	rows, err := s.db.QueryContext(ctx, `SELECT place, name FROM sng_places WHERE game_id = ? ORDER BY place`, game)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []table.Place{}
	for rows.Next() {
		var pl table.Place
		if err := rows.Scan(&pl.Place, &pl.Name); err != nil {
			return nil, err
		}
		out = append(out, pl)
	}
	return out, rows.Err()
}

// PublicEvents drops every event only one player may see (hole cards).
func PublicEvents(evs []engine.Event) []engine.Event {
	out := make([]engine.Event, 0, len(evs))
	for _, e := range evs {
		if e.Kind != engine.EvHole {
			out = append(out, e)
		}
	}
	return out
}

// Write stores one finished hand in a transaction.
func (s *Store) Write(ctx context.Context, d table.HandDone) error {
	h := d.Hand
	if h == nil || !h.Done() {
		return errors.New("history: hand not finished")
	}
	won := map[int]int64{}
	var pot int64
	for _, r := range h.Results() {
		pot += r.Amount
		for i, w := range r.Winners {
			won[w] += r.Shares[i]
		}
	}
	board, _ := json.Marshal(h.Board())
	events, _ := json.Marshal(PublicEvents(h.Events()))
	results, _ := json.Marshal(h.Results())
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer func() { _ = tx.Rollback() }()
	res, err := tx.ExecContext(ctx, `INSERT INTO hands (table_id, table_name, hand_no, small_blind, big_blind,
		button, pot, board, events, results, ended_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		d.TableID, d.TableName, d.HandNo, d.Config.SmallBlind, d.Config.BigBlind, d.Config.Positions.Button,
		pot, string(board), string(events), string(results), s.now().UnixMilli())
	if err != nil {
		return err
	}
	id, err := res.LastInsertId()
	if err != nil {
		return err
	}
	for _, p := range h.Players() {
		user := d.Users[p.Seat]
		if user == "" {
			continue
		}
		hole, _ := json.Marshal(p.Hole)
		// A player deleted meanwhile has no users row: skip, keep the hand.
		if _, err := tx.ExecContext(ctx, `INSERT INTO hand_players (hand_id, user_id, seat, name, start_stack,
			end_stack, won, hole) SELECT ?, ?, ?, ?, ?, ?, ?, ? WHERE EXISTS (SELECT 1 FROM users WHERE id = ?)`,
			id, user, p.Seat, d.Names[p.Seat], p.Start(), p.Stack, won[p.Seat], string(hole), user); err != nil {
			return err
		}
	}
	return tx.Commit()
}

// Summary is one row of a player's hand list.
type Summary struct {
	ID        int64         `json:"id"`
	TableName string        `json:"table_name"`
	HandNo    int           `json:"hand_no"`
	BigBlind  int64         `json:"big_blind"`
	Pot       int64         `json:"pot"`
	Board     []engine.Card `json:"board"`
	Seat      int           `json:"seat"`
	Cards     []engine.Card `json:"cards"` // own hole cards
	Won       int64         `json:"won"`
	Net       int64         `json:"net"` // end stack - start stack
	EndedAt   time.Time     `json:"ended_at"`
}

// List returns the user's hands, newest first, older than before (0 = all).
func (s *Store) List(ctx context.Context, user string, before int64, limit int) ([]Summary, error) {
	if limit <= 0 || limit > 100 {
		limit = 50
	}
	if before <= 0 {
		before = 1<<63 - 1
	}
	rows, err := s.db.QueryContext(ctx, `SELECT h.id, h.table_name, h.hand_no, h.big_blind, h.pot, h.board,
		p.seat, p.hole, p.won, p.end_stack - p.start_stack, h.ended_at
		FROM hand_players p JOIN hands h ON h.id = p.hand_id
		WHERE p.user_id = ? AND p.hand_id < ? ORDER BY p.hand_id DESC LIMIT ?`, user, before, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []Summary{}
	for rows.Next() {
		var sm Summary
		var board, hole string
		var at int64
		if err := rows.Scan(&sm.ID, &sm.TableName, &sm.HandNo, &sm.BigBlind, &sm.Pot, &board, &sm.Seat, &hole,
			&sm.Won, &sm.Net, &at); err != nil {
			return nil, err
		}
		_ = json.Unmarshal([]byte(board), &sm.Board)
		_ = json.Unmarshal([]byte(hole), &sm.Cards)
		sm.EndedAt = time.UnixMilli(at).UTC()
		out = append(out, sm)
	}
	return out, rows.Err()
}

// Seat of a stored hand.
type Seat struct {
	Seat       int    `json:"seat"`
	Name       string `json:"name"`
	StartStack int64  `json:"start_stack"`
	EndStack   int64  `json:"end_stack"`
	Won        int64  `json:"won"`
}

// Hand is a stored hand as its player may replay it.
type Hand struct {
	ID         int64              `json:"id"`
	TableName  string             `json:"table_name"`
	HandNo     int                `json:"hand_no"`
	SmallBlind int64              `json:"small_blind"`
	BigBlind   int64              `json:"big_blind"`
	Button     int                `json:"button"`
	Pot        int64              `json:"pot"`
	Board      []engine.Card      `json:"board"`
	Events     []engine.Event     `json:"events"`
	Results    []engine.PotResult `json:"results"`
	Seats      []Seat             `json:"seats"`
	YourSeat   int                `json:"your_seat"`
	YourCards  []engine.Card      `json:"your_cards"`
	EndedAt    time.Time          `json:"ended_at"`
}

// Get returns a hand the user played.
func (s *Store) Get(ctx context.Context, user string, id int64) (*Hand, error) {
	h := &Hand{ID: id}
	var board, events, results, hole string
	var at int64
	err := s.db.QueryRowContext(ctx, `SELECT h.table_name, h.hand_no, h.small_blind, h.big_blind, h.button, h.pot,
		h.board, h.events, h.results, h.ended_at, p.seat, p.hole
		FROM hands h JOIN hand_players p ON p.hand_id = h.id AND p.user_id = ? WHERE h.id = ?`, user, id).
		Scan(&h.TableName, &h.HandNo, &h.SmallBlind, &h.BigBlind, &h.Button, &h.Pot, &board, &events, &results,
			&at, &h.YourSeat, &hole)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	_ = json.Unmarshal([]byte(board), &h.Board)
	_ = json.Unmarshal([]byte(events), &h.Events)
	_ = json.Unmarshal([]byte(results), &h.Results)
	_ = json.Unmarshal([]byte(hole), &h.YourCards)
	h.EndedAt = time.UnixMilli(at).UTC()
	rows, err := s.db.QueryContext(ctx, `SELECT seat, name, start_stack, end_stack, won FROM hand_players
		WHERE hand_id = ? ORDER BY seat`, id)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	h.Seats = []Seat{}
	for rows.Next() {
		var st Seat
		if err := rows.Scan(&st.Seat, &st.Name, &st.StartStack, &st.EndStack, &st.Won); err != nil {
			return nil, err
		}
		h.Seats = append(h.Seats, st)
	}
	return h, rows.Err()
}

// Stats of one player over every stored hand.
type Stats struct {
	HandsPlayed int   `json:"hands_played"`
	HandsWon    int   `json:"hands_won"`
	BiggestPot  int64 `json:"biggest_pot"` // most chips won in one hand
	SngGames    int   `json:"sng_games"`
	SngWins     int   `json:"sng_wins"`
	SngBest     int   `json:"sng_best_place"` // 0 = no sit-and-go finished yet
}

// StatsOf returns a player's stats.
func (s *Store) StatsOf(ctx context.Context, user string) (Stats, error) {
	var st Stats
	err := s.db.QueryRowContext(ctx, `SELECT COUNT(*), COALESCE(SUM(won > 0), 0), COALESCE(MAX(won), 0)
		FROM hand_players WHERE user_id = ?`, user).Scan(&st.HandsPlayed, &st.HandsWon, &st.BiggestPot)
	if err != nil {
		return st, err
	}
	err = s.db.QueryRowContext(ctx, `SELECT COUNT(*), COALESCE(SUM(place = 1), 0), COALESCE(MIN(place), 0)
		FROM sng_places WHERE user_id = ?`, user).Scan(&st.SngGames, &st.SngWins, &st.SngBest)
	return st, err
}
