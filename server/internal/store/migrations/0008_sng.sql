-- Sit-and-go results. One row per finished game and one per finishing
-- place. Times are Unix milliseconds.

CREATE TABLE sng_games (
    id          INTEGER PRIMARY KEY,
    table_id    TEXT NOT NULL,
    table_name  TEXT NOT NULL,
    players     INTEGER NOT NULL,
    started_at  INTEGER NOT NULL,
    finished_at INTEGER NOT NULL
) STRICT;

CREATE TABLE sng_places (
    game_id INTEGER NOT NULL REFERENCES sng_games (id) ON DELETE CASCADE,
    user_id TEXT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    place   INTEGER NOT NULL,
    name    TEXT NOT NULL,
    PRIMARY KEY (game_id, user_id)
) STRICT;

CREATE INDEX sng_places_user ON sng_places (user_id, game_id DESC);
