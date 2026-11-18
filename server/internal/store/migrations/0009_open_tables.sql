-- Open tables, so a restarted server puts them back. state is the JSON
-- form of table.Saved (settings, seats with stacks, button, hand number,
-- sit-and-go clock and places); a running hand is never stored. saved_at is
-- Unix milliseconds.

CREATE TABLE open_tables (
    id       TEXT PRIMARY KEY,
    state    TEXT NOT NULL,
    saved_at INTEGER NOT NULL
) STRICT;
