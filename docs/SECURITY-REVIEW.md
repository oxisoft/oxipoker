# Security review

Status: in progress (M5). Each area lists what was checked, against which code, and the findings. A finding is fixed with a test or explained here.

## Findings

### F1 Client address could be forged (fixed)

The server used a generic middleware that took the client address from `True-Client-IP`, `X-Real-IP` or the left end of `X-Forwarded-For`, from any sender. Caddy and nginx pass `X-Real-IP` on unchanged and nginx appends to `X-Forwarded-For`, so a client could send a fresh address with every request and never reach the per-address limit on failed sign-ins, TOTP codes, passkey attempts and invitation codes. The per-account limit still held, so one account could not be brute forced, but many accounts could be tried from one machine.

Fix: `server/internal/httpapi/realip.go`. Forwarding headers count only when the request comes from a loopback, private or link-local address (the reverse proxy), and only `X-Forwarded-For`, read from the right. Tests: `TestRealIPTrustsOnlyTheProxyHop` (direct clients, Caddy, nginx with a forged left entry, two proxies, garbage, IPv6) and `TestSigninLimitIgnoresForgedAddresses` (fails with the old middleware). The install guide says how the address is found.

### F2 No Content Security Policy on the web app (fixed)

The web app got `X-Content-Type-Options`, `Referrer-Policy` and `X-Frame-Options`, but no `Content-Security-Policy`, so an injected script would have run with the player's session.

Fix: `server/internal/httpapi/headers.go`. Every response carries `default-src 'self'; script-src 'self' 'wasm-unsafe-eval'` (CanvasKit compiles WebAssembly; JavaScript eval stays off), `style-src 'self' 'unsafe-inline'` (the Flutter engine writes styles at run time; styles cannot run code), `img-src 'self' data: blob:`, `connect-src` limited to this server and, only when voice and video are on, the LiveKit address, plus `object-src 'none'`, `base-uri 'self'`, `form-action 'self'` and `frame-ancestors 'none'`. Avatars and card backs keep their own `default-src 'none'`. The web build bundles CanvasKit and its fonts (`--no-web-resources-cdn`, Noto fonts in the app), so the policy needs no third party: a browser running Oxi Poker talks only to your server and your LiveKit. Characters outside the bundled fonts (for example emoji in a player name) show as boxes instead of fetching a font from a CDN. Also sent: `Cross-Origin-Opener-Policy: same-origin` and a `Permissions-Policy` that allows camera and microphone for this site only.

Tests: `TestWebAppContentSecurityPolicy`, `TestContentSecurityPolicyAllowsLiveKitOnlyWhenMediaIsOn`. Checked in Chromium with the real web build and media on: sign-in, lobby, table over WebSocket and joining voice and video all work with no policy violation, while a fetch to another site is refused.

### F3 No HSTS (fixed)

When `PUBLIC_URL` is https the server sends `Strict-Transport-Security: max-age=31536000` itself, so it does not depend on the proxy configuration. It leaves out `includeSubDomains`: other names under the same domain may not be served over HTTPS and are not the server's to pin. Test: `TestNoHSTSWithoutHTTPS` plus the check in `TestWebAppContentSecurityPolicy`.

### F4 No limit on WebSocket messages per connection (fixed)

Chat was limited (5 messages per 10 seconds), message size too (4 KB), and one account may hold 10 connections, but other intents (watch, sit, actions) had no rate limit: a scripted client could send thousands per second and keep its table and the view builder busy for everyone at the table.

Fix: `server/internal/realtime/conn.go`. Each connection has a token bucket of 40 messages refilled at 20 per second, far above a person at a table. A connection that runs dry is closed with policy violation "too many messages" instead of getting error replies, which would only add work. Tests: `TestFloodingClientIsClosed` (fails without the limit: the connection stays open or ends for another reason) and `TestSteadyClientBelowTheRateStaysOpen` (80 intents at 10 per second). The full-table leak test lifts the limit for its machine-speed bots.

## Areas

### WebSocket origin and limits

Checked: `GET /api/v1/ws` needs a signed-in session; with an `Origin` header it must equal `PUBLIC_URL` (or the request host when that is unset), without one it needs a bearer token, so a cookie alone from a foreign page or a plain script cannot connect (`TestWebSocketAuthAndOrigin`). Every keepalive (25 s) checks the session again: sign-out, a disabled account or a forced password change close the connection. Limits: 4 KB per message (`SetReadLimit`), unknown fields rejected, 10 connections per account (`TestConnectionCapPerUser`), a client that does not read is dropped after 64 queued messages ("too slow"), and the message rate of F4.

### Per-seat view filtering

Checked: `table.State.ViewFor` drops every `hole` event of another seat and fills `cards` only for the viewer's own seat and for seats that showed at showdown; `legal` goes only to the player to act. Showdown values (`value`) appear only on `show` and `win` events, which come after the cards are shown. Tests: `TestViewsNeverLeakHiddenCards` (200 hands, every snapshot, every viewer), `TestPlayersOnlyEverGetTheirOwnHoleCards` (WebSocket) and `TestNoHiddenCardsAcrossAFullTable`: six players and a spectator play 120 hands over the real HTTP and WebSocket API with random bets, raises, all-ins and folds; every WebSocket message and every history list and hand response is searched for another player's hole cards that the message itself does not show. Two deliberate leaks (hole events to everyone, hole events kept in history) both make it fail. It runs in the `Security` workflow on every push.

### History privacy

Checked: `history.Store.Get` joins on the requesting user's own row in `hand_players`, so a hand id of a hand the user did not play gives 404; stored events go through `PublicEvents` (no `hole` events); the list carries only the user's own cards. Covered by the full-table test above.

### Dependencies

`govulncheck` runs on every push and pull request and weekly (new advisories arrive without new commits): clean on 2026-11-19. Pull requests also run GitHub's dependency review (fails at moderate severity and above).

### Still to review

Authentication (password hashing, passkeys, TOTP, sessions, account limits), invitations, uploads, media tokens, admin actions and audit log, container (non-root user 1000, read-only filesystem).

### HTTP headers

Done: see F2 and F3.
