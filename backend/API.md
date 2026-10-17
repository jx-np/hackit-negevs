# Community Scam Shield — Backend API Reference

Temporary Development Base URL: https://monarch-full-lizard.ngrok-free.app

This document describes the HTTP API served by the Go backend (`scamshield`). It
is the contract for the Flutter app and the web client. If code and this
document disagree, the handlers under `backend/internal/*/handler.go` are the
source of truth — please open an issue so we can fix the docs.

- **Base URL:** all routes are prefixed with `/api/v1`
- **Transport:** JSON over HTTPS
- **Encoding:** request and response bodies are JSON with `snake_case` keys
- **IDs:** all resource IDs are **opaque strings** in JSON (e.g. `"42"`), even though they are integers server-side. Treat them as strings.
- **Timestamps:** UTC, ISO-8601 / RFC3339 (e.g. `2026-09-29T08:30:00Z`)
- **Auth:** bearer access token in `Authorization: Bearer <access_token>`
- **Request ID:** every response carries an `X-Request-Id` header; it is also echoed in error bodies as `request_id`. Include it in bug reports.

---

## 1. Concepts and vocabulary

| Term | Meaning |
|---|---|
| **Detection** | A private, one-off scam analysis of pasted text or a screenshot. Never public. (`/detection`) |
| **Post** | A community submission published to the public feed — a redacted scam example. (`/community/posts`) |
| **Feed** | The browsable list of posts. (`/community/feed`) |
| **Comment** | A reply on a post, in the discussion layer. (`/community/discussion`) |
| **Reaction** | An up/down vote on a post (one per user). |
| **Flag** | Escalating a post or comment to moderators for review — the "🚩 report this" action (e.g. a public post that still contains personal information). (`.../flag`) |
| **Phone trust score** | A 0–100 score (0 = risky, 100 = trusted) for a phone number, from the scam phone-number database. (`/detection/phone-number/trust-score`) |
| **Review status** | A post's moderation label: `unverified`, `reviewed`, `disputed`, `hidden`, `removed`. |
| **Guidance / resources** | Situation-specific help and the vetted official resource catalog. |

**Official / validated posts:** there is no separate endpoint for these. A post
authored by an official account and/or marked `reviewed` by a moderator carries
`review_status: "reviewed"`. Clients should surface `review_status` prominently
and never present `unverified` community posts as confirmed fact.

---

## 2. Authentication

### Token model
- **Access token** — short-lived JWT (default 15 min). Sent as `Authorization: Bearer <token>` on every authenticated request.
- **Refresh token** — long-lived opaque string (default 30 days). Used only to obtain a new access token. It **rotates** on every refresh: each refresh returns a new refresh token and invalidates the old one. Store it securely (secure OS storage on mobile; httpOnly-style secure storage on web).
- Reusing an already-rotated refresh token is treated as theft: the whole session chain is revoked and the call returns `401`.

### Access levels used below
- **Public** — no token required.
- **Optional auth** — works anonymously; if a valid token is sent, per-user fields (like `my_vote` and `is_mine`) are filled in.
- **Authenticated** — valid access token required.
- **Moderator** — role `moderator` or `admin`.
- **Admin** — role `admin`.

Roles: `resident` (default), `helper`, `moderator`, `admin`.

---

## 3. Standard error shape

Every error response uses this shape:

```json
{
  "error": {
    "code": "unprocessable_entity",
    "message": "invalid registration input",
    "fields": { "email": "must be a valid email address" }
  },
  "request_id": "b1c2d3e4-..."
}
```

`fields` is present for validation errors and may be empty (`{}`).

| Status | `code` | When |
|---|---|---|
| 400 | `bad_request` | Malformed request (e.g. bad pagination cursor) |
| 401 | `unauthorized` | Missing/invalid access token, or bad credentials |
| 403 | `forbidden` | Authenticated but not allowed (wrong role/owner) |
| 404 | `not_found` | Resource missing or not visible to you |
| 409 | `conflict` | Duplicate (e.g. email taken, already reported) |
| 422 | `unprocessable_entity` | Validation failed; see `fields` |
| 429 | `rate_limited` | Too many requests |
| 500 | `internal_error` | Server error |

**Pagination:** list endpoints use cursor pagination. Pass `?limit=` (default 20,
max 100) and `?cursor=` (opaque string from the previous response's
`next_cursor`). When `next_cursor` is absent/empty, there are no more pages.

---

## 4. Auth endpoints

### POST /auth/register
Public. Creates a user and returns tokens.

Request:
```json
{ "email": "user@example.com", "password": "at-least-8-chars", "display_name": "Alex", "locale": "en-SG" }
```
`locale` is optional (defaults to `en-SG`). Password: 8+ chars, max 72 bytes.
`display_name`: letters, digits and at most one interior space only (no leading/trailing spaces, no punctuation or non-ASCII characters).

Response `201`:
```json
{
  "user": { "id": "1", "email": "user@example.com", "display_name": "Alex", "role": "resident", "locale": "en-SG" },
  "access_token": "<jwt>",
  "refresh_token": "<opaque>",
  "expires_in": 900
}
```
Errors: `409` email taken, `422` invalid input.

### POST /auth/login
Public.
```json
{ "email": "user@example.com", "password": "..." }
```
Response `200`: same shape as register. On failure returns a **generic** `401 invalid credentials` (never reveals whether the email exists).

### POST /auth/refresh
Public. Rotates the refresh token.
```json
{ "refresh_token": "<opaque>" }
```
Response `200`:
```json
{ "access_token": "<jwt>", "refresh_token": "<new-opaque>", "expires_in": 900 }
```
Errors: `401` invalid/expired/reused token. On `401`, send the user back to login.

### POST /auth/logout
Public (needs the refresh token). Revokes the session. Idempotent.
```json
{ "refresh_token": "<opaque>" }
```
Response `204` (no body).

### GET /me
Authenticated. Returns the current user's safe profile.

Response `200`:
```json
{ "id": "1", "email": "user@example.com", "display_name": "Alex", "role": "resident", "locale": "en-SG", "created_at": "2026-09-29T08:30:00Z" }
```

---

## 5. Detection (private scam checks)

Private analysis. Text checks run synchronously; screenshot checks are deferred.
Text is classified by the AI service's decision model (screenshot checks are
classified from their PII-redacted OCR text); if that classifier is unreachable,
detection fails rather than returning a synthesized verdict. All detection
endpoints require authentication: checks and uploads are owned by the caller, and
anonymous checks are not supported.

Private detection data is retained for a bounded period: **uploads for 24 hours**
and **checks for 30 days**. A background retention reaper deletes expired rows and
purges their stored blobs; owners can also delete a check or upload immediately
(see `DELETE /detection/{id}` and `DELETE /uploads/{id}`).

### POST /detection
**Auth required.** Analyze a message.

Request (text):
```json
{ "text": "Your bank account is suspended. Verify now: http://bit.ly/x", "locale": "en-SG" }
```
Request (screenshot — deferred): `{ "upload_id": "12", "locale": "en-SG" }`
First upload the screenshot with `POST /uploads` (below) and wait until its
status is `ready`; then submit its `upload_id` here. The check reuses the
upload's redacted text and returns `409 upload_not_ready` until redaction finishes.

Response `201` (text, ready):
```json
{
  "check_id": "55",
  "status": "ready",
  "verdict": "suspicious",
  "assessment": { "limitations": "This is guidance, not a guarantee. ..." },
  "signals": [
    { "code": "urgency", "evidence_excerpt": "suspended ... verify now", "explanation": "Creates false time pressure." },
    { "code": "suspicious_link", "evidence_excerpt": "bit.ly", "explanation": "Shortened link hides the real destination." }
  ],
  "uncertainty": "Some signals are ambiguous ...",
  "recommended_actions": [
    { "scenario": "clicked_link", "title": "Do not enter credentials", "urgency": "urgent" }
  ],
  "similar_reports": [
    { "report_id": "12", "excerpt": "...", "rationale": "Similar wording", "review_status": "reviewed" }
  ],
  "suggested_tags": ["phishing", "bank-impersonation"]
}
```
`verdict` is one of `suspicious | unclear | likely_safe`. `likely_safe` is **not**
a safety guarantee. `unclear` is a valid, expected outcome.

Response `202` (screenshot, processing): `{ "check_id": "56", "status": "processing" }`
Poll `GET /detection/{id}` until `status` is `ready` or `failed`. A screenshot
check classifies the upload's already-redacted text. If no text was recovered,
the check completes without a verdict. If classification cannot complete the
check resolves to `status: "failed"`.

When a screenshot yields **no readable text** (OCR detects nothing, or every
detected region falls below its confidence floor), the check still resolves to
`status: "ready"` but with **no `verdict` and no `assessment`** — scam
classification is skipped entirely rather than reporting a synthetic
`likely_safe`. `GET /detection/{id}` then returns just
`{ "check_id": "...", "status": "ready" }` (plus no `signals`,
`recommended_actions`, or similar fields). Treat a ready check with no `verdict`
as "couldn't read the image", never as a clean result.

If the **classification service** is unavailable, a text check fails with `503`
(`classification_unavailable`) rather than returning a synthetic verdict — retry
shortly. A screenshot check whose classification cannot complete resolves to
`status: "failed"`.

Errors: `401` if the request is unauthenticated; `422` if neither `text` nor
`upload_id` is provided; `503` (`classification_unavailable`) if the AI
classification service cannot be reached for a text check.

### POST /uploads
**Auth required.** Upload a screenshot to analyze. This is a
**`multipart/form-data`** request (not JSON): send the image in a form field
named `image`. An optional `locale` form field tunes analysis.

Uploading performs **PII removal only** (OCR, text cleanup, and image redaction).
It does not create or classify a detection check. Poll `GET /uploads/{id}` until
the upload status is `ready` or `failed`, then optionally create a check with
`POST /detection`.

- Allowed types: `image/jpeg`, `image/png`, `image/webp`.
- Max size: **10 MiB**.

Response `201`:
```json
{ "upload_id": "12", "media_type": "image/png", "status": "processing" }
```

Errors:
- `401` if the request is unauthenticated.
- `422` if the `image` field is missing or the media type is not one of the allowed types.
- `413` (`payload_too_large`) if the image exceeds 10 MiB.

The raw upload is stored privately for OCR + redaction only; its extracted text
is stored only after PII removal and never logged. Only the redacted derivative
is served back.

### GET /uploads/{id}
Authenticated, owner-only. Returns `{ "upload_id", "media_type", "status" }`.
Use this to poll PII-removal status. Returns `404` for another user's or missing upload.

### GET /uploads/{id}/redacted-image
Authenticated, owner-only. Streams the redacted image with
`Cache-Control: private, no-store`; returns `404` until a derivative exists.

`POST /detection` with an `upload_id` is the only way to create a screenshot
detection check; it requires the upload to be ready (otherwise `409 upload_not_ready`).

### DELETE /uploads/{id}
Authenticated, owner-only. Cancels an upload and purges its stored raw and
redacted blobs. Response `204` with no body.

An unlinked upload is removed on its own. If linked to a check, deleting it
removes the whole task (the check and linked uploads).

Returns `404` if the upload is not yours or does not exist, and `401` if the
request is unauthenticated.

### GET /detection/{id}
Authenticated, owner-only. Returns the current check (same shape as above). Returns
`404` if it is not yours.

### GET /detection/{id}/redacted-image
Authenticated, owner-only. Returns the **redacted** image produced for a
screenshot check — the PII-censored copy, never the original upload. The
response body is the raw image bytes (`Content-Type` is the redacted image's
media type), sent with `Cache-Control: private, no-store`.

Returns `404` if the check is not yours, has no redacted image yet (still
`processing` or `failed`), or does not exist.

### DELETE /detection/{id}
Authenticated, owner-only. Cancels and permanently deletes a check together with
its linked upload(s) and their stored raw and redacted blobs. Deleting a check
that is still `processing` cancels the in-flight OCR + PII-removal job, including
one that is still waiting to begin (workers hold a short grace period before
starting the expensive redaction call), so no further compute is spent on the
deleted task. Response `204` with no body.

Returns `404` if the check is not yours or does not exist (ownership failures are
reported as not-found so the endpoint never reveals whether a check exists), and
`401` if the request is unauthenticated.

This is **irreversible**. It also nulls the `source_check_id` on any community
post published from the check; the post itself and its own image copy are
unaffected.

### GET /me/detection
Authenticated. The user's own check history (paginated). Never returns the original
message text.

Response `200`:
```json
{
  "items": [ { "check_id": "55", "status": "ready", "verdict": "suspicious", "created_at": "2026-09-29T08:30:00Z" } ],
  "next_cursor": "..."
}
```

### POST /detection/{id}/resource-opens
Optional auth. Records that the user opened a recommended resource (this powers the
success metric). Requires either a logged-in user or the check reference.
```json
{ "resource_id": "3", "guidance_id": "7" }
```
`guidance_id` is optional. Response `204`. No message content is stored or logged.

### GET /detection/phone-number/trust-score
Optional auth (anonymous allowed). Looks up a phone number's trust score from the
scam phone-number database. The number is passed as a **query parameter** (not a body).

Query: `phone_number=<string>` (required; formatting like spaces, `+`, `-`, `()` is fine — it is normalized server-side).

Example: `GET /api/v1/detection/phone-number/trust-score?phone_number=%2B6512345678`

Response `200`:
```json
{
  "phone_number": "+6512345678",
  "trust_score": 18,
  "rating": "high_risk",
  "report_count": 42,
  "known": true,
  "classification": ""
}
```
- `trust_score`: integer **0–100**, where **0 = risky** and **100 = trusted**. It is derived from the number of community reports inside the active reporting window (more recent reports lower the score).
- `rating`: categorical bucket — `high_risk` (0–39), `unknown` (40–69), `trusted` (70–100).
- `report_count`: how many community reports back this number inside the active window (0 when unseen).
- `known`: `false` when the number has no reports or classification — in that case `trust_score` is the neutral default **60** (`rating: unknown`) and `report_count` is 0.
- `classification`: a free-form label assigned by the classification system (e.g. a scam category). It is `""` when no active classification applies. Classifications are **windowed** — they only apply for a bounded period after reporting, since scammers often spoof or reuse numbers temporarily.

Errors: `422` if `phone_number` is missing.

> **Classification note:** the classification system that assigns and expires labels is a
> separate component and is not implemented yet, so `classification` is currently always
> `""`. The field is part of the stable contract; clients should render it only when
> non-empty. Trust scores already reflect live community reports (see the report endpoint
> below).

### POST /detection/phone-number/report
**Auth required.** Lets a mobile app (or any client) report a phone number seen in a
suspicious message. Each report is appended to a trust-score ledger that feeds the
trust-score lookup above and the (separate) classification system.

Body:
```json
{ "phone_number": "+6512345678", "reason": "scam" }
```
- `phone_number` (required): formatting like spaces, `+`, `-`, `()` is fine — it is normalized server-side. Must contain at least one digit.
- `reason` (required): a short free-form label, max **32 characters**. Typical values are `scam`, `spam`, or `others`, but any short string is accepted.

Response `202 Accepted` with an empty body. The report is recorded for asynchronous
processing by the classification system; the reported number is **never logged**.

Errors:
- `401` if the request is unauthenticated.
- `422` if `phone_number` has no digits, `reason` is empty, or `reason` exceeds 32 characters.
- `409` if you already reported this phone number inside the current reporting window. Each user
  may report a given number **once per window** — repeating a report cannot inflate a number's
  report count or drag its trust score down.

> **Windowed scoring note:** reports only influence a number's trust score and
> classification for a bounded window (currently **30 days**). Older reports age out, so a
> number that stops being reported recovers its neutral default over time. This limits the
> impact of spoofed or temporary numbers. The same window governs the per-user duplicate-report
> limit: when your report ages out, you may report that number again.

---

## 6. Community feed & posts

Community submissions are **posts**. The listing is the **feed**.

### GET /community/feed
Optional auth. Recent posts, newest first.

Query params: `sort=recent` (default), `scam_type=<category-slug>`, `tag=<tag-slug>`, `cursor=`, `limit=`.

Response `200`:
```json
{
  "items": [
    {
      "post_id": "12",
      "title": "Fake bank SMS",
      "redacted_excerpt": "Your account is suspended ...",
      "category": { "slug": "phishing", "name_key": "category.phishing" },
      "tags": [ { "slug": "bank-impersonation", "name_key": "tag.bank_impersonation" } ],
      "review_status": "reviewed",
      "created_at": "2026-09-29T08:30:00Z",
      "comment_count": 4,
      "reactions": { "up": 10, "down": 1 },
      "my_vote": 0,
      "is_mine": false,
      "top_comments": [
        {
          "comment_id": "88",
          "author_label": "Alex",
          "body": "I got this exact message too!",
          "reply_count": 2,
          "created_at": "2026-09-29T09:10:00Z"
        }
      ]
    }
  ],
  "next_cursor": "..."
}
```

`reactions` carries the post's up/down vote counts, and `my_vote` is the
caller's own vote (`1`, `-1`, or `0`; always `0` for anonymous callers) — the
same shape as post detail (§6), so the card can render the current score and
highlight the user's vote without opening the post.

Every post is assigned a scam category by the classifier; when no real category
can be determined it falls back to the catch-all `other` category, so a post is
never left unclassified (`"category"` is always present in the response).

`is_mine` is `true` when the post was authored by the authenticated caller, and
`false` otherwise (always `false` for anonymous callers). Posts are published
anonymously — the feed never exposes who authored a post — so `is_mine` is the
only ownership signal, letting a logged-in user recognize their own submissions
in the public feed without revealing any other author's identity. Use
`GET /me/posts` to list only your own posts.

`top_comments` is a preview of up to **3** of the post's most active top-level
comments, ordered by activity (number of direct replies, `reply_count`) then
recency. It is a read-only preview for the card — fetch the full threaded
discussion from the comments endpoint (§8). The array is empty when a post has
no comments.

> **Ranking note:** comments have no like/vote mechanism in the current schema,
> so "most active" is measured by reply count, not likes. If true comment likes
> are needed later, a `comment_reactions` table (DB team) would let the ranking
> switch to score-based with no API-shape change.

### GET /community/feed/search
Optional auth. Full-text search over post titles and redacted bodies.
Query: `q=<text>`, plus `scam_type=`, `cursor=`, `limit=`. Same response shape as the feed.

### GET /community/posts/{id}
Optional auth. Full post detail.

Response `200`:
```json
{
  "post_id": "12",
  "title": "Fake bank SMS",
  "redacted_text": "Your account is suspended. Call [redacted-phone] ...",
  "category": { "slug": "phishing", "name_key": "category.phishing" },
  "tags": [ { "slug": "bank-impersonation", "name_key": "tag.bank_impersonation" } ],
  "review_status": "reviewed",
  "created_at": "2026-09-29T08:30:00Z",
  "updated_at": "2026-09-29T09:00:00Z",
  "comment_count": 4,
  "reactions": { "up": 10, "down": 1 },
  "my_vote": 1,
  "redacted_image_urls": [
    "/api/v1/community/posts/12/images/0",
    "/api/v1/community/posts/12/images/1"
  ]
}
```
`my_vote` is `1`, `-1`, or `0` (and `0` for anonymous callers). `category` is
always present: the classifier's prediction, or the catch-all `other` category
when none resolves. `404` if the post is
deleted/hidden/removed (moderators/admins can still see those).

`redacted_image_urls` lists every redacted screenshot attached to the post, in
display order; each entry is a relative API path (see
`GET /community/posts/{id}/images/{n}`), not a storage location. The field is
omitted when the post has no images.

### GET /community/posts/{id}/images/{n}
Public. Returns the redacted screenshot at 0-based position `{n}` in the post's
image list (the ordering of `redacted_image_urls`). PII-censored image only,
never a raw upload; body is raw image bytes (`Content-Type` is the image's media
type) with `Cache-Control: public, max-age=86400`; the copy is independent of the
author's private uploads. Returns `404` when `{n}` is out of range, the post is
not publicly visible, or does not exist.

### POST /community/posts
Authenticated. Publish a post. **Requires explicit `confirm_publication: true`.**
The server re-scrubs `redacted_text` for PII before storing.

Request:
```json
{
  "check_id": "55",
  "upload_ids": ["12", "13"],
  "title": "Fake bank SMS",
  "redacted_text": "Your account is suspended ...",
  "confirm_publication": true,
  "locale": "en-SG"
}
```
`check_id` is optional and now only records provenance (links the post to your
own detection; ignored if not yours).

`upload_ids` is an optional ordered list of uploads to attach as the post's
images. Each must be **your own** upload (from `POST /uploads`) whose detection
has finished and produced a redacted image. For each one the server copies the
**redacted** image into a fresh post-owned object; the copies are independent, so
they survive the private uploads' later expiry or deletion. The attached images
are served via `GET /community/posts/{id}/images/{n}` and surfaced as
`redacted_image_urls` (in `upload_ids` order) in the response. Only the redacted
copy is ever used; the raw upload is never published.

If any `upload_id` is not yours, does not exist, or its redaction has not yet
completed, the whole publish is rejected with `422` (`upload_ids`) and no post is
created. Poll `GET /detection/{check_id}` until `status` is `ready` before
publishing.

The scam category **and tags** are **not** client-supplied: both are assigned
by the backend classifier. Neither `scam_type` nor `tags` is accepted in the
request body (unknown fields are rejected with `422`). A post is always
classified and always tagged: when the classifier yields nothing usable (no
prediction, an unknown slug, or an outage) the server falls back to the
catch-all `other` category and `other` tag rather than leaving the post
unclassified. Predicted tag slugs that do not resolve to known tags are silently
dropped before the fallback is applied; a bad prediction never fails the
publish.

Response `201`: post detail (same shape as `GET /community/posts/{id}`).
Errors: `422` (missing confirmation, empty title/body, or any
`upload_ids` not yours / nonexistent / not yet redacted).

### PATCH /community/posts/{id}
Authenticated; author or moderator/admin. Edit title/body. Fields are optional;
omit to leave unchanged. Editing `redacted_text` re-scrubs it and resets
`review_status` to `unverified` (re-enters moderation). Tags are classifier-owned
and cannot be edited.
```json
{ "title": "Updated title", "redacted_text": "..." }
```
Response `200`: updated post detail. Errors: `403` not owner, `404` missing.

### DELETE /community/posts/{id}
Authenticated; author or moderator/admin. Soft-deletes the post. Response `204`.

### GET /me/posts
Authenticated. The authenticated user's own posts, in any `review_status`
(including `unverified`, `disputed`, `hidden`, and `removed` — ones that would
be filtered out of the public feed), newest first.

Because posts are published anonymously, this is the endpoint a client uses to
let a user find and manage their own submissions. Every item here belongs to the
caller, so `is_mine` is always `true`.

Query params: `cursor=`, `limit=`. Same item shape and response envelope as
`GET /community/feed` (`items[]` + optional `next_cursor`).

---

## 7. Reactions

One up/down vote per user per post.

### PUT /community/posts/{id}/reaction
Authenticated. Set or change your vote.
```json
{ "vote": 1 }
```
`vote` must be `1` (up) or `-1` (down). Response `200`:
```json
{ "up_count": 11, "down_count": 1, "my_vote": 1 }
```
Errors: `422` invalid vote, `404` post not visible.

### DELETE /community/posts/{id}/reaction
Authenticated. Clears your vote. Response `200`:
```json
{ "up_count": 10, "down_count": 1, "my_vote": 0 }
```

> Reaction and comment counts are community signals only — they never determine
> whether a scam is "verified". That stays a moderator decision.

---

## 8. Discussion (comments)

### GET /community/discussion/posts/{id}/comments
Optional auth. The full list of visible comments on a post, oldest first, with
cursor pagination. This is the dedicated per-post comments endpoint (the feed's
`top_comments` is only a 3-item preview).

Query: `cursor=`, `limit=` (**default 10**, max 100). Replies carry a `parent_id`.

Response `200`:
```json
{
  "items": [
    {
      "comment_id": "88",
      "parent_id": "80",
      "author_id": "3",
      "author_label": "Alex",
      "body": "I got this from a fake DHL number too.",
      "status": "visible",
      "created_at": "2026-09-29T09:10:00Z",
      "updated_at": "2026-09-29T09:10:00Z"
    }
  ],
  "next_cursor": "..."
}
```
`parent_id` is present only for replies. `author_label` is a display name (or
`"removed user"`); email is never exposed.

### POST /community/discussion/posts/{id}/comments
Authenticated. Add a comment (body is server-scrubbed).
```json
{ "body": "Watch out, I received the same message.", "parent_id": "80" }
```
`parent_id` is optional (one-level replies) and must belong to the same post.
Response `201`: the created comment. Errors: `422` empty body / bad parent, `404` post not visible.

### PATCH /community/discussion/comments/{id}
Authenticated; author only. Edit the body (re-scrubbed).
```json
{ "body": "Edited text" }
```
Response `200`: updated comment. Errors: `403` not author, `404` missing.

### DELETE /community/discussion/comments/{id}
Authenticated; author or moderator/admin. Soft-removes the comment (`status: removed`).
Response `204`.

---

## 9. Flagging content for moderators

Flag a post or comment for moderator review (the "🚩 report this" action). The main
use case is a public post that slipped out with personal information still in it —
flag it so a moderator can hide/re-scrub it.

### POST /community/posts/{id}/flag
Authenticated.
```json
{ "reason": "personal_information", "details": "Contains someone's phone number." }
```
`reason` ∈ `personal_information | harmful | spam | misinformation | other`. `details`
optional. Response `201`:
```json
{ "flag_id": "5", "status": "open" }
```
Each user can flag a given post once — a repeat returns `409`. This is separate from
the phone-number **report/lookup** feature in §5.

### POST /community/discussion/comments/{id}/flag
Authenticated. Same request/response shape, for a comment.

---

## 10. Taxonomy

### GET /community/scam-types
Public. All scam-type categories.
```json
{ "items": [ { "slug": "phishing", "name_key": "category.phishing", "description_key": "category.phishing.desc" } ] }
```

### GET /community/tags
Public. Tags, optionally filtered. Query: `q=<substring>`, `limit=`.
```json
{ "items": [ { "slug": "bank-impersonation", "name_key": "tag.bank_impersonation" } ] }
```

> `name_key`/`description_key` are i18n keys — resolve them client-side against your
> localization bundle.

---

## 11. Guidance & resources ("Get help now")

### GET /guidance
Optional auth. Situation-specific next steps for a scenario.
Query: `scenario=<clicked_link|just_received|shared_credentials|sent_money|...>`, `locale=`.

Response `200`:
```json
{
  "items": [
    {
      "id": "7",
      "scenario": "clicked_link",
      "urgency": "urgent",
      "title": "You clicked a suspicious link",
      "body": "Do not enter any details ...",
      "resources": [
        {
          "id": "3",
          "slug": "scamshield",
          "country_code": "SG",
          "url": "https://www.scamshield.gov.sg",
          "contact_instructions": "Call 1799",
          "name": "ScamShield",
          "description": "National anti-scam helpline",
          "verified_at": "2026-09-01T00:00:00Z",
          "owner_name": "Content Team"
        }
      ]
    }
  ]
}
```
`urgency` ∈ `normal | urgent | emergency`. Translations fall back to `en-SG` when the
requested locale is missing.

### GET /guidance/resources
Optional auth. The vetted resource catalog. Query: `country=SG` (default), `scenario=`, `locale=`.
```json
{ "items": [ { "id": "3", "slug": "scamshield", "country_code": "SG", "url": "https://www.scamshield.gov.sg", "name": "ScamShield", "verified_at": "2026-09-01T00:00:00Z", "owner_name": "Content Team" } ] }
```
URLs and contact details are returned exactly as stored — the API never fabricates them.

---

## 12. Moderation (moderator/admin only)

### GET /moderation/queue
Open reports (flags) oldest first (paginated).
```json
{
  "items": [
    {
      "flag_id": "5",
      "reason": "personal_information",
      "details": "Contains a phone number.",
      "created_at": "2026-09-29T09:20:00Z",
      "target_type": "post",
      "target_id": "12",
      "excerpt": "Your account is suspended ..."
    }
  ],
  "next_cursor": "..."
}
```
`target_type` is `post` or `comment`.

### POST /moderation/posts/{id}/review
Moderator/admin. Decide on a post.
```json
{ "decision": "hide", "rationale": "Contains PII", "suggestion_id": "2" }
```
`decision` ∈ `reviewed | disputed | hide | remove | restore`. Effect on `review_status`:
`reviewed→reviewed`, `disputed→disputed`, `hide→hidden`, `remove→removed`,
`restore→unverified`. Related open reports for the post are resolved. `rationale` and
`suggestion_id` optional. Response `200`:
```json
{ "decision_id": "9", "post_id": "12", "decision": "hide", "rationale": "Contains PII", "created_at": "2026-09-29T09:25:00Z" }
```

### POST /moderation/comments/{id}/review
Moderator/admin. Decide on a comment.
```json
{ "decision": "remove", "rationale": "Harassment" }
```
`decision` ∈ `reviewed | hide | remove | restore` (`disputed` is invalid for comments →
`422`). Effect on comment `status`: `hide→hidden`, `remove→removed`, `restore→visible`,
`reviewed→` no visible change. Response `200`: decision record with `comment_id` instead of `post_id`.

---

## 13. Admin resource catalog (admin only)

### POST /admin/resources
```json
{
  "slug": "scamshield",
  "country_code": "SG",
  "url": "https://www.scamshield.gov.sg",
  "contact_instructions": "Call 1799",
  "owner_name": "Content Team",
  "verified_at": "2026-09-01T00:00:00Z",
  "translations": [ { "locale": "en-SG", "name": "ScamShield", "description": "National anti-scam helpline" } ]
}
```
Must provide at least one of `url` / `contact_instructions`, and at least one translation.
`verified_at` is required (RFC3339). Response `201`: the resource. Errors: `409` duplicate slug, `422` validation.

### PATCH /admin/resources/{id}
Partial update. Any of `country_code`, `url`, `contact_instructions`, `owner_name`,
`verified_at`, `translations` (upserted). Response `200`: updated resource.

### POST /admin/resources/{id}/archive
Sets the resource inactive (removes it from public listings). Response `204`.

---

## 14. Operations

### GET /health/live
Public. Liveness. `200 { "status": "ok" }`.

### GET /health/ready
Public. Readiness (pings the database). `200 { "status": "ready" }` or `503`.

---

## 15. Full route index

| Method | Path | Access |
|---|---|---|
| POST | `/auth/register` | Public |
| POST | `/auth/login` | Public |
| POST | `/auth/refresh` | Public |
| POST | `/auth/logout` | Public |
| GET | `/me` | Authenticated |
| POST | `/uploads` | Authenticated |
| GET | `/uploads/{id}` | Authenticated (owner) |
| GET | `/uploads/{id}/redacted-image` | Authenticated (owner) |
| DELETE | `/uploads/{id}` | Authenticated (owner) |
| POST | `/detection` | Authenticated |
| GET | `/detection/{id}` | Authenticated (owner) |
| DELETE | `/detection/{id}` | Authenticated (owner) |
| GET | `/detection/{id}/redacted-image` | Authenticated (owner) |
| GET | `/me/detection` | Authenticated |
| POST | `/detection/{id}/resource-opens` | Optional auth |
| GET | `/detection/phone-number/trust-score` | Optional auth |
| GET | `/community/feed` | Optional auth |
| GET | `/community/feed/search` | Optional auth |
| GET | `/community/posts/{id}` | Optional auth |
| GET | `/community/posts/{id}/images/{n}` | Public |
| POST | `/community/posts` | Authenticated |
| PATCH | `/community/posts/{id}` | Authenticated (author/mod) |
| DELETE | `/community/posts/{id}` | Authenticated (author/mod) |
| GET | `/me/posts` | Authenticated |
| PUT | `/community/posts/{id}/reaction` | Authenticated |
| DELETE | `/community/posts/{id}/reaction` | Authenticated |
| POST | `/community/posts/{id}/flag` | Authenticated |
| GET | `/community/scam-types` | Public |
| GET | `/community/tags` | Public |
| GET | `/community/discussion/posts/{id}/comments` | Optional auth |
| POST | `/community/discussion/posts/{id}/comments` | Authenticated |
| PATCH | `/community/discussion/comments/{id}` | Authenticated (author) |
| DELETE | `/community/discussion/comments/{id}` | Authenticated (author/mod) |
| POST | `/community/discussion/comments/{id}/flag` | Authenticated |
| GET | `/guidance` | Optional auth |
| GET | `/guidance/resources` | Optional auth |
| GET | `/moderation/queue` | Moderator |
| POST | `/moderation/posts/{id}/review` | Moderator |
| POST | `/moderation/comments/{id}/review` | Moderator |
| POST | `/admin/resources` | Admin |
| PATCH | `/admin/resources/{id}` | Admin |
| POST | `/admin/resources/{id}/archive` | Admin |
| GET | `/health/live` | Public |
| GET | `/health/ready` | Public |

---

## 16. Notes for teammates

- **Private detection retention & deletion:** private uploads expire after **24 hours** and private checks after **30 days** (schema defaults, indexed by `expires_at`). A background **retention reaper** enforces these windows — enabled with `REAPER_ENABLED` (default `true`), running every `REAPER_INTERVAL` (default `1h`) — deleting expired rows and purging their stored blobs. Owners can also delete immediately: `DELETE /detection/{id}` removes a check (and its uploads and blobs) and `DELETE /uploads/{id}` cancels an upload. Deleting a check is irreversible, cascades its uploads, and nulls `source_check_id` on any published post (the post and its own image copy are unaffected).
- **Screenshot uploads:** `POST /uploads` stores the image and schedules background OCR + PII redaction only. Poll `GET /uploads/{id}`; once ready, `POST /detection` creates a check and classifies the stored redacted text. The redacted image is available via `GET /uploads/{id}/redacted-image` or, once linked, `GET /detection/{id}/redacted-image`, and can be copied to a published post. Redaction is delegated to the Python PII-removal service; when unavailable uploads become failed. Text detection does not depend on it.
- **Phone-number data source:** `GET /detection/phone-number/trust-score` works end to end but its data source is stubbed — until the data team wires the phone reputation table, every number returns `known: false` with the default score 60. The response contract is final.
- **Flag vs. phone report:** "flag" (§9) escalates a *post/comment* to moderators. The phone-number feature (§5) is a *lookup* against the scam-number database. They are unrelated.
- **DB note (backend/DB team):** the `report_receipts` table in `init.sql` is now unused — the "I received this too" feature was removed in favour of reactions. It can be dropped in a future migration.
- **Naming note:** the public API says `posts`, but internally the Go package and the `reports` DB table keep the name `reports`. This is intentional and does not affect the API.
- **i18n:** `name_key` / `description_key` on categories and tags are localization keys, not display strings. Guidance/resource `name`, `title`, `body`, `description` are already localized (with `en-SG` fallback).
