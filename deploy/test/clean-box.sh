#!/usr/bin/env bash
# Clean-box test: follows docs/INSTALL.md step by step on a fresh Linux box
# with Docker (CI runs it on a new GitHub runner VM). Every step here must be
# a step of the guide; when this script needs something the guide does not
# say, the guide gets the missing step.
#
#   deploy/test/clean-box.sh <repo checkout> <work dir>
#
# Environment: OXIPOKER_IMAGE / OXIPOKER_VERSION pick the image under test
# (default ghcr.io/oxisoft/oxipoker:edge, since Docker Hub has releases only).
set -euo pipefail

SRC=$(cd "${1:?repo checkout}" && pwd)
WORK=${2:?work dir}
IMAGE=${OXIPOKER_IMAGE:-ghcr.io/oxisoft/oxipoker}
VERSION=${OXIPOKER_VERSION:-edge}
HOST=localhost                       # stands in for poker.example.com
PASS='clean-box-admin-pass'

step() { printf '\n==== %s\n' "$*"; }
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
setenv() { # setenv KEY VALUE: edit .env like a person with an editor would
  if grep -q "^$1=" .env; then sed -i "s|^$1=.*|$1=$2|" .env; else echo "$1=$2" >>.env; fi
}
wait_healthy() {
  for _ in $(seq 1 60); do
    if docker compose ps oxipoker | grep -q '(healthy)'; then return 0; fi
    sleep 2
  done
  docker compose ps; docker compose logs oxipoker | tail -50
  fail "oxipoker not healthy after 120 s"
}
api() { # api METHOD PATH [JSON]: native app style, bearer token
  local m=$1 p=$2 d=${3:-}
  curl -fsS -k -X "$m" "https://$HOST/api/v1$p" \
    -H 'Content-Type: application/json' ${TOKEN:+-H "Authorization: Bearer $TOKEN"} \
    ${d:+--data "$d"}
}
json() { python3 -c "import json,sys; d=json.load(sys.stdin); print($1)"; }

step "Guide: What you need"
docker compose version || fail "Compose plugin missing"

step "Guide: Minimal option"
rm -rf "$WORK"; mkdir -p "$WORK"; cd "$WORK"
mkdir oxipoker && cd oxipoker
# The guide downloads both files from main; the test takes them from the
# checkout under test so a pull request tests its own files.
cp "$SRC/deploy/compose.yaml" compose.yaml
cp "$SRC/deploy/.env.example" .env
setenv PUBLIC_URL "https://$HOST"
setenv ADMIN_USERNAME admin
setenv ADMIN_PASSWORD "$PASS"
setenv OXIPOKER_VERSION "$VERSION"
setenv OXIPOKER_IMAGE "$IMAGE"
mkdir -m 700 data && sudo chown 1000:1000 data
docker compose up -d

step "Guide: Check that it runs"
wait_healthy
H=$(curl -s http://127.0.0.1:8080/api/v1/health); echo "$H"
echo "$H" | json "d['status']=='ok' and d['webapp'] and not d['media'] and d['database']=='ok' or sys.exit('bad health')"

step "Guide: HTTPS (Caddy)"
# Caddy as the guide's two-line Caddyfile; 'localhost' makes Caddy use its
# own local CA instead of Let's Encrypt, the only difference to a real box.
mkdir -p "$WORK/caddy"
printf '%s {\n    reverse_proxy 127.0.0.1:8080\n}\n' "$HOST" >"$WORK/caddy/Caddyfile"
docker run -d --name cb-caddy --network host -v "$WORK/caddy/Caddyfile:/etc/caddy/Caddyfile:ro" caddy:2 >/dev/null
for _ in $(seq 1 30); do curl -fsk "https://$HOST/api/v1/health" >/dev/null 2>&1 && break; sleep 1; done
curl -fsk "https://$HOST/" | grep -q flutter_bootstrap.js || fail "web app not served through Caddy"
echo "web app served over HTTPS"

step "Guide: First admin"
TOKEN=$(api POST /auth/signin "{\"username\":\"admin\",\"password\":\"$PASS\",\"client\":\"app\"}" | json "d['token']")
[ -n "$TOKEN" ] || fail "admin sign-in"
api GET /me | json "d.get('user',d)['is_admin'] or sys.exit('not admin')"
echo "admin signed in"

step "Guide: Invitations"
INV=$(api POST /admin/invitations '{"expires_in_hours":72,"max_uses":1,"note":"clean box"}')
ITOK=$(echo "$INV" | json "d['token']")
echo "$INV" | json "d['url'].startswith('https://$HOST/') or sys.exit('url not on PUBLIC_URL')"
P=$(TOKEN='' api POST /auth/signup "{\"token\":\"$ITOK\",\"username\":\"friend\",\"password\":\"friend-password-1\",\"client\":\"app\"}")
echo "$P" | json "d['user']['username']=='friend' or sys.exit('signup')"
echo "friend signed up through the invitation"

step "Guide: WebSocket through the proxy"
code=$(curl -sk -o /dev/null -w '%{http_code}' --http1.1 -m 5 "https://$HOST/api/v1/ws" \
  -H 'Connection: Upgrade' -H 'Upgrade: websocket' -H 'Sec-WebSocket-Version: 13' \
  -H 'Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==' -H "Authorization: Bearer $TOKEN" || true)
[ "$code" = 101 ] || fail "WebSocket upgrade through Caddy answered $code"
echo "WebSocket upgrade 101"

step "Guide: Backup"
docker compose exec oxipoker /app/oxipoker -backup "/app/data/backups/oxipoker-$(date +%F).db"
sudo test -s "data/backups/oxipoker-$(date +%F).db" || fail "backup file missing"
if docker compose exec oxipoker /app/oxipoker -backup "/app/data/backups/oxipoker-$(date +%F).db" 2>/dev/null; then
  fail "second backup on the same day overwrote the first"
fi
echo "backup written, second one refused"

step "Guide: Upgrade"
docker compose exec oxipoker /app/oxipoker -backup /app/data/backups/before-upgrade.db
docker compose pull
docker compose up -d
wait_healthy

step "Guide: Restore"
api POST /admin/invitations '{"note":"after backup"}' >/dev/null   # a change the restore must undo
docker compose down
sudo mv data/oxipoker.db data/oxipoker.db.broken
sudo rm -f data/oxipoker.db-wal data/oxipoker.db-shm
sudo cp "data/backups/oxipoker-$(date +%F).db" data/oxipoker.db
sudo chown 1000:1000 data/oxipoker.db
docker compose up -d
wait_healthy
TOKEN=$(api POST /auth/signin "{\"username\":\"friend\",\"password\":\"friend-password-1\",\"client\":\"app\"}" | json "d['token']")
TOKEN=$(api POST /auth/signin "{\"username\":\"admin\",\"password\":\"$PASS\",\"client\":\"app\"}" | json "d['token']")
n=$(api GET /admin/invitations | json "len(d['invitations'])")
[ "$n" = 1 ] || fail "restore: expected 1 invitation from the backup, got $n"
echo "restored: friend signs in, later change gone"

step "Guide: Logs"
docker compose logs oxipoker | tail -3

step "Guide: Full option (VOICE-VIDEO.md keys)"
KEYS=$(docker run --rm "livekit/livekit-server:$(grep ^LIVEKIT_VERSION= .env | cut -d= -f2)" generate-keys)
echo "$KEYS" | sed 's/Secret:.*/Secret: (hidden)/'
setenv LIVEKIT_API_KEY "$(echo "$KEYS" | awk '/API Key/ {print $NF}')"
setenv LIVEKIT_API_SECRET "$(echo "$KEYS" | awk '/API Secret/ {print $NF}')"
# On a real box this is wss://rtc.example.com through the proxy; the runner
# has no second DNS name, so the server reaches LiveKit on the Compose network.
setenv LIVEKIT_URL "ws://livekit:7880"
docker compose --profile full up -d
wait_healthy
H=$(curl -s http://127.0.0.1:8080/api/v1/health); echo "$H"
echo "$H" | json "d['media'] or sys.exit('media false')"
MC=$(api GET /admin/media-check); echo "$MC"
echo "$MC" | json "all(c['status']=='ok' for c in d['checks'] if c['name'] in ('signalling','token')) or sys.exit('media check')"

step "Guide: back to minimal"
docker compose --profile full down
setenv LIVEKIT_URL ""
docker compose up -d
wait_healthy
curl -s http://127.0.0.1:8080/api/v1/health | json "not d['media'] or sys.exit('media still on')"

step "Clean-box test passed"
docker rm -f cb-caddy >/dev/null
docker compose down
