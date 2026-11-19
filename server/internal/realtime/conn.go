package realtime

import (
	"context"
	"encoding/json"
	"errors"
	"strings"
	"sync"
	"time"
	"unicode"
	"unicode/utf8"

	"github.com/coder/websocket"

	"github.com/oxisoft/oxipoker/server/internal/engine"
	"github.com/oxisoft/oxipoker/server/internal/table"
)

// Protocol limits.
const (
	MaxMessageBytes = 4 << 10
	MaxChatRunes    = 300
	ChatBurst       = 5                // chat messages ...
	ChatWindow      = 10 * time.Second // ... per window and connection
	sendQueue       = 64
)

// User is the signed-in account behind a connection.
type User struct {
	ID    string
	Name  string
	Admin bool
}

// Server serves WebSocket connections.
type Server struct {
	Hub    *Hub
	Tables *table.Manager
	// PingEvery is the keepalive interval (default 25 s).
	PingEvery time.Duration
	// Check is called with every keepalive; an error (session revoked,
	// account disabled) closes the connection.
	Check func(ctx context.Context) error
	// Blocks loads the users the connection's user blocked; their chat is
	// not delivered. nil = no blocks.
	Blocks func(ctx context.Context, user string) (map[string]bool, error)
}

type dirty uint8

const (
	dirtyTable dirty = 1 << iota
	dirtyLobby
)

type conn struct {
	user User
	srv  *Server
	ws   *websocket.Conn

	mu    sync.Mutex
	flags dirty
	table string // watched table
	out   []any  // queued messages, sent before the next view
	gone  bool
	chat  []time.Time
	block map[string]bool

	wakeCh chan struct{}
	kill   context.CancelFunc
}

func (c *conn) wake(d dirty) {
	c.mu.Lock()
	c.flags |= d
	c.mu.Unlock()
	select {
	case c.wakeCh <- struct{}{}:
	default:
	}
}

// send queues a message; a client that does not read is disconnected
// instead of growing the queue.
func (c *conn) send(msg any) {
	c.mu.Lock()
	if len(c.out) >= sendQueue {
		c.gone = true
		c.mu.Unlock()
		c.kill()
		return
	}
	c.out = append(c.out, msg)
	c.mu.Unlock()
	select {
	case c.wakeCh <- struct{}{}:
	default:
	}
}

// queued reports whether messages still wait to be written.
func (c *conn) queued() bool {
	c.mu.Lock()
	defer c.mu.Unlock()
	return len(c.out) > 0 && !c.gone
}

func (c *conn) blocks(user string) bool {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.block[user]
}

func (c *conn) setBlocks(set map[string]bool) {
	c.mu.Lock()
	c.block = set
	c.mu.Unlock()
}

// removedFrom is called by the hub (under its lock) when the host removed
// this user from the watched table.
func (c *conn) removedFrom(id string) {
	c.mu.Lock()
	if c.table == id {
		c.table = ""
		c.flags &^= dirtyTable
	}
	c.mu.Unlock()
	c.send(removedMsg{Type: "removed", Table: id})
}

type removedMsg struct {
	Type  string `json:"type"` // "removed"
	Table string `json:"table"`
}

// closedView is called by the hub (under its lock) when the watched table
// closed: the client gets the final view and watches nothing.
func (c *conn) closedView(s table.State) {
	c.mu.Lock()
	if c.table == s.ID {
		c.table = ""
		c.flags &^= dirtyTable
	}
	c.mu.Unlock()
	c.send(viewMsg{Type: "view", View: viewFor(s, c.user.ID)})
}

// Server messages.
type (
	helloMsg struct {
		Type string `json:"type"` // "hello"
		User string `json:"user"`
		Name string `json:"name"`
	}
	viewMsg struct {
		Type string     `json:"type"` // "view"
		View table.View `json:"view"`
	}
	lobbyMsg struct {
		Type   string       `json:"type"` // "lobby"
		Tables []LobbyTable `json:"tables"`
	}
	replyMsg struct {
		Type  string `json:"type"` // "ok" or "error"
		ID    int64  `json:"id,omitempty"`
		Error string `json:"error,omitempty"`
	}
	chatMsg struct {
		Type  string    `json:"type"` // "chat"
		Table string    `json:"table"`
		User  string    `json:"user"`
		Name  string    `json:"name"`
		Text  string    `json:"text"`
		At    time.Time `json:"at"`
	}
)

// Intent is a client message.
type Intent struct {
	ID     int64  `json:"id,omitempty"` // echoed in the reply
	Type   string `json:"type"`
	Table  string `json:"table,omitempty"`  // watch
	On     *bool  `json:"on,omitempty"`     // lobby
	Seat   *int   `json:"seat,omitempty"`   // sit
	Action string `json:"action,omitempty"` // act: fold, check, call, bet, raise
	To     int64  `json:"to,omitempty"`     // act: bet/raise total for the street
	Text   string `json:"text,omitempty"`   // chat
	User   string `json:"user,omitempty"`   // mute, unmute, remove, call_mute, call_remove
	Source string `json:"source,omitempty"` // call_mute: microphone or camera
}

// Errors of intents, sent as reply codes.
var (
	errBadIntent   = errors.New("bad_intent")
	errNotWatching = errors.New("not_watching")
	errNoSpectator = errors.New("spectators_off")
	errBadChat     = errors.New("bad_chat")
	errRateLimited = errors.New("rate_limited")
	errHostOnly    = errors.New("host_or_admin_only")
	errMuted       = errors.New("muted")
	errRemoved     = errors.New("removed")
	errIsPlayer    = errors.New("is_player")
	errMediaOff    = errors.New("media_off")
)

func errorCode(err error) string {
	switch {
	case errors.Is(err, table.ErrNoTable), errors.Is(err, table.ErrClosed):
		return "no_table"
	case errors.Is(err, table.ErrSeatTaken):
		return "seat_taken"
	case errors.Is(err, table.ErrBadSeat):
		return "bad_seat"
	case errors.Is(err, table.ErrSeated):
		return "already_seated"
	case errors.Is(err, table.ErrNotSeated):
		return "not_seated"
	case errors.Is(err, table.ErrNotInHand), errors.Is(err, engine.ErrHandOver):
		return "not_in_hand"
	case errors.Is(err, engine.ErrNotYourTurn):
		return "not_your_turn"
	case errors.Is(err, engine.ErrIllegal):
		return "illegal_action"
	case errors.Is(err, engine.ErrAmount):
		return "bad_amount"
	case errors.Is(err, table.ErrNotSng):
		return "not_sng"
	case errors.Is(err, table.ErrStarted):
		return "sng_started"
	case errors.Is(err, table.ErrFewPlayers):
		return "too_few_players"
	case errors.Is(err, errBadIntent), errors.Is(err, errNotWatching), errors.Is(err, errNoSpectator),
		errors.Is(err, errBadChat), errors.Is(err, errRateLimited), errors.Is(err, errHostOnly),
		errors.Is(err, errMuted), errors.Is(err, errRemoved), errors.Is(err, errIsPlayer), errors.Is(err, errMediaOff):
		return err.Error()
	}
	return "internal"
}

var actions = map[string]engine.ActionKind{"fold": engine.Fold, "check": engine.Check,
	"call": engine.Call, "bet": engine.Bet, "raise": engine.Raise}

// viewFor builds a viewer's view; without spectators a viewer who is not
// seated sees the seats (to pick one) but not the hand.
func viewFor(s table.State, user string) table.View {
	v := s.ViewFor(user)
	if !s.Settings.Spectators && v.YourSeat < 0 {
		v.Hand = nil
		for i, sv := range v.Seats {
			if sv != nil {
				v.Seats[i] = &table.SeatView{User: sv.User, Name: sv.Name, Stack: sv.Stack, SittingOut: sv.SittingOut}
			}
		}
	}
	return v
}

// ErrTooManyConns is returned by Serve when the user has too many open
// connections.
var ErrTooManyConns = errors.New("too many connections")

// Serve runs one accepted connection until it closes.
func (s *Server) Serve(ctx context.Context, ws *websocket.Conn, u User) error {
	ctx, cancel := context.WithCancel(ctx)
	defer cancel()
	c := &conn{user: u, srv: s, ws: ws, wakeCh: make(chan struct{}, 1), kill: cancel}
	if s.Blocks != nil {
		set, err := s.Blocks(ctx, u.ID)
		if err != nil {
			ws.Close(websocket.StatusInternalError, "")
			return err
		}
		c.block = set
	}
	if !s.Hub.register(c) {
		ws.Close(websocket.StatusPolicyViolation, "too many connections")
		return ErrTooManyConns
	}
	defer s.Hub.unregister(c)
	ws.SetReadLimit(MaxMessageBytes)
	c.send(helloMsg{Type: "hello", User: u.ID, Name: u.Name})

	errc := make(chan error, 3)
	go func() { errc <- c.writeLoop(ctx) }()
	go func() { errc <- c.pingLoop(ctx) }()
	go func() { errc <- c.readLoop(ctx) }()
	err := <-errc
	cancel()
	c.mu.Lock()
	slow := c.gone
	c.mu.Unlock()
	if slow {
		ws.Close(websocket.StatusPolicyViolation, "too slow")
	} else {
		ws.Close(websocket.StatusNormalClosure, "")
	}
	return err
}

func (c *conn) write(ctx context.Context, msg any) error {
	b, err := json.Marshal(msg)
	if err != nil {
		return err
	}
	wctx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()
	return c.ws.Write(wctx, websocket.MessageText, b)
}

func (c *conn) writeLoop(ctx context.Context) error {
	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		case <-c.wakeCh:
		}
		c.mu.Lock()
		out, flags, tid := c.out, c.flags, c.table
		c.out, c.flags = nil, 0
		c.mu.Unlock()
		for _, m := range out {
			if err := c.write(ctx, m); err != nil {
				return err
			}
		}
		if flags&dirtyTable != 0 && tid != "" {
			if st, ok := c.srv.Hub.State(tid); ok {
				if err := c.write(ctx, viewMsg{Type: "view", View: viewFor(st, c.user.ID)}); err != nil {
					return err
				}
			}
		}
		if flags&dirtyLobby != 0 {
			if err := c.write(ctx, lobbyMsg{Type: "lobby", Tables: c.srv.Hub.Lobby()}); err != nil {
				return err
			}
		}
	}
}

func (c *conn) pingLoop(ctx context.Context) error {
	every := c.srv.PingEvery
	if every <= 0 {
		every = 25 * time.Second
	}
	t := time.NewTicker(every)
	defer t.Stop()
	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		case <-t.C:
		}
		pctx, cancel := context.WithTimeout(ctx, 15*time.Second)
		err := c.ws.Ping(pctx)
		cancel()
		if err != nil {
			return err
		}
		if c.srv.Check != nil {
			if err := c.srv.Check(ctx); err != nil {
				return err
			}
		}
	}
}

func (c *conn) readLoop(ctx context.Context) error {
	for {
		typ, b, err := c.ws.Read(ctx)
		if err != nil {
			return err
		}
		var in Intent
		dec := json.NewDecoder(strings.NewReader(string(b)))
		dec.DisallowUnknownFields()
		if typ != websocket.MessageText || dec.Decode(&in) != nil {
			c.send(replyMsg{Type: "error", Error: errBadIntent.Error()})
			continue
		}
		if err := c.handle(in); err != nil {
			c.send(replyMsg{Type: "error", ID: in.ID, Error: errorCode(err)})
		} else if in.ID != 0 {
			c.send(replyMsg{Type: "ok", ID: in.ID})
		}
	}
}

func (c *conn) watched() (*table.Table, error) {
	c.mu.Lock()
	id := c.table
	c.mu.Unlock()
	if id == "" {
		return nil, errNotWatching
	}
	return c.srv.Tables.Get(id)
}

func (c *conn) handle(in Intent) error {
	switch in.Type {
	case "ping":
		return nil
	case "lobby":
		c.srv.Hub.setLobby(c, in.On == nil || *in.On)
		return nil
	case "watch":
		t, err := c.srv.Tables.Get(in.Table)
		if err != nil {
			return err
		}
		if !c.srv.Hub.watchAllowed(t.ID(), c.user.ID) {
			return errRemoved
		}
		if _, ok := c.srv.Hub.State(t.ID()); !ok {
			// No change since the table was created: publish a first snapshot.
			st, err := t.Snapshot()
			if err != nil {
				return err
			}
			c.srv.Hub.Publish(st)
		}
		c.mu.Lock()
		c.table = t.ID()
		c.mu.Unlock()
		c.srv.Hub.watch(c, t.ID())
		c.send(c.srv.Hub.moderation(t.ID()))
		return nil
	case "unwatch":
		c.mu.Lock()
		c.table = ""
		c.mu.Unlock()
		c.srv.Hub.watch(c, "")
		return nil
	}
	t, err := c.watched()
	if err != nil {
		return err
	}
	switch in.Type {
	case "sit":
		if in.Seat == nil {
			return errBadIntent
		}
		return t.Sit(c.user.ID, c.user.Name, *in.Seat)
	case "sitout":
		return t.SitOut(c.user.ID)
	case "comeback":
		return t.ComeBack(c.user.ID)
	case "leave":
		return t.Leave(c.user.ID)
	case "act":
		k, ok := actions[in.Action]
		if !ok {
			return errBadIntent
		}
		return t.Act(c.user.ID, engine.Action{Kind: k, To: in.To})
	case "chat":
		return c.chatTo(t, in.Text)
	case "start":
		st, err := t.Snapshot()
		if err != nil {
			return err
		}
		if st.Host != c.user.ID && !c.user.Admin {
			return errHostOnly
		}
		return t.Start()
	case "mute", "unmute", "remove", "call_mute", "call_remove":
		return c.moderate(t, in)
	}
	return errBadIntent
}

// moderate runs the host's moderation: mute or unmute anyone's chat at the
// table, remove a spectator (players leave by the game's rules), switch off
// someone's microphone or camera in the call, or send them out of the call.
func (c *conn) moderate(t *table.Table, in Intent) error {
	if in.User == "" || in.User == c.user.ID {
		return errBadIntent
	}
	if strings.HasPrefix(in.Type, "call_") {
		if !c.srv.Hub.HasCalls() {
			return errMediaOff
		}
		if in.Type == "call_mute" && in.Source != "microphone" && in.Source != "camera" {
			return errBadIntent
		}
	}
	st, ok := c.srv.Hub.State(t.ID())
	if !ok {
		return table.ErrNoTable
	}
	if st.Host != c.user.ID && !c.user.Admin {
		return errHostOnly
	}
	switch in.Type {
	case "mute", "unmute":
		c.srv.Hub.mute(t.ID(), in.User, in.Type == "mute")
	case "call_mute":
		c.srv.Hub.callMute(t.ID(), in.User, in.Source)
	case "call_remove":
		c.srv.Hub.callRemove(t.ID(), in.User)
	case "remove":
		if st.ViewFor(in.User).YourSeat >= 0 {
			return errIsPlayer
		}
		c.srv.Hub.remove(t.ID(), in.User)
	}
	return nil
}

func (c *conn) chatTo(t *table.Table, text string) error {
	text = strings.TrimSpace(text)
	n := utf8.RuneCountInString(text)
	if n == 0 || n > MaxChatRunes || !utf8.ValidString(text) ||
		strings.ContainsFunc(text, func(r rune) bool { return unicode.IsControl(r) }) {
		return errBadChat
	}
	st, ok := c.srv.Hub.State(t.ID())
	if !ok {
		return table.ErrNoTable
	}
	if !st.Settings.Spectators && st.ViewFor(c.user.ID).YourSeat < 0 {
		return errNoSpectator
	}
	now := time.Now()
	c.mu.Lock()
	recent := c.chat[:0]
	for _, at := range c.chat {
		if now.Sub(at) < ChatWindow {
			recent = append(recent, at)
		}
	}
	c.chat = recent
	if len(c.chat) >= ChatBurst {
		c.mu.Unlock()
		return errRateLimited
	}
	c.chat = append(c.chat, now)
	c.mu.Unlock()
	return c.srv.Hub.chat(t.ID(), chatMsg{Type: "chat", Table: t.ID(), User: c.user.ID, Name: c.user.Name, Text: text, At: now.UTC()})
}
