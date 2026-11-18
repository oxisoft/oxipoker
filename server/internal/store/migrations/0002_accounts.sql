-- Accounts and sessions. Times are Unix milliseconds.

CREATE TABLE users (
    id                   TEXT PRIMARY KEY,
    username             TEXT NOT NULL,
    -- lower-case copy: usernames are unique without regard to case
    username_key         TEXT NOT NULL UNIQUE,
    display_name         TEXT NOT NULL,
    password_hash        TEXT NOT NULL DEFAULT '',
    must_change_password INTEGER NOT NULL DEFAULT 0,
    is_admin             INTEGER NOT NULL DEFAULT 0,
    avatar               TEXT NOT NULL DEFAULT '',
    created_at           INTEGER NOT NULL,
    updated_at           INTEGER NOT NULL,
    disabled_at          INTEGER
) STRICT;

CREATE INDEX users_admin ON users (is_admin) WHERE is_admin = 1;

-- Only the SHA-256 of a session token is stored; id is the public handle used
-- to list and revoke sessions.
CREATE TABLE sessions (
    id           TEXT PRIMARY KEY,
    token_hash   BLOB NOT NULL UNIQUE,
    user_id      TEXT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    kind         TEXT NOT NULL CHECK (kind IN ('web', 'app')),
    created_at   INTEGER NOT NULL,
    last_seen_at INTEGER NOT NULL,
    expires_at   INTEGER NOT NULL,
    ip           TEXT NOT NULL DEFAULT '',
    user_agent   TEXT NOT NULL DEFAULT ''
) STRICT;

CREATE INDEX sessions_user ON sessions (user_id);
CREATE INDEX sessions_expires ON sessions (expires_at);
