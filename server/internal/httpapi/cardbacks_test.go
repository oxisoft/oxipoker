package httpapi

import (
	"bytes"
	"encoding/json"
	"image"
	"image/color"
	"image/png"
	"io"
	"net/http"
	"testing"
)

func TestAppearanceAndCardBacks(t *testing.T) {
	ts := newTestServer(t, "")
	admin := appSignin(t, ts)

	// New accounts start on the classic theme and the server default back.
	_, me := ts.do(t, nil, req{method: "GET", path: "/api/v1/me", token: admin})
	if me["theme"] != "classic" || me["card_back"] != "" {
		t.Fatalf("defaults: %v", me)
	}
	_, list := ts.do(t, nil, req{method: "GET", path: "/api/v1/card-backs", token: admin})
	if list["default"] != "classic-red" || len(list["card_backs"].([]any)) != 4 {
		t.Fatalf("built-ins: %v", list)
	}

	// Theme and back switch; bad values change nothing.
	res, me := ts.do(t, nil, req{method: "PATCH", path: "/api/v1/me", token: admin,
		body: map[string]any{"theme": "cyberpunk", "card_back": "cyber-grid"}})
	if res.StatusCode != 200 || me["theme"] != "cyberpunk" || me["card_back"] != "cyber-grid" || me["display_name"] != "alex" {
		t.Fatalf("patch: %d %v", res.StatusCode, me)
	}
	for _, body := range []map[string]any{{"theme": "neon"}, {"card_back": "nope"}, {"theme": "classic", "card_back": "u-missing"}} {
		if res, out := ts.do(t, nil, req{method: "PATCH", path: "/api/v1/me", token: admin, body: body}); res.StatusCode != 400 {
			t.Fatalf("bad %v: %d %v", body, res.StatusCode, out)
		}
	}
	if _, me := ts.do(t, nil, req{method: "GET", path: "/api/v1/me", token: admin}); me["theme"] != "cyberpunk" {
		t.Fatalf("bad patch changed the theme: %v", me)
	}

	upload := func(name string, body []byte) (int, map[string]any) {
		hr, _ := http.NewRequest("POST", ts.URL+"/api/v1/admin/card-backs?name="+name, bytes.NewReader(body))
		hr.Header.Set("Authorization", "Bearer "+admin)
		res, err := http.DefaultClient.Do(hr)
		if err != nil {
			t.Fatal(err)
		}
		defer res.Body.Close()
		out := map[string]any{}
		_ = json.NewDecoder(res.Body).Decode(&out)
		return res.StatusCode, out
	}
	img := image.NewRGBA(image.Rect(0, 0, 1000, 1000))
	img.Set(500, 500, color.RGBA{255, 0, 0, 255})
	var buf bytes.Buffer
	_ = png.Encode(&buf, img)
	if code, _ := upload("Gif", []byte("GIF89a")); code != 415 {
		t.Fatalf("not an image: %d", code)
	}
	if code, _ := upload("", buf.Bytes()); code != 400 {
		t.Fatalf("no name: %d", code)
	}
	code, back := upload("Club%20logo", buf.Bytes())
	if code != 201 || back["name"] != "Club logo" {
		t.Fatalf("upload: %d %v", code, back)
	}
	id := back["id"].(string)

	// The upload is a 500 x 700 PNG.
	hr, _ := http.NewRequest("GET", ts.URL+"/api/v1/card-backs/"+id+"/image", nil)
	hr.Header.Set("Authorization", "Bearer "+admin)
	r, err := http.DefaultClient.Do(hr)
	if err != nil {
		t.Fatal(err)
	}
	data, _ := io.ReadAll(r.Body)
	r.Body.Close()
	cfg, err := png.DecodeConfig(bytes.NewReader(data))
	if err != nil || cfg.Width != 500 || cfg.Height != 700 {
		t.Fatalf("image: %v %+v", err, cfg)
	}

	// The admin makes it the default; then it cannot be deleted.
	res, set := ts.do(t, nil, req{method: "PATCH", path: "/api/v1/admin/settings", token: admin,
		body: map[string]any{"card_back_default": id}})
	if res.StatusCode != 200 || set["card_back_default"] != id {
		t.Fatalf("set default: %d %v", res.StatusCode, set)
	}
	if res, _ := ts.do(t, nil, req{method: "PATCH", path: "/api/v1/admin/settings", token: admin,
		body: map[string]any{"card_back_default": "u-gone"}}); res.StatusCode != 400 {
		t.Fatalf("unknown default: %d", res.StatusCode)
	}
	if res, _ := ts.do(t, nil, req{method: "DELETE", path: "/api/v1/admin/card-backs/" + id, token: admin}); res.StatusCode != 409 {
		t.Fatalf("delete default: %d", res.StatusCode)
	}
	if res, _ := ts.do(t, nil, req{method: "DELETE", path: "/api/v1/admin/card-backs/cyber-grid", token: admin}); res.StatusCode != 409 {
		t.Fatalf("delete built-in: %d", res.StatusCode)
	}

	// Back to a built-in default: the upload can go, and users on it follow the default again.
	ts.do(t, nil, req{method: "PATCH", path: "/api/v1/me", token: admin, body: map[string]any{"card_back": id}})
	ts.do(t, nil, req{method: "PATCH", path: "/api/v1/admin/settings", token: admin, body: map[string]any{"card_back_default": "classic-blue"}})
	if res, _ := ts.do(t, nil, req{method: "DELETE", path: "/api/v1/admin/card-backs/" + id, token: admin}); res.StatusCode != 204 {
		t.Fatalf("delete: %d", res.StatusCode)
	}
	if _, me := ts.do(t, nil, req{method: "GET", path: "/api/v1/me", token: admin}); me["card_back"] != "" {
		t.Fatalf("user back after delete: %v", me)
	}
	if res, _ := ts.do(t, nil, req{method: "DELETE", path: "/api/v1/admin/card-backs/" + id, token: admin}); res.StatusCode != 404 {
		t.Fatalf("delete again: %d", res.StatusCode)
	}
}
