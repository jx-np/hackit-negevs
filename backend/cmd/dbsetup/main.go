// Command dbsetup applies the SQL schema in init.sql to the configured
// database. It is a one-off helper for local/dev provisioning.
//
// Usage (from the backend module directory):
//
//	go run ./cmd/dbsetup --dsn "postgres://user:pass@host:5432/db?sslmode=disable" --schema ../init.sql
//
// If --dsn is omitted it falls back to the DATABASE_URL environment variable.
// Pass --drop to drop existing scamshield tables first (destructive).
package main

import (
	"context"
	"flag"
	"fmt"
	"os"
	"time"

	"github.com/jackc/pgx/v5"
)

func main() {
	dsn := flag.String("dsn", os.Getenv("DATABASE_URL"), "PostgreSQL connection string (defaults to $DATABASE_URL)")
	schemaPath := flag.String("schema", "../init.sql", "path to the schema SQL file")
	drop := flag.Bool("drop", false, "drop existing scamshield tables before applying the schema (destructive)")
	flag.Parse()

	if *dsn == "" {
		fmt.Fprintln(os.Stderr, "error: no DSN provided (use --dsn or set DATABASE_URL)")
		os.Exit(1)
	}

	if err := run(*dsn, *schemaPath, *drop); err != nil {
		fmt.Fprintln(os.Stderr, "error:", err)
		os.Exit(1)
	}
	fmt.Println("schema applied successfully")
}

func run(dsn, schemaPath string, drop bool) error {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	schema, err := os.ReadFile(schemaPath)
	if err != nil {
		return fmt.Errorf("read schema %q: %w", schemaPath, err)
	}

	conn, err := pgx.Connect(ctx, dsn)
	if err != nil {
		return fmt.Errorf("connect: %w", err)
	}
	defer conn.Close(ctx)

	if drop {
		if _, err := conn.Exec(ctx, dropSQL); err != nil {
			return fmt.Errorf("drop existing tables: %w", err)
		}
		fmt.Println("dropped existing tables")
	}

	// pgx's simple protocol executes a multi-statement string in one call.
	if _, err := conn.Exec(ctx, string(schema)); err != nil {
		return fmt.Errorf("apply schema: %w", err)
	}
	return nil
}

// dropSQL removes the schema's tables so the setup can be re-run cleanly.
// CASCADE handles foreign-key dependencies and indexes.
const dropSQL = `
DROP TABLE IF EXISTS
	resource_opens, guidance_resources, resource_translations, resources,
	guidance_translations, guidance, moderation_decisions, moderation_suggestions,
	content_flags, report_reactions, report_receipts, comments, report_tags,
	reports, private_uploads, private_checks, tags, categories,
	refresh_sessions, auth_identities, password_credentials, users
CASCADE;`
