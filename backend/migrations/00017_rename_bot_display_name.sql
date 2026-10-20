-- +goose Up
-- +goose StatementBegin
-- Rename the seeded AI reply bot from "Grok" to "Help". The bot's public
-- display name later became "NegevAI" (see 00018); this migration is kept as
-- written because databases may already have recorded it as applied.
-- Idempotent: a database provisioned from the current init.sql or migration
-- 00016 already has display_name 'NegevAI', so this is a no-op there.
UPDATE users
SET display_name = 'Help', updated_at = now()
WHERE is_bot AND display_name = 'Grok';
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
-- Reverses the rename for the same bot account.
UPDATE users
SET display_name = 'Grok', updated_at = now()
WHERE is_bot AND display_name = 'Help';
-- +goose StatementEnd
