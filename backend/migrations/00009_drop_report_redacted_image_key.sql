-- +goose Up
-- +goose StatementBegin
-- The single-image reports.redacted_image_key column is superseded by the
-- report_images table (one-to-many, ordered). Nothing reads or populates the
-- column anymore: image attachment now flows entirely through report_images.
-- Drop the vestigial column so there is a single clear image path.
ALTER TABLE reports
    DROP COLUMN IF EXISTS redacted_image_key;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
-- Restore the column as a plain nullable text key. Any previously stored keys
-- cannot be recovered; the column comes back empty.
ALTER TABLE reports
    ADD COLUMN redacted_image_key text;
-- +goose StatementEnd
