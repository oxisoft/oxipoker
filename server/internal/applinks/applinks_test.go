package applinks

import (
	"encoding/json"
	"net/http/httptest"
	"testing"
)

func TestParse(t *testing.T) {
	apps, err := Parse("")
	if err != nil || len(apps) != 1 || apps[0] != Official {
		t.Fatalf("empty env: %v %v", apps, err)
	}
	fp := "aa:bb:cc:dd:ee:ff:00:11:22:33:44:55:66:77:88:99:aa:bb:cc:dd:ee:ff:00:11:22:33:44:55:66:77:88:99"
	apps, err = Parse(" org.example.poker=" + fp + " , ," + Official.Package + "=" + Official.CertSHA256)
	if err != nil || len(apps) != 2 || apps[1].Package != "org.example.poker" || apps[1].CertSHA256[:2] != "AA" {
		t.Fatalf("own build: %v %v", apps, err)
	}
	for _, bad := range []string{"nopackage", "x=AA:BB", "org.example=" + fp + ":00", "1org.x=" + fp, "org.example=" + fp[:94] + "zz"} {
		if _, err := Parse(bad); err == nil {
			t.Errorf("Parse(%q) accepted", bad)
		}
	}
}

func TestOrigin(t *testing.T) {
	a := App{Package: "x.y", CertSHA256: "00:01:02:03:04:05:06:07:08:09:0A:0B:0C:0D:0E:0F:10:11:12:13:14:15:16:17:18:19:1A:1B:1C:1D:1E:FF"}
	if got, want := a.Origin(), "android:apk-key-hash:AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHv8"; got != want {
		t.Fatalf("origin %q, want %q", got, want)
	}
	if o := Origins([]App{Official, a}); len(o) != 2 {
		t.Fatal(o)
	}
}

func TestHandler(t *testing.T) {
	other := App{Package: Official.Package, CertSHA256: "00:01:02:03:04:05:06:07:08:09:0A:0B:0C:0D:0E:0F:10:11:12:13:14:15:16:17:18:19:1A:1B:1C:1D:1E:FF"}
	rec := httptest.NewRecorder()
	Handler([]App{Official, other}).ServeHTTP(rec, httptest.NewRequest("GET", "/.well-known/assetlinks.json", nil))
	if ct := rec.Header().Get("Content-Type"); ct != "application/json" {
		t.Fatalf("content type %q", ct)
	}
	var list []statement
	if err := json.Unmarshal(rec.Body.Bytes(), &list); err != nil {
		t.Fatal(err)
	}
	if len(list) != 1 || list[0].Target.PackageName != Official.Package || len(list[0].Target.Fingerprints) != 2 ||
		list[0].Target.Namespace != "android_app" || list[0].Relation[1] != "delegate_permission/common.get_login_creds" {
		t.Fatalf("statement %+v", list)
	}
}
