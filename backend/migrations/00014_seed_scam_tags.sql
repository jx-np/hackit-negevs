-- +goose Up
-- +goose StatementBegin
-- Additional community-scam tags. The tag taxonomy lives in seed.sql, not in a
-- migration, so a database provisioned from migrations alone would not get these
-- rows. The post classifier predicts these slugs, and the publish-time lookup
-- (reports.Service.resolvePredictedTags -> ResolveTagSlugs) silently drops any
-- slug without a matching row, so seed them here too. Keep in sync with
-- classify/tags.py TAGS and backend/seed.sql.
--
-- Idempotent: a database seeded from seed.sql already has these rows.
INSERT INTO tags (slug, name_key) VALUES
	('money-mule',            'tag.money_mule'),
	('loan-scam',             'tag.loan_scam'),
	('gambling-scam',         'tag.gambling_scam'),
	('sextortion',            'tag.sextortion'),
	('family-emergency-scam', 'tag.family_emergency_scam'),
	('ticket-resale-scam',    'tag.ticket_resale_scam')
ON CONFLICT (slug) DO NOTHING;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
-- No-op: tag rows may already be referenced by report_tags. Removing them is not
-- safe, and leaving them in place is harmless.
SELECT 1;
-- +goose StatementEnd
