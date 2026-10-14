// Package config loads process configuration from environment variables.
package config

import (
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"
)

// Config holds all runtime settings. Every field maps to one env var so that
// dev, staging (NAS) and production (Hetzner) differ only in their .env file.
type Config struct {
	Env             string // dev | staging | prod
	HTTPAddr        string
	DatabaseURL     string
	LogLevel        string
	LogFormat       string // text | json
	TemporalAddress string // empty = Temporal disabled
	TemporalNS      string
	CentrifugoURL   string
	CentrifugoKey   string
	VisionURL       string
	LLMBaseURL      string // empty = AI mock mode
	LLMModel        string
	EmbeddingsModel string
	OTLPEndpoint    string // empty = tracing to stdout disabled
	ShutdownTimeout time.Duration
	CORSOrigins     []string
	TrustedProxies  []string // CIDRs of reverse proxies allowed to set X-Forwarded-For
}

// Load reads the environment. It returns an error only for values that are
// present but malformed; missing optional values fall back to dev defaults.
func Load() (Config, error) {
	c := Config{
		Env:             get("APP_ENV", "dev"),
		HTTPAddr:        get("HTTP_ADDR", ":8080"),
		DatabaseURL:     get("DATABASE_URL", "postgres://terra:terra@localhost:5433/terra?sslmode=disable"),
		LogLevel:        get("LOG_LEVEL", "info"),
		LogFormat:       get("LOG_FORMAT", "text"),
		TemporalAddress: get("TEMPORAL_ADDRESS", ""),
		TemporalNS:      get("TEMPORAL_NAMESPACE", "default"),
		CentrifugoURL:   get("CENTRIFUGO_API_URL", ""),
		CentrifugoKey:   get("CENTRIFUGO_API_KEY", ""),
		VisionURL:       get("VISION_URL", ""),
		LLMBaseURL:      get("LLM_BASE_URL", ""),
		LLMModel:        get("LLM_MODEL", "terra"),
		EmbeddingsModel: get("EMBEDDINGS_MODEL", "terra-embed"),
		OTLPEndpoint:    get("OTEL_EXPORTER_OTLP_ENDPOINT", ""),
		CORSOrigins:     splitList(get("CORS_ORIGINS", "http://localhost:5173,http://localhost:4321")),
		TrustedProxies:  splitList(get("TRUSTED_PROXIES", "127.0.0.1,::1")),
	}
	d, err := time.ParseDuration(get("SHUTDOWN_TIMEOUT", "15s"))
	if err != nil {
		return c, fmt.Errorf("SHUTDOWN_TIMEOUT: %w", err)
	}
	c.ShutdownTimeout = d
	if c.Env != "dev" && c.Env != "staging" && c.Env != "prod" && c.Env != "test" {
		return c, fmt.Errorf("APP_ENV must be dev|staging|prod|test, got %q", c.Env)
	}
	return c, nil
}

// MustBool parses a boolean env var with a default.
func MustBool(key string, def bool) bool {
	v, ok := os.LookupEnv(key)
	if !ok {
		return def
	}
	b, err := strconv.ParseBool(v)
	if err != nil {
		return def
	}
	return b
}

func get(key, def string) string {
	if v, ok := os.LookupEnv(key); ok && v != "" {
		return v
	}
	return def
}

func splitList(s string) []string {
	var out []string
	for _, p := range strings.Split(s, ",") {
		if p = strings.TrimSpace(p); p != "" {
			out = append(out, p)
		}
	}
	return out
}
