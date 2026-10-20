-- +goose Up
-- +goose StatementBegin
-- The @help AI reply bot posts its answers as ordinary comments, so it needs a
-- real users row to author them. is_bot marks that row: the bot has no email
-- and no password_credentials / auth_identities rows, so it can never log in,
-- and clients can render an "AI" badge for its comments.
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_bot boolean NOT NULL DEFAULT false;

-- Seed exactly one bot user. Idempotent, so a database provisioned from
-- init.sql (which already has the row) is unaffected.
INSERT INTO users (display_name, role, is_bot)
SELECT 'NegevAI', 'resident', true
WHERE NOT EXISTS (SELECT 1 FROM users WHERE is_bot);
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
-- Deleting the bot user keeps its comments (comments.author_user_id is set to
-- NULL, so the author shows as "removed user"); only the bot identity goes
-- away.
DELETE FROM users WHERE is_bot;

ALTER TABLE users DROP COLUMN IF EXISTS is_bot;
-- +goose StatementEnd
