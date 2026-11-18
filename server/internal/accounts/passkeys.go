package accounts

import (
	"bytes"
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"net/url"
	"strings"
	"sync"
	"time"
	"unicode/utf8"

	"github.com/go-webauthn/webauthn/protocol"
	"github.com/go-webauthn/webauthn/webauthn"
)

// Passkey errors.
var (
	ErrCeremony       = errors.New("passkey ceremony unknown or expired")
	ErrPasskeyInvalid = errors.New("passkey response rejected")
	ErrBadPasskeyName = errors.New("passkey name must be 1 to 64 characters")
	ErrTooManyPasskey = errors.New("too many passkeys")
	// ErrLastSignInMethod protects the only way into an account.
	ErrLastSignInMethod = errors.New("last sign-in method")
)

// Limits for passkeys and pending ceremonies.
const (
	CeremonyTTL    = 5 * time.Minute
	maxCeremonies  = 1000
	maxPasskeys    = 20
	maxCredJSONLen = 64 << 10
)

// Passkey is one registered WebAuthn credential, as shown to its owner.
type Passkey struct {
	ID         string     `json:"id"`
	Name       string     `json:"name"`
	CreatedAt  time.Time  `json:"created_at"`
	LastUsedAt *time.Time `json:"last_used_at,omitempty"`
	Synced     bool       `json:"synced"` // backup state: the provider syncs it between devices
}

type ceremony struct {
	data    webauthn.SessionData
	userID  string // registration: the account the passkey is for
	expires time.Time
}

// Passkeys runs WebAuthn registration and sign-in on top of the accounts
// service. The relying party id is the host of the server's public URL.
type Passkeys struct {
	acc *Service
	wa  *webauthn.WebAuthn

	mu         sync.Mutex
	ceremonies map[string]ceremony
}

// NewPasskeys configures WebAuthn for publicURL (scheme://host[:port]).
func NewPasskeys(acc *Service, publicURL string) (*Passkeys, error) {
	u, err := url.Parse(publicURL)
	if err != nil || u.Hostname() == "" || (u.Scheme != "https" && u.Scheme != "http") {
		return nil, fmt.Errorf("accounts: passkeys need PUBLIC_URL as http(s)://host, got %q", publicURL)
	}
	wa, err := webauthn.New(&webauthn.Config{
		RPID:          u.Hostname(),
		RPDisplayName: "Oxi Poker",
		RPOrigins:     []string{u.Scheme + "://" + u.Host},
	})
	if err != nil {
		return nil, fmt.Errorf("accounts: webauthn: %w", err)
	}
	return &Passkeys{acc: acc, wa: wa, ceremonies: map[string]ceremony{}}, nil
}

// waUser adapts a User plus its credentials to webauthn.User.
type waUser struct {
	u     *User
	creds []webauthn.Credential
}

func (w *waUser) WebAuthnID() []byte                         { return []byte(w.u.ID) }
func (w *waUser) WebAuthnName() string                       { return w.u.Username }
func (w *waUser) WebAuthnDisplayName() string                { return w.u.DisplayName }
func (w *waUser) WebAuthnCredentials() []webauthn.Credential { return w.creds }

func (p *Passkeys) loadUser(ctx context.Context, u *User) (*waUser, error) {
	rows, err := p.acc.db.QueryContext(ctx, `SELECT data FROM passkeys WHERE user_id = ?`, u.ID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	w := &waUser{u: u}
	for rows.Next() {
		var data string
		if err := rows.Scan(&data); err != nil {
			return nil, err
		}
		var c webauthn.Credential
		if err := json.Unmarshal([]byte(data), &c); err != nil {
			return nil, fmt.Errorf("accounts: stored passkey: %w", err)
		}
		w.creds = append(w.creds, c)
	}
	return w, rows.Err()
}

func (p *Passkeys) putCeremony(c ceremony) (string, error) {
	p.mu.Lock()
	defer p.mu.Unlock()
	now := p.acc.now()
	for id, old := range p.ceremonies {
		if now.After(old.expires) {
			delete(p.ceremonies, id)
		}
	}
	if len(p.ceremonies) >= maxCeremonies {
		return "", ErrCeremony
	}
	id := NewID()
	c.expires = now.Add(CeremonyTTL)
	p.ceremonies[id] = c
	return id, nil
}

// takeCeremony returns a pending ceremony once; a second use fails.
func (p *Passkeys) takeCeremony(id string) (ceremony, error) {
	p.mu.Lock()
	defer p.mu.Unlock()
	c, ok := p.ceremonies[id]
	delete(p.ceremonies, id)
	if !ok || p.acc.now().After(c.expires) {
		return ceremony{}, ErrCeremony
	}
	return c, nil
}

// BeginRegistration starts adding a passkey to u. It returns the ceremony id
// and the options for navigator.credentials.create.
func (p *Passkeys) BeginRegistration(ctx context.Context, u *User) (string, *protocol.CredentialCreation, error) {
	w, err := p.loadUser(ctx, u)
	if err != nil {
		return "", nil, err
	}
	if len(w.creds) >= maxPasskeys {
		return "", nil, ErrTooManyPasskey
	}
	exclude := make([]protocol.CredentialDescriptor, 0, len(w.creds))
	for _, c := range w.creds {
		exclude = append(exclude, c.Descriptor())
	}
	opts, data, err := p.wa.BeginRegistration(w,
		webauthn.WithResidentKeyRequirement(protocol.ResidentKeyRequirementRequired),
		webauthn.WithAuthenticatorSelection(protocol.AuthenticatorSelection{
			ResidentKey:      protocol.ResidentKeyRequirementRequired,
			UserVerification: protocol.VerificationRequired,
		}),
		webauthn.WithConveyancePreference(protocol.PreferNoAttestation),
		webauthn.WithExclusions(exclude))
	if err != nil {
		return "", nil, fmt.Errorf("accounts: begin registration: %w", err)
	}
	id, err := p.putCeremony(ceremony{data: *data, userID: u.ID})
	if err != nil {
		return "", nil, err
	}
	return id, opts, nil
}

// FinishRegistration verifies the authenticator's response and stores the
// passkey under name.
func (p *Passkeys) FinishRegistration(ctx context.Context, u *User, ceremonyID string, response json.RawMessage, name string) (*Passkey, error) {
	name, err := checkPasskeyName(name)
	if err != nil {
		return nil, err
	}
	c, err := p.takeCeremony(ceremonyID)
	if err != nil || c.userID != u.ID {
		return nil, ErrCeremony
	}
	if len(response) > maxCredJSONLen {
		return nil, ErrPasskeyInvalid
	}
	parsed, err := protocol.ParseCredentialCreationResponseBytes(response)
	if err != nil {
		return nil, ErrPasskeyInvalid
	}
	w, err := p.loadUser(ctx, u)
	if err != nil {
		return nil, err
	}
	cred, err := p.wa.CreateCredential(w, c.data, parsed)
	if err != nil {
		return nil, ErrPasskeyInvalid
	}
	data, err := json.Marshal(cred)
	if err != nil {
		return nil, err
	}
	now := p.acc.now()
	pk := &Passkey{ID: NewID(), Name: name, CreatedAt: now.UTC().Truncate(time.Millisecond), Synced: cred.Flags.BackupState}
	_, err = p.acc.db.ExecContext(ctx, `INSERT INTO passkeys (id, credential, user_id, name, data, created_at)
		VALUES (?, ?, ?, ?, ?, ?)`, pk.ID, cred.ID, u.ID, name, string(data), now.UnixMilli())
	if err != nil {
		if strings.Contains(err.Error(), "UNIQUE") {
			return nil, ErrPasskeyInvalid
		}
		return nil, fmt.Errorf("accounts: store passkey: %w", err)
	}
	return pk, nil
}

// BeginLogin starts a username-less sign-in (discoverable credentials).
func (p *Passkeys) BeginLogin() (string, *protocol.CredentialAssertion, error) {
	opts, data, err := p.wa.BeginDiscoverableLogin(webauthn.WithUserVerification(protocol.VerificationRequired))
	if err != nil {
		return "", nil, fmt.Errorf("accounts: begin login: %w", err)
	}
	id, err := p.putCeremony(ceremony{data: *data})
	if err != nil {
		return "", nil, err
	}
	return id, opts, nil
}

// FinishLogin verifies an assertion and returns the account it belongs to.
// Unknown credentials, disabled accounts and possible clones all fail with
// ErrPasskeyInvalid.
func (p *Passkeys) FinishLogin(ctx context.Context, ceremonyID string, response json.RawMessage) (*User, error) {
	c, err := p.takeCeremony(ceremonyID)
	if err != nil || c.userID != "" {
		return nil, ErrCeremony
	}
	if len(response) > maxCredJSONLen {
		return nil, ErrPasskeyInvalid
	}
	parsed, err := protocol.ParseCredentialRequestResponseBytes(response)
	if err != nil {
		return nil, ErrPasskeyInvalid
	}
	var found *waUser
	handler := func(rawID, userHandle []byte) (webauthn.User, error) {
		u, err := p.acc.UserByID(ctx, string(userHandle))
		if err != nil {
			return nil, err
		}
		if u.Disabled() {
			return nil, ErrNotFound
		}
		w, err := p.loadUser(ctx, u)
		if err != nil {
			return nil, err
		}
		found = w
		return w, nil
	}
	cred, err := p.wa.ValidateDiscoverableLogin(handler, c.data, parsed)
	if err != nil || found == nil {
		return nil, ErrPasskeyInvalid
	}
	if cred.Authenticator.CloneWarning {
		return nil, ErrPasskeyInvalid
	}
	data, err := json.Marshal(cred)
	if err != nil {
		return nil, err
	}
	res, err := p.acc.db.ExecContext(ctx, `UPDATE passkeys SET data = ?, last_used_at = ? WHERE credential = ? AND user_id = ?`,
		string(data), p.acc.now().UnixMilli(), cred.ID, found.u.ID)
	if err != nil {
		return nil, fmt.Errorf("accounts: update passkey: %w", err)
	}
	if n, _ := res.RowsAffected(); n != 1 {
		return nil, ErrPasskeyInvalid
	}
	return found.u, nil
}

// ListPasskeys returns a user's passkeys, oldest first.
func (p *Passkeys) ListPasskeys(ctx context.Context, userID string) ([]Passkey, error) {
	rows, err := p.acc.db.QueryContext(ctx, `SELECT id, name, data, created_at, last_used_at FROM passkeys
		WHERE user_id = ? ORDER BY created_at, id`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	list := []Passkey{}
	for rows.Next() {
		var pk Passkey
		var data string
		var created int64
		var used sql.NullInt64
		if err := rows.Scan(&pk.ID, &pk.Name, &data, &created, &used); err != nil {
			return nil, err
		}
		var c webauthn.Credential
		if json.NewDecoder(bytes.NewReader([]byte(data))).Decode(&c) == nil {
			pk.Synced = c.Flags.BackupState
		}
		pk.CreatedAt = time.UnixMilli(created).UTC()
		if used.Valid {
			t := time.UnixMilli(used.Int64).UTC()
			pk.LastUsedAt = &t
		}
		list = append(list, pk)
	}
	return list, rows.Err()
}

// RenamePasskey changes the name of one of the user's passkeys.
func (p *Passkeys) RenamePasskey(ctx context.Context, userID, id, name string) error {
	name, err := checkPasskeyName(name)
	if err != nil {
		return err
	}
	res, err := p.acc.db.ExecContext(ctx, `UPDATE passkeys SET name = ? WHERE id = ? AND user_id = ?`, name, id, userID)
	if err != nil {
		return err
	}
	if n, _ := res.RowsAffected(); n == 0 {
		return ErrNotFound
	}
	return nil
}

// RemovePasskey deletes one of u's passkeys. An account without a password
// keeps at least one passkey, or nobody could sign in to it again.
func (p *Passkeys) RemovePasskey(ctx context.Context, u *User, id string) error {
	tx, err := p.acc.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()
	var hash string
	if err := tx.QueryRowContext(ctx, `SELECT password_hash FROM users WHERE id = ?`, u.ID).Scan(&hash); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return ErrNotFound
		}
		return err
	}
	res, err := tx.ExecContext(ctx, `DELETE FROM passkeys WHERE id = ? AND user_id = ?`, id, u.ID)
	if err != nil {
		return err
	}
	if n, _ := res.RowsAffected(); n == 0 {
		return ErrNotFound
	}
	if hash == "" {
		var left int
		if err := tx.QueryRowContext(ctx, `SELECT count(*) FROM passkeys WHERE user_id = ?`, u.ID).Scan(&left); err != nil {
			return err
		}
		if left == 0 {
			return ErrLastSignInMethod
		}
	}
	return tx.Commit()
}

func checkPasskeyName(name string) (string, error) {
	name = strings.TrimSpace(name)
	if name == "" {
		name = "Passkey"
	}
	if n := utf8.RuneCountInString(name); n > 64 {
		return "", ErrBadPasskeyName
	}
	return name, nil
}
