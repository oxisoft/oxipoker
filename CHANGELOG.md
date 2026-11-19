# Changelog

All notable changes to Oxi Poker. Versions follow [Semantic Versioning](https://semver.org); the format follows [Keep a Changelog](https://keepachangelog.com).

## [1.0.0] - unreleased

The first release. Everything below was built in six milestones (specs in [docs/milestones](docs/milestones)); this entry lists what a server owner and a player get.

### Server and deployment (M0)

- One Docker image (`linux/amd64`, `linux/arm64`, scratch base, non-root, read-only root file system) with the web app built in.
- `deploy/compose.yaml` with two options: minimal (game and text chat) and `full` (adds LiveKit for voice and video).
- All data in one folder: SQLite database, uploads, server keys generated on first start.
- `/health` reports the version and whether voice and video are on.

### Accounts and admin (M1)

- No open registration: accounts come from the admin or from invitation links with expiry, use count and note.
- First admin from `ADMIN_USERNAME` and `ADMIN_PASSWORD` on the first start.
- Sign in with a password (argon2id) or a passkey (web and Android); optional two-factor codes with ten recovery codes.
- Own account: display name, password, sessions on other devices, avatar, delete account.
- Admin console: users (create, disable, reset password or two-factor, admin rights), invitations, server settings, audit log of every admin and security event.

### Cash tables (M2)

- No-Limit Texas Hold'em for 2 to 9 seats: blinds, heads-up order, dead button, min-raise rules, side pots, split pots with odd chips.
- The server is the only game authority. Each player receives only their own seat's view; other hole cards never leave the server before a showdown.
- Shuffle from `crypto/rand`; hand evaluator checked against all 2,598,960 five-card hands; property and fuzz tests for chip conservation.
- Lobby with live updates, turn timer, sit out and come back, reconnect that resumes at once.
- Spectators (no hole cards), text chat per table, hand history with replay, personal stats.

### Sit-and-go and finish (M3)

- Sit-and-go tables with turbo, regular and slow blind structures, a server blind clock, places and final standings.
- Tables survive a server restart: a hand cut off mid-way is voided and every stack goes back to its value at the start of that hand.
- Cyberpunk theme next to the classic green felt, built-in card backs, admin-uploaded card backs.
- Block and report users; the host can mute chat and remove spectators.
- The app speaks 12 languages: English, German, Spanish, French, Italian, Brazilian Portuguese, Polish, Russian, Ukrainian, Turkish, Japanese and Simplified Chinese.

### Voice and video (M4)

- Join the table's call with the full option; microphone and camera are off when you join.
- Video tiles at the seats and a strip for spectators, speaking indicator, camera switch on phones.
- The host and admins mute a microphone, stop a camera or remove someone from the call; blocked users are hidden and silenced.
- TURN over TLS for players behind strict routers. Media is never recorded or stored by Oxi Poker.

### Apps and 1.0 (M5)

- Android APK signed with Oxi Poker's own key, published on [fdroid.oxisoft.io](https://fdroid.oxisoft.io); Windows zip, macOS dmg and Linux tarball on GitHub Releases with `SHA256SUMS`.
- About screen with app and server version, and a warning when they differ.
- [Install guide](docs/INSTALL.md): HTTPS with Caddy or nginx, first admin, invitations, upgrades, online backup (`oxipoker -backup`), restore, moving to a new box. Tested on a fresh machine by CI.
- Connection check in the admin console for voice and video: signalling, token round trip and TURN, each failure explained.
- [Security review](docs/SECURITY-REVIEW.md) with nine findings, each fixed with a test: trusted client address, Content Security Policy, HSTS, WebSocket message limits, bounded password hashing, sign-in limits under parallel requests, image decode budget, call access after removal, hardened container.
- CI runs `govulncheck` and a test that plays a full table and checks no response ever carries another player's unshown cards.
