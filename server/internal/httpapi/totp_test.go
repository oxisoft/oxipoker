package httpapi

import (
	"testing"
	"time"

	"github.com/oxisoft/oxipoker/server/internal/accounts"
)

func passwordSignin(t *testing.T, ts *testServer) map[string]any {
	t.Helper()
	res, out := ts.do(t, nil, req{method: "POST", path: "/api/v1/auth/signin",
		body: map[string]string{"username": "alex", "password": "long enough pw", "client": "app"}})
	if res.StatusCode != 200 {
		t.Fatalf("signin: %d %v", res.StatusCode, out)
	}
	return out
}

func TestTOTPFlow(t *testing.T) {
	ts := newTestServer(t, "")
	token := appSignin(t, ts)

	res, out := ts.do(t, nil, req{method: "POST", path: "/api/v1/me/totp/begin", token: token})
	secret, _ := out["secret"].(string)
	if res.StatusCode != 200 || secret == "" || out["qr_png"] == "" || out["otpauth_url"] == nil {
		t.Fatalf("begin: %d %v", res.StatusCode, out)
	}
	if res, _ := ts.do(t, nil, req{method: "POST", path: "/api/v1/me/totp/confirm", token: token, body: map[string]string{"code": "000000"}}); res.StatusCode != 400 {
		t.Fatalf("wrong confirm code: %d", res.StatusCode)
	}
	now := time.Now()
	res, out = ts.do(t, nil, req{method: "POST", path: "/api/v1/me/totp/confirm", token: token,
		body: map[string]string{"code": accounts.TOTPCodeAt(secret, now)}})
	codes, _ := out["recovery_codes"].([]any)
	if res.StatusCode != 200 || len(codes) != 10 {
		t.Fatalf("confirm: %d %v", res.StatusCode, out)
	}
	if res, _ := ts.do(t, nil, req{method: "POST", path: "/api/v1/me/totp/begin", token: token}); res.StatusCode != 409 {
		t.Fatalf("begin while on: %d", res.StatusCode)
	}

	// Password alone no longer signs in.
	out = passwordSignin(t, ts)
	if out["totp_required"] != true || out["token"] != nil {
		t.Fatalf("no second step: %v", out)
	}
	ch := out["challenge"].(string)
	// The code used to confirm is spent.
	if res, _ := ts.do(t, nil, req{method: "POST", path: "/api/v1/auth/totp", body: map[string]string{"challenge": ch, "code": accounts.TOTPCodeAt(secret, now)}}); res.StatusCode != 401 {
		t.Fatalf("replayed code: %d", res.StatusCode)
	}
	res, out = ts.do(t, nil, req{method: "POST", path: "/api/v1/auth/totp",
		body: map[string]string{"challenge": ch, "code": accounts.TOTPCodeAt(secret, now.Add(30*time.Second))}})
	if res.StatusCode != 200 || out["token"] == nil {
		t.Fatalf("totp signin: %d %v", res.StatusCode, out)
	}
	if res, _ := ts.do(t, nil, req{method: "POST", path: "/api/v1/auth/totp", body: map[string]string{"challenge": ch, "code": "123456"}}); res.StatusCode != 401 {
		t.Fatalf("challenge reused: %d", res.StatusCode)
	}

	// A recovery code works once.
	rc := codes[0].(string)
	ch = passwordSignin(t, ts)["challenge"].(string)
	if res, _ := ts.do(t, nil, req{method: "POST", path: "/api/v1/auth/totp", body: map[string]string{"challenge": ch, "code": rc}}); res.StatusCode != 200 {
		t.Fatalf("recovery code: %d", res.StatusCode)
	}
	ch = passwordSignin(t, ts)["challenge"].(string)
	if res, _ := ts.do(t, nil, req{method: "POST", path: "/api/v1/auth/totp", body: map[string]string{"challenge": ch, "code": rc}}); res.StatusCode != 401 {
		t.Fatalf("recovery code reused: %d", res.StatusCode)
	}
	_, out = ts.do(t, nil, req{method: "GET", path: "/api/v1/me/totp", token: token})
	if out["enabled"] != true || out["recovery_codes_left"] != float64(9) {
		t.Fatalf("status: %v", out)
	}

	// Wrong codes burn the challenge.
	ch = passwordSignin(t, ts)["challenge"].(string)
	for range challengeTries {
		ts.do(t, nil, req{method: "POST", path: "/api/v1/auth/totp", body: map[string]string{"challenge": ch, "code": "999999"}})
	}
	if _, out := ts.do(t, nil, req{method: "POST", path: "/api/v1/auth/totp", body: map[string]string{"challenge": ch, "code": codes[1].(string)}}); out["error"] != "challenge_expired" {
		t.Fatalf("challenge after 5 tries: %v", out)
	}

	// Turning it off needs a code.
	if res, _ := ts.do(t, nil, req{method: "POST", path: "/api/v1/me/totp/disable", token: token, body: map[string]string{"code": "nope"}}); res.StatusCode != 400 {
		t.Fatalf("disable without code: %d", res.StatusCode)
	}
	if res, _ := ts.do(t, nil, req{method: "POST", path: "/api/v1/me/totp/disable", token: token, body: map[string]string{"code": codes[2].(string)}}); res.StatusCode != 204 {
		t.Fatalf("disable: %d", res.StatusCode)
	}
	if out := passwordSignin(t, ts); out["token"] == nil {
		t.Fatalf("signin after disable: %v", out)
	}
}
