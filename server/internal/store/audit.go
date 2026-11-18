package store

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
	"time"
)

// AuditEvent is one admin or security event.
type AuditEvent struct {
	ID        int64          `json:"id"`
	At        time.Time      `json:"at"`
	ActorID   string         `json:"actor_id"`
	ActorName string         `json:"actor_name"`
	Action    string         `json:"action"`
	Target    string         `json:"target"`
	IP        string         `json:"ip"`
	Detail    map[string]any `json:"detail,omitempty"`
}

// AuditFilter narrows ListAudit. Zero values mean no filter.
type AuditFilter struct {
	ActorID string
	Action  string // exact action, or a prefix ending in "." (e.g. "user.")
	Before  int64  // only events with id < Before (paging)
	Limit   int    // default 100, max 500
}

// Audit records an event. Detail must never contain secrets.
func (s *Store) Audit(ctx context.Context, e AuditEvent) error {
	if e.Action == "" {
		return fmt.Errorf("store: audit event without action")
	}
	at := e.At
	if at.IsZero() {
		at = time.Now()
	}
	detail := []byte("{}")
	if len(e.Detail) > 0 {
		var err error
		if detail, err = json.Marshal(e.Detail); err != nil {
			return fmt.Errorf("store: audit detail: %w", err)
		}
	}
	_, err := s.db.ExecContext(ctx, `INSERT INTO audit_log (at, actor_id, actor_name, action, target, ip, detail)
		VALUES (?, ?, ?, ?, ?, ?, ?)`, at.UnixMilli(), e.ActorID, e.ActorName, e.Action, e.Target, e.IP, string(detail))
	if err != nil {
		return fmt.Errorf("store: audit: %w", err)
	}
	return nil
}

// ListAudit returns events newest first.
func (s *Store) ListAudit(ctx context.Context, f AuditFilter) ([]AuditEvent, error) {
	var where []string
	var args []any
	if f.ActorID != "" {
		where = append(where, "actor_id = ?")
		args = append(args, f.ActorID)
	}
	if f.Action != "" {
		if strings.HasSuffix(f.Action, ".") {
			where = append(where, "substr(action, 1, ?) = ?")
			args = append(args, len(f.Action), f.Action)
		} else {
			where = append(where, "action = ?")
			args = append(args, f.Action)
		}
	}
	if f.Before > 0 {
		where = append(where, "id < ?")
		args = append(args, f.Before)
	}
	limit := f.Limit
	if limit <= 0 {
		limit = 100
	}
	if limit > 500 {
		limit = 500
	}
	q := `SELECT id, at, actor_id, actor_name, action, target, ip, detail FROM audit_log`
	if len(where) > 0 {
		q += " WHERE " + strings.Join(where, " AND ")
	}
	q += " ORDER BY id DESC LIMIT ?"
	args = append(args, limit)

	rows, err := s.db.QueryContext(ctx, q, args...)
	if err != nil {
		return nil, fmt.Errorf("store: list audit: %w", err)
	}
	defer rows.Close()
	out := []AuditEvent{}
	for rows.Next() {
		var e AuditEvent
		var at int64
		var detail string
		if err := rows.Scan(&e.ID, &at, &e.ActorID, &e.ActorName, &e.Action, &e.Target, &e.IP, &detail); err != nil {
			return nil, err
		}
		e.At = time.UnixMilli(at).UTC()
		if detail != "" && detail != "{}" {
			_ = json.Unmarshal([]byte(detail), &e.Detail)
		}
		out = append(out, e)
	}
	return out, rows.Err()
}
