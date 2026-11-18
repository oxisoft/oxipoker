-- Invitation links: the only way in besides an admin creating the account.
-- Only the SHA-256 of a link's token is stored. Times are Unix milliseconds.

CREATE TABLE invitations (
    id         TEXT PRIMARY KEY,
    token_hash BLOB NOT NULL UNIQUE,
    created_by TEXT REFERENCES users (id) ON DELETE SET NULL,
    note       TEXT NOT NULL DEFAULT '',
    max_uses   INTEGER NOT NULL CHECK (max_uses >= 1),
    uses       INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL,
    expires_at INTEGER NOT NULL,
    revoked_at INTEGER
) STRICT;

-- Who joined through which link.
CREATE TABLE invitation_joins (
    invitation_id TEXT NOT NULL REFERENCES invitations (id) ON DELETE CASCADE,
    user_id       TEXT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    joined_at     INTEGER NOT NULL,
    PRIMARY KEY (invitation_id, user_id)
) STRICT;

CREATE INDEX invitation_joins_user ON invitation_joins (user_id);
