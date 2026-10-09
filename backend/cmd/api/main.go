// Command api is the Community Scam Shield HTTP service entrypoint.
package main

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"scamshield/internal/auth"
	"scamshield/internal/checks"
	"scamshield/internal/config"
	"scamshield/internal/httpx"
	"scamshield/internal/moderation"
	"scamshield/internal/platform/db"
	"scamshield/internal/reports"
	"scamshield/internal/resources"

	"github.com/jackc/pgx/v5/pgxpool"
)

// Build metadata, injected at link time via -ldflags "-X main.version=..." by
// build_linux.sh. Defaults apply for `go run` / plain `go build`.
var (
	version   = "dev"
	commit    = "none"
	buildTime = "unknown"
)

func main() {
	logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelInfo}))
	slog.SetDefault(logger)

	logger.Info("starting scamshield api", "version", version, "commit", commit, "build_time", buildTime)

	if err := run(logger); err != nil {
		logger.Error("service exited with error", "error", err)
		os.Exit(1)
	}
}

func run(logger *slog.Logger) error {
	cfg, err := config.Load()
	if err != nil {
		return err
	}

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	pool, err := db.Connect(ctx, cfg.DatabaseURL)
	if err != nil {
		return err
	}
	defer pool.Close()
	logger.Info("connected to database")

	tokens := auth.NewTokenService(cfg.JWTSecret, cfg.AccessTokenTTL)
	authRepo := auth.NewPostgresRepository(pool)
	authSvc := auth.NewService(authRepo, tokens, auth.Config{
		BcryptCost:      cfg.BcryptCost,
		RefreshTokenTTL: cfg.RefreshTokenTTL,
	})
	authHandler := auth.NewHandler(authSvc, tokens)

	// Domain services and handlers.
	checksRepo := checks.NewPostgresRepository(pool)
	checksHandler := checks.NewHandler(checks.NewService(checksRepo, checksRepo))
	reportsHandler := reports.NewHandler(reports.NewService(reports.NewPostgresRepository(pool)))
	moderationHandler := moderation.NewHandler(moderation.NewService(moderation.NewPostgresRepository(pool)))
	resourcesHandler := resources.NewHandler(resources.NewService(resources.NewPostgresRepository(pool)))

	rateLimiter := httpx.NewRateLimiter(20, 40, nil)
	defer rateLimiter.Close()

	globalMW := httpx.Chain(
		httpx.RequestID,
		httpx.Logging(logger),
		httpx.Recoverer(logger),
		rateLimiter.Middleware,
	)

	// Reusable auth middleware chains.
	requireAuth := auth.RequireAuth(tokens)
	optionalAuth := auth.OptionalAuth(tokens)
	requireModerator := httpx.Chain(auth.RequireAuth(tokens), auth.RequireRole(auth.RoleModerator, auth.RoleAdmin))
	requireAdmin := httpx.Chain(auth.RequireAuth(tokens), auth.RequireRole(auth.RoleAdmin))

	mux := http.NewServeMux()
	authHandler.RegisterRoutes(mux, globalMW)
	checksHandler.RegisterRoutes(mux, requireAuth, optionalAuth, globalMW)
	reportsHandler.RegisterRoutes(mux, requireAuth, optionalAuth, globalMW)
	moderationHandler.RegisterRoutes(mux, requireAuth, optionalAuth, requireModerator, globalMW)
	resourcesHandler.RegisterRoutes(mux, optionalAuth, requireAdmin, globalMW)
	registerHealthRoutes(mux, globalMW, pool)

	srv := &http.Server{
		Addr:              cfg.HTTPAddr,
		Handler:           mux,
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       15 * time.Second,
		WriteTimeout:      15 * time.Second,
		IdleTimeout:       60 * time.Second,
	}

	serverErr := make(chan error, 1)
	go func() {
		logger.Info("http server listening", "addr", cfg.HTTPAddr, "env", cfg.Environment)
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			serverErr <- err
		}
	}()

	select {
	case err := <-serverErr:
		return err
	case <-ctx.Done():
		logger.Info("shutdown signal received")
	}

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := srv.Shutdown(shutdownCtx); err != nil {
		return err
	}
	logger.Info("server stopped cleanly")
	return nil
}

func registerHealthRoutes(mux *http.ServeMux, mw httpx.Middleware, pool *pgxpool.Pool) {
	live := func(w http.ResponseWriter, r *http.Request) {
		httpx.WriteJSON(w, http.StatusOK, map[string]string{"status": "ok"})
	}
	ready := func(w http.ResponseWriter, r *http.Request) {
		pingCtx, cancel := context.WithTimeout(r.Context(), 2*time.Second)
		defer cancel()
		if err := db.Ping(pingCtx, pool); err != nil {
			httpx.WriteError(w, r, http.StatusServiceUnavailable, "not_ready", "database unavailable")
			return
		}
		httpx.WriteJSON(w, http.StatusOK, map[string]string{"status": "ready"})
	}
	mux.Handle("GET /api/v1/health/live", mw(http.HandlerFunc(live)))
	mux.Handle("GET /api/v1/health/ready", mw(http.HandlerFunc(ready)))
}
