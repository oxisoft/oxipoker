// Package applinks lets the official Android app use passkeys on any
// self-hosted server.
//
// Android only offers a passkey for a relying party when the RP's domain
// publishes /.well-known/assetlinks.json naming the app's package and signing
// certificate. A self-hosted server's domain is unknown when the app is built,
// so every server publishes the statement itself. The app's WebAuthn origin is
// then "android:apk-key-hash:<base64url SHA-256 of the certificate>", which the
// server must accept next to its web origin.
package applinks

import (
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"net/http"
	"regexp"
	"strings"
)

// App is one Android app allowed to use this server's passkeys.
type App struct {
	Package string
	// CertSHA256 is the signing certificate's SHA-256 as 32 colon-separated
	// upper-case hex bytes, the form keytool and apksigner print.
	CertSHA256 string
}

// Official is the app published by OxiSoft (fdroid.oxisoft.io, GitHub Releases).
var Official = App{
	Package:    "io.oxisoft.oxipoker",
	CertSHA256: "79:F2:92:04:83:FB:1F:7F:B7:66:36:D9:FF:76:AB:FF:7E:CC:B6:13:6E:B5:62:42:00:61:12:FF:23:9F:33:CD",
}

var (
	pkgRE = regexp.MustCompile(`^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z][A-Za-z0-9_]*)+$`)
	fpRE  = regexp.MustCompile(`^[0-9A-F]{2}(:[0-9A-F]{2}){31}$`)
)

// Parse reads ANDROID_APPS: a comma-separated list of package=SHA256 entries
// for own builds of the app. The official app is always included first.
func Parse(env string) ([]App, error) {
	apps := []App{Official}
	for _, part := range strings.Split(env, ",") {
		part = strings.TrimSpace(part)
		if part == "" {
			continue
		}
		pkg, fp, ok := strings.Cut(part, "=")
		pkg, fp = strings.TrimSpace(pkg), strings.ToUpper(strings.TrimSpace(fp))
		if !ok || !pkgRE.MatchString(pkg) || !fpRE.MatchString(fp) {
			return nil, fmt.Errorf("applinks: ANDROID_APPS entry %q is not package=AA:BB:...(32 bytes)", part)
		}
		dup := false
		for _, a := range apps {
			if a.Package == pkg && a.CertSHA256 == fp {
				dup = true
			}
		}
		if !dup {
			apps = append(apps, App{Package: pkg, CertSHA256: fp})
		}
	}
	return apps, nil
}

// Origin is the WebAuthn origin the Android credential manager reports for the app.
func (a App) Origin() string {
	b, err := hex.DecodeString(strings.ReplaceAll(a.CertSHA256, ":", ""))
	if err != nil {
		panic("applinks: bad fingerprint " + a.CertSHA256) // Parse validated it
	}
	return "android:apk-key-hash:" + base64.RawURLEncoding.EncodeToString(b)
}

// Origins returns the WebAuthn origins of all apps.
func Origins(apps []App) []string {
	out := make([]string, 0, len(apps))
	for _, a := range apps {
		out = append(out, a.Origin())
	}
	return out
}

type target struct {
	Namespace    string   `json:"namespace"`
	PackageName  string   `json:"package_name"`
	Fingerprints []string `json:"sha256_cert_fingerprints"`
}

type statement struct {
	Relation []string `json:"relation"`
	Target   target   `json:"target"`
}

// Handler serves /.well-known/assetlinks.json for apps.
func Handler(apps []App) http.Handler {
	byPkg := map[string][]string{}
	var order []string
	for _, a := range apps {
		if _, ok := byPkg[a.Package]; !ok {
			order = append(order, a.Package)
		}
		byPkg[a.Package] = append(byPkg[a.Package], a.CertSHA256)
	}
	list := make([]statement, 0, len(order))
	for _, pkg := range order {
		list = append(list, statement{
			Relation: []string{"delegate_permission/common.handle_all_urls", "delegate_permission/common.get_login_creds"},
			Target:   target{Namespace: "android_app", PackageName: pkg, Fingerprints: byPkg[pkg]},
		})
	}
	body, _ := json.Marshal(list)
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.Header().Set("Cache-Control", "public, max-age=3600")
		_, _ = w.Write(body)
	})
}
