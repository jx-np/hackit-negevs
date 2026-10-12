-- +goose Up
-- +goose StatementBegin
-- A user may hold at most one live (unexpired) report per phone number, so the
-- insert guard asks "does this reporter already have a report for this number
-- inside the reputation window?". The existing index is keyed on
-- (phone_number, created_at DESC) which serves reputation counting but not the
-- reporter predicate. This index supports the duplicate check directly, and
-- being partial it stays small because anonymous (NULL reporter) rows cannot be
-- deduplicated.
CREATE INDEX phone_reports_reporter_dedupe_idx
    ON phone_reports (phone_number, reporter_user_id, created_at DESC)
    WHERE reporter_user_id IS NOT NULL;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP INDEX IF EXISTS phone_reports_reporter_dedupe_idx;
-- +goose StatementEnd