// Package media issues LiveKit access tokens for table calls. Oxi Poker
// carries no audio or video itself: LiveKit does, and this package only
// says who may join which call, in short-lived signed tokens.
package media

import (
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"errors"
	"net/url"
	"strings"
	"time"
)

// TokenTTL is how long a call token stays valid; the app refreshes it.
const TokenTTL = 10 * time.Minute

// Config holds the LiveKit settings. Media is on when all three are set.
type Config struct {
	URL    string // LiveKit signalling address the apps connect to (wss://...)
	Key    string // API key
	Secret string // API secret
	// TURN over TLS, for the admin console's connection check only (LiveKit
	// itself reads its TURN settings). Empty domain or port 0 = TURN off.
	TURNDomain  string
	TURNTLSPort int
}

// ErrConfig reports incomplete or invalid LiveKit settings.
var ErrConfig = errors.New("media: LIVEKIT_URL, LIVEKIT_API_KEY and LIVEKIT_API_SECRET must be set together, URL as ws(s):// or http(s)://")

// Check validates c. An empty URL = media off (nil error, Enabled false):
// LIVEKIT_URL is the switch, so going back to the minimal option only needs
// it emptied, while the key pair may stay in .env for the next time.
func (c Config) Check() error {
	if c.URL == "" {
		return nil
	}
	if c.Key == "" || c.Secret == "" {
		return ErrConfig
	}
	u, err := url.Parse(c.URL)
	if err != nil || u.Host == "" {
		return ErrConfig
	}
	switch u.Scheme {
	case "ws", "wss", "http", "https":
	default:
		return ErrConfig
	}
	return nil
}

// Enabled reports whether calls are available.
func (c Config) Enabled() bool {
	return c.URL != "" && c.Key != "" && c.Secret != "" && c.Check() == nil
}

// Grant is the LiveKit "video" claim.
type Grant struct {
	Room           string `json:"room,omitempty"`
	RoomJoin       bool   `json:"roomJoin,omitempty"`
	RoomAdmin      bool   `json:"roomAdmin,omitempty"`
	RoomCreate     bool   `json:"roomCreate,omitempty"`
	CanPublish     *bool  `json:"canPublish,omitempty"`
	CanSubscribe   *bool  `json:"canSubscribe,omitempty"`
	CanPublishData *bool  `json:"canPublishData,omitempty"`
}

// Claims is the JWT body LiveKit reads.
type Claims struct {
	Issuer    string `json:"iss"`
	Subject   string `json:"sub,omitempty"`
	Name      string `json:"name,omitempty"`
	NotBefore int64  `json:"nbf"`
	Expires   int64  `json:"exp"`
	ID        string `json:"jti"`
	Video     Grant  `json:"video"`
}

// Room is the LiveKit room name of a table's call.
func Room(tableID string) string { return "table-" + tableID }

// JoinToken lets identity join the call of a table with camera and
// microphone. Chat stays on the Oxi Poker WebSocket, so data messages are off.
func (c Config) JoinToken(tableID, identity, name string, now time.Time) (string, time.Time, error) {
	if !c.Enabled() {
		return "", time.Time{}, ErrConfig
	}
	yes, no := true, false
	exp := now.Add(TokenTTL)
	tok, err := c.sign(Claims{
		Issuer: c.Key, Subject: identity, Name: name,
		NotBefore: now.Add(-10 * time.Second).Unix(), Expires: exp.Unix(),
		Video: Grant{Room: Room(tableID), RoomJoin: true, CanPublish: &yes, CanSubscribe: &yes, CanPublishData: &no},
	})
	return tok, exp, err
}

// AdminToken authorizes server API calls (mute, remove, delete) on a table's room.
func (c Config) AdminToken(tableID string, now time.Time) (string, error) {
	if !c.Enabled() {
		return "", ErrConfig
	}
	return c.sign(Claims{
		Issuer: c.Key, NotBefore: now.Add(-10 * time.Second).Unix(), Expires: now.Add(time.Minute).Unix(),
		Video: Grant{Room: Room(tableID), RoomAdmin: true, RoomCreate: true},
	})
}

func (c Config) sign(cl Claims) (string, error) {
	var id [12]byte
	if _, err := rand.Read(id[:]); err != nil {
		return "", err
	}
	cl.ID = hex.EncodeToString(id[:])
	body, err := json.Marshal(cl)
	if err != nil {
		return "", err
	}
	enc := base64.RawURLEncoding
	head := enc.EncodeToString([]byte(`{"alg":"HS256","typ":"JWT"}`))
	msg := head + "." + enc.EncodeToString(body)
	mac := hmac.New(sha256.New, []byte(c.Secret))
	mac.Write([]byte(msg))
	return msg + "." + enc.EncodeToString(mac.Sum(nil)), nil
}

// Verify checks a token signed with c's secret and returns its claims
// (tests and the fake LiveKit API use it).
func (c Config) Verify(tok string, now time.Time) (Claims, error) {
	var cl Claims
	parts := strings.Split(tok, ".")
	if len(parts) != 3 {
		return cl, errors.New("media: malformed token")
	}
	mac := hmac.New(sha256.New, []byte(c.Secret))
	mac.Write([]byte(parts[0] + "." + parts[1]))
	sig, err := base64.RawURLEncoding.DecodeString(parts[2])
	if err != nil || !hmac.Equal(sig, mac.Sum(nil)) {
		return cl, errors.New("media: bad signature")
	}
	body, err := base64.RawURLEncoding.DecodeString(parts[1])
	if err != nil {
		return cl, err
	}
	if err := json.Unmarshal(body, &cl); err != nil {
		return cl, err
	}
	if cl.Issuer != c.Key {
		return cl, errors.New("media: wrong issuer")
	}
	if t := now.Unix(); t < cl.NotBefore || t >= cl.Expires {
		return cl, errors.New("media: token expired or not yet valid")
	}
	return cl, nil
}
