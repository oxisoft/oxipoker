// Package secret holds the server's root secret. It is generated on first
// start and kept in DATA_DIR, unless SERVER_SECRET provides one. Purpose keys
// (session tokens, invitation links, TOTP encryption) are derived from it with
// HKDF, so the root value itself is never used directly.
package secret

import (
	"crypto/hkdf"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

// FileName is the secret file inside DATA_DIR.
const FileName = "server.key"

// Size is the root secret length in bytes.
const Size = 32

// Source says where the secret came from.
type Source string

// Where a loaded secret came from.
const (
	FromEnv       Source = "env"
	FromFile      Source = "file"
	FromGenerated Source = "generated"
)

// Secret is the root secret.
type Secret struct {
	root []byte
}

// Load returns the root secret: from envValue when set (hex or base64, at
// least 32 bytes), else from DATA_DIR/server.key, else a new random one that
// is written there with mode 0600.
func Load(dataDir, envValue string) (*Secret, Source, error) {
	if v := strings.TrimSpace(envValue); v != "" {
		b, err := decode(v)
		if err != nil {
			return nil, "", fmt.Errorf("secret: SERVER_SECRET: %w", err)
		}
		return &Secret{root: b}, FromEnv, nil
	}
	path := filepath.Join(dataDir, FileName)
	raw, err := os.ReadFile(path)
	switch {
	case err == nil:
		b, err := decode(strings.TrimSpace(string(raw)))
		if err != nil {
			return nil, "", fmt.Errorf("secret: %s: %w", path, err)
		}
		return &Secret{root: b}, FromFile, nil
	case !errors.Is(err, os.ErrNotExist):
		return nil, "", fmt.Errorf("secret: read: %w", err)
	}

	b := make([]byte, Size)
	if _, err := rand.Read(b); err != nil {
		return nil, "", err
	}
	if err := os.MkdirAll(dataDir, 0o700); err != nil {
		return nil, "", err
	}
	// O_EXCL: two processes starting at once must not overwrite each other.
	f, err := os.OpenFile(path, os.O_WRONLY|os.O_CREATE|os.O_EXCL, 0o600)
	if errors.Is(err, os.ErrExist) {
		return Load(dataDir, "")
	}
	if err != nil {
		return nil, "", fmt.Errorf("secret: create: %w", err)
	}
	if _, err := f.WriteString(hex.EncodeToString(b) + "\n"); err != nil {
		f.Close()
		return nil, "", err
	}
	if err := f.Close(); err != nil {
		return nil, "", err
	}
	return &Secret{root: b}, FromGenerated, nil
}

func decode(v string) ([]byte, error) {
	if b, err := hex.DecodeString(v); err == nil {
		return checkLen(b)
	}
	for _, enc := range []*base64.Encoding{base64.StdEncoding, base64.RawStdEncoding, base64.URLEncoding, base64.RawURLEncoding} {
		if b, err := enc.DecodeString(v); err == nil {
			return checkLen(b)
		}
	}
	return nil, errors.New("not hex or base64")
}

func checkLen(b []byte) ([]byte, error) {
	if len(b) < Size {
		return nil, fmt.Errorf("too short: %d bytes, need at least %d", len(b), Size)
	}
	return b, nil
}

// Key derives a 32-byte key for one purpose, e.g. "session" or "totp".
func (s *Secret) Key(purpose string) []byte {
	k, err := hkdf.Key(sha256.New, s.root, nil, "oxipoker/"+purpose, 32)
	if err != nil {
		panic(err) // only fails for lengths beyond 255*32
	}
	return k
}
