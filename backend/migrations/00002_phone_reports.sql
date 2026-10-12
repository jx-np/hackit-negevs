-- +goose Up
-- +goose StatementBegin
-- Phone number abuse reports submitted from client apps. This is an append-only
-- ledger: the phone trust-score lookup derives report counts from recent rows
-- within a rolling window, so stale reports naturally stop influencing a number's
-- reputation (scammers spoof / recycle numbers, so an unbounded history would
-- permanently poison a number that may since have been reassigned).
CREATE TABLE phone_reports (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    phone_number text NOT NULL,
    reason text NOT NULL CHECK (char_length(reason) BETWEEN 1 AND 32),
    reporter_user_id bigint REFERENCES users(id) ON DELETE SET NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);
-- Supports windowed count queries: "reports for this number since <cutoff>".
CREATE INDEX phone_reports_number_created_idx ON phone_reports (phone_number, created_at DESC);

-- Classification is produced by a separate decision system (not yet built) over a
-- rolling window of recent reports. It is cached here keyed by normalized number;
-- a row only applies while now() < window_end, after which the number has no
-- active classification. Keeping this separate from the ledger means the future
-- classifier can be swapped in without touching how reports are recorded.
CREATE TABLE phone_classifications (
    phone_number text PRIMARY KEY,
    classification text NOT NULL,
    window_start timestamptz NOT NULL,
    window_end timestamptz NOT NULL,
    updated_at timestamptz NOT NULL DEFAULT now(),
    CHECK (window_end > window_start)
);
CREATE INDEX phone_classifications_active_idx ON phone_classifications (phone_number, window_end);
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP TABLE IF EXISTS phone_classifications CASCADE;
DROP TABLE IF EXISTS phone_reports CASCADE;
-- +goose StatementEnd
