package realtime

import (
	"context"
	"slices"
	"strings"
	"sync"
	"testing"
	"time"
)

type fakeCalls struct {
	mu  sync.Mutex
	log []string
}

func (f *fakeCalls) add(s string) error {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.log = append(f.log, s)
	return nil
}
func (f *fakeCalls) Mute(_ context.Context, id, user, source string) error {
	return f.add("mute " + user + " " + source)
}
func (f *fakeCalls) Remove(_ context.Context, id, user string) error { return f.add("remove " + user) }
func (f *fakeCalls) Close(_ context.Context, id string) error        { return f.add("close") }
func (f *fakeCalls) got() []string {
	f.mu.Lock()
	defer f.mu.Unlock()
	return slices.Clone(f.log)
}

func TestCallModeration(t *testing.T) {
	// Minimal option: call intents answer media_off.
	plain := newRig(t)
	pid := plain.table(t, true)
	pa := plain.dial(t, "a")
	pa.do(map[string]any{"type": "watch", "table": pid})
	if e := pa.do(map[string]any{"type": "call_remove", "user": "b"}); e != "media_off" {
		t.Fatalf("call intent without media: %q", e)
	}

	r := newRig(t)
	calls := &fakeCalls{}
	r.hub.SetCalls(calls)
	id := r.table(t, true) // host "a"
	a, b, s := r.dial(t, "a"), r.dial(t, "b"), r.dial(t, "s")
	for _, c := range []*client{a, b, s} {
		c.do(map[string]any{"type": "watch", "table": id})
	}
	a.do(map[string]any{"type": "sit", "seat": 0})
	b.do(map[string]any{"type": "sit", "seat": 1})

	if e := b.do(map[string]any{"type": "call_mute", "user": "s", "source": "camera"}); e != "host_or_admin_only" {
		t.Fatalf("call mute by guest: %q", e)
	}
	if e := a.do(map[string]any{"type": "call_mute", "user": "s", "source": "screen"}); e != "bad_intent" {
		t.Fatalf("bad source: %q", e)
	}
	if e := a.do(map[string]any{"type": "call_mute", "user": "b", "source": "microphone"}); e != "" {
		t.Fatal(e)
	}
	// A player can be sent out of the call and keeps the seat; no new token.
	if !r.hub.Watching(id, "b") {
		t.Fatal("b not watching before")
	}
	if e := a.do(map[string]any{"type": "call_remove", "user": "b"}); e != "" {
		t.Fatal(e)
	}
	if r.hub.Watching(id, "b") {
		t.Fatal("b removed from the call may still get a token")
	}
	if e := b.do(map[string]any{"type": "chat", "text": "still playing"}); e != "" {
		t.Fatalf("b lost the table: %q", e)
	}
	// Removing a spectator from the table also ends their call.
	if e := a.do(map[string]any{"type": "remove", "user": "s"}); e != "" {
		t.Fatal(e)
	}
	if err := r.tables.Close(id, "a", false); err != nil {
		t.Fatal(err)
	}
	deadline := time.Now().Add(2 * time.Second)
	for len(calls.got()) < 4 && time.Now().Before(deadline) {
		time.Sleep(10 * time.Millisecond)
	}
	r.hub.WaitCalls()
	// Requests run in their own goroutines: compare as a set.
	got := calls.got()
	slices.Sort(got)
	want := []string{"close", "mute b microphone", "remove b", "remove s"}
	if strings.Join(got, "|") != strings.Join(want, "|") {
		t.Fatalf("calls %v, want %v", got, want)
	}
	if r.hub.Watching(id, "b") {
		t.Fatal("closed table still has a call")
	}
}
