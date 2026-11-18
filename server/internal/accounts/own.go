package accounts

import (
	"context"
	"errors"
	"fmt"
)

// Own-account errors.
var (
	ErrLastAdmin     = errors.New("the last admin cannot be removed")
	ErrWrongPassword = errors.New("current password is wrong")
)

// SetDisplayName changes a user's display name.
func (s *Service) SetDisplayName(ctx context.Context, userID, name string) (string, error) {
	name, err := checkDisplayName(name)
	if err != nil {
		return "", err
	}
	res, err := s.db.ExecContext(ctx, `UPDATE users SET display_name = ?, updated_at = ? WHERE id = ?`,
		name, s.now().UnixMilli(), userID)
	if err != nil {
		return "", err
	}
	if n, _ := res.RowsAffected(); n == 0 {
		return "", ErrNotFound
	}
	return name, nil
}

// checkCurrentPassword passes when the account has no password (passkey only)
// or current matches it.
func checkCurrentPassword(u *User, current string) error {
	if u.PasswordHash == "" {
		return nil
	}
	ok, err := VerifyPassword(u.PasswordHash, current)
	if err != nil {
		return err
	}
	if !ok {
		return ErrWrongPassword
	}
	return nil
}

// ChangePassword sets a new password after checking the current one, clears
// the must-change flag and signs out every other session.
func (s *Service) ChangePassword(ctx context.Context, u *User, current, next, keepSession string) error {
	if err := checkCurrentPassword(u, current); err != nil {
		return err
	}
	if err := CheckPassword(next); err != nil {
		return err
	}
	hash, err := HashPassword(next)
	if err != nil {
		return err
	}
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()
	if _, err := tx.ExecContext(ctx, `UPDATE users SET password_hash = ?, must_change_password = 0, updated_at = ? WHERE id = ?`,
		hash, s.now().UnixMilli(), u.ID); err != nil {
		return fmt.Errorf("accounts: change password: %w", err)
	}
	if _, err := tx.ExecContext(ctx, `DELETE FROM sessions WHERE user_id = ? AND id <> ?`, u.ID, keepSession); err != nil {
		return err
	}
	return tx.Commit()
}

// DeleteUser removes an account with its sessions, passkeys and second
// factor. The last enabled admin cannot be deleted.
func (s *Service) DeleteUser(ctx context.Context, userID string) error {
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()
	var isAdmin bool
	if err := tx.QueryRowContext(ctx, `SELECT is_admin FROM users WHERE id = ?`, userID).Scan(&isAdmin); err != nil {
		return ErrNotFound
	}
	if isAdmin {
		var others int
		if err := tx.QueryRowContext(ctx, `SELECT count(*) FROM users WHERE is_admin = 1 AND disabled_at IS NULL AND id <> ?`,
			userID).Scan(&others); err != nil {
			return err
		}
		if others == 0 {
			return ErrLastAdmin
		}
	}
	if _, err := tx.ExecContext(ctx, `DELETE FROM users WHERE id = ?`, userID); err != nil {
		return fmt.Errorf("accounts: delete user: %w", err)
	}
	return tx.Commit()
}

// DeleteOwnAccount deletes u after checking its password (if it has one).
func (s *Service) DeleteOwnAccount(ctx context.Context, u *User, password string) error {
	if err := checkCurrentPassword(u, password); err != nil {
		return err
	}
	return s.DeleteUser(ctx, u.ID)
}
