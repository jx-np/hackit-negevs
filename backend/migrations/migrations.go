// Package migrations embeds the goose SQL migration files so the migrate
// command (and tests) can run them without depending on the files being
// present on disk at runtime.
package migrations

import "embed"

// FS holds every .sql migration in this directory. goose reads versions from
// the filename prefix (e.g. 00001_baseline.sql).
//
//go:embed *.sql
var FS embed.FS
