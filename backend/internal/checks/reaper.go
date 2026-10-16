package checks

import (
	"context"
	"log/slog"
	"time"
)

// reaperTimeout bounds a single retention pass so a stuck database cannot hang
// the reaper goroutine forever.
const reaperTimeout = 30 * time.Second

// Reaper periodically enforces the retention windows declared in the schema
// (private_uploads expire 24h after creation, private_checks after 30 days) by
// deleting expired rows and purging their stored blobs. Without it those
// windows would exist only as column defaults and indexes, and expired private
// data would accumulate indefinitely.
//
// It never logs message content or storage keys; only counts and errors.
type Reaper struct {
	svc      *Service
	interval time.Duration
	logger   *slog.Logger
}

// NewReaper constructs a Reaper. A non-positive interval falls back to one hour
// and a nil logger falls back to the default logger.
func NewReaper(svc *Service, interval time.Duration, logger *slog.Logger) *Reaper {
	if interval <= 0 {
		interval = time.Hour
	}
	if logger == nil {
		logger = slog.Default()
	}
	return &Reaper{svc: svc, interval: interval, logger: logger}
}

// Run purges once immediately, then on every interval tick, until ctx is
// cancelled. It is intended to run in its own goroutine.
func (r *Reaper) Run(ctx context.Context) {
	r.reap(ctx)

	ticker := time.NewTicker(r.interval)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			r.reap(ctx)
		}
	}
}

// reap performs one retention pass. Failures are logged (pgx errors never carry
// bound parameter values, so no private data is exposed) and swallowed so a
// transient database error does not stop the loop.
func (r *Reaper) reap(ctx context.Context) {
	ctx, cancel := context.WithTimeout(ctx, reaperTimeout)
	defer cancel()

	n, err := r.svc.PurgeExpired(ctx)
	if err != nil {
		r.logger.Warn("retention reap failed", "error", err)
		return
	}
	if n > 0 {
		r.logger.Info("purged expired detection data", "uploads", n)
	}
}
