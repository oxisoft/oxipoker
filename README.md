# Oxi Poker

Self-hosted No-Limit Texas Hold'em for you and your friends. Run one container, send invitation links, play in the browser, on Android or on the desktop. Text chat at every table, and in the full option voice and video too. No real money, no accounts on anyone else's server, no tracking.

> **Status: early development.** The plan and milestones are in [docs/ROADMAP.md](docs/ROADMAP.md). Nothing is playable yet.

## What it will do

- **Cash games and sit-and-go** tournaments, 2 to 9 seats, starting stack and blinds set by the table host
- **Invite-only accounts:** the admin creates users or sends invitation links; sign in with a passkey or a password, optional two-factor codes
- **Spectators** can watch any table (hole cards stay hidden) and join the chat
- **Voice and video** at the table with the full option, powered by [LiveKit](https://livekit.io)
- **Hand history** with replays, and personal stats
- **Classic green felt** or a cyberpunk theme, custom card backs
- Web app built into the server, Android builds via F-Droid, Windows, macOS and Linux builds on GitHub Releases

## Run it

Two options, one Compose file:

```sh
mkdir oxipoker && cd oxipoker
curl -LO https://raw.githubusercontent.com/oxisoft/oxipoker/main/deploy/compose.yaml
curl -L https://raw.githubusercontent.com/oxisoft/oxipoker/main/deploy/.env.example -o .env
# edit .env: PUBLIC_URL, ADMIN_USERNAME, ADMIN_PASSWORD

docker compose up -d                   # minimal: game + text chat
docker compose --profile full up -d    # full: + voice and video
```

The server listens on `127.0.0.1:8080`. Put an HTTPS reverse proxy in front of it: browsers allow passkeys, camera and microphone only over HTTPS. With [Caddy](https://caddyserver.com) that is two lines:

```
poker.example.com {
    reverse_proxy 127.0.0.1:8080
}
```

The game uses a WebSocket (`/api/v1/ws`); Caddy passes it through as is, nginx needs the `Upgrade` and `Connection` headers (example in [docs/VOICE-VIDEO.md](docs/VOICE-VIDEO.md#3-reverse-proxy-for-signalling)).

**Voice and video** need a second DNS name for LiveKit signalling, a few open media ports and, for players behind strict networks, TURN over TLS with its own certificate. [docs/VOICE-VIDEO.md](docs/VOICE-VIDEO.md) walks through it: ports, keys, proxy, certificate, checks.

All data (database, uploads, keys) lives in `./data`. Back up that folder and you have backed up the server.

Images: [`oxisoft/oxipoker`](https://hub.docker.com/r/oxisoft/oxipoker) on Docker Hub, `linux/amd64` and `linux/arm64`.

## Get the apps

- **Browser:** open your server's address; the web app is built in.
- **Android:** install [F-Droid](https://f-droid.org), then add the OxiSoft repository: on your phone open [fdroid.oxisoft.io](https://fdroid.oxisoft.io) and tap the repository link, or add `https://fdroid.oxisoft.io/fdroid/repo` under Settings, Repositories. Search for Oxi Poker and install it; updates arrive through F-Droid. The APK is also attached to every [GitHub release](https://github.com/oxisoft/oxipoker/releases).
- **Windows, macOS, Linux:** download from [GitHub Releases](https://github.com/oxisoft/oxipoker/releases) and check the file against `SHA256SUMS` in the same release.

The Android app is signed with Oxi Poker's own key, not through Google Play. Its certificate SHA-256 fingerprint is:

```
79:F2:92:04:83:FB:1F:7F:B7:66:36:D9:FF:76:AB:FF:7E:CC:B6:13:6E:B5:62:42:00:61:12:FF:23:9F:33:CD
```

Check a downloaded APK with `apksigner verify --print-certs oxipoker-<version>.apk`. Every Oxi Poker release is signed with this key; an APK with any other fingerprint did not come from us.

## Build from source

Requirements: Go 1.27, Flutter 3.50, Docker.

```sh
# server alone (embeds a placeholder page instead of the web app)
cd server && go test ./... && go run ./cmd/oxipoker

# web app
cd app && flutter test && flutter build web --release

# the full image, web app included
docker build --build-context webapp=app/build/web -t oxipoker:dev .
```

## Repository layout

- `server/`: Go server (game engine, API, realtime, embedded web app)
- `app/`: Flutter client for web, Android, Windows, macOS and Linux
- `deploy/`: Compose file and settings template
- `docs/`: roadmap and design notes

## Contributing

Contributions are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) first: pull requests need a one-time signature of the [Contributor License Agreement](CLA.md). Security issues go to security@oxisoft.io, see [SECURITY.md](SECURITY.md).

### Translations

The app speaks 12 languages. Everything except English started as a machine translation, so a native speaker who fixes a few lines makes a real difference. Each language is one file in `app/lib/l10n/`; [CONTRIBUTING.md](CONTRIBUTING.md#translations) shows how to fix a line or add a language with a pull request, no Flutter setup needed.

## License

[GNU Affero General Public License v3.0](LICENSE). If you run a modified version of Oxi Poker for other people, you must offer them the source code of your version.

Made by [OxiSoft](https://oxisoft.io).
