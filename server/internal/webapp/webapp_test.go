package webapp

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func get(t *testing.T, method, path string) *httptest.ResponseRecorder {
	t.Helper()
	rec := httptest.NewRecorder()
	Handler().ServeHTTP(rec, httptest.NewRequest(method, path, nil))
	return rec
}

func TestClientRoutesFallBackToIndex(t *testing.T) {
	index := get(t, "GET", "/").Body.String()
	if index == "" {
		t.Fatal("empty index")
	}
	// Deep links of the app (path URL strategy) must load the app itself.
	for _, p := range []string{"/invite", "/account", "/admin", "/signin", "/a/b/c"} {
		rec := get(t, "GET", p)
		if rec.Code != 200 || rec.Body.String() != index {
			t.Errorf("%s: %d, index served = %v", p, rec.Code, rec.Body.String() == index)
		}
		if rec.Header().Get("Cache-Control") != "no-cache" {
			t.Errorf("%s: index must not be cached", p)
		}
	}
}

func TestAPIPathsNeverFallBack(t *testing.T) {
	for _, p := range []string{"/api", "/api/v1/nope"} {
		rec := get(t, "GET", p)
		if rec.Code != 404 || !strings.Contains(rec.Body.String(), "not_found") ||
			rec.Header().Get("Content-Type") != "application/json" {
			t.Errorf("%s: %d %q", p, rec.Code, rec.Body.String())
		}
	}
}

func TestOnlyReads(t *testing.T) {
	rec := get(t, "POST", "/")
	if rec.Code != http.StatusMethodNotAllowed || rec.Header().Get("Allow") != "GET, HEAD" {
		t.Fatalf("POST: %d", rec.Code)
	}
	if rec := get(t, "HEAD", "/invite"); rec.Code != 200 || rec.Body.Len() != 0 {
		t.Fatalf("HEAD: %d len %d", rec.Code, rec.Body.Len())
	}
}

func TestPathTraversalStaysInBundle(t *testing.T) {
	rec := get(t, "GET", "/../../etc/passwd")
	if strings.Contains(rec.Body.String(), "root:") {
		t.Fatal("escaped the bundle")
	}
}
