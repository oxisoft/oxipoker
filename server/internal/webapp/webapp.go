// Package webapp serves the Flutter web client from inside the server binary.
//
// The bundle is compiled in (go:embed), so the app and the API that serves it
// always come from the same build: there is no web root to fall out of date and
// no second process to run. The Docker build copies `flutter build web` output
// into dist/ before compiling; a plain `go build` embeds the committed
// placeholder page instead.
package webapp

import (
	"embed"
	"io/fs"
	"net/http"
	"path"
	"strings"
)

// `all:` matters: plain go:embed skips files starting with "." or "_", and
// Flutter emits some.
//
//go:embed all:dist
var dist embed.FS

func files() fs.FS {
	sub, err := fs.Sub(dist, "dist")
	if err != nil {
		panic(err) // only if the embed directive stops matching: a build-time fact
	}
	return sub
}

// Bundled reports whether a real Flutter build (not the placeholder) is embedded.
func Bundled() bool {
	_, err := fs.Stat(files(), "flutter_bootstrap.js")
	return err == nil
}

// Handler serves the bundle and falls back to index.html for unknown paths, so
// the client owns its routing. API paths never fall back: a client expecting
// JSON must not get HTML with a 200.
func Handler() http.Handler {
	fsys := files()
	fileServer := http.FileServer(http.FS(fsys))
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet && r.Method != http.MethodHead {
			w.Header().Set("Allow", "GET, HEAD")
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
			return
		}
		if strings.HasPrefix(r.URL.Path, "/api/") || r.URL.Path == "/api" {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusNotFound)
			_, _ = w.Write([]byte(`{"error":"not_found"}`))
			return
		}
		name := strings.TrimPrefix(path.Clean(r.URL.Path), "/")
		if name != "" {
			if info, err := fs.Stat(fsys, name); err == nil && !info.IsDir() {
				// Flutter's entry files must never be cached, or a browser keeps
				// running the previous release after an upgrade.
				if name == "flutter_bootstrap.js" || name == "flutter_service_worker.js" || name == "main.dart.js" {
					w.Header().Set("Cache-Control", "no-cache")
				}
				fileServer.ServeHTTP(w, r)
				return
			}
		}
		serveIndex(w, r, fsys)
	})
}

func serveIndex(w http.ResponseWriter, r *http.Request, fsys fs.FS) {
	b, err := fs.ReadFile(fsys, "index.html")
	if err != nil {
		http.Error(w, "web client missing", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.Header().Set("Cache-Control", "no-cache")
	if r.Method == http.MethodHead {
		return
	}
	_, _ = w.Write(b)
}
