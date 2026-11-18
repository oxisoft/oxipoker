package httpapi

import (
	"bytes"
	"image"
	"image/color"
	"image/png"
	"io"
	"net/http"
	"testing"
)

func TestAvatarEndpoints(t *testing.T) {
	ts := newTestServer(t, "")
	token := appSignin(t, ts)
	_, me := ts.do(t, nil, req{method: "GET", path: "/api/v1/me", token: token})
	id, _ := me["id"].(string)

	send := func(method string, body []byte, tok string) *http.Response {
		hr, _ := http.NewRequest(method, ts.URL+"/api/v1/me/avatar", bytes.NewReader(body))
		hr.Header.Set("Content-Type", "image/png")
		if tok != "" {
			hr.Header.Set("Authorization", "Bearer "+tok)
		}
		res, err := http.DefaultClient.Do(hr)
		if err != nil {
			t.Fatal(err)
		}
		res.Body.Close()
		return res
	}
	get := func(header map[string]string) (*http.Response, []byte) {
		hr, _ := http.NewRequest("GET", ts.URL+"/api/v1/users/"+id+"/avatar", nil)
		hr.Header.Set("Authorization", "Bearer "+token)
		for k, v := range header {
			hr.Header.Set(k, v)
		}
		res, err := http.DefaultClient.Do(hr)
		if err != nil {
			t.Fatal(err)
		}
		defer res.Body.Close()
		b, _ := io.ReadAll(res.Body)
		return res, b
	}

	img := image.NewRGBA(image.Rect(0, 0, 400, 300))
	img.Set(1, 1, color.RGBA{255, 0, 0, 255})
	var buf bytes.Buffer
	_ = png.Encode(&buf, img)

	// No token and no Origin: the CSRF check refuses it before authentication.
	if res := send("PUT", buf.Bytes(), ""); res.StatusCode != 403 {
		t.Fatalf("anonymous upload: %d", res.StatusCode)
	}
	if res, _ := get(nil); res.StatusCode != 404 {
		t.Fatalf("no avatar yet: %d", res.StatusCode)
	}
	if res := send("PUT", []byte("<svg xmlns='http://www.w3.org/2000/svg'/>"), token); res.StatusCode != 415 {
		t.Fatalf("svg: %d", res.StatusCode)
	}
	if res := send("PUT", make([]byte, 6<<20), token); res.StatusCode != 413 {
		t.Fatalf("over the size cap: %d", res.StatusCode)
	}
	if res := send("PUT", buf.Bytes(), token); res.StatusCode != 200 {
		t.Fatalf("upload: %d", res.StatusCode)
	}
	_, me = ts.do(t, nil, req{method: "GET", path: "/api/v1/me", token: token})
	ver, _ := me["avatar"].(string)
	if ver == "" {
		t.Fatal("me.avatar empty after upload")
	}

	res, body := get(nil)
	if res.StatusCode != 200 || res.Header.Get("Content-Type") != "image/png" || res.Header.Get("ETag") != `"`+ver+`"` {
		t.Fatalf("get: %d %v", res.StatusCode, res.Header)
	}
	if cfg, err := png.DecodeConfig(bytes.NewReader(body)); err != nil || cfg.Width != 256 || cfg.Height != 256 {
		t.Fatalf("served image: %+v %v", cfg, err)
	}
	if res, _ := get(map[string]string{"If-None-Match": `"` + ver + `"`}); res.StatusCode != 304 {
		t.Fatalf("conditional get: %d", res.StatusCode)
	}

	if res := send("DELETE", nil, token); res.StatusCode != 204 {
		t.Fatalf("remove: %d", res.StatusCode)
	}
	if res, _ := get(nil); res.StatusCode != 404 {
		t.Fatalf("after remove: %d", res.StatusCode)
	}
}
