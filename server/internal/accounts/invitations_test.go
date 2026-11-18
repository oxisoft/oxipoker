package accounts

import (
	"context"
	"errors"
	"testing"
	"time"
)

func TestInvitationLifecycle(t *testing.T) {
	s := newService(t)
	ctx := context.Background()
	clock := time.Unix(1_800_000_000, 0)
	s.now = func() time.Time { return clock }
	admin, err := s.CreateUser(ctx, NewUser{Username: "alex", Password: "long enough pw", IsAdmin: true})
	if err != nil {
		t.Fatal(err)
	}

	for _, bad := range []NewInvitation{{TTL: time.Minute}, {TTL: 31 * 24 * time.Hour}, {MaxUses: 101}, {MaxUses: -1},
		{Note: string(make([]byte, 201))}} {
		if _, _, err := s.CreateInvitation(ctx, admin, bad); !errors.Is(err, ErrInviteParams) {
			t.Errorf("%+v: %v", bad, err)
		}
	}

	token, inv, err := s.CreateInvitation(ctx, admin, NewInvitation{MaxUses: 2, Note: " poker night "})
	if err != nil || len(token) != 43 || inv.Note != "poker night" || !inv.ExpiresAt.Equal(clock.Add(InviteDefaultTTL).UTC()) {
		t.Fatalf("create: %q %+v %v", token, inv, err)
	}
	if _, err := s.CheckInvitation(ctx, token); err != nil {
		t.Fatalf("check: %v", err)
	}
	if _, err := s.CheckInvitation(ctx, "nope"); !errors.Is(err, ErrInviteInvalid) {
		t.Fatalf("unknown: %v", err)
	}

	sam, err := s.SignUpWithPassword(ctx, token, "sam", "Sam", "sams password")
	if err != nil || sam.IsAdmin || sam.DisplayName != "Sam" {
		t.Fatalf("sign-up 1: %+v %v", sam, err)
	}
	if _, err := s.SignUpWithPassword(ctx, token, "SAM", "", "sams password"); !errors.Is(err, ErrUsernameTaken) {
		t.Fatalf("taken: %v", err)
	}
	// A failed sign-up does not use the link up.
	if _, err := s.SignUpWithPassword(ctx, token, "kim", "", "kims password"); err != nil {
		t.Fatalf("sign-up 2: %v", err)
	}
	if _, err := s.SignUpWithPassword(ctx, token, "lee", "", "lees password"); !errors.Is(err, ErrInviteUsedUp) {
		t.Fatalf("third use: %v", err)
	}
	if _, err := s.Authenticate(ctx, "sam", "sams password"); err != nil {
		t.Fatalf("sam signs in: %v", err)
	}

	list, err := s.ListInvitations(ctx)
	if err != nil || len(list) != 1 || list[0].Uses != 2 || len(list[0].Joined) != 2 || list[0].Joined[0].Username != "sam" || list[0].CreatedBy != "alex" {
		t.Fatalf("list: %+v %v", list, err)
	}

	// Expiry and revocation.
	short, _, _ := s.CreateInvitation(ctx, admin, NewInvitation{TTL: time.Hour})
	clock = clock.Add(time.Hour)
	if _, err := s.SignUpWithPassword(ctx, short, "lee", "", "lees password"); !errors.Is(err, ErrInviteExpired) {
		t.Fatalf("expired: %v", err)
	}
	revoked, rinv, _ := s.CreateInvitation(ctx, admin, NewInvitation{})
	if err := s.RevokeInvitation(ctx, rinv.ID); err != nil {
		t.Fatal(err)
	}
	if _, err := s.CheckInvitation(ctx, revoked); !errors.Is(err, ErrInviteInvalid) {
		t.Fatalf("revoked: %v", err)
	}
	if err := s.RevokeInvitation(ctx, "nope"); !errors.Is(err, ErrNotFound) {
		t.Fatalf("revoke unknown: %v", err)
	}
	if _, err := s.UserByUsername(ctx, "lee"); err == nil {
		t.Fatal("lee exists")
	}
}
