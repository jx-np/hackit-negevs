package logging

import (
	"bytes"
	"context"
	"log/slog"
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestProductionReadsEnv(t *testing.T) {
	t.Setenv("PRODUCTION", "")
	assert.False(t, Production(), "unset means human-readable logs")

	for _, v := range []string{"true", "TRUE", "1", "yes", "on"} {
		t.Setenv("PRODUCTION", v)
		assert.True(t, Production(), "PRODUCTION=%s should enable JSON logging", v)
	}

	for _, v := range []string{"false", "0", "no", "off", "", "banana"} {
		t.Setenv("PRODUCTION", v)
		assert.False(t, Production(), "PRODUCTION=%s should not enable JSON logging", v)
	}
}

func TestNewProductionEmitsJSON(t *testing.T) {
	var buf bytes.Buffer
	log := New(&buf, true)

	log.Info("connected to database", "count", 1)
	log.Warn("slow request", "duration", 1500*time.Millisecond)

	lines := strings.Split(strings.TrimSpace(buf.String()), "\n")
	require.Len(t, lines, 2)
	for _, line := range lines {
		assert.True(t, strings.HasPrefix(line, "{"), "expected JSON line, got %q", line)
		assert.Contains(t, line, `"level":"`)
	}
	assert.Contains(t, lines[0], `"msg":"connected to database"`)
	assert.Contains(t, lines[0], `"count":1`)
	assert.Contains(t, lines[1], `"level":"WARN"`)
}

func TestPrettyHandlerRendersSingleLine(t *testing.T) {
	var buf bytes.Buffer
	log := New(&buf, false)

	log.Info("connected to database")
	log.Warn("database schema up to date", "count", 1)

	out := buf.String()
	require.Len(t, strings.Split(strings.TrimSpace(out), "\n"), 2, "one line per record")
	assert.NotContains(t, out, "\x1b[", "colour must be off for non-terminal writers")

	lines := strings.Split(strings.TrimSpace(out), "\n")
	assert.Regexp(t, `^\d{2}:\d{2}:\d{2}\.\d{3} {2}INFO {2}connected to database$`, lines[0])
	assert.Regexp(t, `^\d{2}:\d{2}:\d{2}\.\d{3} {2}WARN {2}database schema up to date count=1$`, lines[1])
}

func TestPrettyHandlerLevelNames(t *testing.T) {
	var buf bytes.Buffer
	h := NewPrettyHandler(&buf, &PrettyOptions{Level: slog.LevelDebug, Color: new(bool)})
	log := slog.New(h)
	ctx := context.Background()

	log.DebugContext(ctx, "debug line")
	log.InfoContext(ctx, "info line")
	log.WarnContext(ctx, "warn line")
	log.ErrorContext(ctx, "error line")
	log.Log(ctx, slog.LevelInfo+4, "custom line") // INFO+4 == WARN

	lines := strings.Split(strings.TrimSpace(buf.String()), "\n")
	require.Len(t, lines, 5)
	assert.Contains(t, lines[0], " DEBUG debug line")
	assert.Contains(t, lines[1], " INFO  info line")
	assert.Contains(t, lines[2], " WARN  warn line")
	assert.Contains(t, lines[3], " ERROR error line")
	assert.Contains(t, lines[4], " WARN  custom line")

	buf.Reset()
	infoOnly := slog.New(NewPrettyHandler(&buf, &PrettyOptions{Level: slog.LevelInfo, Color: new(bool)}))
	infoOnly.DebugContext(ctx, "dropped")
	infoOnly.InfoContext(ctx, "kept")
	assert.Equal(t, 1, strings.Count(buf.String(), "\n"))
	assert.NotContains(t, buf.String(), "dropped")
}

func TestPrettyHandlerColorsWhenEnabled(t *testing.T) {
	enabled := true
	var buf bytes.Buffer
	slog.New(NewPrettyHandler(&buf, &PrettyOptions{Color: &enabled})).Error("boom", "code", 500)

	out := buf.String()
	assert.Contains(t, out, ansiRed+"ERROR", "level is coloured")
	assert.Contains(t, out, ansiReset, "colour is reset after the level")
	assert.Contains(t, out, ansiDim+"code", "attribute keys are dimmed")
	assert.Contains(t, out, ansiGreen+"500", "values are green")
}

func TestPrettyHandlerAttrFormatting(t *testing.T) {
	var buf bytes.Buffer
	log := New(&buf, false)

	log.Info("http_request",
		"duration", 12*time.Millisecond,
		"empty", "",
		"spaced", "two words",
		"plain", "value",
		"status", 200,
	)
	log.Info("with_preformatted", "a", 1)
	log.WithGroup("req").Info("grouped", "id", "abc", slog.Group("headers", "ua", "curl", "accept", "*/*"))

	out := buf.String()
	assert.Contains(t, out, "duration=12ms", "durations read human-readably")
	assert.Contains(t, out, `empty=""`)
	assert.Contains(t, out, `spaced="two words"`, "values with spaces are quoted")
	assert.Contains(t, out, "plain=value", "simple values are not quoted")
	assert.Contains(t, out, "status=200")
	assert.Contains(t, out, "a=1", "WithAttrs attributes are rendered")
	assert.Contains(t, out, "req.id=abc", "WithGroup prefixes keys")
	assert.Contains(t, out, "req.headers {")
	assert.Contains(t, out, "ua=curl")
	assert.Contains(t, out, "}")
}

func TestPrettyHandlerNeverLeaksRawMultilineValues(t *testing.T) {
	var buf bytes.Buffer
	New(&buf, false).Info("msg", "note", "line one\nline two")

	out := buf.String()
	assert.Equal(t, 1, strings.Count(out, "\n"), "a multi-line value must not split the record")
	assert.Contains(t, out, `\n`, "embedded newlines are escaped")
}