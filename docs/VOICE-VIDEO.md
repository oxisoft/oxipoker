# Voice and video (full option)

The full option adds a [LiveKit](https://livekit.io) media server next to the game. Players and spectators at a table can then talk and see each other. The game server stays the only authority: it decides who may join a table's call, signs short-lived tokens, and mutes or removes people when the host asks.

Without the LiveKit settings the server runs the minimal option (game and text chat), and the apps hide the call controls.

## 1. Names and ports

You need two extra DNS names pointing at your server, for example:

- `rtc.example.com`: LiveKit signalling, through your HTTPS proxy
- `turn.example.com`: TURN over TLS, served by LiveKit itself with its own certificate

And these ports open in the firewall (defaults, all configurable in `.env`):

- `7881/tcp` (`LIVEKIT_RTC_TCP_PORT`): media over TCP
- `7882/udp` (`LIVEKIT_RTC_UDP_PORT`): media over UDP, the normal path
- `3478/udp` (`LIVEKIT_TURN_UDP_PORT`): TURN over UDP
- `5349/tcp` (`LIVEKIT_TURN_TLS_PORT`): TURN over TLS, for networks that block UDP

With ufw:

```sh
ufw allow 7881/tcp
ufw allow 7882/udp
ufw allow 3478/udp
ufw allow 5349/tcp
```

Signalling (`LIVEKIT_HTTP_PORT`, default 7880) is published on 127.0.0.1 only; the proxy reaches it there.

If another service on the machine already uses one of these ports, pick other numbers in `.env`. The container uses the same number inside, because LiveKit tells the apps which ports to connect to.

## 2. Keys and settings

```sh
docker run --rm livekit/livekit-server generate-keys
```

Put the result into `.env`:

```sh
LIVEKIT_URL=wss://rtc.example.com
LIVEKIT_API_KEY=API...
LIVEKIT_API_SECRET=...
LIVEKIT_TURN_ENABLED=true
LIVEKIT_TURN_DOMAIN=turn.example.com
```

The game server checks at start that all three `LIVEKIT_URL`, `LIVEKIT_API_KEY` and `LIVEKIT_API_SECRET` are set, or none of them.

## 3. Reverse proxy for signalling

The apps open a WebSocket to `LIVEKIT_URL`, so the proxy must pass the upgrade through.

Caddy (WebSockets work without extra lines):

```
poker.example.com {
    reverse_proxy 127.0.0.1:8080
}

rtc.example.com {
    reverse_proxy 127.0.0.1:7880
}
```

nginx:

```nginx
server {
    listen 443 ssl;
    http2 on;
    server_name rtc.example.com;

    ssl_certificate     /etc/letsencrypt/live/rtc.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/rtc.example.com/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:7880;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_read_timeout 1h;
        proxy_send_timeout 1h;
    }
}
```

The game server itself also needs the WebSocket lines in nginx (the table runs over `/api/v1/ws`); the same `location` block with `proxy_pass http://127.0.0.1:8080` works for it.

Check signalling: `curl https://rtc.example.com` answers `OK`.

## 4. Certificate for TURN over TLS

LiveKit serves TURN over TLS itself, so it needs the certificate and key for `LIVEKIT_TURN_DOMAIN` as files it can read. By default it looks in `./certs` next to `compose.yaml` for `fullchain.pem` and `privkey.pem` (`LIVEKIT_TURN_CERT_DIR`, `LIVEKIT_TURN_CERT_FILE`, `LIVEKIT_TURN_KEY_FILE`).

With certbot, get the certificate once and let a deploy hook copy it on every renewal:

```sh
certbot certonly --nginx -d turn.example.com \
  --deploy-hook 'install -m 644 "$RENEWED_LINEAGE/fullchain.pem" /srv/oxipoker/certs/fullchain.pem &&
                 install -m 640 -g 1000 "$RENEWED_LINEAGE/privkey.pem" /srv/oxipoker/certs/privkey.pem &&
                 cd /srv/oxipoker && docker compose --profile full restart livekit'
```

Replace `/srv/oxipoker` with your folder. The key file must be readable by the user the container runs as; with rootless Docker that is your own user.

Check TURN over TLS: `openssl s_client -connect turn.example.com:5349 -servername turn.example.com` shows your certificate.

Networks that allow nothing but HTTPS on port 443 also block 5349. If nothing else listens on port 443 of a second IP address, set `LIVEKIT_TURN_TLS_PORT=443` there and those players get through too.

## 5. Start

```sh
docker compose --profile full up -d
```

`GET /api/v1/health` on the game server then reports `"media": true`, and the apps show the call bar at every table.

## What the server enforces

- Only seated players and spectators who watch the table get a token; a token lasts 10 minutes and the apps renew it.
- The table host or an admin can switch off someone's microphone or camera and remove anyone from the call. A removed person gets no new token until the table closes.
- Closing a table deletes its call room.
- Blocking someone in the app hides their video and silences them on your device.
