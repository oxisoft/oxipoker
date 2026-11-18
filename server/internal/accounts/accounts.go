// Package accounts owns users, passwords and sessions.
package accounts

import (
	"context"
	"crypto/rand"
	"database/sql"
	"errors"
	"fmt"
	"log/slog"
	"regexp"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/oxisoft/oxipoker/server/internal/store"
)

// Errors returned by the service.
var (
	ErrNotFound           = errors.New("not found")
	ErrUsernameTaken      = errors.New("username taken")
	ErrBadUsername        = errors.New("username must be 3 to 32 letters, digits, dot, dash or underscore")
	ErrBadDisplayName     = errors.New("display name must be 1 to 64 characters")
	ErrInvalidCredentials = errors.New("invalid credentials")
)

var usernameRE = regexp.MustCompile(`^[A-Za-z0-9_.-]{3,32}$`)

// User is an account. PasswordHash never leaves the server.
type User struct {
	ID                 string     `json:"id"`
	Username           string     `json:"username"`
	DisplayName        string     `json:"display_name"`
	IsAdmin            bool       `json:"is_admin"`
	Avatar             string     `json:"avatar,omitempty"`
	MustChangePassword bool       `json:"must_change_password"`
	CreatedAt          time.Time  `json:"created_at"`
	DisabledAt         *time.Time `json:"disabled_at,omitempty"`
	PasswordHash       string     `json:"-"`
}

// Disabled reports whether the account is disabled.
func (u *User) Disabled() bool { return u.DisabledAt != nil }

// Service is the accounts module.
type Service struct {
	st      *store.Store
	db      *sql.DB
	now     func() time.Time
	totpKey []byte
}

// New returns the accounts service on top of the store.
func New(st *store.Store) *Service {
	return &Service{st: st, db: st.DB(), now: time.Now}
}

// Store returns the underlying store (audit log, settings).
func (s *Service) Store() *store.Store { return s.st }

// NewID returns a random 128-bit identifier as 26 base32 characters.
func NewID() string { return rand.Text() }

// CheckUsername validates a username.
func CheckUsername(u string) error {
	if !usernameRE.MatchString(u) {
		return ErrBadUsername
	}
	return nil
}

func checkDisplayName(d string) (string, error) {
	d = strings.TrimSpace(d)
	if n := utf8.RuneCountInString(d); n < 1 || n > 64 {
		return "", ErrBadDisplayName
	}
	return d, nil
}

// NewUser holds the fields for CreateUser.
type NewUser struct {
	Username    string
	DisplayName string // defaults to Username
	Password    string // may be empty for passkey-only accounts
	IsAdmin     bool
	MustChange  bool
}

// CreateUser creates an account.
func (s *Service) CreateUser(ctx context.Context, n NewUser) (*User, error) {
	u, err := s.prepareUser(n)
	if err != nil {
		return nil, err
	}
	if err := s.insertUser(ctx, s.db, u); err != nil {
		return nil, err
	}
	return u, nil
}

// execer is *sql.DB or *sql.Tx.
type execer interface {
	ExecContext(ctx context.Context, query string, args ...any) (sql.Result, error)
}

// prepareUser validates n and hashes its password; nothing is stored yet.
func (s *Service) prepareUser(n NewUser) (*User, error) {
	if err := CheckUsername(n.Username); err != nil {
		return nil, err
	}
	if n.DisplayName == "" {
		n.DisplayName = n.Username
	}
	display, err := checkDisplayName(n.DisplayName)
	if err != nil {
		return nil, err
	}
	hash := ""
	if n.Password != "" {
		if err := CheckPassword(n.Password); err != nil {
			return nil, err
		}
		if hash, err = HashPassword(n.Password); err != nil {
			return nil, err
		}
	}
	return &User{ID: NewID(), Username: n.Username, DisplayName: display, IsAdmin: n.IsAdmin,
		MustChangePassword: n.MustChange, CreatedAt: s.now().UTC().Truncate(time.Millisecond), PasswordHash: hash}, nil
}

func (s *Service) insertUser(ctx context.Context, db execer, u *User) error {
	ms := u.CreatedAt.UnixMilli()
	_, err := db.ExecContext(ctx, `INSERT INTO users
		(id, username, username_key, display_name, password_hash, must_change_password, is_admin, created_at, updated_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		u.ID, u.Username, strings.ToLower(u.Username), u.DisplayName, u.PasswordHash, u.MustChangePassword, u.IsAdmin, ms, ms)
	if err != nil {
		if strings.Contains(err.Error(), "UNIQUE") {
			return ErrUsernameTaken
		}
		return fmt.Errorf("accounts: create user: %w", err)
	}
	return nil
}

const userCols = `id, username, display_name, password_hash, must_change_password, is_admin, avatar, created_at, disabled_at`

func scanUser(row interface{ Scan(...any) error }) (*User, error) {
	var u User
	var created int64
	var disabled sql.NullInt64
	if err := row.Scan(&u.ID, &u.Username, &u.DisplayName, &u.PasswordHash, &u.MustChangePassword, &u.IsAdmin, &u.Avatar, &created, &disabled); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, ErrNotFound
		}
		return nil, err
	}
	u.CreatedAt = time.UnixMilli(created).UTC()
	if disabled.Valid {
		t := time.UnixMilli(disabled.Int64).UTC()
		u.DisabledAt = &t
	}
	return &u, nil
}

// UserByID returns a user.
func (s *Service) UserByID(ctx context.Context, id string) (*User, error) {
	return scanUser(s.db.QueryRowContext(ctx, `SELECT `+userCols+` FROM users WHERE id = ?`, id))
}

// UserByUsername returns a user, ignoring case.
func (s *Service) UserByUsername(ctx context.Context, username string) (*User, error) {
	return scanUser(s.db.QueryRowContext(ctx, `SELECT `+userCols+` FROM users WHERE username_key = ?`, strings.ToLower(username)))
}

// CountAdmins returns the number of enabled admins.
func (s *Service) CountAdmins(ctx context.Context) (int, error) {
	var n int
	err := s.db.QueryRowContext(ctx, `SELECT COUNT(*) FROM users WHERE is_admin = 1 AND disabled_at IS NULL`).Scan(&n)
	return n, err
}

// Authenticate checks a username and password. Unknown user, wrong password
// and disabled account all return ErrInvalidCredentials, after the same work.
func (s *Service) Authenticate(ctx context.Context, username, password string) (*User, error) {
	u, err := s.UserByUsername(ctx, username)
	if err != nil && !errors.Is(err, ErrNotFound) {
		return nil, err
	}
	hash := dummyHash
	if u != nil && u.PasswordHash != "" {
		hash = u.PasswordHash
	}
	ok, err := VerifyPassword(hash, password)
	if err != nil {
		return nil, err
	}
	if u == nil || u.PasswordHash == "" || !ok || u.Disabled() {
		return nil, ErrInvalidCredentials
	}
	return u, nil
}

// Bootstrap creates the first admin from ADMIN_USERNAME / ADMIN_PASSWORD
// when no admin exists yet. Once one exists the values are ignored.
func (s *Service) Bootstrap(ctx context.Context, username, password string, log *slog.Logger) error {
	n, err := s.CountAdmins(ctx)
	if err != nil {
		return err
	}
	switch {
	case n > 0:
		if username != "" || password != "" {
			log.Info("ADMIN_USERNAME/ADMIN_PASSWORD ignored: an admin already exists")
		}
		return nil
	case username == "" || password == "":
		log.Warn("no admin account yet: set ADMIN_USERNAME and ADMIN_PASSWORD and restart")
		return nil
	}
	u, err := s.CreateUser(ctx, NewUser{Username: username, Password: password, IsAdmin: true})
	if err != nil {
		return fmt.Errorf("first admin %q: %w", username, err)
	}
	log.Info("first admin created", "username", u.Username)
	return s.st.Audit(ctx, store.AuditEvent{ActorName: "system", Action: "user.bootstrap_admin", Target: u.ID,
		Detail: map[string]any{"username": u.Username}})
}
