package realtime

import (
	"strings"
	"testing"
	"time"
)

func TestBlockMuteAndRemove(t *testing.T) {
	r := newRig(t)
	id := r.table(t, true) // host "a"
	a, b, s := r.dial(t, "a"), r.dial(t, "b"), r.dial(t, "s")
	for _, c := range []*client{a, b, s} {
		c.do(map[string]any{"type": "watch", "table": id})
	}
	a.do(map[string]any{"type": "sit", "seat": 0})

	// b blocks s: s's lines no longer reach b, everyone else still sees them.
	r.hub.SetBlocks("b", map[string]bool{"s": true})
	s.do(map[string]any{"type": "chat", "text": "hidden from b"})
	b.do(map[string]any{"type": "chat", "text": "from b"})
	if m := a.wait(func(m msg) bool { return m.Type == "chat" }); m.Text != "hidden from b" {
		t.Fatalf("a first chat: %+v", m)
	}
	if m := b.wait(func(m msg) bool { return m.Type == "chat" }); m.Text != "from b" {
		t.Fatalf("b got a blocked line: %+v", m)
	}
	if got := r.hub.RecentChat(id); len(got) != 2 || got[0].User != "s" {
		t.Fatalf("chat log: %+v", got)
	}

	// Only the host (or an admin) moderates.
	if e := b.do(map[string]any{"type": "mute", "user": "s"}); e != "host_or_admin_only" {
		t.Fatalf("mute by guest: %q", e)
	}
	if e := a.do(map[string]any{"type": "mute", "user": "s"}); e != "" {
		t.Fatal(e)
	}
	if m := s.wait(func(m msg) bool { return m.Type == "moderation" && strings.Contains(string(m.Raw), `"muted":["s"]`) }); m.Type == "" {
		t.Fatal("no moderation message")
	}
	if e := s.do(map[string]any{"type": "chat", "text": "muted now"}); e != "muted" {
		t.Fatalf("muted chat: %q", e)
	}
	a.do(map[string]any{"type": "unmute", "user": "s"})
	if e := s.do(map[string]any{"type": "chat", "text": "back"}); e != "" {
		t.Fatalf("unmuted chat: %q", e)
	}

	// Players are not removed; spectators are, and stay out.
	if e := a.do(map[string]any{"type": "remove", "user": "a"}); e != "bad_intent" {
		t.Fatalf("remove self: %q", e)
	}
	b.do(map[string]any{"type": "sit", "seat": 1})
	time.Sleep(30 * time.Millisecond)
	if e := a.do(map[string]any{"type": "remove", "user": "b"}); e != "is_player" {
		t.Fatalf("remove player: %q", e)
	}
	if e := a.do(map[string]any{"type": "remove", "user": "s"}); e != "" {
		t.Fatal(e)
	}
	s.wait(func(m msg) bool { return m.Type == "removed" })
	if e := s.do(map[string]any{"type": "chat", "text": "still here?"}); e != "not_watching" {
		t.Fatalf("chat after remove: %q", e)
	}
	if e := s.do(map[string]any{"type": "watch", "table": id}); e != "removed" {
		t.Fatalf("watch after remove: %q", e)
	}
}
