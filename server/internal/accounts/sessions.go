package accounts

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"database/sql"
	"encoding/base64"
	"errors"
	"fmt"
	"strings"
	"time"
)

// Session lifetimes: a session lives SessionTTL after its last use; activity
// renews it at most once per renewEvery to keep writes rare.
const (
	SessionTTL = 30 * 24 * time.Hour
	renewEvery = time.Hour
	maxUALen   = 256
)

// Session kinds.
const (
	KindWeb = "web" // HttpOnly cookie
	KindApp = "app" // Authorization: Bearer
)

// Session is one signed-in device. The token itself is never stored.
type Session struct {
	ID         string    `json:"id"`
	UserID     string    `json:"-"`
	Kind       string    `json:"kind"`
	CreatedAt  time.Time `json:"created_at"`
	LastSeenAt time.Time `json:"last_seen_at"`
	ExpiresAt  time.Time `json:"expires_at"`
	IP         string    `json:"ip"`
	UserAgent  string    `json:"user_agent"`
	Current    bool      `json:"current"`
}

func hashToken(token string) []byte {
	h := sha256.Sum256([]byte(token))
	return h[:]
}

// CreateSession signs a user in and returns the bearer token (shown once).
func (s *Service) CreateSession(ctx context.Context, userID, kind, ip, userAgent string) (string, *Session, error) {
	if kind != KindWeb && kind != KindApp {
		return "", nil, fmt.Errorf("accounts: bad session kind %q", kind)
	}
	raw := make([]byte, 32)
	if _, err := rand.Read(raw); err != nil {
		return "", nil, err
	}
	token := base64.RawURLEncoding.EncodeToString(raw)
	if len(userAgent) > maxUALen {
		userAgent = userAgent[:maxUALen]
	}
	now := s.now()
	ss := &Session{ID: NewID(), UserID: userID, Kind: kind, IP: ip, UserAgent: userAgent,
		CreatedAt: now.UTC().Truncate(time.Millisecond), LastSeenAt: now.UTC().Truncate(time.Millisecond),
		ExpiresAt: now.Add(SessionTTL).UTC().Truncate(time.Millisecond)}
	_, err := s.db.ExecContext(ctx, `INSERT INTO sessions
		(id, token_hash, user_id, kind, created_at, last_seen_at, expires_at, ip, user_agent)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		ss.ID, hashToken(token), userID, kind, now.UnixMilli(), now.UnixMilli(), now.Add(SessionTTL).UnixMilli(), ip, userAgent)
	if err != nil {
		return "", nil, fmt.Errorf("accounts: create session: %w", err)
	}
	return token, ss, nil
}

// SessionUser resolves a token to its session and user, renewing the
// session's expiry. Expired sessions, disabled users and unknown tokens all
// return ErrNotFound.
func (s *Service) SessionUser(ctx context.Context, token string) (*Session, *User, error) {
	if token == "" || len(token) > 128 || strings.ContainsAny(token, " \t") {
		return nil, nil, ErrNotFound
	}
	now := s.now()
	row := s.db.QueryRowContext(ctx, `SELECT s.id, s.kind, s.created_at, s.last_seen_at, s.expires_at, s.ip, s.user_agent,
		u.id, u.username, u.display_name, u.password_hash, u.must_change_password, u.is_admin, u.avatar, u.created_at, u.disabled_at
		FROM sessions s JOIN users u ON u.id = s.user_id WHERE s.token_hash = ?`, hashToken(token))
	var ss Session
	var u User
	var created, seen, expires, ucreated int64
	var disabled sql.NullInt64
	err := row.Scan(&ss.ID, &ss.Kind, &created, &seen, &expires, &ss.IP, &ss.UserAgent,
		&u.ID, &u.Username, &u.DisplayName, &u.PasswordHash, &u.MustChangePassword, &u.IsAdmin, &u.Avatar, &ucreated, &disabled)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil, ErrNotFound
	}
	if err != nil {
		return nil, nil, err
	}
	if expires <= now.UnixMilli() || disabled.Valid {
		_, _ = s.db.ExecContext(ctx, `DELETE FROM sessions WHERE id = ?`, ss.ID)
		return nil, nil, ErrNotFound
	}
	if now.UnixMilli()-seen >= renewEvery.Milliseconds() {
		seen, expires = now.UnixMilli(), now.Add(SessionTTL).UnixMilli()
		if _, err := s.db.ExecContext(ctx, `UPDATE sessions SET last_seen_at = ?, expires_at = ? WHERE id = ?`, seen, expires, ss.ID); err != nil {
			return nil, nil, err
		}
	}
	ss.UserID = u.ID
	ss.CreatedAt, ss.LastSeenAt, ss.ExpiresAt = time.UnixMilli(created).UTC(), time.UnixMilli(seen).UTC(), time.UnixMilli(expires).UTC()
	u.CreatedAt = time.UnixMilli(ucreated).UTC()
	return &ss, &u, nil
}

// ListSessions returns a user's live sessions, newest first.
func (s *Service) ListSessions(ctx context.Context, userID string) ([]Session, error) {
	rows, err := s.db.QueryContext(ctx, `SELECT id, kind, created_at, last_seen_at, expires_at, ip, user_agent
		FROM sessions WHERE user_id = ? AND expires_at > ? ORDER BY last_seen_at DESC`, userID, s.now().UnixMilli())
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []Session{}
	for rows.Next() {
		var ss Session
		var c, l, e int64
		if err := rows.Scan(&ss.ID, &ss.Kind, &c, &l, &e, &ss.IP, &ss.UserAgent); err != nil {
			return nil, err
		}
		ss.UserID = userID
		ss.CreatedAt, ss.LastSeenAt, ss.ExpiresAt = time.UnixMilli(c).UTC(), time.UnixMilli(l).UTC(), time.UnixMilli(e).UTC()
		out = append(out, ss)
	}
	return out, rows.Err()
}

// RevokeSession deletes one of the user's sessions.
func (s *Service) RevokeSession(ctx context.Context, userID, sessionID string) error {
	res, err := s.db.ExecContext(ctx, `DELETE FROM sessions WHERE id = ? AND user_id = ?`, sessionID, userID)
	if err != nil {
		return err
	}
	if n, _ := res.RowsAffected(); n == 0 {
		return ErrNotFound
	}
	return nil
}

// RevokeAllSessions deletes every session of a user except keepID (may be "").
func (s *Service) RevokeAllSessions(ctx context.Context, userID, keepID string) (int64, error) {
	res, err := s.db.ExecContext(ctx, `DELETE FROM sessions WHERE user_id = ? AND id != ?`, userID, keepID)
	if err != nil {
		return 0, err
	}
	return res.RowsAffected()
}

// PurgeExpiredSessions removes expired sessions.
func (s *Service) PurgeExpiredSessions(ctx context.Context) (int64, error) {
	res, err := s.db.ExecContext(ctx, `DELETE FROM sessions WHERE expires_at <= ?`, s.now().UnixMilli())
	if err != nil {
		return 0, err
	}
	return res.RowsAffected()
}
