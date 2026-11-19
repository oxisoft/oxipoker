// Package realtime pushes table and lobby state to connected clients over
// WebSocket and turns their messages into table intents. The table actors
// stay the only game authority: this package only builds per-viewer views
// from their snapshots and forwards intents to them.
package realtime

import (
	"context"
	"slices"
	"sync"
	"time"

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
	conns  map[*conn]struct{}

	// Per open table, dropped when it closes. Chat is never stored: the
	// recent lines live here only for reports.
	chatLog map[string][]ChatLine
	muted   map[string]map[string]bool // table -> muted users
	removed map[string]map[string]bool // table -> removed spectators
	// Users sent out of a table's call; they get no new call token while
	// the table is open (they may still play or watch).
	callRemoved map[string]map[string]bool

	calls   Calls
	callsWG sync.WaitGroup
	// CallErr receives failed moderation requests (logging); nil = dropped.
	CallErr func(error)
}

// Calls moderates the table calls on the media server (LiveKit). Methods
// run outside the hub lock, in their own goroutine.
type Calls interface {
	Mute(ctx context.Context, tableID, user, source string) error
	Remove(ctx context.Context, tableID, user string) error
	Close(ctx context.Context, tableID string) error
}

// SetCalls turns call moderation on; call it before serving.
func (h *Hub) SetCalls(c Calls) {
	h.mu.Lock()
	defer h.mu.Unlock()
	h.calls = c
}

// HasCalls reports whether call moderation is on.
func (h *Hub) HasCalls() bool {
	h.mu.Lock()
	defer h.mu.Unlock()
	return h.calls != nil
}

// callTimeout bounds one moderation request to the media server.
const callTimeout = 10 * time.Second

// onCallsLocked runs f against the media server in the background: the
// game never waits for media. A removed user is also refused new tokens,
// so a lost request only delays the effect until their token expires.
func (h *Hub) onCallsLocked(f func(ctx context.Context, c Calls) error) {
	c, report := h.calls, h.CallErr
	if c == nil {
		return
	}
	h.callsWG.Add(1)
	go func() {
		defer h.callsWG.Done()
		ctx, cancel := context.WithTimeout(context.Background(), callTimeout)
		defer cancel()
		if err := f(ctx, c); err != nil && report != nil {
			report(err)
		}
	}()
}

// WaitCalls waits for running moderation requests (tests, shutdown).
func (h *Hub) WaitCalls() { h.callsWG.Wait() }

// ChatLog is how many recent chat lines a table keeps for reports.
const ChatLog = 20

// ChatLine is one table chat line.
type ChatLine struct {
	User string    `json:"user"`
	Name string    `json:"name"`
	Text string    `json:"text"`
	At   time.Time `json:"at"`
}

// NewHub returns an empty hub.
func NewHub() *Hub {
	return &Hub{states: map[string]table.State{}, subs: map[string]map[*conn]struct{}{},
		lobby: map[*conn]struct{}{}, users: map[string]int{},
		conns: map[*conn]struct{}{}, chatLog: map[string][]ChatLine{},
		muted: map[string]map[string]bool{}, removed: map[string]map[string]bool{},
		callRemoved: map[string]map[string]bool{}}
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
		delete(h.chatLog, s.ID)
		delete(h.muted, s.ID)
		delete(h.removed, s.ID)
		delete(h.callRemoved, s.ID)
		id := s.ID
		h.onCallsLocked(func(ctx context.Context, c Calls) error { return c.Close(ctx, id) })
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
	h.conns[c] = struct{}{}
	return true
}

func (h *Hub) unregister(c *conn) {
	h.mu.Lock()
	defer h.mu.Unlock()
	if h.users[c.user.ID]--; h.users[c.user.ID] <= 0 {
		delete(h.users, c.user.ID)
	}
	delete(h.lobby, c)
	delete(h.conns, c)
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

// Restarting tells every client that the server restarts, waits up to
// grace for the message to go out and closes the connections. Apps
// reconnect and watch their table again once the server is back.
func (h *Hub) Restarting(grace time.Duration) {
	h.mu.Lock()
	cs := make([]*conn, 0, len(h.conns))
	for c := range h.conns {
		cs = append(cs, c)
		c.send(restartMsg{Type: "restarting"})
	}
	h.mu.Unlock()
	if len(cs) == 0 {
		return
	}
	end := time.Now().Add(grace)
	for time.Now().Before(end) && slices.ContainsFunc(cs, (*conn).queued) {
		time.Sleep(10 * time.Millisecond)
	}
	for _, c := range cs {
		c.kill()
	}
}

type restartMsg struct {
	Type string `json:"type"`
}

// chat logs a line and sends it to every watcher who has not blocked its
// author. A muted author is refused.
func (h *Hub) chat(id string, m chatMsg) error {
	h.mu.Lock()
	defer h.mu.Unlock()
	if h.muted[id][m.User] {
		return errMuted
	}
	if _, ok := h.states[id]; !ok {
		return table.ErrNoTable
	}
	log := append(h.chatLog[id], ChatLine{User: m.User, Name: m.Name, Text: m.Text, At: m.At})
	if len(log) > ChatLog {
		log = slices.Clone(log[len(log)-ChatLog:])
	}
	h.chatLog[id] = log
	for c := range h.subs[id] {
		if !c.blocks(m.User) {
			c.send(m)
		}
	}
	return nil
}

// RecentChat returns the last chat lines of an open table, for a report.
func (h *Hub) RecentChat(id string) []ChatLine {
	h.mu.Lock()
	defer h.mu.Unlock()
	return slices.Clone(h.chatLog[id])
}

// SetBlocks replaces the block list of every connection of user.
func (h *Hub) SetBlocks(user string, set map[string]bool) {
	h.mu.Lock()
	defer h.mu.Unlock()
	for c := range h.conns {
		if c.user.ID == user {
			c.setBlocks(set)
		}
	}
}

// moderationMsg is a table's chat moderation state, sent to its watchers.
type moderationMsg struct {
	Type  string   `json:"type"` // "moderation"
	Table string   `json:"table"`
	Muted []string `json:"muted"`
}

func (h *Hub) moderationLocked(id string) moderationMsg {
	m := moderationMsg{Type: "moderation", Table: id, Muted: []string{}}
	for u := range h.muted[id] {
		m.Muted = append(m.Muted, u)
	}
	slices.Sort(m.Muted)
	return m
}

// moderation returns the table's current moderation message.
func (h *Hub) moderation(id string) moderationMsg {
	h.mu.Lock()
	defer h.mu.Unlock()
	return h.moderationLocked(id)
}

// mute switches a user's table chat off or on and tells the watchers.
func (h *Hub) mute(id, user string, on bool) {
	h.mu.Lock()
	defer h.mu.Unlock()
	if on {
		if h.muted[id] == nil {
			h.muted[id] = map[string]bool{}
		}
		h.muted[id][user] = true
	} else {
		delete(h.muted[id], user)
	}
	m := h.moderationLocked(id)
	for c := range h.subs[id] {
		c.send(m)
	}
}

// remove sends a spectator away from a table for as long as it is open.
func (h *Hub) remove(id, user string) {
	h.mu.Lock()
	defer h.mu.Unlock()
	if h.removed[id] == nil {
		h.removed[id] = map[string]bool{}
	}
	h.removed[id][user] = true
	h.onCallsLocked(func(ctx context.Context, c Calls) error { return c.Remove(ctx, id, user) })
	for c := range h.subs[id] {
		if c.user.ID == user {
			delete(h.subs[id], c)
			c.removedFrom(id)
		}
	}
}

// Watching reports whether user has a live connection on table id and
// was not removed from it: the condition for joining the table's call.
func (h *Hub) Watching(id, user string) bool {
	h.mu.Lock()
	defer h.mu.Unlock()
	if h.removed[id][user] || h.callRemoved[id][user] {
		return false
	}
	for c := range h.subs[id] {
		if c.user.ID == user {
			return true
		}
	}
	return false
}

// callMute switches off a user's microphone or camera in the table's call.
func (h *Hub) callMute(id, user, source string) {
	h.mu.Lock()
	defer h.mu.Unlock()
	h.onCallsLocked(func(ctx context.Context, c Calls) error { return c.Mute(ctx, id, user, source) })
}

// callRemove sends a user out of the table's call until the table closes;
// they keep their seat or their place as a spectator.
func (h *Hub) callRemove(id, user string) {
	h.mu.Lock()
	defer h.mu.Unlock()
	if h.callRemoved[id] == nil {
		h.callRemoved[id] = map[string]bool{}
	}
	h.callRemoved[id][user] = true
	h.onCallsLocked(func(ctx context.Context, c Calls) error { return c.Remove(ctx, id, user) })
}

// watchAllowed reports whether user may watch table id (not removed).
func (h *Hub) watchAllowed(id, user string) bool {
	h.mu.Lock()
	defer h.mu.Unlock()
	return !h.removed[id][user]
}
