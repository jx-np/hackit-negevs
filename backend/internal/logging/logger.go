// Package logging builds the process-wide structured logger.
//
// Two formats are supported:
//
//   - production (machine-readable): one JSON object per line, the right shape
//     for ingestion by a log pipeline.
//   - development (human-readable): a compact, colourised console line per
//     record, e.g. "15:28:59  INFO  connected to database".
//
// The format is chosen by the caller (see config.Production, driven by the
// PRODUCTION environment variable). Both formats emit the same levels, messages
// and attributes; only the rendering differs.
package logging

import (
	"context"
	"fmt"
	"io"
	"log/slog"
	"os"
	"strconv"
	"strings"
	"sync"
	"time"
)

// Production reports whether PRODUCTION is set to a truthy value. It is read
// directly from the environment so the logger can be configured before the rest
// of the configuration is loaded.
func Production() bool {
	v := strings.TrimSpace(os.Getenv("PRODUCTION"))
	if v == "" {
		return false
	}
	b, err := strconv.ParseBool(v)
	if err != nil {
		// Tolerate the friendlier spellings before giving up.
		switch strings.ToLower(v) {
		case "yes", "y", "on":
			return true
		case "no", "n", "off":
			return false
		}
		return false
	}
	return b
}

// New returns a logger writing to w. When production is true it emits JSON;
// otherwise it emits the human-readable console format.
func New(w io.Writer, production bool) *slog.Logger {
	if production {
		return slog.New(slog.NewJSONHandler(w, &slog.HandlerOptions{Level: slog.LevelInfo}))
	}
	color := ColorSupported(w)
	return slog.New(NewPrettyHandler(w, &PrettyOptions{
		Level: slog.LevelInfo,
		Color: &color,
	}))
}

// PrettyOptions configures the development console handler.
type PrettyOptions struct {
	// Level is the minimum level that is emitted. Defaults to slog.LevelInfo.
	Level slog.Leveler
	// Color enables ANSI escapes. Defaults to auto-detection when nil.
	Color *bool
	// TimeFormat is the timestamp layout. Defaults to "15:04:05.000".
	TimeFormat string
}

// ANSI colour codes used by the console handler.
const (
	ansiReset  = "\x1b[0m"
	ansiDim    = "\x1b[2m"
	ansiRed    = "\x1b[31m"
	ansiGreen  = "\x1b[32m"
	ansiYellow = "\x1b[33m"
	ansiBlue   = "\x1b[34m"
	ansiCyan   = "\x1b[36m"
)

// levelStyle maps a level to its display name and colour.
func levelStyle(l slog.Level) (name, color string) {
	switch {
	case l < slog.LevelInfo:
		return "DEBUG", ansiCyan
	case l < slog.LevelWarn:
		return "INFO", ansiBlue
	case l < slog.LevelError:
		return "WARN", ansiYellow
	default:
		return "ERROR", ansiRed
	}
}

// ColorSupported reports whether w is an interactive terminal that can render
// ANSI escapes. Writing to a file, a pipe, or a redirected stream disables
// colour so the output stays clean.
func ColorSupported(w io.Writer) bool {
	f, ok := w.(*os.File)
	if !ok {
		return false
	}
	info, err := f.Stat()
	if err != nil {
		return false
	}
	return info.Mode()&os.ModeCharDevice != 0
}

// prettyHandler renders each record as a single colourised line:
//
//	15:28:59.664  INFO  connected to database
//	15:28:59.672  INFO  applied database migrations  count=1
//
// Attribute keys are dimmed, groups are rendered inline as "group.key=value",
// and durations are printed human-readably rather than as raw nanoseconds.
type prettyHandler struct {
	mu    *sync.Mutex
	w     io.Writer
	level slog.Leveler
	color bool
	// attrs holds pre-rendered attributes from WithAttrs, each already prefixed
	// with a separating space so it can be appended verbatim.
	attrs string
	// group is the dot-prefixed prefix for the current group scope.
	group string
	// timeFormat is the resolved timestamp layout.
	timeFormat string
}

// NewPrettyHandler builds the human-readable handler used outside production.
func NewPrettyHandler(w io.Writer, opts *PrettyOptions) slog.Handler {
	if opts == nil {
		opts = &PrettyOptions{}
	}
	level := opts.Level
	if level == nil {
		level = slog.LevelInfo
	}
	color := ColorSupported(w)
	if opts.Color != nil {
		color = *opts.Color
	}
	timeFormat := opts.TimeFormat
	if timeFormat == "" {
		timeFormat = "15:04:05.000"
	}
	return &prettyHandler{
		mu:         &sync.Mutex{},
		w:          w,
		level:      level,
		color:      color,
		timeFormat: timeFormat,
	}
}

func (h *prettyHandler) Enabled(_ context.Context, l slog.Level) bool {
	return l >= h.level.Level()
}

func (h *prettyHandler) paint(color, s string) string {
	if !h.color || s == "" {
		return s
	}
	return color + s + ansiReset
}

// Handle renders one record. The whole line is assembled in a local buffer and
// written under a single lock so concurrent requests do not interleave.
func (h *prettyHandler) Handle(_ context.Context, r slog.Record) error {
	var b strings.Builder

	b.WriteString(h.paint(ansiDim, time.Now().Format(h.timeFormat)))
	b.WriteString("  ")

	// Pad the level so messages line up across records.
	name, color := levelStyle(r.Level)
	b.WriteString(h.paint(color, fmt.Sprintf("%-5s", name)))
	b.WriteByte(' ')
	b.WriteString(r.Message)

	b.WriteString(h.attrs)

	// Records' own attributes are not known at WithAttrs time, so render them
	// here. Groups are flattened inline as "group.key=value".
	var openGroups []string
	r.Attrs(func(a slog.Attr) bool {
		writePrettyAttr(&b, h, h.group, a, &openGroups)
		return true
	})
	for range openGroups {
		b.WriteString(h.paint(ansiDim, " }"))
	}

	b.WriteByte('\n')

	h.mu.Lock()
	defer h.mu.Unlock()
	_, err := io.WriteString(h.w, b.String())
	return err
}

// writePrettyAttr appends " key=value" for a, descending into groups.
func writePrettyAttr(b *strings.Builder, h *prettyHandler, group string, a slog.Attr, open *[]string) {
	a.Value = a.Value.Resolve()
	if a.Equal(slog.Attr{}) {
		return
	}

	if a.Value.Kind() == slog.KindGroup {
		attrs := a.Value.Group()
		if len(attrs) == 0 {
			return
		}
		if a.Key != "" {
			key := a.Key
			if group != "" {
				key = group + "." + key
			}
			b.WriteByte(' ')
			b.WriteString(h.paint(ansiDim, key))
			b.WriteString(h.paint(ansiDim, " {"))
			*open = append(*open, key)
		}
		for _, sub := range attrs {
			writePrettyAttr(b, h, "", sub, open)
		}
		return
	}

	if group != "" {
		a.Key = group + "." + a.Key
	}

	b.WriteByte(' ')
	b.WriteString(h.paint(ansiDim, a.Key))
	b.WriteByte('=')
	b.WriteString(h.paint(ansiGreen, prettyValue(a.Value)))
}

// prettyValue renders an attribute value, special-casing durations so they read
// as "1.234ms" instead of nanosecond integers.
func prettyValue(v slog.Value) string {
	switch v.Kind() {
	case slog.KindDuration:
		return v.Duration().String()
	case slog.KindTime:
		return v.Time().Format(time.RFC3339)
	case slog.KindString:
		s := v.String()
		if s == "" || strings.ContainsAny(s, " \t\"\n") {
			return strconv.Quote(s)
		}
		return s
	default:
		return v.String()
	}
}

func (h *prettyHandler) WithAttrs(attrs []slog.Attr) slog.Handler {
	if len(attrs) == 0 {
		return h
	}
	var b strings.Builder
	b.WriteString(h.attrs)
	var open []string
	for _, a := range attrs {
		writePrettyAttr(&b, h, "", a, &open)
	}
	// WithAttrs attributes are pre-rendered, so close any groups they opened.
	for range open {
		b.WriteString(h.paint(ansiDim, " }"))
	}
	clone := *h
	clone.attrs = b.String()
	return &clone
}

func (h *prettyHandler) WithGroup(name string) slog.Handler {
	if name == "" {
		return h
	}
	clone := *h
	if clone.group == "" {
		clone.group = name
	} else {
		clone.group += "." + name
	}
	return &clone
}