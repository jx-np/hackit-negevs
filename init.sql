-- PostgreSQL MVP schema. Private checks and uploads are never exposed through
-- the public report tables; reports contain only explicitly approved redacted text.

CREATE TABLE users (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email text,
    email_normalized text UNIQUE,
    display_name text NOT NULL,
    role text NOT NULL DEFAULT 'resident'
        CHECK (role IN ('resident', 'helper', 'moderator', 'admin')),
    locale text NOT NULL DEFAULT 'en-SG',
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CHECK ((email IS NULL) = (email_normalized IS NULL))
);

CREATE TABLE password_credentials (
    user_id bigint PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    password_hash text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE auth_identities (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider text NOT NULL CHECK (provider IN ('google_firebase')),
    provider_uid text NOT NULL,
    linked_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (provider, provider_uid),
    UNIQUE (user_id, provider)
);

CREATE TABLE refresh_sessions (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash text NOT NULL UNIQUE,
    created_at timestamptz NOT NULL DEFAULT now(),
    expires_at timestamptz NOT NULL,
    revoked_at timestamptz,
    replaced_by_session_id bigint REFERENCES refresh_sessions(id) ON DELETE SET NULL,
    user_agent text,
    CHECK (expires_at > created_at)
);
CREATE INDEX refresh_sessions_user_active_idx ON refresh_sessions (user_id, expires_at)
    WHERE revoked_at IS NULL;

CREATE TABLE categories (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    slug text NOT NULL UNIQUE,
    name_key text NOT NULL,
    description_key text,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE tags (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    slug text NOT NULL UNIQUE,
    name_key text NOT NULL
);

CREATE TABLE private_checks (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    -- Private detection requires an authenticated owner; there are no anonymous
    -- checks. Deleting the owner cascades the check away.
    owner_user_id bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status text NOT NULL DEFAULT 'processing'
        CHECK (status IN ('processing', 'ready', 'failed')),
    input_text text,
    extracted_text text,
    locale text NOT NULL DEFAULT 'en-SG',
    verdict text CHECK (verdict IN ('suspicious', 'unclear', 'likely_safe')),
    assessment jsonb,
    created_at timestamptz NOT NULL DEFAULT now(),
    completed_at timestamptz,
    expires_at timestamptz NOT NULL DEFAULT (now() + interval '30 days'),
    CHECK (expires_at > created_at)
);
CREATE INDEX private_checks_owner_created_idx ON private_checks (owner_user_id, created_at DESC);
CREATE INDEX private_checks_expiry_idx ON private_checks (expires_at);

CREATE TABLE private_uploads (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    check_id bigint REFERENCES private_checks(id) ON DELETE CASCADE,
    -- Uploads are private and owner-scoped: an upload always belongs to the
    -- authenticated user who submitted it.
    owner_user_id bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    storage_key text NOT NULL UNIQUE,
    -- Key of the PII-redacted copy produced by the OCR worker. NULL until the
    -- worker finishes; the original (storage_key) and the redacted copy are
    -- distinct objects so the raw image can be purged independently.
    redacted_storage_key text UNIQUE,
    -- Cleaned/redacted text produced by the PII worker, never raw message text;
    -- stored briefly so a later detection request can classify it.
    extracted_text text,
    media_type text NOT NULL CHECK (media_type IN ('image/jpeg', 'image/png', 'image/webp')),
    byte_size bigint NOT NULL CHECK (byte_size > 0),
    status text NOT NULL DEFAULT 'uploaded'
        CHECK (status IN ('uploaded', 'processing', 'ready', 'failed')),
    created_at timestamptz NOT NULL DEFAULT now(),
    expires_at timestamptz NOT NULL DEFAULT (now() + interval '24 hours'),
    CHECK (expires_at > created_at)
);
CREATE INDEX private_uploads_expiry_idx ON private_uploads (expires_at);

CREATE TABLE reports (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    author_user_id bigint REFERENCES users(id) ON DELETE SET NULL,
    source_check_id bigint REFERENCES private_checks(id) ON DELETE SET NULL,
    -- Nullable: the post stays unclassified (and author-only) until the
    -- classifier assigns a category.
    category_id bigint REFERENCES categories(id) ON DELETE RESTRICT,
    title text NOT NULL,
    redacted_text text NOT NULL,
    source_locale text NOT NULL DEFAULT 'en-SG',
    publication_confirmed_at timestamptz NOT NULL DEFAULT now(),
    review_status text NOT NULL DEFAULT 'unverified'
        CHECK (review_status IN ('unverified', 'reviewed', 'disputed', 'hidden', 'removed')),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    deleted_at timestamptz
);
CREATE INDEX reports_recent_idx ON reports (created_at DESC, id DESC)
    WHERE deleted_at IS NULL AND review_status NOT IN ('hidden', 'removed');
CREATE INDEX reports_category_recent_idx ON reports (category_id, created_at DESC, id DESC)
    WHERE deleted_at IS NULL AND review_status NOT IN ('hidden', 'removed');
-- 'simple' avoids English-only stemming so Chinese, Malay and Hindi text is not
-- mangled; titles are searched alongside the redacted body.
CREATE INDEX reports_search_idx ON reports
    USING gin (to_tsvector('simple', title || ' ' || redacted_text));
CREATE INDEX reports_author_idx ON reports (author_user_id, created_at DESC);
-- Posts still awaiting a classifier decision; supports a retry sweep and the
-- author-only visibility queries.
CREATE INDEX reports_unclassified_idx ON reports (created_at, id)
    WHERE category_id IS NULL AND deleted_at IS NULL;

CREATE TABLE report_tags (
    report_id bigint NOT NULL REFERENCES reports(id) ON DELETE CASCADE,
    tag_id bigint NOT NULL REFERENCES tags(id) ON DELETE RESTRICT,
    PRIMARY KEY (report_id, tag_id)
);
CREATE INDEX report_tags_tag_report_idx ON report_tags (tag_id, report_id);

CREATE TABLE report_images (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    report_id bigint NOT NULL REFERENCES reports(id) ON DELETE CASCADE,
    -- Key of the PII-redacted copy made from an upload the author owned. The raw
    -- upload is never referenced here; only the redacted derivative is served.
    storage_key text NOT NULL UNIQUE,
    media_type text NOT NULL CHECK (media_type IN ('image/jpeg', 'image/png', 'image/webp')),
    -- Stable display order within the post (0-based).
    position int NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX report_images_report_pos_idx ON report_images (report_id, position, id);

CREATE TABLE comments (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    report_id bigint NOT NULL REFERENCES reports(id) ON DELETE CASCADE,
    author_user_id bigint REFERENCES users(id) ON DELETE SET NULL,
    parent_comment_id bigint REFERENCES comments(id) ON DELETE CASCADE,
    body text NOT NULL,
    status text NOT NULL DEFAULT 'visible' CHECK (status IN ('visible', 'hidden', 'removed')),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CHECK (parent_comment_id IS NULL OR parent_comment_id <> id)
);
CREATE INDEX comments_report_created_idx ON comments (report_id, created_at, id)
    WHERE status = 'visible';
CREATE INDEX comments_author_idx ON comments (author_user_id, created_at DESC);

CREATE TABLE report_receipts (
    user_id bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    report_id bigint NOT NULL REFERENCES reports(id) ON DELETE CASCADE,
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, report_id)
);
CREATE INDEX report_receipts_report_idx ON report_receipts (report_id);

-- One vote per user per report. Counts are derived, not denormalized, so votes
-- cannot drift out of sync with the rows that justify them.
CREATE TABLE report_reactions (
    user_id bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    report_id bigint NOT NULL REFERENCES reports(id) ON DELETE CASCADE,
    vote smallint NOT NULL CHECK (vote IN (-1, 1)),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, report_id)
);
CREATE INDEX report_reactions_report_vote_idx ON report_reactions (report_id, vote);

CREATE TABLE content_flags (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    reporter_user_id bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    report_id bigint REFERENCES reports(id) ON DELETE CASCADE,
    comment_id bigint REFERENCES comments(id) ON DELETE CASCADE,
    reason text NOT NULL CHECK (reason IN ('personal_information', 'harmful', 'spam', 'misinformation', 'other')),
    details text,
    status text NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'resolved', 'dismissed')),
    created_at timestamptz NOT NULL DEFAULT now(),
    resolved_at timestamptz,
    CHECK (num_nonnulls(report_id, comment_id) = 1),
    UNIQUE (reporter_user_id, report_id),
    UNIQUE (reporter_user_id, comment_id)
);
CREATE INDEX content_flags_queue_idx ON content_flags (created_at) WHERE status = 'open';

CREATE TABLE moderation_suggestions (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    report_id bigint REFERENCES reports(id) ON DELETE CASCADE,
    comment_id bigint REFERENCES comments(id) ON DELETE CASCADE,
    recommendation text NOT NULL CHECK (recommendation IN ('allow', 'review', 'hide', 'remove')),
    suggested_redactions jsonb NOT NULL DEFAULT '[]'::jsonb,
    model_name text NOT NULL,
    model_version text NOT NULL,
    confidence numeric(5,4) CHECK (confidence BETWEEN 0 AND 1),
    limitations text,
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (num_nonnulls(report_id, comment_id) = 1)
);
CREATE INDEX moderation_suggestions_report_idx ON moderation_suggestions (report_id, created_at DESC);
CREATE INDEX moderation_suggestions_comment_idx ON moderation_suggestions (comment_id, created_at DESC);

CREATE TABLE moderation_decisions (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    report_id bigint REFERENCES reports(id) ON DELETE CASCADE,
    comment_id bigint REFERENCES comments(id) ON DELETE CASCADE,
    moderator_user_id bigint REFERENCES users(id) ON DELETE SET NULL,
    decision text NOT NULL CHECK (decision IN ('reviewed', 'disputed', 'hide', 'remove', 'restore')),
    rationale text,
    suggestion_id bigint REFERENCES moderation_suggestions(id) ON DELETE SET NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (num_nonnulls(report_id, comment_id) = 1)
);
CREATE INDEX moderation_decisions_report_idx ON moderation_decisions (report_id, created_at DESC);
CREATE INDEX moderation_decisions_comment_idx ON moderation_decisions (comment_id, created_at DESC);

CREATE TABLE guidance (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    content_key text NOT NULL UNIQUE,
    scenario text NOT NULL,
    urgency text NOT NULL DEFAULT 'normal' CHECK (urgency IN ('normal', 'urgent', 'emergency')),
    sort_order integer NOT NULL DEFAULT 0,
    active boolean NOT NULL DEFAULT true
);

CREATE TABLE guidance_translations (
    guidance_id bigint NOT NULL REFERENCES guidance(id) ON DELETE CASCADE,
    locale text NOT NULL,
    title text NOT NULL,
    body text NOT NULL,
    PRIMARY KEY (guidance_id, locale)
);

CREATE TABLE resources (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    slug text NOT NULL UNIQUE,
    country_code char(2) NOT NULL DEFAULT 'SG',
    url text,
    contact_instructions text,
    owner_name text NOT NULL,
    verified_at timestamptz NOT NULL,
    active boolean NOT NULL DEFAULT true,
    CHECK (url IS NOT NULL OR contact_instructions IS NOT NULL)
);

CREATE TABLE resource_translations (
    resource_id bigint NOT NULL REFERENCES resources(id) ON DELETE CASCADE,
    locale text NOT NULL,
    name text NOT NULL,
    description text,
    PRIMARY KEY (resource_id, locale)
);

CREATE TABLE guidance_resources (
    guidance_id bigint NOT NULL REFERENCES guidance(id) ON DELETE CASCADE,
    resource_id bigint NOT NULL REFERENCES resources(id) ON DELETE CASCADE,
    sort_order integer NOT NULL DEFAULT 0,
    PRIMARY KEY (guidance_id, resource_id)
);

CREATE TABLE resource_opens (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id bigint REFERENCES users(id) ON DELETE SET NULL,
    check_id bigint REFERENCES private_checks(id) ON DELETE SET NULL,
    guidance_id bigint REFERENCES guidance(id) ON DELETE SET NULL,
    resource_id bigint NOT NULL REFERENCES resources(id) ON DELETE RESTRICT,
    opened_at timestamptz NOT NULL DEFAULT now(),
    CHECK (user_id IS NOT NULL OR check_id IS NOT NULL)
);
CREATE INDEX resource_opens_metric_idx ON resource_opens (opened_at, resource_id);

-- Scam-awareness news shown on the home screen. Each article carries one row
-- per locale; the public API returns every locale at once so the client picks
-- the language. icon is a client-side icon name, never image data.
CREATE TABLE news_articles (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    slug text NOT NULL UNIQUE,
    icon text NOT NULL,
    sort_order integer NOT NULL DEFAULT 0,
    active boolean NOT NULL DEFAULT true
);

CREATE TABLE news_article_translations (
    article_id bigint NOT NULL REFERENCES news_articles(id) ON DELETE CASCADE,
    locale text NOT NULL,
    title text NOT NULL,
    body text NOT NULL,
    PRIMARY KEY (article_id, locale)
);

CREATE INDEX news_articles_order_idx ON news_articles (sort_order, id) WHERE active = true;
