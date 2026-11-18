package httpapi

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/cookiejar"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/oxisoft/oxipoker/server/internal/accounts"
	"github.com/oxisoft/oxipoker/server/internal/store"
)

type testServer struct {
	*httptest.Server
	acc *accounts.Service
	st  *store.Store
}

func newTestServer(t *testing.T, publicURL string) *testServer {
	t.Helper()
	st, err := store.Open(context.Background(), t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	acc := accounts.New(st)
	if _, err := acc.CreateUser(context.Background(), accounts.NewUser{Username: "alex", Password: "long enough pw", IsAdmin: true}); err != nil {
		t.Fatal(err)
	}
	srv := httptest.NewServer(NewRouter(Options{Store: st, Accounts: acc, PublicURL: publicURL}))
	t.Cleanup(func() { srv.Close(); st.Close() })
	return &testServer{Server: srv, acc: acc, st: st}
}

type req struct {
	method, path string
	body         any
	origin       string
	token        string
}

func (ts *testServer) do(t *testing.T, c *http.Client, r req) (*http.Response, map[string]any) {
	t.Helper()
	var body bytes.Buffer
	if r.body != nil {
		_ = json.NewEncoder(&body).Encode(r.body)
	}
	hr, _ := http.NewRequest(r.method, ts.URL+r.path, &body)
	if r.origin != "" {
		hr.Header.Set("Origin", r.origin)
	}
	if r.token != "" {
		hr.Header.Set("Authorization", "Bearer "+r.token)
	}
	if c == nil {
		c = http.DefaultClient
	}
	res, err := c.Do(hr)
	if err != nil {
		t.Fatal(err)
	}
	defer res.Body.Close()
	var out map[string]any
	_ = json.NewDecoder(res.Body).Decode(&out)
	return res, out
}

func appSignin(t *testing.T, ts *testServer) string {
	t.Helper()
	res, out := ts.do(t, nil, req{method: "POST", path: "/api/v1/auth/signin",
		body: map[string]string{"username": "alex", "password": "long enough pw", "client": "app"}})
	if res.StatusCode != 200 || out["token"] == nil {
		t.Fatalf("app signin: %d %v", res.StatusCode, out)
	}
	return out["token"].(string)
}

func TestAppSigninAndBearer(t *testing.T) {
	ts := newTestServer(t, "")
	tok := appSignin(t, ts)

	res, out := ts.do(t, nil, req{method: "GET", path: "/api/v1/me", token: tok})
	if res.StatusCode != 200 || out["username"] != "alex" || out["is_admin"] != true {
		t.Fatalf("me: %d %v", res.StatusCode, out)
	}
	if _, leaked := out["password_hash"]; leaked {
		t.Fatal("password hash in /me")
	}
	if res, _ := ts.do(t, nil, req{method: "GET", path: "/api/v1/me"}); res.StatusCode != 401 {
		t.Fatalf("anonymous /me: %d", res.StatusCode)
	}
	if res, _ := ts.do(t, nil, req{method: "GET", path: "/api/v1/me", token: "forged"}); res.StatusCode != 401 {
		t.Fatalf("forged token: %d", res.StatusCode)
	}

	tok2 := appSignin(t, ts)
	_, out = ts.do(t, nil, req{method: "GET", path: "/api/v1/me/sessions", token: tok})
	list := out["sessions"].([]any)
	if len(list) != 2 {
		t.Fatalf("sessions: %v", out)
	}
	var other string
	for _, s := range list {
		m := s.(map[string]any)
		if m["current"] != true {
			other = m["id"].(string)
		}
	}
	if res, _ := ts.do(t, nil, req{method: "DELETE", path: "/api/v1/me/sessions/" + other, token: tok}); res.StatusCode != 204 {
		t.Fatalf("revoke: %d", res.StatusCode)
	}
	if res, _ := ts.do(t, nil, req{method: "GET", path: "/api/v1/me", token: tok2}); res.StatusCode != 401 {
		t.Fatal("revoked token still works")
	}
	if res, _ := ts.do(t, nil, req{method: "DELETE", path: "/api/v1/me/sessions/" + other, token: tok}); res.StatusCode != 404 {
		t.Fatalf("revoke twice: %d", res.StatusCode)
	}

	appSignin(t, ts)
	res, out = ts.do(t, nil, req{method: "POST", path: "/api/v1/me/sessions/revoke-others", token: tok})
	if res.StatusCode != 200 || out["revoked"] != float64(1) {
		t.Fatalf("revoke others: %d %v", res.StatusCode, out)
	}
	if res, _ := ts.do(t, nil, req{method: "POST", path: "/api/v1/auth/signout", token: tok}); res.StatusCode != 204 {
		t.Fatalf("signout: %d", res.StatusCode)
	}
	if res, _ := ts.do(t, nil, req{method: "GET", path: "/api/v1/me", token: tok}); res.StatusCode != 401 {
		t.Fatal("token works after signout")
	}
	ev, _ := ts.st.ListAudit(context.Background(), store.AuditFilter{Action: "auth."})
	if len(ev) < 4 {
		t.Fatalf("audit events: %d", len(ev))
	}
}

func TestWebCookieAndOrigin(t *testing.T) {
	ts := newTestServer(t, "https://poker.example.com")
	jar, _ := cookiejar.New(nil)
	c := &http.Client{Jar: jar}
	good := "https://poker.example.com"

	res, out := ts.do(t, c, req{method: "POST", path: "/api/v1/auth/signin", origin: "https://evil.example",
		body: map[string]string{"username": "alex", "password": "long enough pw"}})
	if res.StatusCode != 403 || out["error"] != "bad_origin" {
		t.Fatalf("cross-origin signin: %d %v", res.StatusCode, out)
	}

	res, out = ts.do(t, c, req{method: "POST", path: "/api/v1/auth/signin", origin: good,
		body: map[string]string{"username": "alex", "password": "long enough pw"}})
	if res.StatusCode != 200 || out["token"] != nil {
		t.Fatalf("web signin: %d %v", res.StatusCode, out)
	}
	ck := res.Cookies()
	if len(ck) != 1 || ck[0].Name != "__Host-oxipoker_session" || !ck[0].HttpOnly || !ck[0].Secure ||
		ck[0].SameSite != http.SameSiteLaxMode || ck[0].Path != "/" {
		t.Fatalf("cookie: %+v", ck)
	}
	// The test server is plain http, so send the Secure cookie by hand.
	cookie := ck[0].Name + "=" + ck[0].Value
	call := func(method, path, origin string) int {
		hr, _ := http.NewRequest(method, ts.URL+path, nil)
		hr.Header.Set("Cookie", cookie)
		if origin != "" {
			hr.Header.Set("Origin", origin)
		}
		res, err := http.DefaultClient.Do(hr)
		if err != nil {
			t.Fatal(err)
		}
		res.Body.Close()
		return res.StatusCode
	}
	if code := call("GET", "/api/v1/me", ""); code != 200 {
		t.Fatalf("cookie /me: %d", code)
	}
	if code := call("POST", "/api/v1/me/sessions/revoke-others", "https://evil.example"); code != 403 {
		t.Fatalf("cross-origin with cookie: %d", code)
	}
	if code := call("POST", "/api/v1/me/sessions/revoke-others", ""); code != 403 {
		t.Fatalf("no origin with cookie: %d", code)
	}
	if code := call("POST", "/api/v1/auth/signin", ""); code != 403 {
		t.Fatalf("no-origin signin with cookie: %d", code)
	}
	if code := call("POST", "/api/v1/auth/signout", good); code != 204 {
		t.Fatalf("signout: %d", code)
	}
	if code := call("GET", "/api/v1/me", ""); code != 401 {
		t.Fatalf("cookie after signout: %d", code)
	}
}

func TestSameHostOriginWithoutPublicURL(t *testing.T) {
	ts := newTestServer(t, "")
	body := map[string]string{"username": "alex", "password": "long enough pw"}
	if res, _ := ts.do(t, nil, req{method: "POST", path: "/api/v1/auth/signin", origin: ts.URL, body: body}); res.StatusCode != 200 {
		t.Fatalf("same host: %d", res.StatusCode)
	}
	if res, _ := ts.do(t, nil, req{method: "POST", path: "/api/v1/auth/signin", origin: "http://other.test", body: body}); res.StatusCode != 403 {
		t.Fatalf("other host: %d", res.StatusCode)
	}
}

func TestSigninFailuresAndRateLimit(t *testing.T) {
	ts := newTestServer(t, "")
	signin := func(user, pw string) (int, map[string]any, http.Header) {
		res, out := ts.do(t, nil, req{method: "POST", path: "/api/v1/auth/signin",
			body: map[string]string{"username": user, "password": pw, "client": "app"}})
		return res.StatusCode, out, res.Header
	}
	codeWrong, outWrong, _ := signin("alex", "wrong password")
	codeUnknown, outUnknown, _ := signin("nobody", "wrong password")
	if codeWrong != 401 || codeUnknown != 401 || outWrong["error"] != outUnknown["error"] {
		t.Fatalf("answers differ: %d %v / %d %v", codeWrong, outWrong, codeUnknown, outUnknown)
	}
	if res, _ := ts.do(t, nil, req{method: "POST", path: "/api/v1/auth/signin", body: map[string]any{"username": "alex", "extra": 1}}); res.StatusCode != 400 {
		t.Fatalf("unknown field: %d", res.StatusCode)
	}

	// Per account: 10 failures lock the account name, also for the right password.
	for range accountFailLimit - 1 {
		signin("ALEX", "wrong password")
	}
	code, _, h := signin("alex", "long enough pw")
	if code != 429 || h.Get("Retry-After") == "" {
		t.Fatalf("account limit: %d", code)
	}
	ev, _ := ts.st.ListAudit(context.Background(), store.AuditFilter{Action: "auth.signin_failed"})
	if len(ev) != accountFailLimit+1 {
		t.Fatalf("failed signins audited: %d", len(ev))
	}
	for _, e := range ev {
		if strings.Contains(e.Detail["username"].(string)+e.Target, "wrong") {
			t.Fatal("password in audit log")
		}
	}
}

func TestFailLimiter(t *testing.T) {
	l := newFailLimiter(2, time.Minute)
	now := time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC)
	l.now = func() time.Time { return now }
	l.fail("ip")
	if l.blocked("ip") != 0 {
		t.Fatal("blocked after one failure")
	}
	l.fail("ip")
	if l.blocked("ip") != time.Minute {
		t.Fatalf("wait = %v", l.blocked("ip"))
	}
	if l.blocked("other") != 0 {
		t.Fatal("keys share a counter")
	}
	now = now.Add(time.Minute)
	if l.blocked("ip") != 0 {
		t.Fatal("still blocked after the window")
	}
	l.fail("ip")
	l.fail("ip")
	l.clear("ip")
	if l.blocked("ip") != 0 {
		t.Fatal("clear did not reset")
	}
}
