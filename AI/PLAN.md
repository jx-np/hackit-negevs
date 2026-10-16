# PLAN.md — ScamWatch Python AI Service

Build plan for the **Python AI service** that lives under `AI/` (next to `backend/`). This document is written for the agent that will implement it. Read `../AGENTS.md` first for project-wide context and the non-negotiable privacy rules. This plan is the authoritative spec for the AI service; where this plan and your assumptions disagree, follow this plan.

> Scope for this phase: **PII Removal** and **Scam Classification** only. A potential third "Scam Detection" service (for the mobile app's on-device fallback) is **explicitly out of scope** and must not be built now.

---

## 1. What you are building

A **single Python server** (FastAPI) that the Go backend calls over HTTP. It hosts two concerns, each in its **own virtualenv** so their dependencies stay isolated:

1. **PII Removal** — takes a screenshot, OCRs it, decides which text regions are personal data, and censors those regions on the image.
2. **Scam Classification** — takes message text and returns the full explainable `Assessment` the Go side already models.

Both concerns call a **separate, GPU-hosted decision model** — Cloudflare `clef-flash`, served by **SGLang** — over its `/v1/systemone` endpoint. The decision model is **not** a venv or a Python dependency; it is a separate process (Docker container) that your service talks to as an HTTP client.

### Process topology (three processes)

```
┌────────────────┐   HTTP (/v1/pii/redact,     ┌─────────────────────────┐   HTTP (/v1/systemone)   ┌───────────────────────────┐
│  Go backend    │   /v1/classify)             │  AI API server (FastAPI)│                          │  SGLang serving           │
│  (scamshield)  │ ──────────────────────────▶ │  CPU: PaddleOCR + Pillow│ ───────────────────────▶ │  Cloudflare/clef-flash    │
│  ProcessUpload │ ◀────────────────────────── │  + orchestration        │ ◀─────────────────────── │  GPU (Docker)             │
└────────────────┘   redacted image + text     └─────────────────────────┘   per-option probabilities └───────────────────────────┘
```

- **AI API server**: your code. Runs on **CPU** (PaddleOCR + Pillow). This is the only process the Go backend knows about.
- **SGLang clef-flash**: infra you run on a **GPU** box/container. Your AI server is just an HTTP client to it. Base URL is configurable (`CLEF_BASE_URL`).
- The two venvs (`pii`, `classify`) are internal to the AI API server.

---

## 2. Directory layout to create

```
AI/
├── PLAN.md                   # this file
├── README.md                 # how to set up venvs, run SGLang, run the server (write this)
├── .env.example              # all env keys with safe dev defaults (see §8)
├── app/                      # FastAPI server — the one process Go talks to
│   ├── __init__.py
│   ├── main.py               # FastAPI app, endpoint wiring, startup/shutdown
│   ├── config.py             # env loading (CLEF_BASE_URL, model names, thresholds, timeouts)
│   ├── clef_client.py        # thin async /v1/systemone HTTP client (shared by both concerns)
│   ├── schemas.py            # pydantic request/response models (match Go contract in §6)
│   └── logging.py            # privacy-safe logging setup (NEVER logs raw text/image bytes)
├── pii/                      # PII removal concern (own venv)
│   ├── __init__.py
│   ├── requirements.txt      # paddleocr, paddlepaddle (CPU), pillow, numpy — pinned
│   ├── ocr.py                # OcrEngine.extractImageWithBoundingBox(image)
│   ├── decide.py             # per-box noul question → is-PII? via clef_client
│   └── censor.py             # Pillow: fill PII bounding boxes on the image
├── classify/                 # scam classification concern (own venv)
│   ├── __init__.py
│   ├── requirements.txt      # httpx/pydantic only — no heavy ML deps — pinned
│   └── classify.py           # build questions, call clef, map to Assessment
├── sglang/
│   └── run-clef.sh           # docker run command for clef-flash (see §4)
└── tests/
    ├── test_ocr.py
    ├── test_decide.py
    ├── test_censor.py
    └── test_classify.py
```

> **Venv note.** The user wants one venv per concern. Practically, `app/` imports from both `pii/` and `classify/`. Set up so the running server uses the **PII venv** (the heavier one with PaddleOCR) as the host interpreter and treats `classify/` as pure-Python callable within it, OR run two workers. Default recommendation: a single process on the PII venv, with `classify/requirements.txt` installed into it too; keep the `classify/` requirements file separate so the classification concern stays dependency-light and could be split into its own process later. Document whichever you choose in `README.md`.

---

## 3. The decision model: Cloudflare clef-flash via `/v1/systemone`

`clef-flash` is a decision model: you give it a `state` (the thing to reason about) and a set of typed **questions**, and in a single forward pass it returns a **probability per allowed option per question**. There is **no free-form text output and nothing to parse** — you read probabilities directly. This is why it is used for both PII decisions and scam classification.

### Endpoint

`POST {CLEF_BASE_URL}/v1/systemone`

### Request body

```jsonc
{
  "model": "Cloudflare/clef-flash",
  "state": "<string or JSON — the content to reason about>",
  "questions": {
    "<question_id>": { "type": "...", "instructions": "...", /* type-specific fields */ }
  }
  // "images": [ ... ]  // Clef extension; NOT used in this project (see note below)
}
```

- 1–64 questions per call. `instructions` is optional and defaults to the question id — always provide clear instructions anyway.
- **We pass TEXT ONLY.** Do not send the screenshot image to clef (`images` is unused). PII decisions run on the OCR'd text of each box, not the pixels.

### Question types we use

| Type | Shape | Returns |
| --- | --- | --- |
| `noul` | `{ "type": "noul", "instructions": "..." }` | probability that the statement is **true** |
| `choice` | `{ "type": "choice", "instructions": "...", "criteria": { "optId": "desc", ... } }` | `choice` (argmax), `confidence`, `probabilities` |
| `score` | `{ "type": "score", "instructions": "...", "criteria": ["level0","level1",...] }` | `score` = Σ(level_index × prob), `confidence`, `legend`, `probabilities` |

### Response body

```jsonc
{
  "model": "Cloudflare/clef-flash",
  "answers": {
    "<question_id>": { /* type-specific: probability | choice+confidence+probabilities | score+legend+probabilities */ }
  },
  "usage": { /* token usage */ }
}
```

### `clef_client.py` requirements

- Async HTTP client (httpx.AsyncClient) with a configurable base URL (`CLEF_BASE_URL`, default `http://localhost:30000`) and timeout (`CLEF_TIMEOUT_SECONDS`, default `30`).
- One method: `async def system_one(state: str, questions: dict) -> dict` returning the parsed `answers` map.
- Validate `len(questions)` is in `[1, 64]`; if a caller needs more, it must batch (see §5.2).
- On non-2xx or timeout, raise a typed error the callers translate into a safe failure (PII: fail closed — see §5.4; classification: return an `unclear` fallback — see §6.4).
- **Never log** `state`, question instructions that embed content, or raw answers containing content. Log only question ids, counts, latency, and status.

> Known gotcha from upstream: `/v1/systemone` may not be reachable through the SGLang **model gateway**; call the SGLang server **directly**. Point `CLEF_BASE_URL` at the SGLang server port, not a gateway.

---

## 4. Serving clef-flash with SGLang (infra)

This is a **separate process** on a GPU host. The implementing agent writes `sglang/run-clef.sh` and documents it; running it is an ops step, not part of the Python app.

`sglang/run-clef.sh` (single-GPU example, e.g. H200 — adjust for the actual GPU):

```bash
#!/usr/bin/env bash
set -euo pipefail

docker run --gpus all --shm-size 32g -p 30000:30000 \
  -v "$HOME/.cache/huggingface:/root/.cache/huggingface" \
  --ipc=host \
  lmsysorg/sglang:dev-clef \
  sglang serve \
    --model-path Cloudflare/clef-flash \
    --host 0.0.0.0 \
    --port 30000
```

- The server then answers Jev/SystemOne at `http://<host>:30000/v1/systemone`.
- Smoke test to put in `README.md`:

```bash
curl http://localhost:30000/v1/systemone \
  -H 'Content-Type: application/json' \
  -d '{"model":"Cloudflare/clef-flash","state":"Please verify your bank OTP now","questions":{"urgency":{"type":"noul","instructions":"Does this message express urgency?"}}}'
```

- Requires a capable GPU; this is the main infra prerequisite. The AI API server itself stays CPU-only.
- Document that model weights are fetched from Hugging Face into the mounted cache; **keep weights out of git**.

---

## 5. PII Removal

Endpoint: `POST /v1/pii/redact` — called by the Go worker behind `ProcessUpload`.

### 5.1 OCR — `pii/ocr.py`

Implement an `OcrEngine` initialized once at server startup (model load is expensive; reuse the instance).

- Model: PaddleOCR **PP-OCRv6_small** or **PP-OCRv6_medium**, running on **CPU**. Make the model selectable via env (`OCR_MODEL`, default `PP-OCRv6_small`).
- Required function:

```python
def extractImageWithBoundingBox(self, image) -> list[dict]:
    """
    Run self.ocr.predict(image) and return one entry per detected text box:
      { "box": [[x0,y0],[x1,y1],[x2,y2],[x3,y3]],  # 4 corner points
        "text": "<recognized text>",
        "score": <float recognition confidence> }
    """
```

- Internally call `self.ocr.predict(image)`, then extract, for each detected region, the **polygon coords**, the **recognized text**, and the **confidence score**. Normalize PaddleOCR's output structure into the dict list above regardless of the exact 3.x return shape.
- Keep the function name `extractImageWithBoundingBox` exactly (user-specified). It should accept an image path or an in-memory image (bytes / PIL Image / ndarray); document what you accept.
- Drop boxes below a configurable recognition-confidence floor (`OCR_MIN_SCORE`, default `0.5`) before sending to the decision step.

### 5.2 PII decision — `pii/decide.py`

For **each OCR box**, ask clef-flash one `noul` question whether that box's **text** contains PII.

- Question id scheme: `box_0`, `box_1`, ... (index aligns back to the OCR box list).
- Instruction (refined — use this wording):
  > "Does this text contain personally identifiable information such as a person's full name, phone number, email address, home or mailing address, national ID / NRIC / passport number, date of birth, bank account number, or payment card number? Answer true only if such personal data is present."
- `state` = the box text for that question. Because `state` is shared per call, send **one box's text per question with the box text embedded in the instruction**, OR set `state` to a neutral prompt and put each box's text inside its own question's instructions. **Chosen approach:** put each box's text inside its own question's `instructions` (so one call can cover many boxes), and keep `state` a short fixed framing string like `"Classify each field for personally identifiable information."` Document this clearly.
- **Batching (critical):** clef accepts max 64 questions per call. For an image with N boxes:
  - N ≤ 64 → one `/v1/systemone` call.
  - N > 64 → split into ceil(N/64) calls; preserve box-index → question-id mapping so results reassemble correctly.
  - When redacting **multiple images in one request** (batch mode), run OCR per image, then pack questions across images up to 64 per clef call to minimize round-trips. Keep a mapping of `(image_index, box_index)` → `question_id`.
- A box is **PII** when its returned true-probability ≥ `PII_THRESHOLD` (default `0.5`, env-configurable).

### 5.3 Censoring — `pii/censor.py`

- Use **Pillow (PIL)**. For every box marked PII, draw a **filled opaque rectangle** (default solid black) covering the box polygon's bounding rectangle. Make fill color configurable; default black.
- Return the redacted image as bytes in the same media type the Go side sent (`image/jpeg|png|webp`).
- Also produce **cleaned extracted text**: the concatenation of all box texts in reading order, with PII boxes replaced by a `[redacted]` placeholder (never the original PII value).

### 5.4 `/v1/pii/redact` contract

Request (from Go worker):

```jsonc
{
  "image_base64": "<base64 of the original screenshot bytes>",
  "media_type": "image/png",         // image/jpeg | image/png | image/webp
  "locale": "en-SG"                   // optional, forwarded context
}
```

Response (success):

```jsonc
{
  "redacted_image_base64": "<base64 of censored image, same media_type>",
  "media_type": "image/png",
  "extracted_text": "<cleaned text; PII boxes replaced with [redacted]>",
  "pii_box_count": 3,
  "total_box_count": 11
}
```

- **Fail closed on PII.** If OCR succeeds but the clef call fails/times out, do **not** return an under-redacted image. Return an error (HTTP 502) so the Go worker marks the check `failed` rather than risk leaking PII. Document this explicitly.
- If OCR finds no text, return the original image unchanged with `extracted_text: ""` and `pii_box_count: 0`.
- **Privacy:** never log `image_base64`, `redacted_image_base64`, `extracted_text`, or any box text. Log only counts, latency, status.

> The Go side's documented flow is: fetch image via `upload.StorageKey` → OCR → redact PII → `Analyze(redactedText, locale)` → persist via `repo.CompleteCheckFromUpload`. In the new design the AI service does OCR + redaction, and classification can run on the returned `extracted_text` either by the Go `Analyze` fallback or by calling `/v1/classify`. See §7.

---

## 6. Scam Classification

Endpoint: `POST /v1/classify`.

The Go `internal/checks/analyzer.go` rules classifier is a **stub that predates this AI service**. This Python service becomes the real classifier and must emit the **full `Assessment` JSON** so the Go side can persist it directly. The Go rules analyzer remains as a documented **fallback** (used if the AI service is unreachable). Keep the exact field names and allowed values below — they mirror Go constants and DB CHECK constraints; do not rename them.

### 6.1 Request

```jsonc
{
  "text": "<message text — already PII-redacted when it came from a screenshot>",
  "locale": "en-SG"   // optional; defaults to en-SG
}
```

### 6.2 clef questions to build (`classify/classify.py`)

`state` = the message `text`. Build these questions in a single `/v1/systemone` call (well within the 64 limit):

1. **Verdict** — a `score` question, id `verdict`:
   - `criteria`: `["likely_safe", "unclear", "suspicious"]` (ordered low→high risk).
   - instructions: "Rate how likely this message is a scam, from clearly safe to clearly a scam."
   - Map the returned `score` (0.0–2.0) to a verdict: `< 0.67 → likely_safe`, `< 1.34 → unclear`, else `suspicious`. (Thresholds env-tunable: `VERDICT_LOW`, `VERDICT_HIGH`.)
2. **Signals** — one `noul` question per signal code. **Question ids MUST equal the signal codes** so results map straight into `signals[]`:
   - `urgency` — "Does this message use urgency or pressure to make the reader act fast?"
   - `credential_request` — "Does it ask for passwords, OTPs, PINs, Singpass, or other login credentials?"
   - `money_request` — "Does it ask to transfer money, pay a fee, or share bank/card/payment details?"
   - `suspicious_link` — "Does it contain a link that looks risky (shortener, lookalike brand domain, raw IP, or unexpected URL)?"
   - `prize_lottery` — "Does it claim the reader won a prize, lottery, or unexpected reward?"
   - `authority_impersonation` — "Does it claim to be a bank, government agency, police, courier, or other authority?"
   - A signal **fires** when its true-probability ≥ `SIGNAL_THRESHOLD` (default `0.5`).

### 6.3 Mapping clef answers → `Assessment`

Produce exactly this JSON (snake_case; matches Go `checks.Assessment`):

```jsonc
{
  "verdict": "suspicious | unclear | likely_safe",
  "signals": [
    { "code": "<fired signal code>", "evidence_excerpt": "<short, link-sanitized snippet>", "explanation": "<fixed copy per code>" }
  ],
  "uncertainty": "<string>",
  "limitations": "<fixed string, see below>",
  "recommended_actions": [
    { "scenario": "<string>", "title": "<string>", "urgency": "normal | urgent" }
  ],
  "suggested_tags": [ "phishing", "otp-scam", "..." ]
}
```

Rules for building each field — **reuse the Go copy and mapping verbatim** so public-facing wording stays consistent across the AI path and the Go fallback. Port these from `backend/internal/checks/analyzer.go`:

- **`signals[].code`** — only the signal codes that fired. Allowed set exactly: `urgency`, `credential_request`, `money_request`, `suspicious_link`, `prize_lottery`, `authority_impersonation`.
- **`signals[].explanation`** — copy the per-code explanation strings from `analyzer.go` (`textRules[].explanation` and the link explanation). Keep them identical.
- **`signals[].evidence_excerpt`** — a short (≤ 80 runes) snippet of the message supporting the signal, with any URL reduced to host-only `[link: example.com]` form and never a clickable URL. Port `excerptAround` / `sanitizeLinks` behavior.
- **`verdict`** — from the `score` question mapping in §6.2.
- **`uncertainty`** — port `uncertaintyFor(verdict, signalCount)` strings verbatim.
- **`limitations`** — the exact `limitationsText` constant from `analyzer.go`.
- **`recommended_actions`** — port `recommendedActions(detected, verdict, locale)` logic verbatim (scenario/title/urgency per fired signal, plus the always-on "Check with ScamShield (call 1799)…" step for any non-`likely_safe` verdict, and the fallback action when none fired). `urgency` values are `normal` or `urgent` only.
- **`suggested_tags`** — port `suggestedTags(detected)` mapping verbatim: credential→`phishing`+`otp-scam`; impersonation→`bank-impersonation`+`delivery-scam`; prize→`prize-scam`; money→`money-request`; suspicious_link→`suspicious-link`. Dedupe, deterministic order.

> Because `evidence_excerpt`, explanations, tags, and recommended actions are all derivable from the fired signals + the original text, clef only needs to decide **verdict** and **which signals fired**. Everything else is deterministic Python mirroring the Go code. This keeps the two code paths consistent and testable.

### 6.4 Classification failure fallback

If the clef call fails/times out, return a safe `unclear` assessment: `verdict: "unclear"`, empty `signals`, the standard `limitations`, the generic fallback `recommended_action`, and an `uncertainty` string explaining the automated check could not complete. Never 500 the whole request for a model hiccup — the Go side can still show a cautious result.

---

## 7. Go ↔ Python integration seam (reference only — do NOT implement Go here)

> This phase is **Python-only**. The Go wiring below is documented so your HTTP contracts line up exactly with where they'll plug in. Do not modify Go code in this phase.

The seam is `backend/internal/checks/service.go`:

```go
func (s *Service) ProcessUpload(ctx context.Context, checkID, uploadID int64) error
```

Currently a stub that calls `s.repo.FailCheck(ctx, checkID, &uploadID)`. Its documented TODO flow (keep your contracts compatible with it):

1. Fetch the image via `upload.StorageKey` (see `checks.Upload`: `StorageKey`, `MediaType ∈ image/jpeg|png|webp`, `ByteSize`).
2. Run OCR → **this becomes a call to `POST /v1/pii/redact`** with the image bytes (base64) and `media_type`.
3. Redact PII from the extracted text → **done inside `/v1/pii/redact`**; Go receives `redacted_image_base64` + `extracted_text`.
4. `Analyze(redactedText, locale)` → either the Go rules fallback **or** a call to `POST /v1/classify` with `extracted_text`. The Python `/v1/classify` returns the full `Assessment` JSON that maps 1:1 onto `checks.Assessment`.
5. Persist via `repo.CompleteCheckFromUpload`.

Relevant Go types your JSON must match (from `backend/internal/checks/checks.go`), serialized snake_case:

- `Assessment{ verdict, signals[], uncertainty, limitations, recommended_actions[], suggested_tags[] }`
- `Signal{ code, evidence_excerpt, explanation }`
- `RecommendedAction{ scenario, title, urgency }`
- Verdict values: `suspicious | unclear | likely_safe`. Urgency values: `normal | urgent` (`emergency` exists in Go but the analyzer never emits it; don't emit it).

**Privacy at the seam:** the Go `ProcessUpload` doc says *never log extracted_text*. The Python side mirrors this: never log image bytes, OCR text, box text, or raw messages. Redaction happens before anything is persisted or published.

---

## 8. Configuration (`app/config.py` + `.env.example`)

All configurable via env; provide safe dev defaults. Real env vars win.

| Key | Default | Purpose |
| --- | --- | --- |
| `AI_HTTP_ADDR` | `:8099` | address the FastAPI server binds |
| `CLEF_BASE_URL` | `http://localhost:30000` | SGLang clef-flash server (call directly, not via gateway) |
| `CLEF_MODEL` | `Cloudflare/clef-flash` | model name sent in the request body |
| `CLEF_TIMEOUT_SECONDS` | `30` | clef HTTP timeout |
| `OCR_MODEL` | `PP-OCRv6_small` | `PP-OCRv6_small` or `PP-OCRv6_medium` |
| `OCR_MIN_SCORE` | `0.5` | drop OCR boxes below this recognition confidence |
| `PII_THRESHOLD` | `0.5` | min true-probability to treat an OCR box as PII |
| `SIGNAL_THRESHOLD` | `0.5` | min true-probability for a classification signal to fire |
| `VERDICT_LOW` | `0.67` | score < this → `likely_safe` |
| `VERDICT_HIGH` | `1.34` | score < this → `unclear`, else `suspicious` |
| `LOG_LEVEL` | `info` | logging verbosity (never raise to a level that leaks content) |

Keep model weights out of git; document the HF cache mount in `README.md`.

---

## 9. Privacy requirements (hard, non-negotiable — from ../AGENTS.md)

- **Never log** image bytes, OCR text, per-box text, `extracted_text`, `state`, question instructions containing content, or raw messages. Log only ids, counts, latency, status, verdict label.
- Redaction happens **before** anything is persisted or published. `/v1/pii/redact` **fails closed**: if the PII decision can't complete, do not return a possibly-under-redacted image.
- `extracted_text` returned to Go has PII replaced with `[redacted]`; `evidence_excerpt` is length-bounded and link-sanitized to host-only `[link: host]`.
- Reference secrets by key name, never echo values. Don't send screenshots to clef (text only).

---

## 10. Testing & verification

Set up `pytest`. Add tests that run **without** a live clef server by mocking `clef_client.system_one`:

- `test_ocr.py` — `extractImageWithBoundingBox` normalizes PaddleOCR output into `{box, text, score}`; low-score boxes dropped. Use a tiny fixture image.
- `test_decide.py` — mapping of per-box noul probabilities → PII booleans at threshold; batching splits >64 boxes into multiple calls with correct id↔box mapping; fail-closed on clef error.
- `test_censor.py` — Pillow fills the right rectangles (assert pixels in a box region are the fill color; assert non-PII regions unchanged); output media type preserved.
- `test_classify.py` — clef answers → `Assessment` mapping: verdict thresholds, signal firing at threshold, exact ported copy for explanations/limitations/uncertainty, tag and recommended-action mapping, deterministic ordering, and the `unclear` fallback on clef failure.

Verification steps to run before claiming done:

- Create both venvs, install pinned requirements, import-check the packages.
- `pytest` green.
- Lint/format with `ruff` + `black` (add configs; pin versions).
- Manual smoke: start the server with a mocked/stubbed clef (or the real SGLang container if a GPU is available) and curl `/healthz`, `/v1/classify`, and `/v1/pii/redact` with a sample image. Confirm no content appears in logs.
- Clean up any temporary files/images created during testing.

---

## 11. Build order (suggested)

1. Scaffold `AI/` tree, both `requirements.txt` files (pinned), `.env.example`, `README.md` skeleton.
2. `app/config.py`, `app/logging.py` (privacy-safe), `app/clef_client.py` (+ test with mock).
3. `classify/classify.py` + `/v1/classify` endpoint + `test_classify.py`. (No GPU needed to develop against a mocked clef.)
4. `pii/ocr.py` (`extractImageWithBoundingBox`) + `test_ocr.py`.
5. `pii/decide.py` (batched noul, fail-closed) + `test_decide.py`.
6. `pii/censor.py` (Pillow) + `test_censor.py`.
7. `/v1/pii/redact` endpoint wiring in `app/main.py`.
8. `sglang/run-clef.sh` + `README.md` run/smoke-test docs.
9. Full `pytest`, lint, manual smoke, cleanup.

Do not build the third "Scam Detection" service. Do not modify Go code. Coordinate before changing any field name or allowed value in §6.
