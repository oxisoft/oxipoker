package media

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"
)

// Sources a host can switch off in someone's call.
const (
	SourceMicrophone = "microphone"
	SourceCamera     = "camera"
)

// Rooms moderates table calls through the LiveKit server API (Twirp,
// JSON). Every call signs its own short-lived admin token for the room.
type Rooms struct {
	cfg    Config
	base   string // http(s)://host[:port][/prefix]
	client *http.Client
}

// NewRooms returns the moderation client for c, or ErrConfig when media is off.
func NewRooms(c Config) (*Rooms, error) {
	if !c.Enabled() {
		return nil, ErrConfig
	}
	u, err := url.Parse(c.URL)
	if err != nil {
		return nil, ErrConfig
	}
	switch u.Scheme {
	case "ws":
		u.Scheme = "http"
	case "wss":
		u.Scheme = "https"
	}
	return &Rooms{cfg: c, base: strings.TrimRight(u.String(), "/"), client: &http.Client{Timeout: 10 * time.Second}}, nil
}

// twirpError is LiveKit's error body.
type twirpError struct {
	Code string `json:"code"`
	Msg  string `json:"msg"`
}

// errGone means the room or participant does not exist: nobody to moderate.
var errGone = errors.New("media: not in the call")

func (r *Rooms) call(ctx context.Context, tableID, method string, in, out any) error {
	tok, err := r.cfg.AdminToken(tableID, time.Now())
	if err != nil {
		return err
	}
	body, err := json.Marshal(in)
	if err != nil {
		return err
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, r.base+"/twirp/livekit.RoomService/"+method, bytes.NewReader(body))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+tok)
	res, err := r.client.Do(req)
	if err != nil {
		return fmt.Errorf("media: %s: %w", method, err)
	}
	defer res.Body.Close()
	data, _ := io.ReadAll(io.LimitReader(res.Body, 1<<20))
	if res.StatusCode != http.StatusOK {
		var te twirpError
		_ = json.Unmarshal(data, &te)
		if te.Code == "not_found" || res.StatusCode == http.StatusNotFound {
			return errGone
		}
		return fmt.Errorf("media: %s: %d %s %s", method, res.StatusCode, te.Code, te.Msg)
	}
	if out != nil {
		return json.Unmarshal(data, out)
	}
	return nil
}

// enum reads a protobuf enum that arrives as a name or a number.
type enum string

func (e *enum) UnmarshalJSON(b []byte) error {
	var s string
	if json.Unmarshal(b, &s) == nil {
		*e = enum(strings.ToUpper(s))
		return nil
	}
	var n int
	if err := json.Unmarshal(b, &n); err != nil {
		return err
	}
	*e = enum(fmt.Sprint(n))
	return nil
}

type trackInfo struct {
	Sid    string `json:"sid"`
	Type   enum   `json:"type"`
	Source enum   `json:"source"`
	Muted  bool   `json:"muted"`
}

type participantInfo struct {
	Identity string      `json:"identity"`
	Tracks   []trackInfo `json:"tracks"`
}

// matches reports whether t is the microphone or the camera track.
// TrackSource: CAMERA = 1, MICROPHONE = 2; TrackType: AUDIO = 0, VIDEO = 1.
func (t trackInfo) matches(source string) bool {
	switch t.Source {
	case "CAMERA", "1":
		return source == SourceCamera
	case "MICROPHONE", "2":
		return source == SourceMicrophone
	case "SCREEN_SHARE", "SCREEN_SHARE_AUDIO", "3", "4":
		return false
	}
	// Unknown source: go by the track type.
	if source == SourceMicrophone {
		return t.Type == "AUDIO" || t.Type == "0" || t.Type == ""
	}
	return t.Type == "VIDEO" || t.Type == "1"
}

// Mute switches off a participant's microphone or camera. The participant
// can turn it on again; muting is a host's nudge, removal is the hard stop.
// Nobody in the call is not an error.
func (r *Rooms) Mute(ctx context.Context, tableID, identity, source string) error {
	if source != SourceMicrophone && source != SourceCamera {
		return fmt.Errorf("media: unknown source %q", source)
	}
	var p participantInfo
	err := r.call(ctx, tableID, "GetParticipant", map[string]string{"room": Room(tableID), "identity": identity}, &p)
	if errors.Is(err, errGone) {
		return nil
	}
	if err != nil {
		return err
	}
	for _, t := range p.Tracks {
		if t.Muted || !t.matches(source) {
			continue
		}
		err := r.call(ctx, tableID, "MutePublishedTrack", map[string]any{
			"room": Room(tableID), "identity": identity, "track_sid": t.Sid, "muted": true}, nil)
		if err != nil && !errors.Is(err, errGone) {
			return err
		}
	}
	return nil
}

// Remove sends a participant out of the table's call.
func (r *Rooms) Remove(ctx context.Context, tableID, identity string) error {
	err := r.call(ctx, tableID, "RemoveParticipant", map[string]string{"room": Room(tableID), "identity": identity}, nil)
	if errors.Is(err, errGone) {
		return nil
	}
	return err
}

// Close ends the table's call for everyone.
func (r *Rooms) Close(ctx context.Context, tableID string) error {
	err := r.call(ctx, tableID, "DeleteRoom", map[string]string{"room": Room(tableID)}, nil)
	if errors.Is(err, errGone) {
		return nil
	}
	return err
}
