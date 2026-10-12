-- +goose Up
-- +goose StatementBegin
-- The scam category of a community post is now assigned by the classifier
-- instead of the client, so a post can exist before it has one. category_id
-- becomes nullable; unclassified posts (category_id IS NULL) are visible only
-- to their author and to moderators, and are excluded from the public feed,
-- search, reactions and flags.
ALTER TABLE reports ALTER COLUMN category_id DROP NOT NULL;

-- Supports the retry sweep over posts awaiting classification and the
-- author-only visibility checks.
CREATE INDEX reports_unclassified_idx ON reports (created_at, id)
    WHERE category_id IS NULL AND deleted_at IS NULL;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
-- Re-classify anything still pending, otherwise the NOT NULL constraint
-- cannot be restored.
UPDATE reports SET category_id = (SELECT id FROM categories WHERE slug = 'phishing')
    WHERE category_id IS NULL;

DROP INDEX IF EXISTS reports_unclassified_idx;

ALTER TABLE reports ALTER COLUMN category_id SET NOT NULL;
-- +goose StatementEnd