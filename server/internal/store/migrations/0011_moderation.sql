-- Moderation: who blocked whom, and reports for the admin console. A report
-- keeps the last chat lines of its table as JSON, because table chat itself
-- is never stored.

CREATE TABLE blocks (
    user_id    TEXT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    blocked_id TEXT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    created_at INTEGER NOT NULL,
    PRIMARY KEY (user_id, blocked_id)
) STRICT;

CREATE TABLE reports (
    id          INTEGER PRIMARY KEY,
    reporter_id TEXT REFERENCES users (id) ON DELETE SET NULL,
    reported_id TEXT REFERENCES users (id) ON DELETE SET NULL,
    reporter    TEXT NOT NULL, -- names at report time, kept when accounts go
    reported    TEXT NOT NULL,
    table_id    TEXT NOT NULL DEFAULT '',
    table_name  TEXT NOT NULL DEFAULT '',
    reason      TEXT NOT NULL,
    note        TEXT NOT NULL DEFAULT '',
    chat        TEXT NOT NULL DEFAULT '[]',
    created_at  INTEGER NOT NULL,
    resolved_at INTEGER,
    resolved_by TEXT NOT NULL DEFAULT ''
) STRICT;

CREATE INDEX reports_open ON reports (resolved_at, id);
