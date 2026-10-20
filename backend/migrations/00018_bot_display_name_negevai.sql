-- +goose Up
-- +goose StatementBegin
-- The AI reply bot's public display name is now "NegevAI". This is a separate
-- migration because 00017 was already applied (as Grok -> Help) on existing
-- databases, so editing that file in place would never run again. It also
-- catches a database seeded directly as "Grok". Idempotent: on a database
-- provisioned from the current init.sql or 00016 the row is already 'NegevAI'.
UPDATE users
SET display_name = 'NegevAI', updated_at = now()
WHERE is_bot AND display_name IN ('Grok', 'Help');
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
-- Reverses the rename for the same bot account.
UPDATE users
SET display_name = 'Help', updated_at = now()
WHERE is_bot AND display_name = 'NegevAI';
-- +goose StatementEnd
