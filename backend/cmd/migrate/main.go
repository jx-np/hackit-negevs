// Command migrate applies database schema migrations.
//
// Usage (from the backend module directory):
//
//	go run ./cmd/migrate --dsn "postgres://user:pass@host:5432/db?sslmode=disable" up
//	go run ./cmd/migrate up          # uses $DATABASE_URL
//	go run ./cmd/migrate down        # roll back the most recent migration
//	go run ./cmd/migrate status      # show current vs latest version
//	go run ./cmd/migrate version     # print the current schema version
//
// Migrations are embedded in the binary (see the migrations package), so the
// command is self-contained and does not need the .sql files on disk. The same
// runner also executes automatically on API startup; this command exists for
// manual control (e.g. rolling back) and inspection.
//
// If --dsn is omitted it falls back to the DATABASE_URL environment variable.
package main

import (
	"context"
	"flag"
	"fmt"
	"os"
	"time"

	"scamshield/internal/platform/db"
	"scamshield/migrations"
)

func main() {
	dsn := flag.String("dsn", os.Getenv("DATABASE_URL"), "PostgreSQL connection string (defaults to $DATABASE_URL)")
	flag.Parse()

	command := flag.Arg(0)
	if command == "" {
		command = "up"
	}

	if *dsn == "" {
		fmt.Fprintln(os.Stderr, "error: no DSN provided (use --dsn or set DATABASE_URL)")
		os.Exit(1)
	}

	if err := run(*dsn, command); err != nil {
		fmt.Fprintln(os.Stderr, "error:", err)
		os.Exit(1)
	}
}

func run(dsn, command string) error {
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()

	pool, err := db.Connect(ctx, dsn)
	if err != nil {
		return err
	}
	defer pool.Close()

	switch command {
	case "up":
		applied, err := migrations.Up(ctx, pool)
		if err != nil {
			return err
		}
		if applied == 0 {
			fmt.Println("database schema up to date")
		} else {
			fmt.Printf("applied %d migration(s)\n", applied)
		}
		return nil
	case "down":
		if err := migrations.Down(ctx, pool); err != nil {
			return err
		}
		fmt.Println("rolled back the most recent migration")
		return nil
	case "status":
		current, err := migrations.CurrentVersion(ctx, pool)
		if err != nil {
			return err
		}
		latest, err := migrations.LatestVersion()
		if err != nil {
			return err
		}
		fmt.Printf("current version: %d\nlatest version:  %d\n", current, latest)
		if current < latest {
			fmt.Println("status: behind (run `migrate up`)")
		} else {
			fmt.Println("status: up to date")
		}
		return nil
	case "version":
		current, err := migrations.CurrentVersion(ctx, pool)
		if err != nil {
			return err
		}
		fmt.Printf("%d\n", current)
		return nil
	default:
		return fmt.Errorf("unknown command %q (want: up, down, status, version)", command)
	}
}
