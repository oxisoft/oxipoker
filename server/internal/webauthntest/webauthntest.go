// Package webauthntest is a software passkey authenticator for tests: it
// answers registration and sign-in options the way a browser plus platform
// authenticator would (ES256, "none" attestation, user verified).
package webauthntest

import (
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/binary"
	"encoding/json"
	"fmt"

	"github.com/fxamacker/cbor/v2"
)

var b64 = base64.RawURLEncoding

// Authenticator holds passkeys for one relying party.
type Authenticator struct {
	Origin string // e.g. https://poker.example
	RPID   string // e.g. poker.example
	// Synced sets the backup-eligible and backed-up flags, like a synced passkey.
	Synced bool

	keys map[string]*key // by credential id (base64url)
	last string          // the newest passkey, used by Get
}

type key struct {
	priv       *ecdsa.PrivateKey
	userHandle []byte
	counter    uint32
}

// New returns an empty authenticator.
func New(origin, rpID string) *Authenticator {
	return &Authenticator{Origin: origin, RPID: rpID, keys: map[string]*key{}}
}

// options is the part of PublicKeyCredential{Creation,Request}Options we need.
type options struct {
	PublicKey struct {
		Challenge string `json:"challenge"`
		RP        struct {
			ID string `json:"id"`
		} `json:"rp"`
		RPID string `json:"rpId"`
		User struct {
			ID string `json:"id"`
		} `json:"user"`
	} `json:"publicKey"`
}

func (a *Authenticator) clientData(typ, challenge, origin string) []byte {
	cd, _ := json.Marshal(map[string]any{"type": typ, "challenge": challenge, "origin": origin, "crossOrigin": false})
	return cd
}

func (a *Authenticator) flags(at bool) byte {
	f := byte(0x01 | 0x04) // user present, user verified
	if a.Synced {
		f |= 0x08 | 0x10
	}
	if at {
		f |= 0x40
	}
	return f
}

// Create answers navigator.credentials.create options (the JSON the server
// sent) and returns the credential JSON to post back. Origin overrides
// a.Origin when not empty.
func (a *Authenticator) Create(optionsJSON []byte, origin string) ([]byte, error) {
	var o options
	if err := json.Unmarshal(optionsJSON, &o); err != nil {
		return nil, err
	}
	if origin == "" {
		origin = a.Origin
	}
	userHandle, err := b64.DecodeString(o.PublicKey.User.ID)
	if err != nil {
		return nil, fmt.Errorf("user id: %w", err)
	}
	priv, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	if err != nil {
		return nil, err
	}
	credID := make([]byte, 16)
	_, _ = rand.Read(credID)
	ecdh, _ := priv.PublicKey.ECDH()
	raw := ecdh.Bytes() // 0x04 | X | Y
	cose, err := cbor.Marshal(map[int]any{1: 2, 3: -7, -1: 1, -2: raw[1:33], -3: raw[33:65]})
	if err != nil {
		return nil, err
	}
	rpHash := sha256.Sum256([]byte(a.RPID))
	auth := append([]byte{}, rpHash[:]...)
	auth = append(auth, a.flags(true))
	auth = binary.BigEndian.AppendUint32(auth, 0)
	auth = append(auth, make([]byte, 16)...) // AAGUID
	auth = binary.BigEndian.AppendUint16(auth, uint16(len(credID)))
	auth = append(auth, credID...)
	auth = append(auth, cose...)
	att, err := cbor.Marshal(map[string]any{"fmt": "none", "attStmt": map[string]any{}, "authData": auth})
	if err != nil {
		return nil, err
	}
	a.last = b64.EncodeToString(credID)
	a.keys[a.last] = &key{priv: priv, userHandle: userHandle}
	return json.Marshal(map[string]any{
		"id": b64.EncodeToString(credID), "rawId": b64.EncodeToString(credID), "type": "public-key",
		"response": map[string]any{
			"clientDataJSON":    b64.EncodeToString(a.clientData("webauthn.create", o.PublicKey.Challenge, origin)),
			"attestationObject": b64.EncodeToString(att),
			"transports":        []string{"internal"},
		},
	})
}

// Get answers navigator.credentials.get options with the newest
// stored passkey and returns the assertion JSON. Counter is added to the
// stored sign counter before signing (0 = a synced passkey that never counts).
func (a *Authenticator) Get(optionsJSON []byte, counterStep uint32) ([]byte, error) {
	var o options
	if err := json.Unmarshal(optionsJSON, &o); err != nil {
		return nil, err
	}
	k, ok := a.keys[a.last]
	if !ok {
		return nil, fmt.Errorf("no passkey")
	}
	return a.sign(o.PublicKey.Challenge, a.last, k, counterStep)
}

func (a *Authenticator) sign(challenge, id string, k *key, counterStep uint32) ([]byte, error) {
	k.counter += counterStep
	rpHash := sha256.Sum256([]byte(a.RPID))
	auth := append([]byte{}, rpHash[:]...)
	auth = append(auth, a.flags(false))
	auth = binary.BigEndian.AppendUint32(auth, k.counter)
	cd := a.clientData("webauthn.get", challenge, a.Origin)
	cdHash := sha256.Sum256(cd)
	digest := sha256.Sum256(append(append([]byte{}, auth...), cdHash[:]...))
	sig, err := ecdsa.SignASN1(rand.Reader, k.priv, digest[:])
	if err != nil {
		return nil, err
	}
	return json.Marshal(map[string]any{
		"id": id, "rawId": id, "type": "public-key",
		"response": map[string]any{
			"clientDataJSON":    b64.EncodeToString(cd),
			"authenticatorData": b64.EncodeToString(auth),
			"signature":         b64.EncodeToString(sig),
			"userHandle":        b64.EncodeToString(k.userHandle),
		},
	})
}

// SetCounter forces the stored sign counter of every passkey (clone tests).
func (a *Authenticator) SetCounter(n uint32) {
	for _, k := range a.keys {
		k.counter = n
	}
}
