# AGENTS.md

Guidance for AI agents working in this repository. Read this before making changes.

## What this project is

**ScamWatch** (internal/code name `scamshield`, public API term "Community Scam Shield") is a community-centric platform — web and mobile — that helps protect mostly seniors and other at-risk users from scam messages. Users can privately check a suspicious message, then optionally publish a redacted version to a public community feed where others learn from real examples. Moderators review flagged content.

Core user-facing capabilities:
- **Private detection** — paste text or a screenshot and get an explainable scam assessment (never public).
- **Community feed** — browse, search, post, comment on, and vote on redacted scam examples.
- **Phone trust score** — look up a phone number's 0–100 reputation (0 = risky, 100 = trusted).
- **Guidance & resources** — situation-specific next steps and a vetted official resource catalog (Singapore-oriented pilot: ScamShield 1799).
- **Moderation** — flag queue, review decisions, resource catalog admin.

Audience is non-technical seniors, so copy must be plain, calm, and never alarmist. A `likely_safe` verdict is explicitly **not** a safety guarantee, and `unclear` is a valid outcome. Never present `unverified` community posts as confirmed fact.

## Privacy is a hard requirement

This is the single most important constraint in the codebase. Treat it as non-negotiable:

- Private checks and uploads are **never** exposed through the public report/post tables. A post contains only the explicitly approved, redacted text the user confirmed for publication.
- Publishing a post requires explicit `confirm_publication: true`; the server **re-scrubs** `redacted_text` for PII before storing. Comments are scrubbed too.
- **Never log** `input_text`, `extracted_text`, or any raw message content. Excerpts echoed back to users are length-bounded and have URLs reduced to host-only, non-clickable form (e.g. `[link: example.com]`).
- Private detection requires authentication: checks and uploads are always owned, and anonymous checks are not supported. Ownership failures resolve to `not_found` to avoid leaking existence.
- Private detection data is retained for a bounded period — uploads default to 24h, checks to 30 days — and is deleted (rows **and** stored blobs) either by its owner on request or by the retention reaper. Deletion is real removal, never a hide-only flag.
- Be cautious with `.env` and any credential files. Reference secrets by key name, never echo their values.

## Repository layout

```
.
├── init.sql            # PostgreSQL schema (source of truth for the data model)
├── README.md
└── backend/            # Go HTTP API service (module: scamshield)
    ├── API.md          # HTTP API contract — read this for endpoint shapes
    ├── cmd/
    │   ├── api/        # main.go — HTTP service entrypoint
    │   └── dbsetup/    # one-off schema provisioning helper
    ├── internal/
    │   ├── auth/       # register/login/refresh/logout, JWT, roles, middleware
    │   ├── checks/     # private detection (detection = "checks" internally)
    │   ├── classifier/ # post scam-category classifier port + stub (Python model not wired yet)
    │   ├── config/     # env-var config loading with dev defaults
    │   ├── httpx/      # middleware (request ID, logging, recover, rate limit), JSON/error helpers
    │   ├── moderation/ # flag queue + moderator decisions
    │   ├── platform/db/# pgx pool connect/ping
    │   ├── reports/    # community posts/feed/comments/reactions ("posts" = "reports" internally)
    │   └── resources/  # guidance + resource catalog + admin
    ├── .env.example
    ├── go.mod / go.sum
    ├── seed.sql / seed_demo.ps1 / promote_mod.sql
    ├── e2e_test.ps1 / e2e_moderation.ps1
    └── build_linux.sh / build_linux.bat
```

## Backend (Go) — the live service

- **Language/runtime:** Go 1.25. Module name is `scamshield`.
- **Dependencies:** `pgx/v5` (Postgres), `golang-jwt/jwt/v5`, `google/uuid`, `golang.org/x/crypto` (bcrypt), `stretchr/testify` (tests). Keep the dependency set lean; prefer the standard library.
- **HTTP:** standard-library `net/http` with Go 1.22+ method+pattern routing (`mux.Handle("GET /api/v1/...")`). No web framework.
- **Architecture per domain package:** `handler.go` (HTTP), `service.go` (business logic, transport-agnostic), `repository.go` (Postgres via pgx). Follow this layering when adding features — handlers never touch the DB directly.
- **Routing:** all routes are prefixed `/api/v1`. Middleware chains are composed with `httpx.Chain`; auth via `auth.RequireAuth` / `auth.OptionalAuth` / `auth.RequireRole`.
- **Error shape & conventions:** JSON, `snake_case` keys. IDs are opaque **strings** in JSON (integers server-side). Timestamps are UTC RFC3339. List endpoints use cursor pagination (`?limit=` default 20 max 100, `?cursor=` opaque). Use the standard error envelope in `API.md` §3 (`{ "error": { "code", "message", "fields" }, "request_id" }`).
- **API contract:** `backend/API.md` documents every endpoint. The handlers under `internal/*/handler.go` are the source of truth; if you change behavior, update `API.md` to match.

### Internal vs public naming (do not "fix" these)
- Public API says **post** / **feed**; the Go package and DB table are named **reports**. Intentional.
- Public API says **detection**; the Go package is named **checks**. Intentional.

### Post scam-category classifier
`POST /community/posts` does **not** accept `scam_type`. The category is assigned server-side by `internal/classifier` (`Classifier.Classify(ctx, scrubbedText, locale)`), currently wired to `classifier.NewStub()` in `cmd/api/main.go`, which always returns `"phishing"`. `reports.category_id` is therefore **nullable**: a post with `category_id IS NULL` is *unclassified* and visible only to its author (`GET /me/posts`, post detail) and to moderators — it is excluded from the public feed, search, reactions and flags. Classification failure must never fail the publish; it just leaves the post unclassified. Swap the stub for a real decision-model client (Python service below) behind the same interface — it receives only scrubbed text and must never log it.

### Current detection classifier
Text detection is classified by the Python AI service's decision model. `internal/checks/classifier.go` defines the `Classifier` port, an `HTTPClassifier` that POSTs to the AI service's `/v1/classify` (the same base URL as redaction, `PII_SERVICE_URL`), and a bounded `ClassifierPool` that fronts it: at most `DefaultClassifierWorkers` (= 2) classifications run at once, and a failed call is retried up to `DefaultClassifierRetries` (= 2) times. There is **no local rules analyzer** any more. A classifier outage fails the check — HTTP `503` (`classification_unavailable`) for text checks, `status: "failed"` for screenshot checks — rather than synthesizing a verdict. Only scrubbed/redacted text is ever sent to the service, and it is never logged. The `checks.Assessment` response contract is stable — coordinate before changing it.

## Running the backend locally

Work from the `backend/` directory (where `go.mod` lives).

1. Copy env: `cp .env.example .env` and fill real values (see `internal/config/config.go` for all keys and defaults: `DATABASE_URL`, `HTTP_ADDR` default `:8080`, `JWT_SECRET`, `APP_ENV`, `ACCESS_TOKEN_TTL` default `15m`, `REFRESH_TOKEN_TTL` default `720h`, `BCRYPT_COST` default `12`). Config auto-loads `.env` from the working dir; real env vars win over the file. `JWT_SECRET` must be set in non-development environments.
2. Provision the schema: `go run ./cmd/dbsetup --dsn "$DATABASE_URL" --schema ../init.sql` (defaults to `$DATABASE_URL` and `../init.sql`). `--drop` drops existing tables first (**destructive** — ask before using against anything shared).
3. Optionally seed: `backend/seed.sql`, `seed_demo.ps1`, `promote_mod.sql`.
4. Run: `go run ./cmd/api`.

### Build, test, verify
- **Build:** `go build ./...`. Linux release binary: `./build_linux.sh` (or `build_linux.bat`) → `builds/hackit-16-backend-linux-amd64` (static, CGO disabled).
- **Test:** `go test ./...`. Add table-driven tests for new logic; `phone_test.go` is a good model to follow.
- **E2E:** `e2e_test.ps1` and `e2e_moderation.ps1` (PowerShell) exercise the live API.
- Always build and run relevant tests after a change before presenting it. Clean up temporary files.

## Python services (planned) — PII removal & scam classification

A **single Python server** will host two concerns, each in its **own virtualenv** (keep their dependencies isolated):

1. **PII removal / cleanup** for screenshot uploads:
   - **PaddleOCR** extracts text and bounding boxes from the image.
   - A **decision model** marks which detected regions are sensitive (PII).
   - **Pillow (PIL)** censors the sensitive bounding boxes directly on the image.
   - Output is cleaned extracted text plus a redacted image. Raw/original content must never be logged or exposed publicly.

2. **Scam classification** using decision model(s) (details to be provided later). This replaces the removed Go rules-first analyzer; text detection now calls it via `internal/checks/classifier.go` (`POST /v1/classify`).

### How this connects to the Go backend
The Go side already has the seam for this, currently stubbed:
- `internal/checks/service.go` → `ProcessUpload(ctx, checkID, uploadID)` is the entry point an async OCR+redaction worker calls after a screenshot check is parked in `processing`. Its flow: fetch image via `upload.StorageKey` → run OCR → redact PII from extracted text → classify via `POST /v1/classify` → persist via `repo.CompleteCheckFromUpload`. It marks the check `failed` rather than fabricating a result (and when OCR recovers no text, completes `ready` with no assessment).
- `POST /uploads` and `POST /detection` require authentication (uploads and checks are always owner-scoped). `POST /detection` also accepts an `upload_id` to schedule a screenshot check as a separate step. The OCR + PII-redaction worker runs through the `pii.Redactor` bridge and is only live when `PII_SERVICE_URL` is configured; otherwise screenshot checks fail cleanly rather than persisting un-redacted content. Coordinate before building screenshot UI/flow.
- The phone-number trust-score endpoint works end-to-end but its data source is stubbed (every number returns `known: false`, default score 60). The response contract is final.
- Retention and cancellation are implemented: private uploads expire after 24h and checks after 30d (schema `expires_at` defaults), enforced by the background reaper in `internal/checks/reaper.go` (started from `cmd/api/main.go`, configured by `REAPER_ENABLED`/`REAPER_INTERVAL`). Owners can also delete immediately via `DELETE /detection/{id}` and `DELETE /uploads/{id}`; deletion removes the rows and purges the raw + redacted blobs. Deleting a check actively cancels its in-flight OCR + PII-removal worker (workers are registered per check in `internal/checks/service.go` and hold a 1s grace period before starting redaction, so a quick delete costs no compute), and is safe mid-OCR — any completion update that still races through finds no row, so the worker discards the redacted blob it just wrote.

When wiring Python in, keep the Go/Python boundary behind a clear interface (e.g. HTTP call from a Go worker to the Python server), preserve the privacy rules above (no raw-content logging; redaction before anything is persisted or published), and keep the Go `Assessment`/detection response contract stable unless a change is explicitly agreed.

### Python conventions (apply once the service exists)
- One venv per concern (PII, scam classification). Pin dependencies (e.g. `requirements.txt` with exact versions) per venv.
- Keep models and heavy weights out of git; document how to fetch them.
- Mirror the backend's privacy posture: never log image bytes, OCR text, or raw messages.

## Working agreements for agents

- **Match existing patterns.** Follow the handler/service/repository layering, `snake_case` JSON, opaque string IDs, cursor pagination, and the standard error envelope.
- **Keep `API.md` and `init.sql` in sync** with code changes. `init.sql` is the data-model source of truth; handlers are the API source of truth.
- **Privacy first** on every change touching checks, uploads, posts, or comments.
- **Verify before claiming done:** `go build ./...` and `go test ./...` for backend changes.
- **Destructive actions** (schema `--drop`, bulk deletes, anything against shared/live data) need explicit confirmation first.
- Note: `report_receipts` in `init.sql` is unused (feature removed in favor of reactions) and may be dropped in a future migration.
