package accounts

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"strings"
	"time"
	"unicode/utf8"
)

// Moderation limits.
const (
	MaxReportNote      = 500 // characters
	MaxReportChatLines = 20
	maxBlocks          = 500
	maxOpenReports     = 20 // per reporter
)

// Report reasons.
var ReportReasons = []string{"chat", "behaviour", "other"}

// Moderation errors.
var (
	ErrBlockSelf      = errors.New("you cannot block yourself")
	ErrTooManyBlocks  = errors.New("too many blocked users")
	ErrBadReport      = errors.New("report: reason chat, behaviour or other, note up to 500 characters")
	ErrReportSelf     = errors.New("you cannot report yourself")
	ErrTooManyReports = errors.New("too many open reports")
)

// BlockedUser is one entry of a block list.
type BlockedUser struct {
	ID          string    `json:"id"`
	Username    string    `json:"username"`
	DisplayName string    `json:"display_name"`
	CreatedAt   time.Time `json:"created_at"`
}

// Block hides target's chat (and later video) from user. Blocking twice is
// not an error.
func (s *Service) Block(ctx context.Context, user, target string) error {
	if user == target {
		return ErrBlockSelf
	}
	if _, err := s.UserByID(ctx, target); err != nil {
		return err
	}
	var n int
	if err := s.db.QueryRowContext(ctx, `SELECT COUNT(*) FROM blocks WHERE user_id = ?`, user).Scan(&n); err != nil {
		return err
	}
	if n >= maxBlocks {
		return ErrTooManyBlocks
	}
	_, err := s.db.ExecContext(ctx, `INSERT INTO blocks (user_id, blocked_id, created_at) VALUES (?, ?, ?)
		ON CONFLICT DO NOTHING`, user, target, s.now().UnixMilli())
	return err
}

// Unblock removes target from user's block list.
func (s *Service) Unblock(ctx context.Context, user, target string) error {
	_, err := s.db.ExecContext(ctx, `DELETE FROM blocks WHERE user_id = ? AND blocked_id = ?`, user, target)
	return err
}

// Blocks returns user's block list, newest first.
func (s *Service) Blocks(ctx context.Context, user string) ([]BlockedUser, error) {
	rows, err := s.db.QueryContext(ctx, `SELECT u.id, u.username, u.display_name, b.created_at
		FROM blocks b JOIN users u ON u.id = b.blocked_id WHERE b.user_id = ? ORDER BY b.created_at DESC`, user)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []BlockedUser{}
	for rows.Next() {
		var b BlockedUser
		var ms int64
		if err := rows.Scan(&b.ID, &b.Username, &b.DisplayName, &ms); err != nil {
			return nil, err
		}
		b.CreatedAt = time.UnixMilli(ms).UTC()
		out = append(out, b)
	}
	return out, rows.Err()
}

// BlockedIDs returns the ids user has blocked as a set.
func (s *Service) BlockedIDs(ctx context.Context, user string) (map[string]bool, error) {
	bs, err := s.Blocks(ctx, user)
	if err != nil {
		return nil, err
	}
	set := make(map[string]bool, len(bs))
	for _, b := range bs {
		set[b.ID] = true
	}
	return set, nil
}

// ChatLine is one table chat line kept with a report.
type ChatLine struct {
	User string    `json:"user"`
	Name string    `json:"name"`
	Text string    `json:"text"`
	At   time.Time `json:"at"`
}

// NewReport is what a user files.
type NewReport struct {
	Reporter  string
	Reported  string
	TableID   string
	TableName string
	Reason    string
	Note      string
	Chat      []ChatLine
}

// Report is a report as the admin console shows it.
type Report struct {
	ID         int64      `json:"id"`
	ReporterID string     `json:"reporter_id,omitempty"`
	ReportedID string     `json:"reported_id,omitempty"`
	Reporter   string     `json:"reporter"`
	Reported   string     `json:"reported"`
	TableID    string     `json:"table_id,omitempty"`
	TableName  string     `json:"table_name,omitempty"`
	Reason     string     `json:"reason"`
	Note       string     `json:"note"`
	Chat       []ChatLine `json:"chat"`
	CreatedAt  time.Time  `json:"created_at"`
	ResolvedAt *time.Time `json:"resolved_at,omitempty"`
	ResolvedBy string     `json:"resolved_by,omitempty"`
}

func validReason(r string) bool {
	for _, x := range ReportReasons {
		if r == x {
			return true
		}
	}
	return false
}

// FileReport stores a report.
func (s *Service) FileReport(ctx context.Context, n NewReport) (*Report, error) {
	n.Note = strings.TrimSpace(n.Note)
	if !validReason(n.Reason) || utf8.RuneCountInString(n.Note) > MaxReportNote || !utf8.ValidString(n.Note) {
		return nil, ErrBadReport
	}
	if n.Reporter == n.Reported {
		return nil, ErrReportSelf
	}
	from, err := s.UserByID(ctx, n.Reporter)
	if err != nil {
		return nil, err
	}
	to, err := s.UserByID(ctx, n.Reported)
	if err != nil {
		return nil, err
	}
	var open int
	if err := s.db.QueryRowContext(ctx, `SELECT COUNT(*) FROM reports WHERE reporter_id = ? AND resolved_at IS NULL`,
		n.Reporter).Scan(&open); err != nil {
		return nil, err
	}
	if open >= maxOpenReports {
		return nil, ErrTooManyReports
	}
	if len(n.Chat) > MaxReportChatLines {
		n.Chat = n.Chat[len(n.Chat)-MaxReportChatLines:]
	}
	if n.Chat == nil {
		n.Chat = []ChatLine{}
	}
	chat, err := json.Marshal(n.Chat)
	if err != nil {
		return nil, err
	}
	now := s.now().UTC().Truncate(time.Millisecond)
	res, err := s.db.ExecContext(ctx, `INSERT INTO reports (reporter_id, reported_id, reporter, reported, table_id,
		table_name, reason, note, chat, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		from.ID, to.ID, from.Username, to.Username, n.TableID, n.TableName, n.Reason, n.Note, string(chat), now.UnixMilli())
	if err != nil {
		return nil, err
	}
	id, _ := res.LastInsertId()
	return &Report{ID: id, ReporterID: from.ID, ReportedID: to.ID, Reporter: from.Username, Reported: to.Username,
		TableID: n.TableID, TableName: n.TableName, Reason: n.Reason, Note: n.Note, Chat: n.Chat, CreatedAt: now}, nil
}

// Reports lists reports, newest first: open ones, or resolved ones too.
func (s *Service) Reports(ctx context.Context, all bool, limit int) ([]Report, error) {
	if limit <= 0 || limit > 200 {
		limit = 100
	}
	q := `SELECT id, COALESCE(reporter_id, ''), COALESCE(reported_id, ''), reporter, reported, table_id, table_name,
		reason, note, chat, created_at, resolved_at, resolved_by FROM reports`
	if !all {
		q += ` WHERE resolved_at IS NULL`
	}
	rows, err := s.db.QueryContext(ctx, q+` ORDER BY id DESC LIMIT ?`, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []Report{}
	for rows.Next() {
		var r Report
		var chat string
		var created int64
		var resolved sql.NullInt64
		if err := rows.Scan(&r.ID, &r.ReporterID, &r.ReportedID, &r.Reporter, &r.Reported, &r.TableID, &r.TableName,
			&r.Reason, &r.Note, &chat, &created, &resolved, &r.ResolvedBy); err != nil {
			return nil, err
		}
		_ = json.Unmarshal([]byte(chat), &r.Chat)
		if r.Chat == nil {
			r.Chat = []ChatLine{}
		}
		r.CreatedAt = time.UnixMilli(created).UTC()
		if resolved.Valid {
			t := time.UnixMilli(resolved.Int64).UTC()
			r.ResolvedAt = &t
		}
		out = append(out, r)
	}
	return out, rows.Err()
}

// ResolveReport closes an open report.
func (s *Service) ResolveReport(ctx context.Context, id int64, by string) error {
	res, err := s.db.ExecContext(ctx, `UPDATE reports SET resolved_at = ?, resolved_by = ?
		WHERE id = ? AND resolved_at IS NULL`, s.now().UnixMilli(), by, id)
	if err != nil {
		return err
	}
	if n, _ := res.RowsAffected(); n == 0 {
		return ErrNotFound
	}
	return nil
}
