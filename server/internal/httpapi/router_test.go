package httpapi

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestHealth(t *testing.T) {
	srv := httptest.NewServer(NewRouter(Options{}))
	defer srv.Close()

	res, err := http.Get(srv.URL + "/api/v1/health")
	if err != nil {
		t.Fatal(err)
	}
	defer res.Body.Close()
	if res.StatusCode != http.StatusOK {
		t.Fatalf("status %d", res.StatusCode)
	}
	var h Health
	if err := json.NewDecoder(res.Body).Decode(&h); err != nil {
		t.Fatal(err)
	}
	if h.Status != "ok" || h.Version == "" {
		t.Fatalf("unexpected health %+v", h)
	}
}

func TestUnknownAPIPathIsJSON404(t *testing.T) {
	srv := httptest.NewServer(NewRouter(Options{}))
	defer srv.Close()

	for _, p := range []string{"/api/v1/nope", "/api/v2/x", "/api"} {
		res, err := http.Get(srv.URL + p)
		if err != nil {
			t.Fatal(err)
		}
		res.Body.Close()
		if res.StatusCode != http.StatusNotFound {
			t.Errorf("%s: status %d, want 404", p, res.StatusCode)
		}
		if ct := res.Header.Get("Content-Type"); !strings.HasPrefix(ct, "application/json") {
			t.Errorf("%s: content type %q, want JSON", p, ct)
		}
	}
}

func TestClientRoutesServeIndex(t *testing.T) {
	srv := httptest.NewServer(NewRouter(Options{}))
	defer srv.Close()

	for _, p := range []string{"/", "/tables/42", "/invite/abc"} {
		res, err := http.Get(srv.URL + p)
		if err != nil {
			t.Fatal(err)
		}
		res.Body.Close()
		if res.StatusCode != http.StatusOK {
			t.Errorf("%s: status %d", p, res.StatusCode)
		}
		if ct := res.Header.Get("Content-Type"); !strings.HasPrefix(ct, "text/html") {
			t.Errorf("%s: content type %q, want HTML", p, ct)
		}
	}
}

func TestWebAppRejectsWrites(t *testing.T) {
	srv := httptest.NewServer(NewRouter(Options{}))
	defer srv.Close()

	res, err := http.Post(srv.URL+"/", "text/plain", strings.NewReader("x"))
	if err != nil {
		t.Fatal(err)
	}
	res.Body.Close()
	if res.StatusCode != http.StatusMethodNotAllowed {
		t.Fatalf("status %d, want 405", res.StatusCode)
	}
}
