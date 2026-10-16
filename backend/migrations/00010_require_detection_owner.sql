-- +goose Up
-- +goose StatementBegin
-- Private detection is now owner-scoped: every check and every upload must
-- belong to an authenticated user. Anonymous checks and uploads are no longer
-- supported, so owner_user_id becomes NOT NULL on both tables.
--
-- Existing ownerless rows are purged first so the NOT NULL constraints apply.
-- This is safe: uploads are ephemeral (24h TTL) and anonymous rows were never
-- retrievable by anyone. Uploads are deleted before checks; the remaining
-- ownerless checks then go (any uploads still linked to them cascade away).
DELETE FROM private_uploads WHERE owner_user_id IS NULL;
DELETE FROM private_checks WHERE owner_user_id IS NULL;
ALTER TABLE private_checks ALTER COLUMN owner_user_id SET NOT NULL;
ALTER TABLE private_uploads ALTER COLUMN owner_user_id SET NOT NULL;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
ALTER TABLE private_uploads ALTER COLUMN owner_user_id DROP NOT NULL;
ALTER TABLE private_checks ALTER COLUMN owner_user_id DROP NOT NULL;
-- +goose StatementEnd
