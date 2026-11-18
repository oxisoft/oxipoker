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
	"os"
	"os/signal"
	"strconv"
	"syscall"
	"time"

	"github.com/oxisoft/oxipoker/server/internal/accounts"
	"github.com/oxisoft/oxipoker/server/internal/httpapi"
	"github.com/oxisoft/oxipoker/server/internal/secret"
	"github.com/oxisoft/oxipoker/server/internal/store"
	"github.com/oxisoft/oxipoker/server/internal/version"
)

func main() {
	healthcheck := flag.Bool("healthcheck", false, "probe the local server and exit 0 when healthy (used by the Docker HEALTHCHECK)")
	showVersion := flag.Bool("version", false, "print the version and exit")
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
	}

	log := slog.New(slog.NewTextHandler(os.Stdout, nil))
	media := os.Getenv("LIVEKIT_URL") != ""
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
	if err := acc.Bootstrap(ctx, os.Getenv("ADMIN_USERNAME"), os.Getenv("ADMIN_PASSWORD"), log); err != nil {
		log.Error("bootstrap admin", "err", err)
		os.Exit(1)
	}
	go purgeSessions(ctx, acc, log)

	publicURL := os.Getenv("PUBLIC_URL")
	if publicURL == "" {
		log.Warn("PUBLIC_URL is not set: Origin is checked against the request host and cookies are not Secure")
	}

	srv := &http.Server{
		Addr: net.JoinHostPort("", port),
		Handler: httpapi.NewRouter(httpapi.Options{Media: media, Store: st, Secret: sec,
			Accounts: acc, PublicURL: publicURL}),
		ReadHeaderTimeout: 10 * time.Second,
		IdleTimeout:       120 * time.Second,
	}

	go func() {
		log.Info("oxipoker listening", "version", version.Version, "port", port, "media", media)
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Error("server stopped", "err", err)
			os.Exit(1)
		}
	}()

	<-ctx.Done()
	shutdownCtx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()
	if err := srv.Shutdown(shutdownCtx); err != nil {
		log.Error("shutdown", "err", err)
	}
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
