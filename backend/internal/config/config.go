// Package config loads runtime configuration from environment variables with
// sane development defaults.
package config

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"
)

// Config holds all runtime configuration for the API service.
type Config struct {
	HTTPAddr        string
	DatabaseURL     string
	JWTSecret       string
	AccessTokenTTL  time.Duration
	RefreshTokenTTL time.Duration
	BcryptCost      int
	Environment     string
	// Production enables machine-readable (JSON) logging. When false the
	// service logs in the human-readable console format. Driven by the
	// PRODUCTION environment variable.
	Production bool
	// StorageDir is the root directory for the local blob store that holds
	// uploaded screenshots and their redacted derivatives. Driven by
	// STORAGE_DIR.
	StorageDir string
	// PIIServiceURL is the base URL of the Python AI service, which hosts both
	// PII redaction (POST /v1/redact) for screenshot uploads and scam
	// classification (POST /v1/classify) for text detection. When empty the
	// service falls back to a stub redactor (screenshot checks fail cleanly)
	// and has no classifier (text detection fails), since the local rules
	// analyzer was removed. Driven by PII_SERVICE_URL.
	PIIServiceURL string
	// TagConfidenceThreshold is the minimum model probability for a predicted
	// community-post tag to be attached to a post. Predicted tags scored below
	// it are dropped. Driven by TAG_CONFIDENCE_THRESHOLD; defaults to 0.30.
	TagConfidenceThreshold float64
	// ReaperEnabled turns on the background retention reaper that deletes
	// expired private checks/uploads (and their blobs). Driven by
	// REAPER_ENABLED; defaults to true.
	ReaperEnabled bool
	// ReaperInterval is how often the retention reaper runs. Driven by
	// REAPER_INTERVAL; defaults to one hour.
	ReaperInterval time.Duration
	// LLMBaseURL is the base URL of the OpenAI-compatible LLM gateway used by
	// the @help comment bot. Driven by LLM_BASE_URL; defaults to
	// https://litellm.chimmy.xyz/v1.
	LLMBaseURL string
	// LLMAPIKey is the API key for the LLM gateway. The @help bot is enabled
	// only when this is set. Driven by LLM_API_KEY; defaults to empty.
	LLMAPIKey string
	// LLMModel is the model the @help bot asks for. Driven by LLM_MODEL;
	// defaults to deepseek-v4.1-flash.
	LLMModel string
	// LLMTimeout is the timeout for a single LLM request. Driven by LLM_TIMEOUT;
	// defaults to 5m (the model is a slow reasoning model).
	LLMTimeout time.Duration
	// GrokMaxConcurrent is the maximum number of @help LLM jobs running at the
	// same time. Driven by GROK_MAX_CONCURRENT; defaults to 32. Values below 1
	// are rejected.
	GrokMaxConcurrent int
}

// IsDevelopment reports whether the service is running in the development
// environment.
func (c Config) IsDevelopment() bool {
	return c.Environment == "development"
}

// GrokEnabled reports whether the @help comment bot is enabled. It requires an
// API key for the LLM gateway; without one the bot is not wired up and an
// "@help" mention is just ordinary comment text.
func (c Config) GrokEnabled() bool {
	return strings.TrimSpace(c.LLMAPIKey) != ""
}

// Defaults for the LLM gateway used by the @help comment bot.
const (
	defaultLLMBaseURL        = "https://litellm.chimmy.xyz/v1"
	defaultLLMModel          = "deepseek-v4.1-flash"
	defaultLLMTimeout        = 5 * time.Minute
	defaultGrokMaxConcurrent = 32
)

// Load reads configuration from the environment, applying defaults, and
// validates it. It first attempts to load a .env file from the working
// directory so local development "just works" without exporting vars manually.
func Load() (Config, error) {
	loadDotEnv() // best-effort; missing .env is fine
	cfg := Config{
		HTTPAddr:    getEnv("HTTP_ADDR", ":8080"),
		DatabaseURL: getEnv("DATABASE_URL", "postgres://postgres:postgres@localhost:5432/scamshield?sslmode=disable"),
		JWTSecret:   getEnv("JWT_SECRET", "dev-insecure-secret-change-me"),
		Environment: getEnv("APP_ENV", "development"),
		Production:  getEnvBool("PRODUCTION", false),

		StorageDir:    getEnv("STORAGE_DIR", "./data/uploads"),
		PIIServiceURL: getEnv("PII_SERVICE_URL", ""),
		ReaperEnabled: getEnvBool("REAPER_ENABLED", true),
	}

	reaperInterval, err := getEnvDuration("REAPER_INTERVAL", time.Hour)
	if err != nil {
		return Config{}, err
	}
	cfg.ReaperInterval = reaperInterval

	tagThreshold, err := getEnvFloat("TAG_CONFIDENCE_THRESHOLD", 0.30)
	if err != nil {
		return Config{}, err
	}
	cfg.TagConfidenceThreshold = tagThreshold

	accessTTL, err := getEnvDuration("ACCESS_TOKEN_TTL", 15*time.Minute)
	if err != nil {
		return Config{}, err
	}
	cfg.AccessTokenTTL = accessTTL

	refreshTTL, err := getEnvDuration("REFRESH_TOKEN_TTL", 720*time.Hour)
	if err != nil {
		return Config{}, err
	}
	cfg.RefreshTokenTTL = refreshTTL

	bcryptCost, err := getEnvInt("BCRYPT_COST", 12)
	if err != nil {
		return Config{}, err
	}
	cfg.BcryptCost = bcryptCost

	// LLM gateway settings for the @help comment bot.
	cfg.LLMBaseURL = getEnv("LLM_BASE_URL", defaultLLMBaseURL)
	cfg.LLMAPIKey = getEnv("LLM_API_KEY", "")
	cfg.LLMModel = getEnv("LLM_MODEL", defaultLLMModel)

	llmTimeout, err := getEnvDuration("LLM_TIMEOUT", defaultLLMTimeout)
	if err != nil {
		return Config{}, err
	}
	cfg.LLMTimeout = llmTimeout

	grokMaxConcurrent, err := getEnvInt("GROK_MAX_CONCURRENT", defaultGrokMaxConcurrent)
	if err != nil {
		return Config{}, err
	}
	cfg.GrokMaxConcurrent = grokMaxConcurrent

	if err := cfg.validate(); err != nil {
		return Config{}, err
	}

	return cfg, nil
}

func (c Config) validate() error {
	if !c.IsDevelopment() && c.JWTSecret == "" {
		return fmt.Errorf("config: JWT_SECRET must be set in non-development environments")
	}
	if c.GrokMaxConcurrent < 1 {
		return fmt.Errorf("config: GROK_MAX_CONCURRENT must be at least 1, got %d", c.GrokMaxConcurrent)
	}
	return nil
}

func getEnv(key, fallback string) string {
	if v, ok := os.LookupEnv(key); ok && v != "" {
		return v
	}
	return fallback
}

func getEnvDuration(key string, fallback time.Duration) (time.Duration, error) {
	v, ok := os.LookupEnv(key)
	if !ok || v == "" {
		return fallback, nil
	}
	d, err := time.ParseDuration(v)
	if err != nil {
		return 0, fmt.Errorf("config: invalid duration for %s: %w", key, err)
	}
	return d, nil
}

func getEnvBool(key string, fallback bool) bool {
	v, ok := os.LookupEnv(key)
	if !ok || v == "" {
		return fallback
	}
	b, err := strconv.ParseBool(strings.TrimSpace(v))
	if err != nil {
		return fallback
	}
	return b
}

func getEnvInt(key string, fallback int) (int, error) {
	v, ok := os.LookupEnv(key)
	if !ok || v == "" {
		return fallback, nil
	}
	n, err := strconv.Atoi(v)
	if err != nil {
		return 0, fmt.Errorf("config: invalid int for %s: %w", key, err)
	}
	return n, nil
}

func getEnvFloat(key string, fallback float64) (float64, error) {
	v, ok := os.LookupEnv(key)
	if !ok || v == "" {
		return fallback, nil
	}
	f, err := strconv.ParseFloat(strings.TrimSpace(v), 64)
	if err != nil {
		return 0, fmt.Errorf("config: invalid float for %s: %w", key, err)
	}
	return f, nil
}

// loadDotEnv reads KEY=VALUE pairs from a .env file in the working directory
// and sets any that are not already present in the environment. It is a
// best-effort convenience for local development: a missing file is ignored, and
// real environment variables always take precedence over the file.
//
// Supported syntax: blank lines and lines beginning with '#' are skipped; an
// optional leading "export " is stripped; surrounding single or double quotes
// around the value are removed. It intentionally does not expand variables.
func loadDotEnv() {
	f, err := os.Open(".env")
	if err != nil {
		return
	}
	defer f.Close()

	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		line = strings.TrimPrefix(line, "export ")

		key, value, ok := strings.Cut(line, "=")
		if !ok {
			continue
		}
		key = strings.TrimSpace(key)
		value = strings.TrimSpace(value)
		if len(value) >= 2 {
			if (value[0] == '"' && value[len(value)-1] == '"') ||
				(value[0] == '\'' && value[len(value)-1] == '\'') {
				value = value[1 : len(value)-1]
			}
		}
		if key == "" {
			continue
		}
		// Real environment variables win over the file.
		if _, exists := os.LookupEnv(key); !exists {
			_ = os.Setenv(key, value)
		}
	}
}
