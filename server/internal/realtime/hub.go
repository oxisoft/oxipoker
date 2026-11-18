// Package realtime pushes table and lobby state to connected clients over
// WebSocket and turns their messages into table intents. The table actors
// stay the only game authority: this package only builds per-viewer views
// from their snapshots and forwards intents to them.
package realtime

import (
	"slices"
	"sync"

	"github.com/oxisoft/oxipoker/server/internal/table"
)

// MaxConnsPerUser limits the open connections of one account (tabs and
// devices together).
const MaxConnsPerUser = 10

// Hub keeps the latest snapshot of every open table and the connections
// that watch a table or the lobby.
type Hub struct {
	mu     sync.Mutex
	states map[string]table.State
	order  []string // table ids, oldest first
	subs   map[string]map[*conn]struct{}
	lobby  map[*conn]struct{}
	users  map[string]int // open connections per user
}

// NewHub returns an empty hub.
func NewHub() *Hub {
	return &Hub{states: map[string]table.State{}, subs: map[string]map[*conn]struct{}{},
		lobby: map[*conn]struct{}{}, users: map[string]int{}}
}

// TableOptions are the table options that feed the hub; pass it to
// table.NewManager.
func (h *Hub) TableOptions(string) table.Options {
	return table.Options{OnChange: h.Publish}
}

// Publish stores a table snapshot and wakes its watchers and the lobby. It
// is called from the table goroutine and never blocks. Older snapshots
// than the stored one are ignored.
func (h *Hub) Publish(s table.State) {
	h.mu.Lock()
	defer h.mu.Unlock()
	old, known := h.states[s.ID]
	if known && old.Version > s.Version {
		return
	}
	if !known && !s.Closed {
		h.order = append(h.order, s.ID)
	}
	if s.Closed {
		delete(h.states, s.ID)
		h.order = slices.DeleteFunc(h.order, func(id string) bool { return id == s.ID })
		// Watchers still get the final, closed view.
		for c := range h.subs[s.ID] {
			c.closedView(s)
		}
		delete(h.subs, s.ID)
	} else {
		h.states[s.ID] = s
		for c := range h.subs[s.ID] {
			c.wake(dirtyTable)
		}
	}
	for c := range h.lobby {
		c.wake(dirtyLobby)
	}
}

// State returns the latest snapshot of a table.
func (h *Hub) State(id string) (table.State, bool) {
	h.mu.Lock()
	defer h.mu.Unlock()
	s, ok := h.states[id]
	return s, ok
}

// LobbyTable is one open table as the lobby shows it. It holds nothing a
// player could not see by sitting at the table.
type LobbyTable struct {
	ID       string         `json:"id"`
	Host     string         `json:"host"`
	Settings table.Settings `json:"settings"`
	Taken    int            `json:"taken"`
	Players  []string       `json:"players"` // display names in seat order
	HandNo   int            `json:"hand_no"`
}

// Summary is the lobby entry of a snapshot.
func Summary(s table.State) LobbyTable {
	lt := LobbyTable{ID: s.ID, Host: s.Host, Settings: s.Settings, HandNo: s.HandNo, Players: []string{}}
	for _, p := range s.Seats {
		if p != nil {
			lt.Taken++
			lt.Players = append(lt.Players, p.Name)
		}
	}
	return lt
}

// Lobby lists the open tables, oldest first.
func (h *Hub) Lobby() []LobbyTable {
	h.mu.Lock()
	defer h.mu.Unlock()
	out := make([]LobbyTable, 0, len(h.order))
	for _, id := range h.order {
		out = append(out, Summary(h.states[id]))
	}
	return out
}

func (h *Hub) register(c *conn) bool {
	h.mu.Lock()
	defer h.mu.Unlock()
	if h.users[c.user.ID] >= MaxConnsPerUser {
		return false
	}
	h.users[c.user.ID]++
	return true
}

func (h *Hub) unregister(c *conn) {
	h.mu.Lock()
	defer h.mu.Unlock()
	if h.users[c.user.ID]--; h.users[c.user.ID] <= 0 {
		delete(h.users, c.user.ID)
	}
	delete(h.lobby, c)
	for id, m := range h.subs {
		delete(m, c)
		if len(m) == 0 {
			delete(h.subs, id)
		}
	}
}

// watch moves c to table id ("" = none).
func (h *Hub) watch(c *conn, id string) {
	h.mu.Lock()
	defer h.mu.Unlock()
	for tid, m := range h.subs {
		delete(m, c)
		if len(m) == 0 {
			delete(h.subs, tid)
		}
	}
	if id == "" {
		return
	}
	if h.subs[id] == nil {
		h.subs[id] = map[*conn]struct{}{}
	}
	h.subs[id][c] = struct{}{}
	c.wake(dirtyTable)
}

func (h *Hub) setLobby(c *conn, on bool) {
	h.mu.Lock()
	defer h.mu.Unlock()
	if on {
		h.lobby[c] = struct{}{}
		c.wake(dirtyLobby)
	} else {
		delete(h.lobby, c)
	}
}

// broadcast sends a message to every watcher of a table.
func (h *Hub) broadcast(id string, msg any) {
	h.mu.Lock()
	defer h.mu.Unlock()
	for c := range h.subs[id] {
		c.send(msg)
	}
}
