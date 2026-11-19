package media

import (
	"strings"
	"testing"
	"time"
)

var cfg = Config{URL: "wss://poker.example.com/livekit", Key: "APIkey1", Secret: "a-long-enough-secret-for-tests-0123456789"}

func TestConfigCheck(t *testing.T) {
	if err := (Config{}).Check(); err != nil || (Config{}).Enabled() {
		t.Fatalf("empty config must be valid and off: %v", err)
	}
	if !cfg.Enabled() {
		t.Fatal("full config must be on")
	}
	if err := (Config{Key: "k", Secret: "s"}).Check(); err != nil || (Config{Key: "k", Secret: "s"}).Enabled() {
		t.Fatalf("keys without LIVEKIT_URL must be valid and off (back to minimal): %v", err)
	}
	for _, c := range []Config{
		{URL: cfg.URL},
		{URL: cfg.URL, Key: "k"},
		{URL: cfg.URL, Secret: "s"},
		{URL: "ftp://x", Key: "k", Secret: "s"},
		{URL: "livekit:7880", Key: "k", Secret: "s"},
	} {
		if c.Check() == nil || c.Enabled() {
			t.Errorf("%+v must be rejected", c)
		}
	}
}

func TestJoinToken(t *testing.T) {
	now := time.Unix(1_800_000_000, 0)
	tok, exp, err := cfg.JoinToken("t1", "u1", "Alice", now)
	if err != nil {
		t.Fatal(err)
	}
	if !exp.Equal(now.Add(TokenTTL)) {
		t.Fatalf("expiry %v", exp)
	}
	cl, err := cfg.Verify(tok, now)
	if err != nil {
		t.Fatal(err)
	}
	v := cl.Video
	if cl.Subject != "u1" || cl.Name != "Alice" || cl.Issuer != "APIkey1" || v.Room != "table-t1" || !v.RoomJoin {
		t.Fatalf("claims %+v", cl)
	}
	if v.RoomAdmin || v.RoomCreate || !*v.CanPublish || !*v.CanSubscribe || *v.CanPublishData {
		t.Fatalf("grant %+v", v)
	}
	if _, err := cfg.Verify(tok, now.Add(TokenTTL)); err == nil {
		t.Fatal("expired token accepted")
	}
	other := cfg
	other.Secret = "another-secret-another-secret-0123456789"
	if _, err := other.Verify(tok, now); err == nil {
		t.Fatal("token verified with a different secret")
	}
	parts := strings.Split(tok, ".")
	if _, err := cfg.Verify(parts[0]+"."+parts[1]+"x."+parts[2], now); err == nil {
		t.Fatal("tampered token accepted")
	}
	tok2, _, _ := cfg.JoinToken("t1", "u1", "Alice", now)
	if tok2 == tok {
		t.Fatal("tokens must carry a unique id")
	}
	if _, _, err := (Config{}).JoinToken("t1", "u1", "A", now); err == nil {
		t.Fatal("token issued with media off")
	}
}

func TestAdminToken(t *testing.T) {
	now := time.Unix(1_800_000_000, 0)
	tok, err := cfg.AdminToken("t9", now)
	if err != nil {
		t.Fatal(err)
	}
	cl, err := cfg.Verify(tok, now)
	if err != nil {
		t.Fatal(err)
	}
	if !cl.Video.RoomAdmin || cl.Video.Room != "table-t9" || cl.Video.RoomJoin || cl.Subject != "" {
		t.Fatalf("admin claims %+v", cl)
	}
	if _, err := cfg.Verify(tok, now.Add(time.Minute)); err == nil {
		t.Fatal("admin token must be short-lived")
	}
}
