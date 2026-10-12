-- +goose Up
-- +goose StatementBegin
-- The OCR + PII-removal worker produces a redacted copy of an uploaded
-- screenshot. We keep the original (storage_key) and the redacted result
-- (redacted_storage_key) as separate objects so the original can be purged
-- early while the redacted copy survives long enough to be reused in a post.
-- Nullable because an upload has no redacted copy until the worker finishes.
ALTER TABLE private_uploads
    ADD COLUMN redacted_storage_key text UNIQUE;
-- +goose StatementEnd

-- +goose StatementBegin
-- A published post may carry the redacted screenshot its author checked. Only
-- the redacted image is ever referenced here: the raw upload never leaks into
-- public post material. Nullable because most posts are text-only.
ALTER TABLE reports
    ADD COLUMN redacted_image_key text;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
ALTER TABLE reports
    DROP COLUMN IF EXISTS redacted_image_key;
-- +goose StatementEnd

-- +goose StatementBegin
ALTER TABLE private_uploads
    DROP COLUMN IF EXISTS redacted_storage_key;
-- +goose StatementEnd
