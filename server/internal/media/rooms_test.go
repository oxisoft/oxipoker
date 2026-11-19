package media

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync"
	"testing"
	"time"
)

// fakeLiveKit answers the RoomService methods the server uses and records
// every call after checking its admin token.
type fakeLiveKit struct {
	t     *testing.T
	cfg   Config
	mu    sync.Mutex
	calls []string
	rooms map[string]map[string][]trackInfo // room -> identity -> tracks
}

func (f *fakeLiveKit) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	method, ok := strings.CutPrefix(r.URL.Path, "/twirp/livekit.RoomService/")
	if !ok || r.Method != http.MethodPost {
		http.NotFound(w, r)
		return
	}
	var in struct {
		Room, Identity string
		TrackSid       string `json:"track_sid"`
		Muted          bool
	}
	_ = json.NewDecoder(r.Body).Decode(&in)
	cl, err := f.cfg.Verify(strings.TrimPrefix(r.Header.Get("Authorization"), "Bearer "), time.Now())
	if err != nil || !cl.Video.RoomAdmin || cl.Video.Room != in.Room {
		w.WriteHeader(http.StatusUnauthorized)
		_, _ = w.Write([]byte(`{"code":"unauthenticated","msg":"bad token"}`))
		return
	}
	f.mu.Lock()
	defer f.mu.Unlock()
	f.calls = append(f.calls, method+" "+in.Identity+in.TrackSid)
	room, ok := f.rooms[in.Room]
	notFound := func() {
		w.WriteHeader(http.StatusNotFound)
		_, _ = w.Write([]byte(`{"code":"not_found","msg":"room not found"}`))
	}
	if !ok {
		notFound()
		return
	}
	switch method {
	case "GetParticipant":
		tracks, ok := room[in.Identity]
		if !ok {
			notFound()
			return
		}
		_ = json.NewEncoder(w).Encode(map[string]any{"identity": in.Identity, "tracks": tracks})
	case "MutePublishedTrack":
		for i, tr := range room[in.Identity] {
			if tr.Sid == in.TrackSid {
				room[in.Identity][i].Muted = in.Muted
			}
		}
		_, _ = w.Write([]byte(`{}`))
	case "RemoveParticipant":
		delete(room, in.Identity)
		_, _ = w.Write([]byte(`{}`))
	case "DeleteRoom":
		delete(f.rooms, in.Room)
		_, _ = w.Write([]byte(`{}`))
	default:
		http.NotFound(w, r)
	}
}

func TestRooms(t *testing.T) {
	f := &fakeLiveKit{t: t, rooms: map[string]map[string][]trackInfo{
		Room("t1"): {
			"bob": {{Sid: "TR_mic", Type: "AUDIO", Source: "MICROPHONE"}, {Sid: "TR_cam", Type: "VIDEO", Source: "CAMERA"},
				{Sid: "TR_screen", Type: "VIDEO", Source: "SCREEN_SHARE"}},
			"eve": {{Sid: "TR_eve", Type: "1", Source: "1"}},
		}}}
	hs := httptest.NewServer(f)
	defer hs.Close()
	f.cfg = Config{URL: "ws" + strings.TrimPrefix(hs.URL, "http"), Key: "APIkey", Secret: "a secret that is long enough"}
	r, err := NewRooms(f.cfg)
	if err != nil {
		t.Fatal(err)
	}
	ctx := context.Background()
	if err := r.Mute(ctx, "t1", "bob", SourceMicrophone); err != nil {
		t.Fatal(err)
	}
	if err := r.Mute(ctx, "t1", "eve", SourceCamera); err != nil {
		t.Fatal(err)
	}
	room := f.rooms[Room("t1")]
	if !room["bob"][0].Muted || room["bob"][1].Muted || room["bob"][2].Muted || !room["eve"][0].Muted {
		t.Fatalf("tracks after mute: %+v", room)
	}
	if err := r.Mute(ctx, "t1", "bob", "screen"); err == nil {
		t.Fatal("unknown source accepted")
	}
	// Not in the call, or no call at all: nothing to do, no error.
	for _, err := range []error{r.Mute(ctx, "t1", "nobody", SourceCamera), r.Remove(ctx, "t9", "bob"), r.Close(ctx, "t9")} {
		if err != nil {
			t.Fatal(err)
		}
	}
	if err := r.Remove(ctx, "t1", "eve"); err != nil {
		t.Fatal(err)
	}
	if _, ok := room["eve"]; ok {
		t.Fatal("eve still in the call")
	}
	if err := r.Close(ctx, "t1"); err != nil {
		t.Fatal(err)
	}
	if _, ok := f.rooms[Room("t1")]; ok {
		t.Fatal("room not deleted")
	}
	want := []string{"GetParticipant bob", "MutePublishedTrack bobTR_mic", "GetParticipant eve", "MutePublishedTrack eveTR_eve",
		"GetParticipant nobody", "RemoveParticipant bob", "DeleteRoom ", "RemoveParticipant eve", "DeleteRoom "}
	if strings.Join(f.calls, "|") != strings.Join(want, "|") {
		t.Fatalf("calls:\n%v\nwant\n%v", f.calls, want)
	}

	// A wrong secret is an error, not silence.
	bad, _ := NewRooms(Config{URL: hs.URL, Key: "APIkey", Secret: "another secret entirely"})
	if err := bad.Remove(ctx, "t1", "bob"); err == nil || !strings.Contains(err.Error(), "401") {
		t.Fatalf("bad token: %v", err)
	}
	if _, err := NewRooms(Config{}); err == nil {
		t.Fatal("rooms without settings")
	}
}
