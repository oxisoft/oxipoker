package accounts

import (
	"bytes"
	"context"
	"errors"
	"testing"
	"time"
)

func TestTOTPSecretSealedAtRest(t *testing.T) {
	s := newService(t)
	ctx := context.Background()
	u, err := s.CreateUser(ctx, NewUser{Username: "zoe", Password: "long enough pw"})
	if err != nil {
		t.Fatal(err)
	}
	if _, err := s.BeginTOTP(ctx, u); err == nil {
		t.Fatal("began without a key")
	}
	s.SetTOTPKey(bytes.Repeat([]byte{1}, 32))
	e, err := s.BeginTOTP(ctx, u)
	if err != nil {
		t.Fatal(err)
	}
	var stored []byte
	if err := s.db.QueryRowContext(ctx, `SELECT secret FROM totp WHERE user_id = ?`, u.ID).Scan(&stored); err != nil {
		t.Fatal(err)
	}
	if bytes.Contains(stored, []byte(e.Secret)) {
		t.Fatal("secret stored in clear")
	}
	if !bytes.HasPrefix(e.QRPNG, []byte("\x89PNG")) {
		t.Fatal("QR is not a PNG")
	}
	// A pending enrolment is not a second factor yet.
	if st, _ := s.TOTPStatus(ctx, u.ID); st.Enabled {
		t.Fatal("enabled before confirm")
	}
	if _, err := s.VerifySecondFactor(ctx, u.ID, TOTPCodeAt(e.Secret, time.Now())); !errors.Is(err, ErrTOTPNotEnabled) {
		t.Fatalf("verify while pending: %v", err)
	}
	// Another server key cannot open it.
	s.SetTOTPKey(bytes.Repeat([]byte{2}, 32))
	if _, err := s.ConfirmTOTP(ctx, u, TOTPCodeAt(e.Secret, time.Now())); err == nil {
		t.Fatal("opened with the wrong key")
	}
	s.SetTOTPKey(bytes.Repeat([]byte{1}, 32))
	if _, err := s.ConfirmTOTP(ctx, u, TOTPCodeAt(e.Secret, time.Now())); err != nil {
		t.Fatal(err)
	}
	// Codes older than one step are refused.
	if _, err := s.VerifySecondFactor(ctx, u.ID, TOTPCodeAt(e.Secret, time.Now().Add(-90*time.Second))); !errors.Is(err, ErrInvalidCode) {
		t.Fatalf("old code: %v", err)
	}
	if err := s.ResetTOTP(ctx, u.ID); err != nil {
		t.Fatal(err)
	}
	if st, _ := s.TOTPStatus(ctx, u.ID); st.Enabled || st.RecoveryCodes != 0 {
		t.Fatalf("after reset: %+v", st)
	}
}
