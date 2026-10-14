# PII Redaction Service — HTTP Contract

This document specifies **exactly** what the Python PII-removal service must
expose for the Go backend (`scamshield`) to use it. It is the authoritative
contract for the Go ↔ Python boundary.

The Go side depends only on the `pii.Redactor` interface
(`backend/internal/pii/pii.go`); the HTTP implementation lives in
`backend/internal/pii/client.go`. When `PII_SERVICE_URL` is set, the backend
constructs `pii.NewClient(url)` and calls the service described here. When it is
empty, a stub is used that always fails (screenshot checks resolve to
`failed`).

Co-locating the two processes is expected, but the boundary is plain HTTP so
they can restart, scale, and be swapped independently.

---

## ⚠️ Current mismatch (must be reconciled before anything works)

The Python service in `AI/` and the Go client **do not currently agree**. As
wired today they cannot talk to each other. Every dimension differs:

| Dimension | Go client expects (`client.go`) | Python exposes today (`AI/app/main.py`) |
| --- | --- | --- |
| URL path | `POST /v1/redact` | `POST /v1/pii/redact` |
| Request encoding | `multipart/form-data` | JSON body |
| Image field | file part `image` (raw bytes) | `image_base64` (base64 string) |
| Media type field | from the image part's `Content-Type` header | `media_type` (JSON string) |
| Locale field | text part `locale` | `locale` (JSON, optional) |
| Response: text | `redacted_text` | `extracted_text` |
| Response: image | `image_base64` | `redacted_image_base64` |
| Response: media type | `image_media_type` | `media_type` |
| Response: region count | `regions_redacted` | `pii_box_count` (+ `total_box_count`) |

**Pick one side as the source of truth and change the other to match.** The two
options are laid out at the end under “Reconciliation options.” The spec below
describes the contract the **Go client requires** — i.e. what the Python service
must expose if we keep the Go side unchanged.

---

## Endpoint the Go client calls

### `POST {PII_SERVICE_URL}/v1/redact`

Takes one screenshot, returns the PII-stripped text and a censored copy of the
image.

#### Request — `multipart/form-data`

| Part | Kind | Required | Description |
| --- | --- | --- | --- |
| `locale` | text | yes (may be empty string) | OCR/language hint, e.g. `en-SG`. The Go side always sends it; it is derived from the check's locale. |
| `image` | file | yes | Raw screenshot bytes. The part carries a `Content-Type` header set to the upload's media type (`image/jpeg`, `image/png`, or `image/webp`) and a `filename` like `upload.png`. |

Notes for the implementer:
- The image is sent as **raw bytes in a file part**, not base64. Read it from
  the multipart `image` field (e.g. FastAPI `UploadFile = File(...)`).
- Trust but verify the declared `Content-Type`; the Go upload layer already
  restricts uploads to `image/jpeg | image/png | image/webp` and caps size at
  **10 MiB**, but the service should still decode defensively.
- The Go HTTP client timeout is **60 seconds**. OCR + the decision model must
  comfortably finish within that or the Go worker marks the check `failed`.

#### Response — `200 application/json`

```json
{
  "redacted_text":    "string",
  "image_base64":     "string",
  "image_media_type": "image/png",
  "regions_redacted": 3
}
```

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `redacted_text` | string | yes | Extracted text with PII removed. May be empty if no text was found. Treated as sensitive by the Go side and never logged. |
| `image_base64` | string | yes | The censored image, base64-encoded (standard encoding, with padding). Decoded with Go's `base64.StdEncoding`. Must be non-empty — an empty string is treated as an error. |
| `image_media_type` | string | yes | Content type of the censored image, e.g. `image/png`. If omitted/empty, the Go side falls back to the original upload's media type. |
| `regions_redacted` | integer | no | Count of censored regions. Non-content metadata, safe to log. Defaults to 0 if omitted. |

#### Error responses

Any **non-200** status, transport error, timeout, or malformed/undecodable body
causes the Go side to wrap `pii.ErrUnavailable` and **fail the check** — it will
never persist or publish un-redacted content. Specifically:

- Use a non-2xx status (e.g. `400` for a bad image, `502` when the downstream
  decision model is unavailable) to signal failure.
- **Fail closed:** if PII detection cannot complete, return an error status
  rather than a possibly under-redacted image. This matches the existing
  Python behaviour (502 on clef outage).
- The Go side reads at most 4096 bytes of a non-200 body and discards it (never
  logged), so error bodies need not be structured.

#### Privacy requirements (non-negotiable)

Mirrors `AGENTS.md` and the Go-side posture:

- **Never log** image bytes, OCR text, per-box text, `redacted_text`, or any raw
  message content. Log only ids, counts, latency, status, and media types.
- `redacted_text` returned to Go must already have PII replaced/removed.
- Only text (never screenshot pixels) is sent onward to any decision model.

---

## Health check

The Go client does not call a health endpoint, but operators should expose one.
The current Python service exposes `GET /healthz` → `{"status":"ok"}`. Keep it.

---

## Reconciliation options

Choose one; do not leave the mismatch in place.

### Option A — change Python to match the Go client (smallest Go footprint)

Add a `POST /v1/redact` route to the FastAPI app that:
1. accepts `multipart/form-data` (`locale` text part + `image` file part),
2. reads raw image bytes from the file part (no base64 decode on input),
3. runs the existing OCR → decide → censor pipeline,
4. returns JSON with the **Go field names**: `redacted_text`, `image_base64`,
   `image_media_type`, `regions_redacted`.

This can be a thin adapter in front of the existing `redact_endpoint` logic.
The existing `/v1/pii/redact` JSON endpoint can stay for other callers.

Field remapping from the current Python internals:
- `extracted_text` → `redacted_text`
- `base64(censored image)` → `image_base64`
- `media_type` → `image_media_type`
- `pii_box_count` → `regions_redacted`
- the Go contract has no equivalent of `total_box_count`; drop it or keep it as
  an extra field (the Go decoder ignores unknown fields).

### Option B — change the Go client to match Python

Edit `backend/internal/pii/client.go` to:
1. POST to `/v1/pii/redact`,
2. send JSON `{ "image_base64", "media_type", "locale" }` (base64-encode the
   image in Go),
3. decode the response fields `redacted_image_base64`, `media_type`,
   `extracted_text`, `pii_box_count` into `pii.Result`.

This keeps the Python service untouched but means base64-encoding the image on
the Go side (larger request bodies) and re-pointing the documented wire
protocol in `client.go`.

**Recommendation:** Option A. Multipart avoids base64-inflating a 10 MiB upload
on every request, and keeping the Go-side `pii.Result` field names stable
avoids churn in the detection worker. The Python change is a small additive
adapter.
