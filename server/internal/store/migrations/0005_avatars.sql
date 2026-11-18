-- Profile pictures. Each is re-encoded by the server to a 256 px square PNG;
-- users.avatar holds its version (a short hash), used for cache busting.

CREATE TABLE avatars (
    user_id    TEXT PRIMARY KEY REFERENCES users (id) ON DELETE CASCADE,
    png        BLOB NOT NULL,
    updated_at INTEGER NOT NULL
) STRICT;
