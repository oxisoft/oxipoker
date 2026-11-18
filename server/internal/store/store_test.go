package store

import (
	"context"
	"os"
	"path/filepath"
	"testing"
	"time"
)

func open(t *testing.T, dir string) *Store {
	t.Helper()
	s, err := Open(context.Background(), dir)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { s.Close() })
	return s
}

func TestOpenSetsPragmasAndMigrates(t *testing.T) {
	dir := t.TempDir()
	s := open(t, dir)
	ctx := context.Background()

	var mode string
	if err := s.DB().QueryRowContext(ctx, "PRAGMA journal_mode").Scan(&mode); err != nil || mode != "wal" {
		t.Fatalf("journal_mode = %q, %v", mode, err)
	}
	var fk, busy int
	if err := s.DB().QueryRowContext(ctx, "PRAGMA foreign_keys").Scan(&fk); err != nil || fk != 1 {
		t.Fatalf("foreign_keys = %d, %v", fk, err)
	}
	if err := s.DB().QueryRowContext(ctx, "PRAGMA busy_timeout").Scan(&busy); err != nil || busy != 10000 {
		t.Fatalf("busy_timeout = %d, %v", busy, err)
	}
	ms, _ := loadMigrations()
	v, err := s.SchemaVersion(ctx)
	if err != nil || v != ms[len(ms)-1].version {
		t.Fatalf("schema version = %d, %v", v, err)
	}
	if _, err := os.Stat(filepath.Join(dir, FileName)); err != nil {
		t.Fatal(err)
	}
}

func TestReopenIsIdempotent(t *testing.T) {
	dir := t.TempDir()
	s := open(t, dir)
	if err := s.SetSetting(context.Background(), "k", "v"); err != nil {
		t.Fatal(err)
	}
	s.Close()

	s2 := open(t, dir)
	var n int
	if err := s2.DB().QueryRow("SELECT COUNT(*) FROM schema_migrations").Scan(&n); err != nil {
		t.Fatal(err)
	}
	ms, _ := loadMigrations()
	if n != len(ms) {
		t.Fatalf("migrations recorded %d times, want %d", n, len(ms))
	}
	if v, _ := s2.Setting(context.Background(), "k", ""); v != "v" {
		t.Fatalf("setting lost after reopen: %q", v)
	}
}

func TestRefusesNewerSchema(t *testing.T) {
	dir := t.TempDir()
	s := open(t, dir)
	if _, err := s.DB().Exec("INSERT INTO schema_migrations VALUES (9999, '9999_future.sql', 0)"); err != nil {
		t.Fatal(err)
	}
	s.Close()
	if _, err := Open(context.Background(), dir); err == nil {
		t.Fatal("opened a database with a newer schema")
	}
}

func TestSettings(t *testing.T) {
	s := open(t, t.TempDir())
	ctx := context.Background()
	if v, err := s.Setting(ctx, "missing", "def"); err != nil || v != "def" {
		t.Fatalf("default = %q, %v", v, err)
	}
	_ = s.SetSetting(ctx, "a", "1")
	_ = s.SetSetting(ctx, "a", "2")
	if v, _ := s.Setting(ctx, "a", ""); v != "2" {
		t.Fatalf("upsert = %q", v)
	}
}

func TestAudit(t *testing.T) {
	s := open(t, t.TempDir())
	ctx := context.Background()
	if err := s.Audit(ctx, AuditEvent{}); err == nil {
		t.Fatal("event without action accepted")
	}
	at := time.Date(2026, 11, 18, 8, 0, 0, 0, time.UTC)
	events := []AuditEvent{
		{At: at, ActorID: "u1", ActorName: "oxi", Action: "user.create", Target: "u2", IP: "192.0.2.1", Detail: map[string]any{"admin": false}},
		{ActorID: "u1", ActorName: "oxi", Action: "invite.create", Target: "i1"},
		{ActorID: "u2", ActorName: "alex", Action: "user.signin", IP: "192.0.2.2"},
	}
	for _, e := range events {
		if err := s.Audit(ctx, e); err != nil {
			t.Fatal(err)
		}
	}
	all, err := s.ListAudit(ctx, AuditFilter{})
	if err != nil || len(all) != 3 {
		t.Fatalf("list = %d, %v", len(all), err)
	}
	if all[0].Action != "user.signin" || all[2].Action != "user.create" {
		t.Fatalf("not newest first: %v", all)
	}
	first := all[2]
	if !first.At.Equal(at) || first.IP != "192.0.2.1" || first.Detail["admin"] != false {
		t.Fatalf("round trip: %+v", first)
	}
	if got, _ := s.ListAudit(ctx, AuditFilter{ActorID: "u1"}); len(got) != 2 {
		t.Fatalf("actor filter = %d", len(got))
	}
	if got, _ := s.ListAudit(ctx, AuditFilter{Action: "user."}); len(got) != 2 {
		t.Fatalf("prefix filter = %d", len(got))
	}
	if got, _ := s.ListAudit(ctx, AuditFilter{Action: "user"}); len(got) != 0 {
		t.Fatalf("exact filter matched a prefix: %d", len(got))
	}
	if got, _ := s.ListAudit(ctx, AuditFilter{Before: all[0].ID, Limit: 1}); len(got) != 1 || got[0].Action != "invite.create" {
		t.Fatalf("paging = %v", got)
	}
}

func TestConcurrentWrites(t *testing.T) {
	s := open(t, t.TempDir())
	ctx := context.Background()
	errs := make(chan error, 40)
	for range 40 {
		go func() { errs <- s.Audit(ctx, AuditEvent{Action: "test.write"}) }()
	}
	for range 40 {
		if err := <-errs; err != nil {
			t.Fatal(err)
		}
	}
	if got, _ := s.ListAudit(ctx, AuditFilter{Limit: 500}); len(got) != 40 {
		t.Fatalf("writes = %d", len(got))
	}
}
