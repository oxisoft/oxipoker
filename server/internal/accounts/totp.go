package accounts

import (
	"bytes"
	"context"
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"crypto/sha256"
	"crypto/subtle"
	"database/sql"
	"errors"
	"fmt"
	"image/png"
	"strings"
	"time"

	"github.com/pquerna/otp"
	"github.com/pquerna/otp/hotp"
	"github.com/pquerna/otp/totp"
)

// TOTP errors.
var (
	ErrTOTPEnabled    = errors.New("two-factor sign-in is already on")
	ErrTOTPNotEnabled = errors.New("two-factor sign-in is off")
	ErrInvalidCode    = errors.New("invalid code")
)

// TOTP parameters: RFC 6238 defaults that every authenticator app supports.
const (
	totpPeriod        = 30
	totpSkew          = 1 // accept one step before and after
	RecoveryCodeCount = 10
)

// TOTPEnrollment is what the user scans: the otpauth URL as text and as a QR PNG.
type TOTPEnrollment struct {
	Secret string `json:"secret"`
	URL    string `json:"otpauth_url"`
	QRPNG  []byte `json:"qr_png"` // base64 in JSON
}

// TOTPStatus describes a user's second factor.
type TOTPStatus struct {
	Enabled       bool `json:"enabled"`
	RecoveryCodes int  `json:"recovery_codes_left"`
}

// SetTOTPKey sets the 32-byte key that seals TOTP secrets at rest.
func (s *Service) SetTOTPKey(key []byte) { s.totpKey = key }

func (s *Service) seal(plain []byte) ([]byte, error) {
	gcm, err := s.gcm()
	if err != nil {
		return nil, err
	}
	nonce := make([]byte, gcm.NonceSize())
	if _, err := rand.Read(nonce); err != nil {
		return nil, err
	}
	return gcm.Seal(nonce, nonce, plain, []byte("oxipoker totp v1")), nil
}

func (s *Service) open(sealed []byte) ([]byte, error) {
	gcm, err := s.gcm()
	if err != nil {
		return nil, err
	}
	if len(sealed) < gcm.NonceSize() {
		return nil, errors.New("accounts: sealed totp secret too short")
	}
	n := gcm.NonceSize()
	return gcm.Open(nil, sealed[:n], sealed[n:], []byte("oxipoker totp v1"))
}

func (s *Service) gcm() (cipher.AEAD, error) {
	if len(s.totpKey) != 32 {
		return nil, errors.New("accounts: TOTP key not set")
	}
	b, err := aes.NewCipher(s.totpKey)
	if err != nil {
		return nil, err
	}
	return cipher.NewGCM(b)
}

// BeginTOTP starts enrolment: a new secret that becomes active once
// ConfirmTOTP sees a valid code. A pending enrolment is replaced.
func (s *Service) BeginTOTP(ctx context.Context, u *User) (*TOTPEnrollment, error) {
	st, err := s.TOTPStatus(ctx, u.ID)
	if err != nil {
		return nil, err
	}
	if st.Enabled {
		return nil, ErrTOTPEnabled
	}
	key, err := totp.Generate(totp.GenerateOpts{Issuer: "Oxi Poker", AccountName: u.Username, Period: totpPeriod,
		Digits: otp.DigitsSix, Algorithm: otp.AlgorithmSHA1})
	if err != nil {
		return nil, err
	}
	sealed, err := s.seal([]byte(key.Secret()))
	if err != nil {
		return nil, err
	}
	img, err := key.Image(256, 256)
	if err != nil {
		return nil, err
	}
	var buf bytes.Buffer
	if err := png.Encode(&buf, img); err != nil {
		return nil, err
	}
	_, err = s.db.ExecContext(ctx, `INSERT INTO totp (user_id, secret, created_at) VALUES (?, ?, ?)
		ON CONFLICT (user_id) DO UPDATE SET secret = excluded.secret, created_at = excluded.created_at, last_step = 0`,
		u.ID, sealed, s.now().UnixMilli())
	if err != nil {
		return nil, fmt.Errorf("accounts: begin totp: %w", err)
	}
	return &TOTPEnrollment{Secret: key.Secret(), URL: key.URL(), QRPNG: buf.Bytes()}, nil
}

// matchStep returns the time step code belongs to, or 0.
func (s *Service) matchStep(secret, code string, after int64) int64 {
	code = strings.TrimSpace(code)
	if len(code) != 6 {
		return 0
	}
	now := s.now().Unix() / totpPeriod
	for d := int64(-totpSkew); d <= totpSkew; d++ {
		step := now + d
		if step <= after {
			continue
		}
		want, err := hotp.GenerateCodeCustom(secret, uint64(step), hotp.ValidateOpts{Digits: otp.DigitsSix, Algorithm: otp.AlgorithmSHA1})
		if err == nil && subtle.ConstantTimeCompare([]byte(want), []byte(code)) == 1 {
			return step
		}
	}
	return 0
}

// ConfirmTOTP turns two-factor sign-in on and returns fresh recovery codes
// (shown once).
func (s *Service) ConfirmTOTP(ctx context.Context, u *User, code string) ([]string, error) {
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback()
	var sealed []byte
	var confirmed sql.NullInt64
	err = tx.QueryRowContext(ctx, `SELECT secret, confirmed_at FROM totp WHERE user_id = ?`, u.ID).Scan(&sealed, &confirmed)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, ErrTOTPNotEnabled
	}
	if err != nil {
		return nil, err
	}
	if confirmed.Valid {
		return nil, ErrTOTPEnabled
	}
	secret, err := s.open(sealed)
	if err != nil {
		return nil, err
	}
	step := s.matchStep(string(secret), code, 0)
	if step == 0 {
		return nil, ErrInvalidCode
	}
	if _, err := tx.ExecContext(ctx, `UPDATE totp SET confirmed_at = ?, last_step = ? WHERE user_id = ?`,
		s.now().UnixMilli(), step, u.ID); err != nil {
		return nil, err
	}
	codes, err := newRecoveryCodes(ctx, tx, u.ID)
	if err != nil {
		return nil, err
	}
	return codes, tx.Commit()
}

func newRecoveryCodes(ctx context.Context, tx *sql.Tx, userID string) ([]string, error) {
	if _, err := tx.ExecContext(ctx, `DELETE FROM recovery_codes WHERE user_id = ?`, userID); err != nil {
		return nil, err
	}
	codes := make([]string, RecoveryCodeCount)
	for i := range codes {
		t := strings.ToLower(rand.Text()) // 26 base32 characters, 130 bits
		codes[i] = t[:5] + "-" + t[5:10] + "-" + t[10:15]
		h := sha256.Sum256([]byte(codes[i]))
		if _, err := tx.ExecContext(ctx, `INSERT INTO recovery_codes (user_id, code_hash) VALUES (?, ?)`, userID, h[:]); err != nil {
			return nil, err
		}
	}
	return codes, nil
}

// TOTPStatus reports whether a user has a confirmed second factor.
func (s *Service) TOTPStatus(ctx context.Context, userID string) (TOTPStatus, error) {
	var st TOTPStatus
	err := s.db.QueryRowContext(ctx, `SELECT confirmed_at IS NOT NULL,
		(SELECT count(*) FROM recovery_codes WHERE user_id = ? AND used_at IS NULL)
		FROM totp WHERE user_id = ?`, userID, userID).Scan(&st.Enabled, &st.RecoveryCodes)
	if errors.Is(err, sql.ErrNoRows) {
		return TOTPStatus{}, nil
	}
	if !st.Enabled {
		st.RecoveryCodes = 0
	}
	return st, err
}

// VerifySecondFactor accepts a current TOTP code (each step once) or an
// unused recovery code (then spent). It reports which one matched.
func (s *Service) VerifySecondFactor(ctx context.Context, userID, code string) (method string, err error) {
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return "", err
	}
	defer tx.Rollback()
	var sealed []byte
	var last int64
	err = tx.QueryRowContext(ctx, `SELECT secret, last_step FROM totp WHERE user_id = ? AND confirmed_at IS NOT NULL`,
		userID).Scan(&sealed, &last)
	if errors.Is(err, sql.ErrNoRows) {
		return "", ErrTOTPNotEnabled
	}
	if err != nil {
		return "", err
	}
	code = strings.ToLower(strings.TrimSpace(code))
	if len(code) == 6 {
		secret, err := s.open(sealed)
		if err != nil {
			return "", err
		}
		step := s.matchStep(string(secret), code, last)
		if step == 0 {
			return "", ErrInvalidCode
		}
		if _, err := tx.ExecContext(ctx, `UPDATE totp SET last_step = ? WHERE user_id = ?`, step, userID); err != nil {
			return "", err
		}
		return "totp", tx.Commit()
	}
	h := sha256.Sum256([]byte(code))
	res, err := tx.ExecContext(ctx, `UPDATE recovery_codes SET used_at = ? WHERE user_id = ? AND code_hash = ? AND used_at IS NULL`,
		s.now().UnixMilli(), userID, h[:])
	if err != nil {
		return "", err
	}
	if n, _ := res.RowsAffected(); n != 1 {
		return "", ErrInvalidCode
	}
	return "recovery_code", tx.Commit()
}

// DisableTOTP turns two-factor sign-in off after checking a code.
func (s *Service) DisableTOTP(ctx context.Context, u *User, code string) error {
	if _, err := s.VerifySecondFactor(ctx, u.ID, code); err != nil {
		return err
	}
	return s.ResetTOTP(ctx, u.ID)
}

// ResetTOTP removes a user's second factor without a code (admin reset).
func (s *Service) ResetTOTP(ctx context.Context, userID string) error {
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()
	if _, err := tx.ExecContext(ctx, `DELETE FROM totp WHERE user_id = ?`, userID); err != nil {
		return err
	}
	if _, err := tx.ExecContext(ctx, `DELETE FROM recovery_codes WHERE user_id = ?`, userID); err != nil {
		return err
	}
	return tx.Commit()
}

// TOTPCodeAt returns the code for secret at t (tests and tools).
func TOTPCodeAt(secret string, t time.Time) string {
	c, _ := totp.GenerateCodeCustom(secret, t, totp.ValidateOpts{Period: totpPeriod, Digits: otp.DigitsSix, Algorithm: otp.AlgorithmSHA1})
	return c
}
