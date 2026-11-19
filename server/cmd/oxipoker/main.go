// Command oxipoker is the Oxi Poker server: game, API and the embedded web client.
package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"log/slog"
	"net"
	"net/http"
	"net/url"
	"os"
	"os/signal"
	"path/filepath"
	"strconv"
	"syscall"
	"time"

	"github.com/oxisoft/oxipoker/server/internal/accounts"
	"github.com/oxisoft/oxipoker/server/internal/applinks"
	"github.com/oxisoft/oxipoker/server/internal/history"
	"github.com/oxisoft/oxipoker/server/internal/httpapi"
	"github.com/oxisoft/oxipoker/server/internal/media"
	"github.com/oxisoft/oxipoker/server/internal/realtime"
	"github.com/oxisoft/oxipoker/server/internal/secret"
	"github.com/oxisoft/oxipoker/server/internal/store"
	"github.com/oxisoft/oxipoker/server/internal/table"
	"github.com/oxisoft/oxipoker/server/internal/tablestore"
	"github.com/oxisoft/oxipoker/server/internal/version"
)

func main() {
	healthcheck := flag.Bool("healthcheck", false, "probe the local server and exit 0 when healthy (used by the Docker HEALTHCHECK)")
	showVersion := flag.Bool("version", false, "print the version and exit")
	backup := flag.String("backup", "", "write a consistent copy of the database to this file while the server keeps running, then exit")
	flag.Parse()

	port := env("PORT", "8080")
	if p, err := strconv.Atoi(port); err != nil || p < 1 || p > 65535 {
		fmt.Fprintf(os.Stderr, "invalid PORT %q\n", port)
		os.Exit(2)
	}

	switch {
	case *showVersion:
		fmt.Println(version.Version)
		return
	case *healthcheck:
		os.Exit(probe(port))
	case *backup != "":
		os.Exit(runBackup(env("DATA_DIR", "data"), *backup))
	}

	log := slog.New(slog.NewTextHandler(os.Stdout, nil))
	livekit := media.Config{URL: os.Getenv("LIVEKIT_URL"), Key: os.Getenv("LIVEKIT_API_KEY"), Secret: os.Getenv("LIVEKIT_API_SECRET")}
	if err := livekit.Check(); err != nil {
		log.Error("livekit", "err", err)
		os.Exit(2)
	}
	mediaOn := livekit.Enabled()
	dataDir := env("DATA_DIR", "data")

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	// The secret is loaded before the database so a broken SERVER_SECRET
	// fails the start without touching the data volume.
	sec, src, err := secret.Load(dataDir, os.Getenv("SERVER_SECRET"))
	if err != nil {
		log.Error("server secret", "err", err)
		os.Exit(1)
	}
	log.Info("server secret loaded", "source", string(src))

	st, err := store.Open(ctx, dataDir)
	if err != nil {
		log.Error("database", "err", err)
		os.Exit(1)
	}
	defer st.Close()
	schema, _ := st.SchemaVersion(ctx)
	log.Info("database ready", "dir", dataDir, "schema", schema)

	acc := accounts.New(st)
	acc.SetTOTPKey(sec.Key("totp"))
	if err := acc.Bootstrap(ctx, os.Getenv("ADMIN_USERNAME"), os.Getenv("ADMIN_PASSWORD"), log); err != nil {
		log.Error("bootstrap admin", "err", err)
		os.Exit(1)
	}
	go purgeSessions(ctx, acc, log)

	publicURL := os.Getenv("PUBLIC_URL")
	if publicURL == "" {
		log.Warn("PUBLIC_URL is not set: Origin is checked against the request host, cookies are not Secure, passkeys are off")
	}
	apps, err := applinks.Parse(os.Getenv("ANDROID_APPS"))
	if err != nil {
		log.Error("android apps", "err", err)
		os.Exit(1)
	}
	var passkeys *accounts.Passkeys
	if u, perr := url.Parse(publicURL); perr == nil && net.ParseIP(u.Hostname()) != nil {
		// WebAuthn needs a domain name: a LAN server reached by IP signs in with passwords.
		log.Warn("PUBLIC_URL is an IP address: passkeys are off (they need a domain name)")
	} else if publicURL != "" {
		if passkeys, err = accounts.NewPasskeys(acc, publicURL, applinks.Origins(apps)...); err != nil {
			log.Error("passkeys", "err", err)
			os.Exit(1)
		}
	}

	hub := realtime.NewHub()
	if mediaOn {
		rooms, err := media.NewRooms(livekit)
		if err != nil {
			log.Error("livekit", "err", err)
			os.Exit(2)
		}
		hub.CallErr = func(err error) { log.Warn("call moderation", "err", err) }
		hub.SetCalls(rooms)
	}
	// The history and table writers outlive the signal context: on shutdown
	// they are closed in order after the tables have stopped.
	hist := history.New(context.Background(), st.DB(), log)
	saves := tablestore.New(st.DB(), log)
	tables := table.NewManager(30*time.Minute, func(id string) table.Options {
		o := hub.TableOptions(id)
		o.OnHandDone = hist.Record
		o.OnGameDone = hist.RecordGame
		o.OnSave = saves.Save
		return o
	})
	saved, err := saves.Load(ctx)
	if err != nil {
		log.Error("load open tables", "err", err)
		os.Exit(1)
	}
	n, errs := tables.Restore(saved)
	for _, e := range errs {
		log.Warn("table not restored", "err", e)
	}
	log.Info("open tables restored", "count", n)

	srv := &http.Server{
		Addr: net.JoinHostPort("", port),
		Handler: httpapi.NewRouter(httpapi.Options{Media: mediaOn, LiveKit: livekit, Store: st, Secret: sec,
			Accounts: acc, Passkeys: passkeys, PublicURL: publicURL, AndroidApps: apps,
			Tables: tables, Hub: hub, History: hist}),
		ReadHeaderTimeout: 10 * time.Second,
		IdleTimeout:       120 * time.Second,
	}

	go func() {
		log.Info("oxipoker listening", "version", version.Version, "port", port, "media", mediaOn)
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Error("server stopped", "err", err)
			os.Exit(1)
		}
	}()

	<-ctx.Done()
	// Graceful restart: no new hand starts, a running hand is voided (its
	// stacks go back to the hand start), the tables are stored and the
	// clients are told; apps reconnect and watch again on their own.
	log.Info("shutting down")
	tables.Shutdown()
	hub.Restarting(2 * time.Second)
	shutdownCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := srv.Shutdown(shutdownCtx); err != nil {
		log.Error("shutdown", "err", err)
	}
	saves.Close()
	hist.Close()
	log.Info("tables stored, bye")
}

func purgeSessions(ctx context.Context, acc *accounts.Service, log *slog.Logger) {
	t := time.NewTicker(6 * time.Hour)
	defer t.Stop()
	for {
		if n, err := acc.PurgeExpiredSessions(ctx); err != nil && ctx.Err() == nil {
			log.Warn("purge sessions", "err", err)
		} else if n > 0 {
			log.Info("expired sessions purged", "count", n)
		}
		select {
		case <-ctx.Done():
			return
		case <-t.C:
		}
	}
}

func probe(port string) int {
	c := http.Client{Timeout: 3 * time.Second}
	res, err := c.Get("http://127.0.0.1:" + port + "/api/v1/health")
	if err != nil {
		return 1
	}
	res.Body.Close()
	if res.StatusCode != http.StatusOK {
		return 1
	}
	return 0
}

func env(key, def string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return def
}

// runBackup copies the database of dataDir to dst and prints where it went.
// It opens the same database file as the running server; SQLite's locking
// keeps both processes consistent.
func runBackup(dataDir, dst string) int {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Minute)
	defer cancel()
	if _, err := os.Stat(filepath.Join(dataDir, store.FileName)); err != nil {
		fmt.Fprintf(os.Stderr, "backup: no database in %s: %v\n", dataDir, err)
		return 1
	}
	st, err := store.Open(ctx, dataDir)
	if err != nil {
		fmt.Fprintf(os.Stderr, "backup: %v\n", err)
		return 1
	}
	defer st.Close()
	if err := st.Backup(ctx, dst); err != nil {
		fmt.Fprintf(os.Stderr, "backup: %v\n", err)
		return 1
	}
	fmt.Println(dst)
	return 0
}
