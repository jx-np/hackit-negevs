-- +goose Up
-- +goose StatementBegin
-- The community-scam tag taxonomy lives in seed.sql, not in a migration, so a
-- database provisioned from migrations alone has an EMPTY tags table. The post
-- classifier still predicts tag slugs, but the publish-time lookup
-- (reports.Service.resolvePredictedTags -> ResolveTagSlugs) finds no matching
-- row and silently drops every tag, so posts come out untagged. The category is
-- seeded by 00005_seed_taxonomy_backfill_dev.sql, which is why the category
-- resolves while the tags are empty.
--
-- Seed the canonical tags here so every environment gets them. Keep this in
-- sync with classify/tags.py TAGS and backend/seed.sql.
INSERT INTO tags (slug, name_key) VALUES
	('bank-impersonation', 'tag.bank_impersonation'),
	('otp-scam',           'tag.otp_scam'),
	('phishing',           'tag.phishing'),
	('prize-scam',         'tag.prize_scam'),
	('delivery-scam',      'tag.delivery_scam'),
	('money-request',      'tag.money_request'),
	('suspicious-link',    'tag.suspicious_link'),
	('government-impersonation', 'tag.government_impersonation'),
	('other',              'tag.other')
ON CONFLICT (slug) DO NOTHING;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
-- No-op: tag rows may already be referenced by report_tags. Removing them is not
-- safe, and leaving the canonical taxonomy in place is harmless.
SELECT 1;
-- +goose StatementEnd
