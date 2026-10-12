package migrations

// Self-contained migration runner. It intentionally avoids any third-party
// migration library: the embedded .sql files use a small, well-known annotation
// format (a subset of goose's) and this runner parses and applies them directly
// over a pgx pool. Staying library-free keeps the dependency tree lean (notably
// it avoids pulling in an embedded SQLite driver that some migration libraries
// register unconditionally).
//
// On-disk format per file (prefixed by a numeric version, e.g. 00001_name.sql):
//
//	-- +goose Up
//	-- +goose StatementBegin
//	<up SQL>
//	-- +goose StatementEnd
//	-- +goose Down
//	-- +goose StatementBegin
//	<down SQL>
//	-- +goose StatementEnd
//
// The StatementBegin/StatementEnd markers are optional and are stripped; the Up
// and Down bodies are each applied as a single multi-statement batch inside one
// transaction.
//
// Applied state is tracked in the goose_db_version table so that a database
// previously migrated with goose is honored without re-applying anything.

import (
	"context"
	"fmt"
	"io/fs"
	"sort"
	"strconv"
	"strings"

	"github.com/jackc/pgx/v5/pgxpool"
)

// Migration is a single parsed migration file.
type Migration struct {
	Version int64
	Name    string
	Up      string
	Down    string
}

// Load parses every embedded migration, sorted by ascending version.
func Load() ([]Migration, error) {
	entries, err := fs.Glob(FS, "*.sql")
	if err != nil {
		return nil, fmt.Errorf("migrations: glob: %w", err)
	}
	sort.Strings(entries)

	migs := make([]Migration, 0, len(entries))
	for _, name := range entries {
		raw, err := fs.ReadFile(FS, name)
		if err != nil {
			return nil, fmt.Errorf("migrations: read %s: %w", name, err)
		}
		version, err := parseVersion(name)
		if err != nil {
			return nil, err
		}
		up, down := splitUpDown(string(raw))
		if strings.TrimSpace(up) == "" {
			return nil, fmt.Errorf("migrations: %s has an empty Up section", name)
		}
		migs = append(migs, Migration{Version: version, Name: name, Up: up, Down: down})
	}

	sort.Slice(migs, func(i, j int) bool { return migs[i].Version < migs[j].Version })
	for i := 1; i < len(migs); i++ {
		if migs[i].Version == migs[i-1].Version {
			return nil, fmt.Errorf("migrations: duplicate version %d (%s and %s)", migs[i].Version, migs[i-1].Name, migs[i].Name)
		}
	}
	return migs, nil
}

// Up applies every migration whose version is greater than the current applied
// version, in ascending order, each inside its own transaction. It returns the
// number of migrations applied (0 when already up to date).
func Up(ctx context.Context, pool *pgxpool.Pool) (int, error) {
	if err := ensureVersionTable(ctx, pool); err != nil {
		return 0, err
	}
	migs, err := Load()
	if err != nil {
		return 0, err
	}
	current, err := currentVersion(ctx, pool)
	if err != nil {
		return 0, err
	}

	applied := 0
	for _, m := range migs {
		if m.Version <= current {
			continue
		}
		if err := applyUp(ctx, pool, m); err != nil {
			return applied, err
		}
		applied++
	}
	return applied, nil
}

// Down rolls back the most recently applied migration. It is primarily for the
// CLI; the service never rolls back automatically.
func Down(ctx context.Context, pool *pgxpool.Pool) error {
	if err := ensureVersionTable(ctx, pool); err != nil {
		return err
	}
	migs, err := Load()
	if err != nil {
		return err
	}
	current, err := currentVersion(ctx, pool)
	if err != nil {
		return err
	}
	if current == 0 {
		return nil
	}

	var target *Migration
	for i := range migs {
		if migs[i].Version == current {
			target = &migs[i]
			break
		}
	}
	if target == nil {
		return fmt.Errorf("migrations: applied version %d not found among embedded migrations", current)
	}
	if strings.TrimSpace(target.Down) == "" {
		return fmt.Errorf("migrations: %s has no Down section", target.Name)
	}
	return applyDown(ctx, pool, *target)
}

// CurrentVersion returns the highest applied migration version (0 when none).
func CurrentVersion(ctx context.Context, pool *pgxpool.Pool) (int64, error) {
	if err := ensureVersionTable(ctx, pool); err != nil {
		return 0, err
	}
	return currentVersion(ctx, pool)
}

// LatestVersion returns the highest embedded migration version.
func LatestVersion() (int64, error) {
	migs, err := Load()
	if err != nil {
		return 0, err
	}
	if len(migs) == 0 {
		return 0, nil
	}
	return migs[len(migs)-1].Version, nil
}

func applyUp(ctx context.Context, pool *pgxpool.Pool, m Migration) error {
	tx, err := pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("migrations: begin %s: %w", m.Name, err)
	}
	defer tx.Rollback(ctx) //nolint:errcheck

	if _, err := tx.Exec(ctx, m.Up); err != nil {
		return fmt.Errorf("migrations: apply %s: %w", m.Name, err)
	}
	if _, err := tx.Exec(ctx,
		`INSERT INTO goose_db_version (version_id, is_applied) VALUES ($1, true)`, m.Version); err != nil {
		return fmt.Errorf("migrations: record %s: %w", m.Name, err)
	}
	if err := tx.Commit(ctx); err != nil {
		return fmt.Errorf("migrations: commit %s: %w", m.Name, err)
	}
	return nil
}

func applyDown(ctx context.Context, pool *pgxpool.Pool, m Migration) error {
	tx, err := pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("migrations: begin down %s: %w", m.Name, err)
	}
	defer tx.Rollback(ctx) //nolint:errcheck

	if _, err := tx.Exec(ctx, m.Down); err != nil {
		return fmt.Errorf("migrations: roll back %s: %w", m.Name, err)
	}
	// Mark the version as no longer applied by inserting a down marker row,
	// matching goose's bookkeeping (it keys off the latest row per version).
	if _, err := tx.Exec(ctx,
		`INSERT INTO goose_db_version (version_id, is_applied) VALUES ($1, false)`, m.Version); err != nil {
		return fmt.Errorf("migrations: record down %s: %w", m.Name, err)
	}
	if err := tx.Commit(ctx); err != nil {
		return fmt.Errorf("migrations: commit down %s: %w", m.Name, err)
	}
	return nil
}

func ensureVersionTable(ctx context.Context, pool *pgxpool.Pool) error {
	// Schema matches goose's Postgres version table so prior goose-managed
	// databases interoperate without migration of the bookkeeping itself.
	const q = `CREATE TABLE IF NOT EXISTS goose_db_version (
	id serial PRIMARY KEY,
	version_id bigint NOT NULL,
	is_applied boolean NOT NULL,
	tstamp timestamp NULL DEFAULT now()
)`
	if _, err := pool.Exec(ctx, q); err != nil {
		return fmt.Errorf("migrations: ensure version table: %w", err)
	}
	return nil
}

// currentVersion returns the latest applied version using goose's semantics:
// for each version_id the most recent row wins, and the current version is the
// highest version_id whose latest row has is_applied = true.
func currentVersion(ctx context.Context, pool *pgxpool.Pool) (int64, error) {
	const q = `SELECT version_id, is_applied
	FROM goose_db_version
	ORDER BY id DESC`
	rows, err := pool.Query(ctx, q)
	if err != nil {
		return 0, fmt.Errorf("migrations: read version: %w", err)
	}
	defer rows.Close()

	seen := map[int64]bool{}
	var current int64
	for rows.Next() {
		var versionID int64
		var isApplied bool
		if err := rows.Scan(&versionID, &isApplied); err != nil {
			return 0, fmt.Errorf("migrations: scan version: %w", err)
		}
		if seen[versionID] {
			continue // an older row for a version we've already resolved
		}
		seen[versionID] = true
		if isApplied && versionID > current {
			current = versionID
		}
	}
	if err := rows.Err(); err != nil {
		return 0, fmt.Errorf("migrations: iterate versions: %w", err)
	}
	return current, nil
}

func parseVersion(filename string) (int64, error) {
	base := filename
	if i := strings.IndexByte(base, '_'); i > 0 {
		base = base[:i]
	} else {
		base = strings.TrimSuffix(base, ".sql")
	}
	v, err := strconv.ParseInt(base, 10, 64)
	if err != nil {
		return 0, fmt.Errorf("migrations: %s has no numeric version prefix", filename)
	}
	return v, nil
}

// splitUpDown extracts the Up and Down SQL bodies, stripping annotation lines
// (-- +goose Up/Down/StatementBegin/StatementEnd). Lines before the first "Up"
// marker are ignored.
func splitUpDown(content string) (up, down string) {
	var upLines, downLines []string
	section := "" // "", "up", or "down"

	for _, line := range strings.Split(content, "\n") {
		trimmed := strings.TrimSpace(line)
		if strings.HasPrefix(trimmed, "-- +goose") {
			switch {
			case strings.Contains(trimmed, "Up"):
				section = "up"
			case strings.Contains(trimmed, "Down"):
				section = "down"
			}
			// StatementBegin/StatementEnd and the Up/Down markers are all skipped.
			continue
		}
		switch section {
		case "up":
			upLines = append(upLines, line)
		case "down":
			downLines = append(downLines, line)
		}
	}
	return strings.TrimSpace(strings.Join(upLines, "\n")), strings.TrimSpace(strings.Join(downLines, "\n"))
}
