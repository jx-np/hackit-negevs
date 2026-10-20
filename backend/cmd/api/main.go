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
	"scamshield/internal/grok"
	"scamshield/internal/httpx"
	"scamshield/internal/logging"
	"scamshield/internal/moderation"
	"scamshield/internal/news"
	"scamshield/internal/pii"
	"scamshield/internal/platform/db"
	"scamshield/internal/reports"
	"scamshield/internal/resources"
	"scamshield/internal/sse"
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
	// fails screenshot checks cleanly. The same AI service also powers scam
	// classification (see detectionClassifier below).
	var redactor pii.Redactor = pii.NewStub()
	if cfg.PIIServiceURL != "" {
		redactor = pii.NewClient(cfg.PIIServiceURL)
		logger.Info("pii redaction service configured", "url", cfg.PIIServiceURL)
	} else {
		logger.Warn("pii redaction service not configured; screenshot checks will fail until PII_SERVICE_URL is set")
	}

	// Scam-assessment classifier for private text detection. It is the same AI
	// service that performs PII redaction, so it reuses PII_SERVICE_URL. A
	// bounded queue (DefaultClassifierWorkers) caps how many classifications are
	// in flight at once and retries transient failures (DefaultClassifierRetries).
	var detectionClassifier checks.Classifier
	if cfg.PIIServiceURL != "" {
		detectionClassifier = checks.NewClassifierPool(
			checks.NewHTTPClassifier(cfg.PIIServiceURL),
			checks.DefaultClassifierWorkers,
			checks.DefaultClassifierRetries,
		)
		logger.Info("scam classification service configured",
			"url", cfg.PIIServiceURL,
			"workers", checks.DefaultClassifierWorkers,
			"retries", checks.DefaultClassifierRetries,
		)
	} else {
		logger.Warn("scam classification service not configured; text detection will fail until PII_SERVICE_URL is set")
	}

	// Domain services and handlers.
	checksRepo := checks.NewPostgresRepository(pool)
	checksSvc := checks.NewService(checksRepo, checksRepo, store, redactor, detectionClassifier)
	checksHandler := checks.NewHandler(checksSvc)
	// The scam classifier assigns each post's category and tags on publish. When
	// the AI service is configured it supplies both; otherwise the stub keeps
	// posts classified during local development.
	var postClassifier classifier.Classifier = classifier.NewStub()
	if cfg.PIIServiceURL != "" {
		postClassifier = classifier.NewHTTPClassifier(cfg.PIIServiceURL, cfg.TagConfidenceThreshold)
		logger.Info("community post classification configured",
			"url", cfg.PIIServiceURL,
			"tag_threshold", cfg.TagConfidenceThreshold,
		)
	}
	reportsHandler := reports.NewHandler(reports.NewService(reports.NewPostgresRepository(pool), postClassifier, store))
	moderationSvc := moderation.NewService(moderation.NewPostgresRepository(pool))
	moderationHandler := moderation.NewHandler(moderationSvc)
	resourcesHandler := resources.NewHandler(resources.NewService(resources.NewPostgresRepository(pool)))
	newsHandler := news.NewHandler(news.NewService(news.NewPostgresRepository(pool)))

	// In-memory SSE hub for per-post discussion and @help progress events. It
	// is single-process; a multi-instance deployment would put Redis pub/sub or
	// Postgres LISTEN/NOTIFY in front of it. BaseContext is the signal context
	// so every stream returns on shutdown instead of holding Shutdown open.
	streamHub := sse.NewHub()
	sseHandler := sse.NewHandler(
		sse.NewService(sse.NewPostgresRepository(pool)),
		streamHub,
		sse.HandlerOptions{Logger: logger, BaseContext: ctx},
	)

	// Comment observers are fanned out through a composite: the SSE hub is
	// always registered, and the @help bot is added when an LLM key is
	// configured. Observers must not block.
	observers := []moderation.CommentObserver{sse.NewCommentObserver(streamHub)}
	if cfg.GrokEnabled() {
		observers = append(observers, grok.New(ctx, pool, store, grok.Config{
			BaseURL:       cfg.LLMBaseURL,
			APIKey:        cfg.LLMAPIKey,
			Model:         cfg.LLMModel,
			Timeout:       cfg.LLMTimeout,
			MaxConcurrent: cfg.GrokMaxConcurrent,
		}, logger, sse.NewGrokPublisher(streamHub)))
		logger.Info("@help comment bot enabled",
			"base_url", cfg.LLMBaseURL,
			"model", cfg.LLMModel,
			"timeout", cfg.LLMTimeout,
			"max_concurrent", cfg.GrokMaxConcurrent,
		)
	} else {
		logger.Warn("@help comment bot disabled; set LLM_API_KEY to enable @help replies")
	}
	moderationSvc.SetCommentObserver(moderation.NewCommentObserverGroup(observers...))

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
	newsHandler.RegisterRoutes(mux, optionalAuth, globalMW)
	sseHandler.RegisterRoutes(mux, optionalAuth, globalMW)
	registerHealthRoutes(mux, globalMW, pool)

	// Background retention reaper: enforces the private_uploads (24h) and
	// private_checks (30d) expiry windows by deleting expired rows and purging
	// their stored blobs. It runs on the signal context, so it stops on
	// shutdown. Set REAPER_ENABLED=false to disable.
	if cfg.ReaperEnabled {
		go checks.NewReaper(checksSvc, cfg.ReaperInterval, logger).Run(ctx)
		logger.Info("retention reaper started", "interval", cfg.ReaperInterval)
	} else {
		logger.Warn("retention reaper disabled; expired detection data will accumulate")
	}

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
	// Close open SSE streams first: http.Server.Shutdown waits for active
	// handlers, and a long-lived stream would otherwise hold it open until the
	// deadline. The handler base context is also already cancelled here.
	streamHub.Close()
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
