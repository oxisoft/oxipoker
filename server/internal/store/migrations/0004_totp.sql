-- TOTP second factor and recovery codes. Times are Unix milliseconds.

CREATE TABLE totp (
    user_id      TEXT PRIMARY KEY REFERENCES users (id) ON DELETE CASCADE,
    secret       BLOB NOT NULL,            -- AES-GCM sealed with the server's "totp" key
    confirmed_at INTEGER,                  -- NULL while enrolment waits for the first code
    last_step    INTEGER NOT NULL DEFAULT 0, -- newest accepted 30 s step: codes are single use
    created_at   INTEGER NOT NULL
) STRICT;

-- Only the SHA-256 of each recovery code is stored.
CREATE TABLE recovery_codes (
    user_id   TEXT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    code_hash BLOB NOT NULL,
    used_at   INTEGER,
    PRIMARY KEY (user_id, code_hash)
) STRICT;
