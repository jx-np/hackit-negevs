-- +goose Up
-- +goose StatementBegin
-- TEMPORARY (development only): keep community posts visible while the scam
-- category classifier is still a stub.
--
-- Two things leave posts unclassified (category_id IS NULL), which hides them
-- from the public feed, search, reactions, flags and comments:
--   1. The scam-category taxonomy lives in seed.sql, not in a migration, so a
--      database provisioned from migrations alone has an EMPTY categories
--      table. The classifier stub predicts 'phishing', but the publish-time
--      lookup finds no such row, so every new post is stored unclassified.
--   2. Posts published before the taxonomy existed already have
--      category_id IS NULL.
--
-- Seeding the taxonomy here is what actually unblocks NEW posts: once the
-- 'phishing' category row exists, the classifier stub resolves it on publish.
-- The backfill then fixes the existing NULL rows. Both steps are idempotent and
-- safe to run alongside seed.sql.
--
-- (Supersedes the earlier 00004 backfill, which ran against an empty categories
-- table and was therefore a no-op.)
--
-- Remove this migration once the real classifier is wired in and the taxonomy
-- is provisioned/seeded as part of normal setup.
INSERT INTO categories (slug, name_key, description_key) VALUES
	('scam_call',    'category.scam_call',     'category.scam_call.desc'),
	('scam_text',    'category.scam_text',     'category.scam_text.desc'),
	('phishing',     'category.phishing',      'category.phishing.desc'),
	('ecommerce',    'category.ecommerce',     'category.ecommerce.desc'),
	('investment',   'category.investment',    'category.investment.desc'),
	('job_scam',     'category.job_scam',      'category.job_scam.desc'),
	('impersonation','category.impersonation', 'category.impersonation.desc'),
	('other',        'category.other',         'category.other.desc')
ON CONFLICT (slug) DO NOTHING;

UPDATE reports SET category_id = (SELECT id FROM categories WHERE slug = 'phishing')
    WHERE category_id IS NULL;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
-- No-op: the original category_id values are not recoverable, and leaving the
-- backfilled category (and the seeded taxonomy) in place is harmless.
SELECT 1;
-- +goose StatementEnd
