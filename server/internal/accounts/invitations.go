package accounts

import (
	"context"
	"crypto/rand"
	"database/sql"
	"encoding/base64"
	"errors"
	"fmt"
	"strings"
	"time"
	"unicode/utf8"
)

// Invitation limits.
const (
	InviteMinTTL     = time.Hour
	InviteMaxTTL     = 30 * 24 * time.Hour
	InviteDefaultTTL = 72 * time.Hour
	InviteMaxUses    = 100
	inviteMaxNote    = 200
)

var (
	ErrInviteInvalid = errors.New("invitation unknown or revoked")
	ErrInviteExpired = errors.New("invitation expired")
	ErrInviteUsedUp  = errors.New("invitation already used")
	ErrInviteParams  = errors.New("invitation: expiry 1 hour to 30 days, 1 to 100 uses, note up to 200 characters")
)

// Invitation is an invitation link as admins see it (the token is shown only
// once, at creation).
type Invitation struct {
	ID        string       `json:"id"`
	Note      string       `json:"note"`
	MaxUses   int          `json:"max_uses"`
	Uses      int          `json:"uses"`
	CreatedAt time.Time    `json:"created_at"`
	ExpiresAt time.Time    `json:"expires_at"`
	RevokedAt *time.Time   `json:"revoked_at,omitempty"`
	CreatedBy string       `json:"created_by,omitempty"` // username, empty when that admin is gone
	Joined    []JoinedUser `json:"joined"`
}

// JoinedUser is an account created through an invitation.
type JoinedUser struct {
	ID          string    `json:"id"`
	Username    string    `json:"username"`
	DisplayName string    `json:"display_name"`
	JoinedAt    time.Time `json:"joined_at"`
}

// NewInvitation is what an admin asks for.
type NewInvitation struct {
	TTL     time.Duration // 0 = InviteDefaultTTL
	MaxUses int           // 0 = 1
	Note    string
}

// CreateInvitation makes a link. It returns the secret token once.
func (s *Service) CreateInvitation(ctx context.Context, admin *User, n NewInvitation) (string, *Invitation, error) {
	if n.TTL == 0 {
		n.TTL = InviteDefaultTTL
	}
	if n.MaxUses == 0 {
		n.MaxUses = 1
	}
	n.Note = strings.TrimSpace(n.Note)
	if n.TTL < InviteMinTTL || n.TTL > InviteMaxTTL || n.MaxUses < 1 || n.MaxUses > InviteMaxUses ||
		utf8.RuneCountInString(n.Note) > inviteMaxNote || !utf8.ValidString(n.Note) {
		return "", nil, ErrInviteParams
	}
	raw := make([]byte, 32)
	_, _ = rand.Read(raw)
	token := base64.RawURLEncoding.EncodeToString(raw)
	now := s.now().UTC().Truncate(time.Millisecond)
	inv := &Invitation{ID: NewID(), Note: n.Note, MaxUses: n.MaxUses, CreatedAt: now, ExpiresAt: now.Add(n.TTL),
		CreatedBy: admin.Username, Joined: []JoinedUser{}}
	_, err := s.db.ExecContext(ctx, `INSERT INTO invitations (id, token_hash, created_by, note, max_uses, created_at, expires_at)
		VALUES (?, ?, ?, ?, ?, ?, ?)`, inv.ID, hashToken(token), admin.ID, inv.Note, inv.MaxUses,
		now.UnixMilli(), inv.ExpiresAt.UnixMilli())
	if err != nil {
		return "", nil, fmt.Errorf("accounts: create invitation: %w", err)
	}
	return token, inv, nil
}

// ListInvitations returns every invitation, newest first, with who joined.
func (s *Service) ListInvitations(ctx context.Context) ([]Invitation, error) {
	rows, err := s.db.QueryContext(ctx, `SELECT i.id, i.note, i.max_uses, i.uses, i.created_at, i.expires_at,
		i.revoked_at, COALESCE(u.username, '') FROM invitations i LEFT JOIN users u ON u.id = i.created_by
		ORDER BY i.created_at DESC, i.id`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []Invitation{}
	index := map[string]int{}
	for rows.Next() {
		var inv Invitation
		var created, expires int64
		var revoked sql.NullInt64
		if err := rows.Scan(&inv.ID, &inv.Note, &inv.MaxUses, &inv.Uses, &created, &expires, &revoked, &inv.CreatedBy); err != nil {
			return nil, err
		}
		inv.CreatedAt, inv.ExpiresAt = time.UnixMilli(created).UTC(), time.UnixMilli(expires).UTC()
		if revoked.Valid {
			t := time.UnixMilli(revoked.Int64).UTC()
			inv.RevokedAt = &t
		}
		inv.Joined = []JoinedUser{}
		index[inv.ID] = len(out)
		out = append(out, inv)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	jrows, err := s.db.QueryContext(ctx, `SELECT j.invitation_id, u.id, u.username, u.display_name, j.joined_at
		FROM invitation_joins j JOIN users u ON u.id = j.user_id ORDER BY j.joined_at`)
	if err != nil {
		return nil, err
	}
	defer jrows.Close()
	for jrows.Next() {
		var invID string
		var j JoinedUser
		var at int64
		if err := jrows.Scan(&invID, &j.ID, &j.Username, &j.DisplayName, &at); err != nil {
			return nil, err
		}
		j.JoinedAt = time.UnixMilli(at).UTC()
		if i, ok := index[invID]; ok {
			out[i].Joined = append(out[i].Joined, j)
		}
	}
	return out, jrows.Err()
}

// RevokeInvitation stops a link from working. Accounts made through it stay.
func (s *Service) RevokeInvitation(ctx context.Context, id string) error {
	res, err := s.db.ExecContext(ctx, `UPDATE invitations SET revoked_at = COALESCE(revoked_at, ?) WHERE id = ?`,
		s.now().UnixMilli(), id)
	if err != nil {
		return err
	}
	if n, _ := res.RowsAffected(); n == 0 {
		return ErrNotFound
	}
	return nil
}

// InvitationInfo is what a visitor with a link learns about it.
type InvitationInfo struct {
	ExpiresAt time.Time `json:"expires_at"`
	Note      string    `json:"note"`
}

// CheckInvitation tells whether token can still be used, without using it.
func (s *Service) CheckInvitation(ctx context.Context, token string) (*InvitationInfo, error) {
	var maxUses, uses int
	var expires int64
	var revoked sql.NullInt64
	var info InvitationInfo
	err := s.db.QueryRowContext(ctx, `SELECT max_uses, uses, expires_at, revoked_at, note FROM invitations
		WHERE token_hash = ?`, hashToken(token)).Scan(&maxUses, &uses, &expires, &revoked, &info.Note)
	switch {
	case errors.Is(err, sql.ErrNoRows):
		return nil, ErrInviteInvalid
	case err != nil:
		return nil, err
	case revoked.Valid:
		return nil, ErrInviteInvalid
	case s.now().UnixMilli() >= expires:
		return nil, ErrInviteExpired
	case uses >= maxUses:
		return nil, ErrInviteUsedUp
	}
	info.ExpiresAt = time.UnixMilli(expires).UTC()
	return &info, nil
}

// consumeInvitation takes one use of token inside tx, or says why it cannot.
func (s *Service) consumeInvitation(ctx context.Context, tx *sql.Tx, token string) (string, error) {
	var id string
	err := tx.QueryRowContext(ctx, `UPDATE invitations SET uses = uses + 1
		WHERE token_hash = ? AND revoked_at IS NULL AND expires_at > ? AND uses < max_uses RETURNING id`,
		hashToken(token), s.now().UnixMilli()).Scan(&id)
	if errors.Is(err, sql.ErrNoRows) {
		if _, cerr := s.CheckInvitation(ctx, token); cerr != nil {
			return "", cerr
		}
		return "", ErrInviteInvalid
	}
	return id, err
}

// signUp creates u through the invitation token in one transaction: the link
// is checked again here, so a link used up meanwhile refuses. extra runs in
// the same transaction (the passkey of a passkey sign-up).
func (s *Service) signUp(ctx context.Context, token string, u *User, extra func(*sql.Tx) error) error {
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()
	invID, err := s.consumeInvitation(ctx, tx, token)
	if err != nil {
		return err
	}
	if err := s.insertUser(ctx, tx, u); err != nil {
		return err
	}
	if _, err := tx.ExecContext(ctx, `INSERT INTO invitation_joins (invitation_id, user_id, joined_at) VALUES (?, ?, ?)`,
		invID, u.ID, s.now().UnixMilli()); err != nil {
		return err
	}
	if extra != nil {
		if err := extra(tx); err != nil {
			return err
		}
	}
	return tx.Commit()
}

// SignUpWithPassword creates a player account through an invitation link.
func (s *Service) SignUpWithPassword(ctx context.Context, token, username, displayName, password string) (*User, error) {
	if password == "" {
		return nil, ErrWeakPassword
	}
	if _, err := s.CheckInvitation(ctx, token); err != nil {
		return nil, err // fail fast before the slow password hash
	}
	u, err := s.prepareUser(NewUser{Username: username, DisplayName: displayName, Password: password})
	if err != nil {
		return nil, err
	}
	if err := s.signUp(ctx, token, u, nil); err != nil {
		return nil, err
	}
	return u, nil
}

// UsernameFree reports whether username is valid and not taken.
func (s *Service) UsernameFree(ctx context.Context, username string) error {
	if err := CheckUsername(username); err != nil {
		return err
	}
	var n int
	if err := s.db.QueryRowContext(ctx, `SELECT COUNT(*) FROM users WHERE username_key = ?`,
		strings.ToLower(username)).Scan(&n); err != nil {
		return err
	}
	if n > 0 {
		return ErrUsernameTaken
	}
	return nil
}
