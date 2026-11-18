package accounts

import (
	"bytes"
	"context"
	"errors"
	"log/slog"
	"strings"
	"testing"
	"time"

	"github.com/oxisoft/oxipoker/server/internal/store"
)

func newService(t *testing.T) *Service {
	t.Helper()
	st, err := store.Open(context.Background(), t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { st.Close() })
	return New(st)
}

func TestPasswordHashing(t *testing.T) {
	h, err := HashPassword("correct horse battery")
	if err != nil || !strings.HasPrefix(h, "$argon2id$v=19$m=19456,t=2,p=1$") {
		t.Fatalf("hash %q, %v", h, err)
	}
	h2, _ := HashPassword("correct horse battery")
	if h == h2 {
		t.Fatal("same salt twice")
	}
	if ok, err := VerifyPassword(h, "correct horse battery"); !ok || err != nil {
		t.Fatalf("verify good: %v %v", ok, err)
	}
	if ok, _ := VerifyPassword(h, "correct horse batterY"); ok {
		t.Fatal("verify bad password succeeded")
	}
	for _, bad := range []string{"", "$bcrypt$x", "$argon2id$v=19$m=0,t=1,p=1$AA$AA", "$argon2id$v=19$m=99999999,t=1,p=1$AA$AA"} {
		if _, err := VerifyPassword(bad, "x"); err == nil {
			t.Fatalf("accepted hash %q", bad)
		}
	}
	if CheckPassword("short") == nil || CheckPassword(strings.Repeat("a", 257)) == nil || CheckPassword("          ") == nil {
		t.Fatal("weak password accepted")
	}
	if CheckPassword("ten chars!") != nil {
		t.Fatal("10 characters rejected")
	}
}

func TestUsernames(t *testing.T) {
	s := newService(t)
	ctx := context.Background()
	for _, bad := range []string{"ab", strings.Repeat("a", 33), "has space", "émile", "a/b"} {
		if _, err := s.CreateUser(ctx, NewUser{Username: bad}); !errors.Is(err, ErrBadUsername) {
			t.Fatalf("%q: %v", bad, err)
		}
	}
	u, err := s.CreateUser(ctx, NewUser{Username: "Alex", Password: "long enough pw"})
	if err != nil || u.DisplayName != "Alex" {
		t.Fatalf("%+v %v", u, err)
	}
	if _, err := s.CreateUser(ctx, NewUser{Username: "alex"}); !errors.Is(err, ErrUsernameTaken) {
		t.Fatalf("case-insensitive unique: %v", err)
	}
	got, err := s.UserByUsername(ctx, "ALEX")
	if err != nil || got.ID != u.ID || got.Username != "Alex" {
		t.Fatalf("lookup: %+v %v", got, err)
	}
	if _, err := s.UserByID(ctx, "nope"); !errors.Is(err, ErrNotFound) {
		t.Fatal(err)
	}
	if _, err := s.CreateUser(ctx, NewUser{Username: "bob", DisplayName: "   "}); !errors.Is(err, ErrBadDisplayName) {
		t.Fatal(err)
	}
	if _, err := s.CreateUser(ctx, NewUser{Username: "carol", Password: "short"}); !errors.Is(err, ErrWeakPassword) {
		t.Fatal(err)
	}
}

func TestAuthenticate(t *testing.T) {
	s := newService(t)
	ctx := context.Background()
	u, _ := s.CreateUser(ctx, NewUser{Username: "alex", Password: "long enough pw"})
	if got, err := s.Authenticate(ctx, "ALEX", "long enough pw"); err != nil || got.ID != u.ID {
		t.Fatalf("good: %v", err)
	}
	if _, err := s.Authenticate(ctx, "alex", "wrong password"); !errors.Is(err, ErrInvalidCredentials) {
		t.Fatal(err)
	}
	if _, err := s.Authenticate(ctx, "nobody", "long enough pw"); !errors.Is(err, ErrInvalidCredentials) {
		t.Fatal(err)
	}
	_, _ = s.CreateUser(ctx, NewUser{Username: "passkeyonly"})
	if _, err := s.Authenticate(ctx, "passkeyonly", ""); !errors.Is(err, ErrInvalidCredentials) {
		t.Fatal("empty password matched a passkey-only account")
	}
	_, _ = s.db.Exec(`UPDATE users SET disabled_at = 1 WHERE id = ?`, u.ID)
	if _, err := s.Authenticate(ctx, "alex", "long enough pw"); !errors.Is(err, ErrInvalidCredentials) {
		t.Fatal("disabled user signed in")
	}
}

func TestBootstrap(t *testing.T) {
	s := newService(t)
	ctx := context.Background()
	var buf bytes.Buffer
	log := slog.New(slog.NewTextHandler(&buf, nil))

	if err := s.Bootstrap(ctx, "", "", log); err != nil || !strings.Contains(buf.String(), "no admin") {
		t.Fatalf("empty env: %v %s", err, buf.String())
	}
	if err := s.Bootstrap(ctx, "oxi", "short", log); err == nil {
		t.Fatal("weak bootstrap password accepted")
	}
	if err := s.Bootstrap(ctx, "oxi", "first admin password", log); err != nil {
		t.Fatal(err)
	}
	u, err := s.UserByUsername(ctx, "oxi")
	if err != nil || !u.IsAdmin {
		t.Fatalf("admin: %+v %v", u, err)
	}
	buf.Reset()
	if err := s.Bootstrap(ctx, "other", "another admin password", log); err != nil || !strings.Contains(buf.String(), "ignored") {
		t.Fatalf("second run: %v %s", err, buf.String())
	}
	if _, err := s.UserByUsername(ctx, "other"); !errors.Is(err, ErrNotFound) {
		t.Fatal("second bootstrap created a user")
	}
	if _, err := s.Authenticate(ctx, "oxi", "another admin password"); err == nil {
		t.Fatal("second bootstrap changed the password")
	}
	ev, _ := s.Store().ListAudit(ctx, store.AuditFilter{Action: "user.bootstrap_admin"})
	if len(ev) != 1 || ev[0].Target != u.ID {
		t.Fatalf("audit: %+v", ev)
	}
}

func TestSessions(t *testing.T) {
	s := newService(t)
	ctx := context.Background()
	clock := time.Date(2026, 11, 18, 8, 0, 0, 0, time.UTC)
	s.now = func() time.Time { return clock }
	u, _ := s.CreateUser(ctx, NewUser{Username: "alex", Password: "long enough pw"})

	if _, _, err := s.CreateSession(ctx, u.ID, "sms", "", ""); err == nil {
		t.Fatal("bad kind accepted")
	}
	tok, ss, err := s.CreateSession(ctx, u.ID, KindApp, "192.0.2.1", strings.Repeat("x", 500))
	if err != nil || len(tok) != 43 {
		t.Fatalf("create: %q %v", tok, err)
	}
	var stored []byte
	_ = s.db.QueryRow(`SELECT token_hash FROM sessions WHERE id = ?`, ss.ID).Scan(&stored)
	if bytes.Contains(stored, []byte(tok)) || len(stored) != 32 {
		t.Fatal("token stored in clear")
	}

	gs, gu, err := s.SessionUser(ctx, tok)
	if err != nil || gu.ID != u.ID || gs.ID != ss.ID || len(gs.UserAgent) != maxUALen {
		t.Fatalf("lookup: %v", err)
	}
	for _, bad := range []string{"", tok + "x", "a b", strings.Repeat("a", 200)} {
		if _, _, err := s.SessionUser(ctx, bad); !errors.Is(err, ErrNotFound) {
			t.Fatalf("token %q: %v", bad, err)
		}
	}

	// Sliding renewal: used after 20 days, it lives 30 more days.
	clock = clock.Add(20 * 24 * time.Hour)
	gs, _, _ = s.SessionUser(ctx, tok)
	if !gs.ExpiresAt.Equal(clock.Add(SessionTTL)) {
		t.Fatalf("not renewed: %v", gs.ExpiresAt)
	}
	clock = clock.Add(SessionTTL + time.Second)
	if _, _, err := s.SessionUser(ctx, tok); !errors.Is(err, ErrNotFound) {
		t.Fatal("expired session accepted")
	}

	t1, s1, _ := s.CreateSession(ctx, u.ID, KindWeb, "", "")
	_, s2, _ := s.CreateSession(ctx, u.ID, KindApp, "", "")
	list, _ := s.ListSessions(ctx, u.ID)
	if len(list) != 2 {
		t.Fatalf("list = %d", len(list))
	}
	other, _ := s.CreateUser(ctx, NewUser{Username: "bob"})
	if err := s.RevokeSession(ctx, other.ID, s1.ID); !errors.Is(err, ErrNotFound) {
		t.Fatal("revoked someone else's session")
	}
	if err := s.RevokeSession(ctx, u.ID, s2.ID); err != nil {
		t.Fatal(err)
	}
	if n, _ := s.RevokeAllSessions(ctx, u.ID, s1.ID); n != 0 {
		t.Fatalf("revoke all removed %d", n)
	}
	if _, _, err := s.SessionUser(ctx, t1); err != nil {
		t.Fatal("kept session lost")
	}
	_, _ = s.db.Exec(`UPDATE users SET disabled_at = 1 WHERE id = ?`, u.ID)
	if _, _, err := s.SessionUser(ctx, t1); !errors.Is(err, ErrNotFound) {
		t.Fatal("disabled user's session accepted")
	}
	_, _ = s.db.Exec(`DELETE FROM users WHERE id = ?`, other.ID)
	clock = clock.Add(2 * SessionTTL)
	if _, err := s.PurgeExpiredSessions(ctx); err != nil {
		t.Fatal(err)
	}
}
