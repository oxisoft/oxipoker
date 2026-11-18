-- Appearance: each user's theme and card back, and card backs uploaded by an
-- admin. users.card_back '' follows the server default (setting
-- card_back_default). Built-in backs are drawn by the apps and have no row
-- here; uploaded ones are re-encoded to a 500 x 700 PNG.

ALTER TABLE users ADD COLUMN theme TEXT NOT NULL DEFAULT 'classic';
ALTER TABLE users ADD COLUMN card_back TEXT NOT NULL DEFAULT '';

CREATE TABLE card_backs (
    id         TEXT PRIMARY KEY,
    name       TEXT NOT NULL,
    png        BLOB NOT NULL,
    created_at INTEGER NOT NULL
) STRICT;
