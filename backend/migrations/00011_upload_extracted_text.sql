-- +goose Up
-- +goose StatementBegin
-- The screenshot pipeline was split: POST /uploads now runs OCR + PII removal
-- only and stores the cleaned (already redacted) text on the upload, which a
-- later POST /detection reuses to classify without re-running OCR. The text is
-- never raw message content and is never logged.
ALTER TABLE private_uploads ADD COLUMN IF NOT EXISTS extracted_text text;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
ALTER TABLE private_uploads DROP COLUMN IF EXISTS extracted_text;
-- +goose StatementEnd
