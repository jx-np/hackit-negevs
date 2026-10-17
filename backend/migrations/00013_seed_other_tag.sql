-- +goose Up
-- +goose StatementBegin
-- The catch-all "other" tag backs the classifier fallback: when a post's
-- prediction yields no resolvable tag, reports.Service attaches this tag so the
-- post is never left untagged (see service.go fallbackTagSlug). Keep in sync with
-- classify/tags.py TAGS and backend/seed.sql.
--
-- 00012_seed_tags.sql already seeds this row, but a database that ran 00012
-- before the "other" row was added will not re-run it. This migration is
-- idempotent, so it lands the row either way.
INSERT INTO tags (slug, name_key) VALUES
	('other', 'tag.other')
ON CONFLICT (slug) DO NOTHING;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
-- No-op: tag rows may already be referenced by report_tags. Removing them is not
-- safe, and leaving the catch-all tag in place is harmless.
SELECT 1;
-- +goose StatementEnd
