package table

import (
	"errors"
	"testing"
	"time"
)

func TestManagerCloseRights(t *testing.T) {
	m := NewManager(time.Hour, nil)
	defer m.Shutdown()
	tb, err := m.Create("host", settings())
	if err != nil {
		t.Fatal(err)
	}
	if _, err := m.Create("host", Settings{Seats: 12}); err == nil {
		t.Fatal("bad settings accepted")
	}
	if got, _ := m.Get(tb.ID()); got != tb {
		t.Fatal("get")
	}
	if err := m.Close(tb.ID(), "guest", false); !errors.Is(err, ErrForbidden) {
		t.Fatalf("guest close: %v", err)
	}
	if err := m.Close(tb.ID(), "host", false); err != nil {
		t.Fatal(err)
	}
	<-tb.Done()
	if _, err := m.Get(tb.ID()); !errors.Is(err, ErrNoTable) {
		t.Fatal("closed table still listed")
	}
	tb2, _ := m.Create("host", settings())
	if err := m.Close(tb2.ID(), "admin", true); err != nil {
		t.Fatal(err)
	}
	if err := m.Close("nope", "admin", true); !errors.Is(err, ErrNoTable) {
		t.Fatal(err)
	}
}

func TestManagerClosesEmptyTables(t *testing.T) {
	m := NewManager(80*time.Millisecond, nil)
	defer m.Shutdown()
	empty, _ := m.Create("host", settings())
	busy, _ := m.Create("host", settings())
	if err := busy.Sit("a", "Ann", 0); err != nil {
		t.Fatal(err)
	}
	select {
	case <-empty.Done():
	case <-time.After(3 * time.Second):
		t.Fatal("empty table not closed")
	}
	time.Sleep(150 * time.Millisecond)
	if _, err := m.Get(busy.ID()); err != nil {
		t.Fatal("table with a player was closed")
	}
	if n := len(m.List()); n != 1 {
		t.Fatalf("%d tables listed", n)
	}
}
