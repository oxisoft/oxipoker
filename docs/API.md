# Oxi Poker HTTP API

Base path `/api/v1`. JSON in and out. Errors are `{"error": "<code>"}` with a matching HTTP status.

Authentication: the web app gets an HttpOnly session cookie; native apps send `"client": "app"` at sign-in,
receive a `token` and pass it as `Authorization: Bearer <token>`. State-changing browser requests must
carry an `Origin` equal to the server's `PUBLIC_URL`.

This file grows with each milestone. Status: M1 in progress.

## Health

- `GET /health`: `{status, version, api, webapp, media, database}` (`api` = API level, 1 for Oxi Poker 1.0); 503 when the database is not reachable.

## Sign-in

- `POST /auth/signin` `{username, password, client?}`: 200 `{user, session, token?}`; 401
  `invalid_credentials` (same for unknown user and wrong password); 429 `rate_limited` with `Retry-After`.
  With two-factor sign-in on, the answer is 200 `{totp_required: true, challenge}` and no session.
- `POST /auth/totp` `{challenge, code}`: a 6-digit code (each one works once) or a recovery code; 200 as
  password sign-in; 401 `invalid_code` or `challenge_expired` (5 minutes, 5 tries).
- `POST /auth/passkey/begin`: 200 `{ceremony, options}`; pass `options.publicKey` to
  `navigator.credentials.get`. Discoverable credentials, no username needed. The ceremony lasts 5 minutes
  and is single use.
- `POST /auth/passkey/finish` `{ceremony, credential, client?}`: 200 as password sign-in; 401
  `invalid_credentials` for an unknown, expired or reused ceremony, a removed passkey, a disabled account or
  a sign counter that went backwards (possible cloned authenticator).
- `POST /auth/signout`: 204, ends the current session.

Passkey endpoints exist only when `PUBLIC_URL` is set to a domain name (the relying party id is its host; a server
reached by IP address, such as a LAN box, signs in with passwords). A passkey sign-in
needs no TOTP step: the passkey with user verification already is two factors.

The Android app signs in with passkeys too: every server publishes `GET /.well-known/assetlinks.json` for the
official app (`io.oxisoft.oxipoker`) and accepts its `android:apk-key-hash:...` WebAuthn origin. Own builds
of the app with another signing key are added with `ANDROID_APPS=package=AA:BB:...` (SHA-256 of the signing
certificate as keytool prints it, comma-separated for several).

## Own account

- `GET /me`: the signed-in user.
- `PATCH /me` `{display_name?, theme?, card_back?}`: the updated user; 400 `bad_display_name` (1 to 64
  characters), `bad_theme` (`classic` or `cyberpunk`) or `bad_card_back` (an id from `GET /card-backs`, `""` =
  the server default). A bad theme or card back changes nothing.
- `GET /card-backs`: `{default, card_backs: [{id, name, theme?, built_in}]}`. Built-in backs are drawn by the
  apps from their id; uploaded ones (`u-` ids) come from `GET /card-backs/{id}/image` (500 x 700 PNG, immutable).
- `POST /me/password` `{current_password, new_password}`: 204, every other session is signed out; 403
  `wrong_password`; 400 `bad_password` (10 to 256 characters). Passkey-only accounts send no current password.
- `DELETE /me` `{password}`: 204, the account and all its data are gone; 403 `wrong_password`; 409
  `last_admin`.
- `PUT /me/avatar` (raw PNG, JPEG, GIF or WebP as the body): the updated user, `avatar` = new version. The
  server crops the centre square and re-encodes a 256 px PNG, so no metadata survives. 413 `too_large` (body
  over the upload cap, 5 MiB by default) or `image_too_large` (over 8192 px a side or 40 megapixels); 415
  `bad_image` (anything else, SVG included).
- `DELETE /me/avatar`: 204.
- `GET /users/{id}/avatar?v={avatar}`: the PNG for signed-in users, `ETag` = version, private cache for a
  day, 304 on `If-None-Match`; 404 when the user has none or is disabled.
- `GET /me/sessions`: `{sessions: [...]}` with `current` marking this one.
- `DELETE /me/sessions/{id}`: 204; 404 for a session that is not yours.
- `POST /me/sessions/revoke-others`: `{revoked: n}`.
- `GET /me/totp`: `{enabled, recovery_codes_left}`.
- `POST /me/totp/begin`: `{secret, otpauth_url, qr_png}` (PNG as base64); 409 `totp_enabled`. A new begin
  replaces a pending one.
- `POST /me/totp/confirm` `{code}`: `{recovery_codes: [10]}`, shown once; 400 `invalid_code`.
- `POST /me/totp/disable` `{code}`: 204 with a current code or a recovery code; 400 `invalid_code`.
- `GET /me/passkeys`: `{passkeys: [{id, name, created_at, last_used_at?, synced}]}`.
- `POST /me/passkeys/begin`: 200 `{ceremony, options}` for `navigator.credentials.create` (resident key
  and user verification required, no attestation); 409 `too_many_passkeys` (20).
- `POST /me/passkeys/finish` `{ceremony, credential, name?}`: 201 passkey; 400 `passkey_rejected` or
  `bad_name` (1 to 64 characters, default "Passkey").
- `PATCH /me/passkeys/{id}` `{name}`: 204.
- `DELETE /me/passkeys/{id}`: 204; 409 `last_sign_in_method` when the account has no password and this is
  its last passkey.

## Invitations

There is no open registration: new players join through an invitation link `<server>/invite#<token>`. The
token sits in the URL fragment, so it never reaches an access log; the app reads it, and native apps take the
server address from the same link. Only the SHA-256 of a token is stored.

Admins (403 `admin_only` for everyone else):

- `POST /admin/invitations` `{expires_in_hours?, max_uses?, note?}`: 201 `{invitation, token, url}`; the
  token is shown only here. Defaults: 72 hours, one use. 400 `bad_invitation` outside 1 to 720 hours, 1 to 100
  uses, a note up to 200 characters.
- `GET /admin/invitations`: `{invitations: [{id, note, max_uses, uses, created_at, expires_at, revoked_at?,
  created_by, joined: [{id, username, display_name, joined_at}]}]}`, newest first.
- `DELETE /admin/invitations/{id}`: 204; the link stops working, accounts made through it stay.

Anyone holding a link (callable by native apps without a token, like sign-in):

- `POST /invitations/check` `{token}`: `{expires_at, note, passkeys}` (`passkeys` = passkey sign-up offered).
- `POST /auth/signup` `{token, username, display_name?, password, client?}`: signs the new player in, same
  answer as `/auth/signin`.
- `POST /auth/signup/passkey/begin` `{token, username, display_name?}`: `{ceremony, options}` for
  `navigator.credentials.create`; nothing is stored yet.
- `POST /auth/signup/passkey/finish` `{ceremony, credential, name?, client?}`: creates the account with that
  passkey and no password, then signs in; 400 `passkey_rejected`.

The link is checked again inside the transaction that creates the account, so a link used up meanwhile
refuses. Errors of all four: 404 `invitation_invalid` (unknown or revoked), 410 `invitation_expired`, 410
`invitation_used`, 400 `bad_username` / `bad_display_name` / `bad_password`, 409 `username_taken`, 429
`rate_limited` after too many bad tokens from one IP.

## Admin console

All under `/admin`, admins only (403 `admin_only`). Every change lands in the audit log.

- `GET /admin/users?q=&limit=&offset=`: `{users, total}`, `q` matches username or display name (no
  wildcards), ordered by username, 50 per page by default (200 at most).
- `POST /admin/users` `{username, display_name?, is_admin?}`: 201 `{user, temporary_password}`. The admin
  never chooses the password: the new user must replace the temporary one at the first sign-in.
- `PATCH /admin/users/{id}` `{disabled?, is_admin?}`: the updated user. Disabling signs the user out
  everywhere. 409 `last_admin` when no other enabled admin would remain; 409 `self` for disabling or demoting
  yourself.
- `DELETE /admin/users/{id}`: 204; 409 `self` (use `DELETE /me`) or `last_admin`.
- `POST /admin/users/{id}/reset-password`: `{temporary_password}`, shown once; signs the user out everywhere.
- `POST /admin/users/{id}/reset-2fa`: 204, TOTP and recovery codes removed.
- `GET /admin/settings`, `PATCH /admin/settings` `{table_creation?, max_upload_bytes?, card_back_default?}`:
  `table_creation` is `everyone` (default) or `admins`; `max_upload_bytes` 256 KiB to 20 MiB (default 5 MiB);
  `card_back_default` any card back id (default `classic-red`). 400 `bad_settings`.
- `POST /admin/card-backs?name=` (raw PNG, JPEG or WebP as the body): 201 with the new back; the centre 5:7 area
  is re-encoded to a 500 x 700 PNG. 400 `bad_name` (1 to 40 characters), 409 `too_many_card_backs` (50 at
  most), 413 and 415 as for avatars.
- `DELETE /admin/card-backs/{id}`: 204, users who had picked it follow the default again; 409 `built_in` or
  `is_default`; 404.
- `GET /admin/audit?action=&actor=&before=&limit=`: `{events: [{id, at, actor_id, actor_name, action, target,
  ip, detail}]}`, newest first. `action` is exact or a prefix ending in a dot (`user.`); page with
  `before=<last id>`; 100 per page by default (500 at most).
- `GET /admin/reports?all=1&limit=`: `{reports: [{id, reporter_id?, reported_id?, reporter, reported, table_id?,
  table_name?, reason, note, chat: [{user, name, text, at}], created_at, resolved_at?, resolved_by?}]}`, newest
  first; open ones only without `all=1`. `chat` is the table's last 20 lines at report time.
- `POST /admin/reports/{id}/resolve`: 204; 404 if unknown or already resolved.

A user holding a temporary password gets 403 `password_change_required` on everything except `GET /me`,
`POST /me/password` and `POST /auth/signout`.

## Block and report

- `GET /me/blocks`: `{blocks: [{id, username, display_name, created_at}]}`, newest first.
- `PUT /me/blocks/{user id}`: 204 (again is fine). The blocked user's table chat is no longer delivered to you,
  on open connections at once. 400 `block_self`, 404, 409 `too_many_blocks` (500).
- `DELETE /me/blocks/{user id}`: 204.
- `POST /reports` `{user, table?, reason: chat|behaviour|other, note?}`: 201 `{id}`. With an open `table` the
  server attaches that table's last 20 chat lines itself; the note is up to 500 characters. 400 `bad_report` or
  `report_self`, 404, 429 `too_many_reports` (20 open per reporter).

## Tables (lobby)

Signed in. Settings in JSON use whole seconds for `turn_time`.

- `GET /api/v1/tables` lists the open tables, oldest first: `{"tables":[{"id","host","settings":{name, seats, small_blind, big_blind, starting_stack, turn_time, spectators},"taken","players":[names],"hand_no"}]}`.
- `POST /api/v1/tables` `{name, seats, small_blind, big_blind, starting_stack, turn_time, spectators, kind?, structure?}` creates a table hosted by the caller (201, lobby entry). `kind` is `cash` (default) or `sng` (sit-and-go); a sit-and-go needs `structure`: `turbo` (3 minute levels), `regular` (6) or `slow` (10), and its small and big blind are those of the first level. Limits: name 1 to 40 characters, 2 to 9 seats, big blind at least 1 and small blind not above it, starting stack at least two big blinds, turn time 5 to 300 s. Errors: `bad_settings` (with `detail`), `admins_only` when the admin setting `table_creation` is `admins`, `too_many_tables` (100 open tables).
- `DELETE /api/v1/tables/{id}` closes a table (204); only its host or an admin (`host_or_admin_only`). A running hand is cancelled and every stack goes back to where it was before it.

Empty tables close by themselves after 30 minutes.

### Voice and video (full option)

`GET /api/v1/health` reports `"media": true` when the server has LiveKit settings (`LIVEKIT_URL`, `LIVEKIT_API_KEY`, `LIVEKIT_API_SECRET`, all three or none; a partial set stops the server at start).

- `POST /api/v1/tables/{id}/media-token` returns `{"url","token","room","expires_at"}`: a LiveKit token for the table's call, valid 10 minutes, for the caller as identity (user id) and name. Only users who watch the table on a live WebSocket (players and spectators) and were not removed by the host get one; the app asks again before `expires_at`. Errors: `media_off` (404, minimal option), `not_found` (no such table), `not_at_table` (403).

## Realtime (WebSocket)

`GET /api/v1/ws` upgrades to a WebSocket. One connection per tab or app carries the lobby, the watched table and its chat.

- Auth: browsers use the session cookie and must send `Origin` equal to the server's `PUBLIC_URL`; native apps send `Authorization: Bearer <token>` and no Origin. Anything else gets 401 or 403 before the upgrade.
- At most 10 connections per account (the 11th is closed with status 1008). Messages are JSON text frames of at most 4 KiB. The server pings every 25 s and re-checks the session: a signed-out session, a disabled account or a reset password closes the connection. A client that does not read its messages is disconnected.

Client messages (`id` is optional; when set, the server answers `{"type":"ok","id":n}` or `{"type":"error","id":n,"error":"<code>"}`):

- `{"type":"lobby","on":true}` / `false`: receive `lobby` messages whenever a table opens, closes or changes.
- `{"type":"watch","table":"<id>"}`: watch one table (replaces the previous one); the current view is sent at once, so a client that reconnects (a phone that slept) sends `watch` again and is back where it was. `{"type":"unwatch"}`.
- On the watched table: `{"type":"sit","seat":n}` (buy in with the starting stack), `{"type":"sitout"}`, `{"type":"comeback"}` (a player with no chips buys in again), `{"type":"leave"}` (folds if in a hand), `{"type":"act","action":"fold|check|call|bet|raise","to":n}` (`to` = the player's total for the street, for bet and raise), `{"type":"chat","text":"..."}`, `{"type":"ping"}`, `{"type":"start"}` (host or admin starts a sit-and-go with the players seated; it also starts by itself when every seat is taken).
- Host or admin only: `{"type":"mute","user":"<id>"}` and `{"type":"unmute","user":"<id>"}` switch anyone's table chat off and on while the table is open; `{"type":"remove","user":"<id>"}` sends a spectator away (`is_player` for a seated player), and that user cannot watch the table again until it closes.
- Host or admin only, full option (`media_off` otherwise): `{"type":"call_mute","user":"<id>","source":"microphone"|"camera"}` switches that track off in the table's call (the user may turn it on again); `{"type":"call_remove","user":"<id>"}` sends a player or spectator out of the call, and they get no new call token until the table closes, while keeping their seat or place. Removing a spectator from the table also ends their call, and closing the table ends the call for everyone. The server makes these changes through the LiveKit server API in the background: the game never waits for them.

Sit-and-go tables carry `sng` in the view: `{phase: registering|running|finished, level, small_blind, big_blind, next_small_blind?, next_big_blind?, level_ends?, places: [{place, user, name}], started?}`. Blinds rise between hands once `level_ends` has passed; places list the finished players, best first, and the winner as place 1 when the phase is `finished`. During registration players take and leave seats freely; once it runs nobody joins, nobody rebuys, and a player who leaves keeps the seat sitting out: blinds are posted and the hand folded until the chips are gone. Busted players leave the table with their place. Errors: `not_sng`, `sng_started`, `too_few_players`, `host_or_admin_only`.

Server messages:

- `{"type":"hello","user","name"}` first.
- `{"type":"view","view":{...}}` after every change of the watched table. The view is built for this viewer: own hole cards, cards shown at showdown, and `hand.legal` only for the player to act (`fold`, `check`, `call` = chips to call, `bet_kind` = `bet` or `raise`, `min_to`, `max_to`). Spectators see no hole cards. On a table without spectators, someone who is not seated sees the seats but no hand. A closed table sends a last view with `"closed":true`.
- `{"type":"lobby","tables":[...]}`, same entries as `GET /api/v1/tables`.
- `{"type":"chat","table","user","name","text","at"}`. Chat is for players and spectators of the table, 1 to 300 characters, 5 messages per 10 s per connection, and is never stored (the last 20 lines stay in memory for reports). Lines of users you blocked are not sent to you.
- `{"type":"moderation","table","muted":["<user id>"]}` after `watch` and after every mute change.
- `{"type":"removed","table"}`: the host removed you; you watch nothing now.

Error codes: `bad_intent`, `not_watching`, `no_table`, `seat_taken`, `bad_seat`, `already_seated`, `not_seated`, `not_in_hand`, `not_your_turn`, `illegal_action`, `bad_amount`, `bad_chat`, `rate_limited`, `spectators_off`, `muted`, `removed`, `is_player`, `host_or_admin_only`. An error never changes the table.

## Hand history and stats

Every finished hand is stored with what was seen at the table: public actions, the board, cards shown at showdown and the pots. Each player's own hole cards are kept in their own row and only returned to them; cards of others that were never shown are never written.

- `GET /api/v1/me/hands?before=<id>&limit=<1..100>` lists your hands, newest first: `{"hands":[{"id","table_name","hand_no","big_blind","pot","board","seat","cards","won","net","ended_at"}]}` (`net` = end stack minus start stack).
- `GET /api/v1/me/hands/{id}` replays one of your hands: settings, `button`, `board`, `events` (in order), `results`, `seats` (name, start and end stack, chips won), `your_seat`, `your_cards`. 404 for hands you did not play.
- `GET /api/v1/me/stats`: `{"hands_played","hands_won","biggest_pot","sng_games","sng_wins","sng_best_place"}` (`biggest_pot` = most chips won in one hand; `sng_best_place` is 0 until you finish a sit-and-go).
- `GET /api/v1/me/games?limit=<1..100>` lists the sit-and-go games you played, newest first: `{"games":[{"id","table_name","players","your_place","places":[{"place","name"}],"started_at","finished_at"}]}`. A game is stored when its last player standing wins, right after its last hand.
