-- Hand history. Only what was seen at the table is stored: public actions,
-- board and cards shown at showdown; each player's own hole cards are kept in
-- their own row and only returned to them. Undealt and folded cards of others
-- are never written. Times are Unix milliseconds.

CREATE TABLE hands (
    id          INTEGER PRIMARY KEY,
    table_id    TEXT NOT NULL,
    table_name  TEXT NOT NULL,
    hand_no     INTEGER NOT NULL,
    small_blind INTEGER NOT NULL,
    big_blind   INTEGER NOT NULL,
    button      INTEGER NOT NULL,
    pot         INTEGER NOT NULL,
    board       TEXT NOT NULL, -- JSON cards
    events      TEXT NOT NULL, -- JSON public events
    results     TEXT NOT NULL, -- JSON pot results
    ended_at    INTEGER NOT NULL
) STRICT;

CREATE TABLE hand_players (
    hand_id     INTEGER NOT NULL REFERENCES hands (id) ON DELETE CASCADE,
    user_id     TEXT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    seat        INTEGER NOT NULL,
    name        TEXT NOT NULL,
    start_stack INTEGER NOT NULL,
    end_stack   INTEGER NOT NULL,
    won         INTEGER NOT NULL, -- chips won from the pots
    hole        TEXT NOT NULL,    -- JSON own cards, only for this user
    PRIMARY KEY (hand_id, user_id)
) STRICT;

CREATE INDEX hand_players_user ON hand_players (user_id, hand_id DESC);
