# Install and operate Oxi Poker

This guide takes you from an empty Linux server to a running Oxi Poker with HTTPS, a first admin and invitation links for your friends, and then covers upgrades, backups, logs and moving to another box.

There are two options in one Compose file:

- **Minimal:** one container. The game, text chat, history, passkeys. Needs one DNS name and HTTPS.
- **Full:** adds a LiveKit media server for voice and video at the table. Needs a second DNS name and a few open ports. Start with minimal; you can switch to full later without losing anything.

## What you need

- A Linux server (amd64 or arm64) with [Docker Engine](https://docs.docker.com/engine/install/) and the Compose plugin (`docker compose version` prints a version). 1 CPU and 1 GB of memory carry several tables; the full option wants 2 CPUs for a few video calls at once.
- A DNS name pointing at the server, for example `poker.example.com`.
- Ports 80 and 443 open for the HTTPS proxy.

## Minimal option

The `docker` commands in this guide assume your user may run Docker (member of the `docker` group, or rootless Docker). Otherwise put `sudo` in front of them.

```sh
mkdir oxipoker && cd oxipoker
curl -LO https://raw.githubusercontent.com/oxisoft/oxipoker/main/deploy/compose.yaml
curl -L https://raw.githubusercontent.com/oxisoft/oxipoker/main/deploy/.env.example -o .env
nano .env
mkdir -m 700 data && sudo chown 1000:1000 data
docker compose up -d
```

In `.env` (any editor will do) set three values before the first start:

- `PUBLIC_URL`: the address players will use, `https://poker.example.com`. Passkeys and invitation links are bound to it.
- `ADMIN_USERNAME` and `ADMIN_PASSWORD`: the first admin, created on the first start (password 10 characters or more).
- `OXIPOKER_VERSION`: `latest`, or a release such as `1.0.0` if you want to choose when to upgrade.

The image comes from Docker Hub. Every release is also on `ghcr.io/oxisoft/oxipoker` with the same tags: set `OXIPOKER_IMAGE=ghcr.io/oxisoft/oxipoker` if Docker Hub limits your pulls.

The container runs as user 1000, not root, which is why `data` is handed to uid 1000. With rootless Docker, uid 1000 inside the container maps to another uid on the host; give the folder to it through a container instead:

```sh
docker run --rm -v "$PWD/data:/d" alpine chown 1000:1000 /d
```

Check that it runs:

```sh
docker compose ps                         # STATUS shows (healthy) after about 10 seconds
curl -s http://127.0.0.1:8080/api/v1/health
```

The health answer looks like `{"status":"ok","version":"1.0.0","api":1,"webapp":true,"media":false,"database":"ok"}`. The server listens on `127.0.0.1:8080` only; the next step puts HTTPS in front of it. Another port: set `OXIPOKER_PORT` in `.env`.

## HTTPS

Browsers allow passkeys, camera and microphone only over HTTPS. The game also uses a WebSocket on `/api/v1/ws`, which the proxy must pass through.

### Caddy

[Caddy](https://caddyserver.com/docs/install) gets and renews the certificate by itself and passes WebSockets as they are. `/etc/caddy/Caddyfile`:

```
poker.example.com {
    reverse_proxy 127.0.0.1:8080
}
```

Then `sudo systemctl reload caddy`.

### nginx

nginx needs the WebSocket headers and a certificate, for example from certbot. In the `http` block (for instance in `/etc/nginx/conf.d/websocket.conf`):

```nginx
map $http_upgrade $connection_upgrade {
    default upgrade;
    ''      close;
}
```

The site, `/etc/nginx/sites-available/poker.example.com`:

```nginx
server {
    listen 80;
    server_name poker.example.com;
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_read_timeout 1h;
        client_max_body_size 20m;
    }
}
```

```sh
sudo ln -s /etc/nginx/sites-available/poker.example.com /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
sudo certbot --nginx -d poker.example.com
```

certbot adds the `listen 443 ssl` part and renews the certificate on its own. `proxy_read_timeout` keeps quiet tables connected; without it nginx closes the WebSocket after 60 seconds and the apps reconnect every minute. `client_max_body_size` lets avatars and card backs through up to the largest upload limit the admin console allows.

Open `https://poker.example.com`: the sign-in page of the web app appears.

## First admin

Sign in with `ADMIN_USERNAME` and `ADMIN_PASSWORD`. Then, on the account screen:

1. Change the password. The values in `.env` are used only while no admin exists; you can delete `ADMIN_PASSWORD` from `.env` afterwards.
2. Add a passkey, or turn on two-factor sign-in with an authenticator app.

The shield icon in the top bar opens the admin console: invitations, players, settings and reports.

## Invitations

There is no open registration. Players join through invitation links:

1. Admin console, Invitations, New invitation. Choose how long it stays valid (1 to 720 hours, 72 by default) and how many people may use it (1 by default; up to 100 for a group chat), and add a note so you remember who it was for.
2. Copy the link. It is shown only once; the server keeps a hash, not the link.
3. Send it to your friend. Opening it in a browser or the app leads to sign-up with a passkey or a password.

A link you sent to the wrong place can be revoked in the same list; accounts already made through it stay.

## Apps

- **Browser:** the server's address; nothing to install.
- **Android:** from the OxiSoft F-Droid repository (see the [README](../README.md#get-the-apps) for the repository address and the signing fingerprint) or the APK from [GitHub Releases](https://github.com/oxisoft/oxipoker/releases).
- **Windows, macOS, Linux:** from [GitHub Releases](https://github.com/oxisoft/oxipoker/releases); check the download against `SHA256SUMS` in the same release (`sha256sum -c SHA256SUMS --ignore-missing` on Linux, `Get-FileHash` on Windows, `shasum -a 256` on macOS).
  - Windows builds are not code signed, so SmartScreen shows "Windows protected your PC" on the first start. Click "More info", then "Run anyway". Unpack the whole zip first and start the app from the unpacked folder.
  - macOS builds are signed and notarised: open the dmg and drag Oxi Poker to Applications.
  - Linux: unpack the tarball and run `./oxipoker`. It needs GTK 3 and libsecret, which desktop distributions ship.

On first start the apps ask for the server address: enter `poker.example.com`.

## Full option: voice and video

Voice and video run through [LiveKit](https://livekit.io), a second container from the same Compose file. You need:

- a second DNS name for LiveKit signalling, for example `rtc.example.com`, proxied over HTTPS like the game;
- open media ports: 7881/tcp and 7882/udp by default;
- for players behind strict networks, TURN: 3478/udp, and TURN over TLS on its own DNS name (for example `turn.example.com`) with its own certificate, on 5349/tcp by default.

[VOICE-VIDEO.md](VOICE-VIDEO.md) walks through every step: names and ports, keys (`docker run --rm livekit/livekit-server generate-keys`), the proxy, the TURN certificate and how to check each part. When `.env` is filled in:

```sh
docker compose --profile full up -d
curl -s http://127.0.0.1:8080/api/v1/health    # "media":true
```

Back to minimal at any time: `docker compose --profile full down`, empty `LIVEKIT_URL` in `.env`, `docker compose up -d`.

Then sign in as admin, open **Admin**, tab **Settings**, and press **Run the check** under "Voice and video connection check". Give LiveKit a minute after it starts: until then it reports "not ready" and the check says so. The server tries three things and explains every failure in plain words:

- **LiveKit signalling:** LiveKit answers at `LIVEKIT_URL` (DNS, proxy, container).
- **Call token round trip:** LiveKit accepts a token signed with `LIVEKIT_API_KEY` and `LIVEKIT_API_SECRET` (the same pair in both services, clocks in sync).
- **TURN over TLS:** the TURN TLS port answers with a valid certificate for `LIVEKIT_TURN_DOMAIN`.

The check runs from the server, so it proves the names, ports and keys, not the network of each player. Media ports (UDP) are covered in [VOICE-VIDEO.md](VOICE-VIDEO.md).

## Operations

All state lives in `./data`: the database `oxipoker.db` (accounts, avatars, tables, hand history) with its `-wal` and `-shm` files, and `server.key` (the root key; among other things it encrypts the two-factor secrets of players who use an authenticator app). `.env` holds your settings, `./certs` the TURN certificate in the full option.

### Upgrade

```sh
docker compose exec oxipoker /app/oxipoker -backup /app/data/backups/before-upgrade.db
docker compose pull
docker compose up -d          # add --profile full on the full option
```

With `OXIPOKER_VERSION=latest` that takes the newest release; with a pinned version, change the number in `.env` first. The server updates the database by itself on start. Downgrades are refused: an older server stops with "database schema N is newer than this server: refusing to downgrade" instead of damaging the data. To go back, restore the backup taken before the upgrade (below) and pin the old version.

A hand that is being played when the container restarts is called off: the table comes back with the stacks from the start of that hand, and players reconnect on their own within seconds. Upgrade between hands, or tell the table first.

Any 1.x app works with any 1.x server; the app's About section (account screen) shows both versions and says when the server is too old for the app.

### Backup

The server writes a consistent copy of the database while it runs:

```sh
docker compose exec oxipoker /app/oxipoker -backup /app/data/backups/oxipoker-$(date +%F).db
```

The copy lands in `./data/backups/` on the host. Copy it and `data/server.key` off the box, for example with restic, borg or rsync run as root (`data` is readable only by uid 1000 and root). Do not copy `oxipoker.db` itself while the server runs: the file alone, without the committed pages still in `oxipoker.db-wal`, can be incomplete.

A daily backup from root's cron on the host (`sudo crontab -e`), keeping 14 days:

```
15 4 * * * cd /home/you/oxipoker && docker compose exec -T oxipoker /app/oxipoker -backup /app/data/backups/oxipoker-$(date +\%F).db >/dev/null && find data/backups -name 'oxipoker-*.db' -mtime +14 -delete
```

The backup refuses to overwrite an existing file, so a second run on the same day fails loudly instead of replacing the morning copy.

With rootless Docker the files in `data/` belong to a mapped user id on the host and the Docker daemon is your own, so use your own crontab there, and `find ... -delete` fails with "permission denied" even with the right path. Delete old copies through a throwaway container instead: `docker run --rm -v "$PWD/data:/d" alpine find /d/backups -name 'oxipoker-*.db' -mtime +14 -delete`. The server image itself has no shell or `rm`.

### Restore

`data` belongs to uid 1000 with mode 700, so on the host only root (or your account, if its uid is 1000) can reach into it; that is why these commands use `sudo`.

```sh
docker compose down
sudo mv data/oxipoker.db data/oxipoker.db.broken
sudo rm -f data/oxipoker.db-wal data/oxipoker.db-shm
sudo cp /path/to/oxipoker-2026-11-19.db data/oxipoker.db
sudo chown 1000:1000 data/oxipoker.db
docker compose up -d
```

Restore `server.key` from the same backup. With a different key the rest of the data is intact, but codes from authenticator apps no longer match: those players sign in with a passkey or their password plus a recovery code, then set up two-factor sign-in again.

### Logs

```sh
docker compose logs -f oxipoker          # the game server
docker compose logs -f livekit           # full option: the media server
```

The server logs one line per event in `key=value` form. Docker keeps logs until the container is recreated; to cap their size set `"log-opts": {"max-size": "10m", "max-file": "3"}` in `/etc/docker/daemon.json`.

### Moving to a new box

1. On the new box: install Docker and the proxy as above, copy `compose.yaml` and `.env`.
2. On the old box: `docker compose down`, so the database is closed and complete.
3. Copy the whole `data` folder (and `certs` on the full option) to the new box, keeping the owner uid 1000: `sudo rsync -a old:oxipoker/data/ data/`.
4. On the new box: `docker compose up -d` (`--profile full` on the full option), then point the DNS names at the new address.
5. When the new box answers on `https://poker.example.com/api/v1/health`, remove the data from the old one.

Keep `PUBLIC_URL` the same: passkeys belong to that name, and a new name means every player adds a new passkey (passwords keep working).

## When something does not work

- **The container restarts or shows (unhealthy):** `docker compose logs oxipoker`. "permission denied" on `/app/data` means `data` does not belong to uid 1000 (see the minimal option).
- **The page loads but tables never update, or the app says "reconnecting":** the proxy drops the WebSocket. Check the `Upgrade` and `Connection` headers in nginx.
- **Passkeys fail:** the address in the browser differs from `PUBLIC_URL`, or the site runs without HTTPS.
- **Voice and video:** [VOICE-VIDEO.md](VOICE-VIDEO.md) has the checks per port.
