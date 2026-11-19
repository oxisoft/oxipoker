package realtime

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/coder/websocket"
)

func TestFloodingClientIsClosed(t *testing.T) {
	r := newRig(t)
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	ws, _, err := websocket.Dial(ctx, r.url+"?u=a", nil)
	if err != nil {
		t.Fatal(err)
	}
	defer ws.Close(websocket.StatusNormalClosure, "")
	go func() {
		for range 10 * int(IntentBurst) {
			if ws.Write(ctx, websocket.MessageText, []byte(`{"type":"watch","table":"nope"}`)) != nil {
				return
			}
		}
	}()
	for {
		if _, _, err = ws.Read(ctx); err != nil {
			break
		}
	}
	var ce websocket.CloseError
	if !errors.As(err, &ce) || ce.Code != websocket.StatusPolicyViolation || ce.Reason != "too many messages" {
		t.Fatalf("flooding connection ended with %v, want policy violation 'too many messages'", err)
	}
}

func TestSteadyClientBelowTheRateStaysOpen(t *testing.T) {
	r := newRig(t)
	c := r.dial(t, "a")
	tb := r.table(t, true)
	// Twice the burst at half the rate: the bucket never runs dry.
	for range 2 * int(IntentBurst) {
		if e := c.do(map[string]any{"type": "watch", "table": tb}); e != "" {
			t.Fatal(e)
		}
		time.Sleep(time.Duration(float64(time.Second) / (IntentRate / 2)))
	}
}
