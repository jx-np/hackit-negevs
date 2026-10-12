-- +goose Up
-- +goose StatementBegin
-- Superseded by 00005. This migration originally tried to backfill posts to the
-- 'phishing' category, but it ran against an empty categories table (the
-- taxonomy lives in seed.sql, not in a migration) so the backfill resolved to
-- NULL and did nothing. The working fix (seed the taxonomy, then backfill) lives
-- in 00005. This file is kept as a no-op so its already-applied version record
-- stays consistent on databases that applied it.
SELECT 1;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
SELECT 1;
-- +goose StatementEnd
