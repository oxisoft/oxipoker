// Package store owns the SQLite database in DATA_DIR: connection settings,
// embedded migrations and the small tables shared by every module.
package store

import (
	"context"
	"database/sql"
	"embed"
	"errors"
	"fmt"
	"io/fs"
	"net/url"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"time"

	_ "github.com/ncruces/go-sqlite3/driver" // registers the "sqlite3" driver
)

//go:embed migrations/*.sql
var migrationFS embed.FS

// FileName is the database file inside DATA_DIR.
const FileName = "oxipoker.db"

// Store wraps the database handle.
type Store struct {
	db *sql.DB
}

// Open creates DATA_DIR if needed, opens the database with WAL, foreign keys
// and a busy timeout, and applies every pending migration.
func Open(ctx context.Context, dataDir string) (*Store, error) {
	if err := os.MkdirAll(dataDir, 0o700); err != nil {
		return nil, fmt.Errorf("store: data dir: %w", err)
	}
	path, err := filepath.Abs(filepath.Join(dataDir, FileName))
	if err != nil {
		return nil, err
	}
	q := url.Values{}
	q.Add("_pragma", "journal_mode(WAL)")
	q.Add("_pragma", "foreign_keys(1)")
	q.Add("_pragma", "busy_timeout(10000)")
	q.Add("_pragma", "synchronous(NORMAL)")
	q.Set("_txlock", "immediate")
	dsn := "file:" + filepath.ToSlash(path) + "?" + q.Encode()

	db, err := sql.Open("sqlite3", dsn)
	if err != nil {
		return nil, fmt.Errorf("store: open: %w", err)
	}
	db.SetMaxOpenConns(8)
	db.SetConnMaxIdleTime(5 * time.Minute)
	if err := db.PingContext(ctx); err != nil {
		db.Close()
		return nil, fmt.Errorf("store: ping: %w", err)
	}
	s := &Store{db: db}
	if err := s.migrate(ctx); err != nil {
		db.Close()
		return nil, err
	}
	return s, nil
}

// DB returns the database handle for the modules that own their tables.
func (s *Store) DB() *sql.DB { return s.db }

// Close closes the database.
func (s *Store) Close() error { return s.db.Close() }

// Backup writes a consistent copy of the live database to dst with VACUUM
// INTO. It is safe while the server runs: readers and writers keep going and
// the copy holds every committed transaction up to the moment it starts. The
// parent directory is created; an existing dst is refused, so a backup never
// overwrites another one.
func (s *Store) Backup(ctx context.Context, dst string) error {
	if dst == "" {
		return fmt.Errorf("store: backup: empty destination")
	}
	if _, err := os.Stat(dst); err == nil {
		return fmt.Errorf("store: backup: %s already exists", dst)
	}
	if err := os.MkdirAll(filepath.Dir(dst), 0o700); err != nil {
		return fmt.Errorf("store: backup dir: %w", err)
	}
	if _, err := s.db.ExecContext(ctx, `VACUUM INTO ?`, dst); err != nil {
		return fmt.Errorf("store: backup: %w", err)
	}
	return os.Chmod(dst, 0o600)
}

// Ping reports whether the database answers.
func (s *Store) Ping(ctx context.Context) error { return s.db.PingContext(ctx) }

type migration struct {
	version int
	name    string
	sql     string
}

func loadMigrations() ([]migration, error) {
	entries, err := fs.ReadDir(migrationFS, "migrations")
	if err != nil {
		return nil, err
	}
	var out []migration
	seen := map[int]bool{}
	for _, e := range entries {
		name := e.Name()
		num, _, ok := strings.Cut(name, "_")
		if !ok || !strings.HasSuffix(name, ".sql") {
			return nil, fmt.Errorf("store: bad migration name %q", name)
		}
		v, err := strconv.Atoi(num)
		if err != nil || v <= 0 || seen[v] {
			return nil, fmt.Errorf("store: bad migration version %q", name)
		}
		seen[v] = true
		body, err := migrationFS.ReadFile("migrations/" + name)
		if err != nil {
			return nil, err
		}
		out = append(out, migration{version: v, name: name, sql: string(body)})
	}
	sort.Slice(out, func(i, j int) bool { return out[i].version < out[j].version })
	return out, nil
}

func (s *Store) migrate(ctx context.Context) error {
	if _, err := s.db.ExecContext(ctx, `CREATE TABLE IF NOT EXISTS schema_migrations (
		version    INTEGER PRIMARY KEY,
		name       TEXT NOT NULL,
		applied_at INTEGER NOT NULL
	) STRICT`); err != nil {
		return fmt.Errorf("store: version table: %w", err)
	}
	ms, err := loadMigrations()
	if err != nil {
		return err
	}
	current, err := s.SchemaVersion(ctx)
	if err != nil {
		return err
	}
	if len(ms) > 0 && current > ms[len(ms)-1].version {
		return fmt.Errorf("store: database schema %d is newer than this server (%d): refusing to downgrade", current, ms[len(ms)-1].version)
	}
	for _, m := range ms {
		if m.version <= current {
			continue
		}
		if err := s.apply(ctx, m); err != nil {
			return err
		}
	}
	return nil
}

func (s *Store) apply(ctx context.Context, m migration) error {
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()
	if _, err := tx.ExecContext(ctx, m.sql); err != nil {
		return fmt.Errorf("store: migration %s: %w", m.name, err)
	}
	if _, err := tx.ExecContext(ctx, `INSERT INTO schema_migrations (version, name, applied_at) VALUES (?, ?, ?)`,
		m.version, m.name, time.Now().UnixMilli()); err != nil {
		return fmt.Errorf("store: record migration %s: %w", m.name, err)
	}
	return tx.Commit()
}

// SchemaVersion returns the highest applied migration, 0 for a new database.
func (s *Store) SchemaVersion(ctx context.Context) (int, error) {
	var v sql.NullInt64
	err := s.db.QueryRowContext(ctx, `SELECT MAX(version) FROM schema_migrations`).Scan(&v)
	if err != nil && !errors.Is(err, sql.ErrNoRows) {
		return 0, fmt.Errorf("store: schema version: %w", err)
	}
	return int(v.Int64), nil
}

// Setting returns a server setting, or def when it was never set.
func (s *Store) Setting(ctx context.Context, key, def string) (string, error) {
	var v string
	err := s.db.QueryRowContext(ctx, `SELECT value FROM settings WHERE key = ?`, key).Scan(&v)
	if errors.Is(err, sql.ErrNoRows) {
		return def, nil
	}
	if err != nil {
		return "", fmt.Errorf("store: setting %s: %w", key, err)
	}
	return v, nil
}

// SetSetting stores a server setting.
func (s *Store) SetSetting(ctx context.Context, key, value string) error {
	_, err := s.db.ExecContext(ctx, `INSERT INTO settings (key, value, updated_at) VALUES (?, ?, ?)
		ON CONFLICT(key) DO UPDATE SET value = excluded.value, updated_at = excluded.updated_at`,
		key, value, time.Now().UnixMilli())
	if err != nil {
		return fmt.Errorf("store: set setting %s: %w", key, err)
	}
	return nil
}
