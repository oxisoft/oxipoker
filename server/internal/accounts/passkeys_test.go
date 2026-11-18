package accounts

import (
	"errors"
	"strings"
	"testing"
	"time"
)

func TestPasskeyConfig(t *testing.T) {
	s := newService(t)
	for _, bad := range []string{"", "poker.example", "ftp://poker.example", "https://"} {
		if _, err := NewPasskeys(s, bad); err == nil {
			t.Fatalf("accepted PUBLIC_URL %q", bad)
		}
	}
	if _, err := NewPasskeys(s, "https://poker.example:8443"); err != nil {
		t.Fatal(err)
	}
}

func TestCeremoniesAreSingleUseAndExpire(t *testing.T) {
	s := newService(t)
	now := time.Unix(1_800_000_000, 0)
	s.now = func() time.Time { return now }
	p, err := NewPasskeys(s, "https://poker.example")
	if err != nil {
		t.Fatal(err)
	}
	id, _, err := p.BeginLogin()
	if err != nil {
		t.Fatal(err)
	}
	if _, err := p.takeCeremony(id); err != nil {
		t.Fatal(err)
	}
	if _, err := p.takeCeremony(id); !errors.Is(err, ErrCeremony) {
		t.Fatalf("second use: %v", err)
	}
	id, _, _ = p.BeginLogin()
	now = now.Add(CeremonyTTL + time.Second)
	if _, err := p.takeCeremony(id); !errors.Is(err, ErrCeremony) {
		t.Fatalf("expired ceremony: %v", err)
	}
	// Expired ceremonies are swept, and the table is capped.
	for range maxCeremonies {
		if _, _, err := p.BeginLogin(); err != nil {
			t.Fatal(err)
		}
	}
	if _, _, err := p.BeginLogin(); !errors.Is(err, ErrCeremony) {
		t.Fatalf("cap: %v", err)
	}
	now = now.Add(CeremonyTTL + time.Second)
	if _, _, err := p.BeginLogin(); err != nil {
		t.Fatalf("after sweep: %v", err)
	}
}

func TestPasskeyNames(t *testing.T) {
	if n, err := checkPasskeyName("   "); err != nil || n != "Passkey" {
		t.Fatalf("empty name: %q %v", n, err)
	}
	if _, err := checkPasskeyName(strings.Repeat("é", 65)); !errors.Is(err, ErrBadPasskeyName) {
		t.Fatalf("long name: %v", err)
	}
}
