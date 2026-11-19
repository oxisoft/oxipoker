#!/usr/bin/env bash
# Signs and notarises the macOS release build. Used by .github/workflows/release.yml.
#
#   release-sign.sh app <path/to/Oxi Poker.app>   sign the app (hardened runtime)
#   release-sign.sh dmg <path/to/oxipoker.dmg>    sign the dmg, notarise it, staple the ticket
#
# Needs these environment variables (repository secrets):
#   MACOS_CERT_P12_B64   Developer ID Application certificate with its private key, PKCS#12, base64
#   MACOS_CERT_PASSWORD  password of that PKCS#12 file
#   APPLE_API_KEY_B64    App Store Connect API key (AuthKey_XXXX.p8), base64
#   APPLE_API_KEY_ID     its key id
#   APPLE_API_ISSUER     its issuer id
# Without MACOS_CERT_P12_B64 it prints a warning and exits 0: the build stays unsigned.
set -euo pipefail

mode="${1:?usage: release-sign.sh app|dmg <path>}"
target="${2:?usage: release-sign.sh app|dmg <path>}"
here="$(cd "$(dirname "$0")" && pwd)"
tmp="${RUNNER_TEMP:-${TMPDIR:-/tmp}}"
keychain="$tmp/oxipoker-signing.keychain-db"

if [[ -z "${MACOS_CERT_P12_B64:-}" ]]; then
  echo "::warning::MACOS_CERT_P12_B64 is not set: the macOS build is NOT signed or notarised."
  exit 0
fi

# Imports the certificate into a temporary keychain once per job and prints the identity hash.
identity() {
  if [[ ! -f "$keychain" ]]; then
    local kcpass
    kcpass="$(openssl rand -hex 24)"
    echo "$MACOS_CERT_P12_B64" | base64 --decode > "$tmp/cert.p12"
    security create-keychain -p "$kcpass" "$keychain"
    security set-keychain-settings -lut 3600 "$keychain"
    security unlock-keychain -p "$kcpass" "$keychain"
    security import "$tmp/cert.p12" -k "$keychain" -P "${MACOS_CERT_PASSWORD:-}" -T /usr/bin/codesign
    security set-key-partition-list -S apple-tool:,apple: -s -k "$kcpass" "$keychain" > /dev/null
    security list-keychains -d user -s "$keychain" $(security list-keychains -d user | tr -d '"')
    rm -f "$tmp/cert.p12"
  fi
  security find-identity -v -p codesigning "$keychain" | awk '/Developer ID Application/ { print $2; exit }'
}

case "$mode" in
  app)
    id="$(identity)"
    [[ -n "$id" ]] || { echo "no Developer ID Application identity in MACOS_CERT_P12_B64"; exit 1; }
    sign=(codesign --force --timestamp --options runtime --sign "$id" --keychain "$keychain")
    # Inside out: nested frameworks and libraries first, then the app with its entitlements.
    find "$target/Contents/Frameworks" -depth \( -name '*.framework' -o -name '*.dylib' \) -print0 2>/dev/null |
      while IFS= read -r -d '' item; do "${sign[@]}" "$item"; done
    "${sign[@]}" --entitlements "$here/Runner/Release.entitlements" "$target"
    codesign --verify --deep --strict --verbose=2 "$target"
    ;;
  dmg)
    id="$(identity)"
    [[ -n "$id" ]] || { echo "no Developer ID Application identity in MACOS_CERT_P12_B64"; exit 1; }
    codesign --force --timestamp --sign "$id" --keychain "$keychain" "$target"
    if [[ -z "${APPLE_API_KEY_B64:-}" ]]; then
      echo "::warning::APPLE_API_KEY_B64 is not set: the dmg is signed but NOT notarised."
      exit 0
    fi
    echo "$APPLE_API_KEY_B64" | base64 --decode > "$tmp/AuthKey.p8"
    trap 'rm -f "$tmp/AuthKey.p8"' EXIT
    xcrun notarytool submit "$target" --wait --timeout 30m \
      --key "$tmp/AuthKey.p8" --key-id "${APPLE_API_KEY_ID:?}" --issuer "${APPLE_API_ISSUER:?}"
    xcrun stapler staple "$target"
    xcrun stapler validate "$target"
    spctl -a -t open --context context:primary-signature -vv "$target"
    ;;
  *)
    echo "unknown mode: $mode"; exit 2 ;;
esac
