package accounts

import (
	"context"
	"crypto/rand"
	"database/sql"
	"errors"
	"fmt"
	"strings"
)

// ErrSelf refuses admin actions on the admin's own account that have their own
// endpoint (delete, disable, demote yourself: use /me or ask another admin).
var ErrSelf = errors.New("use your own account settings for that")

// UserPage is one page of the admin user list.
type UserPage struct {
	Users []User `json:"users"`
	Total int    `json:"total"`
}

// ListUsers returns users whose username or display name contains q
// (case-insensitive), ordered by username.
func (s *Service) ListUsers(ctx context.Context, q string, limit, offset int) (*UserPage, error) {
	if limit <= 0 || limit > 200 {
		limit = 50
	}
	offset = max(offset, 0)
	pattern := "%" + strings.NewReplacer(`\`, `\\`, "%", `\%`, "_", `\_`).Replace(strings.ToLower(strings.TrimSpace(q))) + "%"
	where := `WHERE username_key LIKE ?1 ESCAPE '\' OR lower(display_name) LIKE ?1 ESCAPE '\'`
	page := &UserPage{Users: []User{}}
	if err := s.db.QueryRowContext(ctx, `SELECT COUNT(*) FROM users `+where, pattern).Scan(&page.Total); err != nil {
		return nil, err
	}
	rows, err := s.db.QueryContext(ctx, `SELECT `+userCols+` FROM users `+where+` ORDER BY username_key LIMIT ?2 OFFSET ?3`,
		pattern, limit, offset)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		u, err := scanUser(rows)
		if err != nil {
			return nil, err
		}
		page.Users = append(page.Users, *u)
	}
	return page, rows.Err()
}

// otherAdmins counts enabled admins other than userID.
func otherAdmins(ctx context.Context, tx *sql.Tx, userID string) (int, error) {
	var n int
	err := tx.QueryRowContext(ctx, `SELECT COUNT(*) FROM users WHERE is_admin = 1 AND disabled_at IS NULL AND id <> ?`,
		userID).Scan(&n)
	return n, err
}

// updateGuarded runs update on userID unless that would leave the server
// without an enabled admin (when the user is an enabled admin now).
func (s *Service) updateGuarded(ctx context.Context, userID string, removesAdmin bool, update string, args ...any) error {
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()
	var isAdmin bool
	var disabled sql.NullInt64
	if err := tx.QueryRowContext(ctx, `SELECT is_admin, disabled_at FROM users WHERE id = ?`, userID).Scan(&isAdmin, &disabled); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return ErrNotFound
		}
		return err
	}
	if removesAdmin && isAdmin && !disabled.Valid {
		n, err := otherAdmins(ctx, tx, userID)
		if err != nil {
			return err
		}
		if n == 0 {
			return ErrLastAdmin
		}
	}
	if _, err := tx.ExecContext(ctx, update, append(args, userID)...); err != nil {
		return fmt.Errorf("accounts: update user: %w", err)
	}
	return tx.Commit()
}

// SetDisabled disables (and signs out) or enables an account.
func (s *Service) SetDisabled(ctx context.Context, userID string, disabled bool) error {
	now := s.now().UnixMilli()
	if !disabled {
		return s.updateGuarded(ctx, userID, false, `UPDATE users SET disabled_at = NULL, updated_at = ? WHERE id = ?`, now)
	}
	if err := s.updateGuarded(ctx, userID, true,
		`UPDATE users SET disabled_at = COALESCE(disabled_at, ?), updated_at = ? WHERE id = ?`, now, now); err != nil {
		return err
	}
	_, err := s.RevokeAllSessions(ctx, userID, "")
	return err
}

// SetAdmin grants or removes admin rights.
func (s *Service) SetAdmin(ctx context.Context, userID string, admin bool) error {
	return s.updateGuarded(ctx, userID, !admin, `UPDATE users SET is_admin = ?, updated_at = ? WHERE id = ?`,
		admin, s.now().UnixMilli())
}

// NewTemporaryPassword returns a random one-time password like
// "K7QD-M2XA-9PLW-R4TE" (80 bits).
func NewTemporaryPassword() string {
	const alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // no 0/O, 1/I
	b := make([]byte, 16)
	_, _ = rand.Read(b)
	var sb strings.Builder
	for i, c := range b {
		if i > 0 && i%4 == 0 {
			sb.WriteByte('-')
		}
		sb.WriteByte(alphabet[int(c)%len(alphabet)])
	}
	return sb.String()
}

// ResetPassword sets a one-time temporary password that must be changed at
// the next sign-in, and signs the user out everywhere.
func (s *Service) ResetPassword(ctx context.Context, userID string) (string, error) {
	temp := NewTemporaryPassword()
	hash, err := HashPassword(temp)
	if err != nil {
		return "", err
	}
	res, err := s.db.ExecContext(ctx, `UPDATE users SET password_hash = ?, must_change_password = 1, updated_at = ? WHERE id = ?`,
		hash, s.now().UnixMilli(), userID)
	if err != nil {
		return "", err
	}
	if n, _ := res.RowsAffected(); n == 0 {
		return "", ErrNotFound
	}
	if _, err := s.RevokeAllSessions(ctx, userID, ""); err != nil {
		return "", err
	}
	return temp, nil
}
