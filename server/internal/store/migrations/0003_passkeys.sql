-- Passkeys (WebAuthn credentials). Times are Unix milliseconds.
-- The user handle given to authenticators is the user's id; it is random and
-- carries no personal data.

CREATE TABLE passkeys (
    id           TEXT PRIMARY KEY,           -- public handle for list/rename/remove
    credential   BLOB NOT NULL UNIQUE,       -- WebAuthn credential id
    user_id      TEXT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    name         TEXT NOT NULL,
    data         TEXT NOT NULL,              -- JSON of the verified credential (public key, counter, flags)
    created_at   INTEGER NOT NULL,
    last_used_at INTEGER
) STRICT;

CREATE INDEX passkeys_user ON passkeys (user_id);
