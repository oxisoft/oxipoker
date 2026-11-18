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

	"github.com/oxisoft/oxipoker/server/internal/httpapi"
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

	srv := &http.Server{
		Addr:              net.JoinHostPort("", port),
		Handler:           httpapi.NewRouter(httpapi.Options{Media: media}),
		ReadHeaderTimeout: 10 * time.Second,
		IdleTimeout:       120 * time.Second,
	}

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

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
