-- +goose Up
-- +goose StatementBegin
-- A post can carry several redacted screenshots in a stable display order.
-- Each row references the redacted copy of an upload the author owned; the raw
-- upload is never referenced here. ON DELETE CASCADE ties images to their post.
-- This table supersedes the earlier single-image reports.redacted_image_key
-- column, which migration 00009 drops.
CREATE TABLE report_images (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    report_id bigint NOT NULL REFERENCES reports(id) ON DELETE CASCADE,
    storage_key text NOT NULL UNIQUE,
    media_type text NOT NULL CHECK (media_type IN ('image/jpeg', 'image/png', 'image/webp')),
    position int NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now()
);
-- +goose StatementEnd

-- +goose StatementBegin
CREATE INDEX report_images_report_pos_idx ON report_images (report_id, position, id);
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP TABLE IF EXISTS report_images;
-- +goose StatementEnd
