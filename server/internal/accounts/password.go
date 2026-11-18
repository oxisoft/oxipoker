package accounts

import (
	"crypto/rand"
	"crypto/subtle"
	"encoding/base64"
	"errors"
	"fmt"
	"strings"
	"unicode/utf8"

	"golang.org/x/crypto/argon2"
)

// argon2id parameters (OWASP 2025 baseline: 19 MiB, 2 passes, 1 lane).
const (
	argonTime    = 2
	argonMemory  = 19 * 1024
	argonThreads = 1
	argonKeyLen  = 32
	argonSaltLen = 16
)

// Password length limits, counted in characters.
const (
	MinPasswordLen = 10
	MaxPasswordLen = 256
)

// ErrWeakPassword is returned for passwords outside the length limits.
var ErrWeakPassword = fmt.Errorf("password must be %d to %d characters", MinPasswordLen, MaxPasswordLen)

// CheckPassword enforces the password policy.
func CheckPassword(pw string) error {
	n := utf8.RuneCountInString(pw)
	if n < MinPasswordLen || n > MaxPasswordLen || strings.TrimSpace(pw) == "" {
		return ErrWeakPassword
	}
	return nil
}

// HashPassword returns an argon2id hash in PHC string format.
func HashPassword(pw string) (string, error) {
	salt := make([]byte, argonSaltLen)
	if _, err := rand.Read(salt); err != nil {
		return "", err
	}
	key := argon2.IDKey([]byte(pw), salt, argonTime, argonMemory, argonThreads, argonKeyLen)
	b64 := base64.RawStdEncoding
	return fmt.Sprintf("$argon2id$v=%d$m=%d,t=%d,p=%d$%s$%s",
		argon2.Version, argonMemory, argonTime, argonThreads, b64.EncodeToString(salt), b64.EncodeToString(key)), nil
}

// VerifyPassword reports whether pw matches a hash from HashPassword. The
// parameters come from the hash, so older hashes keep working after a change.
func VerifyPassword(hash, pw string) (bool, error) {
	parts := strings.Split(hash, "$")
	if len(parts) != 6 || parts[1] != "argon2id" {
		return false, errors.New("accounts: unknown hash format")
	}
	var v int
	if _, err := fmt.Sscanf(parts[2], "v=%d", &v); err != nil || v != argon2.Version {
		return false, errors.New("accounts: unsupported argon2 version")
	}
	var m uint32
	var t uint32
	var p uint8
	if _, err := fmt.Sscanf(parts[3], "m=%d,t=%d,p=%d", &m, &t, &p); err != nil || m == 0 || t == 0 || p == 0 || m > 1<<21 || t > 16 {
		return false, errors.New("accounts: bad argon2 parameters")
	}
	b64 := base64.RawStdEncoding
	salt, err := b64.DecodeString(parts[4])
	if err != nil {
		return false, err
	}
	want, err := b64.DecodeString(parts[5])
	if err != nil || len(want) == 0 {
		return false, errors.New("accounts: bad argon2 key")
	}
	got := argon2.IDKey([]byte(pw), salt, t, m, p, uint32(len(want)))
	return subtle.ConstantTimeCompare(got, want) == 1, nil
}

// dummyHash is verified against when the user does not exist, so an unknown
// username costs the same time as a wrong password.
var dummyHash = func() string {
	h, err := HashPassword("not a real password, only for timing")
	if err != nil {
		panic(err)
	}
	return h
}()
