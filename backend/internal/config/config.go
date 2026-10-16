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
	// PIIServiceURL is the base URL of the Python PII-removal service used to
	// redact screenshot uploads. When empty the service falls back to a stub
	// redactor that fails screenshot checks cleanly (text detection is
	// unaffected). Driven by PII_SERVICE_URL.
	PIIServiceURL string
}

// IsDevelopment reports whether the service is running in the development
// environment.
func (c Config) IsDevelopment() bool {
	return c.Environment == "development"
}

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
	}

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

	if err := cfg.validate(); err != nil {
		return Config{}, err
	}

	return cfg, nil
}

func (c Config) validate() error {
	if !c.IsDevelopment() && c.JWTSecret == "" {
		return fmt.Errorf("config: JWT_SECRET must be set in non-development environments")
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
