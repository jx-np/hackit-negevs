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
	"scamshield/internal/classifier"
	"scamshield/internal/config"
	"scamshield/internal/httpx"
	"scamshield/internal/logging"
	"scamshield/internal/moderation"
	"scamshield/internal/pii"
	"scamshield/internal/platform/db"
	"scamshield/internal/reports"
	"scamshield/internal/resources"
	"scamshield/internal/storage"
	"scamshield/migrations"

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
	// Configuration is loaded first so the log format can follow PRODUCTION.
	// A failure here happens before the service exists, so it is reported with a
	// best-effort logger and the process exits.
	cfg, err := config.Load()
	if err != nil {
		logging.New(os.Stdout, logging.Production()).Error("invalid configuration", "error", err)
		os.Exit(1)
	}

	logger := logging.New(os.Stdout, cfg.Production)
	slog.SetDefault(logger)

	logger.Info("starting scamshield api",
		"version", version, "commit", commit, "build_time", buildTime,
		"env", cfg.Environment, "addr", cfg.HTTPAddr,
	)

	if err := run(cfg, logger); err != nil {
		logger.Error("service exited with error", "error", err)
		os.Exit(1)
	}
}

func run(cfg config.Config, logger *slog.Logger) error {
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	pool, err := db.Connect(ctx, cfg.DatabaseURL)
	if err != nil {
		return err
	}
	defer pool.Close()
	logger.Info("connected to database")

	// Apply any pending schema migrations before serving. The runner is a no-op
	// when the database is already at the latest embedded version, so this is
	// safe to run on every startup. A failure here means the schema is stale or
	// broken, so the service refuses to start rather than serve against it.
	applied, err := migrations.Up(ctx, pool)
	if err != nil {
		return err
	}
	if applied > 0 {
		logger.Info("applied database migrations", "count", applied)
	} else {
		logger.Info("database schema up to date")
	}

	tokens := auth.NewTokenService(cfg.JWTSecret, cfg.AccessTokenTTL)
	authRepo := auth.NewPostgresRepository(pool)
	authSvc := auth.NewService(authRepo, tokens, auth.Config{
		BcryptCost:      cfg.BcryptCost,
		RefreshTokenTTL: cfg.RefreshTokenTTL,
	})
	authHandler := auth.NewHandler(authSvc, tokens)

	// Local blob store for uploaded screenshots and their redacted
	// derivatives. Shared by the checks (private detection) and reports
	// (community posts) domains so a post can carry its own copy of a check's
	// redacted image.
	store, err := storage.NewLocalStore(cfg.StorageDir)
	if err != nil {
		return err
	}
	logger.Info("blob storage ready", "dir", cfg.StorageDir)

	// PII-removal redactor for screenshot uploads. When PII_SERVICE_URL is set
	// the Python service is called over HTTP; otherwise a stub is used that
	// fails screenshot checks cleanly (text detection is unaffected).
	var redactor pii.Redactor = pii.NewStub()
	if cfg.PIIServiceURL != "" {
		redactor = pii.NewClient(cfg.PIIServiceURL)
		logger.Info("pii redaction service configured", "url", cfg.PIIServiceURL)
	} else {
		logger.Warn("pii redaction service not configured; screenshot checks will fail until PII_SERVICE_URL is set")
	}

	// Domain services and handlers.
	checksRepo := checks.NewPostgresRepository(pool)
	checksHandler := checks.NewHandler(checks.NewService(checksRepo, checksRepo, store, redactor))
	// The scam classifier assigns each post's category on publish. Swap the
	// stub for the decision-model client once that service exists.
	postClassifier := classifier.NewStub()
	reportsHandler := reports.NewHandler(reports.NewService(reports.NewPostgresRepository(pool), postClassifier, store))
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
		// Generous read/write windows so multipart screenshot uploads (up to
		// ~10 MiB) have time to stream in and the redacted image to stream out
		// over slower mobile connections.
		ReadTimeout:  60 * time.Second,
		WriteTimeout: 60 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	serverErr := make(chan error, 1)
	go func() {
		logger.Info("http server listening", "addr", cfg.HTTPAddr, "env", cfg.Environment, "log_format", logFormat(cfg))
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

// logFormat names the active log format, so startup output makes it obvious
// which one is in use.
func logFormat(cfg config.Config) string {
	if cfg.Production {
		return "json"
	}
	return "console"
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
