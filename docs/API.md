# Oxi Poker HTTP API

Base path `/api/v1`. JSON in and out. Errors are `{"error": "<code>"}` with a matching HTTP status.

Authentication: the web app gets an HttpOnly session cookie; native apps send `"client": "app"` at sign-in,
receive a `token` and pass it as `Authorization: Bearer <token>`. State-changing browser requests must
carry an `Origin` equal to the server's `PUBLIC_URL`.

This file grows with each milestone. Status: M1 in progress.

## Health

- `GET /health`: `{status, version, webapp, media, database}`; 503 when the database is not reachable.

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

Passkey endpoints exist only when `PUBLIC_URL` is set (the relying party id is its host). A passkey sign-in
needs no TOTP step: the passkey with user verification already is two factors.

## Own account

- `GET /me`: the signed-in user.
- `PATCH /me` `{display_name}`: the updated user; 400 `bad_display_name` (1 to 64 characters).
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
- `GET /admin/settings`, `PATCH /admin/settings` `{table_creation?, max_upload_bytes?}`: `table_creation` is
  `everyone` (default) or `admins`; `max_upload_bytes` 256 KiB to 20 MiB (default 5 MiB). 400 `bad_settings`.
- `GET /admin/audit?action=&actor=&before=&limit=`: `{events: [{id, at, actor_id, actor_name, action, target,
  ip, detail}]}`, newest first. `action` is exact or a prefix ending in a dot (`user.`); page with
  `before=<last id>`; 100 per page by default (500 at most).

A user holding a temporary password gets 403 `password_change_required` on everything except `GET /me`,
`POST /me/password` and `POST /auth/signout`.
