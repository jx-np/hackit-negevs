# ScamWatch AI Service

Python AI service for **ScamWatch** (see `../AGENTS.md`). It exposes an HTTP API
the Go backend (`scamshield`) calls for two concerns:

1. **PII Removal** — OCR a screenshot, decide which text regions are personal
   data, and censor those regions on the image.
2. **Scam Classification** — classify message text into the full explainable
   `Assessment` the Go side models.

Both concerns use a separate, GPU-hosted decision model — Cloudflare
`clef-flash`, served by **SGLang** over `/v1/systemone`. The AI server itself is
**CPU-only** (PaddleOCR + Pillow); it is just an HTTP client to SGLang.

## Process topology

```
Go backend ──HTTP──▶ AI API server (FastAPI, CPU) ──HTTP──▶ SGLang clef-flash (GPU)
  ProcessUpload       /v1/pii/redact, /v1/classify           /v1/systemone
```

- **AI API server** — this repo. Runs PaddleOCR + Pillow + orchestration.
- **SGLang clef-flash** — infra you run on a GPU box (see `sglang/run-clef.sh`).
  Point `CLEF_BASE_URL` at the SGLang server port directly (not a gateway).

## Privacy (non-negotiable)

Mirrors the backend's posture (`../AGENTS.md`):

- **Never log** image bytes, OCR text, per-box text, `extracted_text`, clef
  `state`, question instructions that embed content, or raw messages. Log only
  ids, counts, latency, status, and the verdict label.
- `/v1/pii/redact` **fails closed**: if the PII decision can't complete, it
  returns HTTP 502 rather than a possibly under-redacted image.
- `extracted_text` returned to Go has PII replaced with `[redacted]`.
- Only **text** is sent to clef — never the screenshot pixels.

## Layout

```
AI/
├── app/        # FastAPI server (the one process Go talks to)
│   ├── main.py         # app, endpoints, startup/shutdown
│   ├── config.py       # env loading
│   ├── clef_client.py  # async /v1/systemone client (shared)
│   ├── schemas.py      # pydantic request/response models
│   └── logging.py      # privacy-safe logging
├── pii/        # PII removal concern (heavier venv: PaddleOCR + Pillow)
│   ├── ocr.py          # OcrEngine.extractImageWithBoundingBox
│   ├── decide.py       # per-box noul PII decision (batched, fail-closed)
│   ├── censor.py       # Pillow censoring + cleaned text
│   └── requirements.txt
├── classify/   # scam classification concern (dependency-light)
│   ├── classify.py     # build questions, call clef, map to Assessment
│   └── requirements.txt
├── sglang/run-clef.sh  # docker run for clef-flash (ops step)
└── tests/              # pytest, all mock clef (no GPU needed)
```

## Virtualenvs

The user wants **one venv per concern** so dependencies stay isolated. In
practice `app/` imports from both `pii/` and `classify/`, so the running server
uses the **PII venv** (the heavier one, with PaddleOCR) as its interpreter and
treats `classify/` as pure-Python callable within it.

`classify/requirements.txt` is kept separate and intentionally dependency-light
(httpx/pydantic only) so the classification concern could be split into its own
process later. For local dev you install both into the PII venv.

### Set up the PII venv (runs the server + all tests)

```bash
cd AI
python -m venv .venv-pii
# Windows PowerShell:
.\.venv-pii\Scripts\Activate.ps1
# macOS/Linux:
# source .venv-pii/bin/activate

# PaddleOCR 3.x needs the PaddlePaddle 3.x CPU framework, published on
# PaddlePaddle's own index (not PyPI). Install it first:
pip install paddlepaddle==3.3.0 -i https://www.paddlepaddle.org.cn/packages/stable/cpu/

pip install -r pii/requirements.txt
pip install -r classify/requirements.txt   # dependency-light; shares the venv
```

### (Optional) classify-only venv

If you later run classification as its own process:

```bash
python -m venv .venv-classify
.\.venv-classify\Scripts\Activate.ps1
pip install -r classify/requirements.txt
```

### Import check

```bash
python -c "import app.main, pii.ocr, pii.decide, pii.censor, classify.classify"
```

## Configuration

Copy `.env.example` to `.env` and adjust. Real env vars win over the file.

| Key | Default | Purpose |
| --- | --- | --- |
| `AI_HTTP_ADDR` | `:8099` | address the FastAPI server binds |
| `CLEF_BASE_URL` | `http://localhost:30000` | SGLang clef-flash server (direct, not a gateway) |
| `CLEF_MODEL` | `Cloudflare/clef-flash` | model name sent in the request body |
| `CLEF_TIMEOUT_SECONDS` | `30` | clef HTTP timeout |
| `OCR_MODEL` | `PP-OCRv6_small_rec` | PaddleOCR 3.x text-recognition model name (note the `_rec` suffix); PaddleOCR 2.x uses its default model |
| `OCR_MIN_SCORE` | `0.5` | drop OCR boxes below this recognition confidence |
| `PII_THRESHOLD` | `0.5` | min true-probability to treat an OCR box as PII |
| `SIGNAL_THRESHOLD` | `0.5` | min true-probability for a classification signal to fire |
| `VERDICT_LOW` | `0.67` | score < this → `likely_safe` |
| `VERDICT_HIGH` | `1.34` | score < this → `unclear`, else `suspicious` |
| `LOG_LEVEL` | `info` | logging verbosity (never raise to a level that leaks content) |

## Run the server

```bash
cd AI
# with the PII venv active:
python -m app.main
# or:
uvicorn app.main:app --host 0.0.0.0 --port 8099
```

Endpoints:

- `GET /healthz` → `{"status": "ok"}`
- `POST /v1/classify` → full `Assessment` JSON
- `POST /v1/pii/redact` → redacted image (base64) + cleaned text

## Run clef-flash (SGLang, GPU)

This is a **separate process** on a GPU host. Model weights are fetched from
Hugging Face into the mounted cache — **keep weights out of git**.

```bash
./sglang/run-clef.sh
```

Smoke-test the decision model directly:

```bash
curl http://localhost:30000/v1/systemone \
  -H 'Content-Type: application/json' \
  -d '{"model":"Cloudflare/clef-flash","state":"Please verify your bank OTP now","questions":{"urgency":{"type":"noul","instructions":"Does this message express urgency?"}}}'
```

> Known gotcha: `/v1/systemone` may not be reachable through the SGLang model
> gateway — call the SGLang server directly. Point `CLEF_BASE_URL` at the
> server port.

## Tests, lint, format

All tests mock the clef client, so **no GPU or SGLang is required**.

```bash
cd AI
pytest
ruff check .
black --check .
```

## Try OCR on a document image

With the PII venv active, pass a local image (PNG, JPEG, etc.) to the standalone
runner. It uses the real PaddleOCR engine, prints recognized text, confidence
scores, and bounding boxes to the terminal, and opens a window drawing every
detected box with a numbered `text (confidence)` label on top of the image:

```powershell
cd AI
.\.venv-pii\Scripts\Activate.ps1
python .\ocr_document.py "C:\path\to\document.png"
```

Useful flags:

- `--save overlay.png` also writes the labelled overlay to a file.
- `--no-window` skips opening the window (useful on headless machines; pair it
  with `--save` to just produce the overlay file).

The first run may download the OCR model. This runs locally and does not need
pytest, the API server, or SGLang. The recognized text is printed in your
terminal and drawn in the window, so use a document you are comfortable
displaying there. The pinned PaddleOCR 3.x stack honors `OCR_MODEL` (default
`PP-OCRv6_small_rec` — note the `_rec` suffix on the recognition-model name; the
bare tier name like `PP-OCRv6_small` has no engine binding); older PaddleOCR 2.x
installs ignore it and use their built-in default recognition model.

## Manual smoke (no GPU)

Classification falls back to a safe `unclear` result when clef is unreachable,
so you can smoke-test the server without SGLang running:

```bash
# start the server, then:
curl http://localhost:8099/healthz
curl http://localhost:8099/v1/classify \
  -H 'Content-Type: application/json' \
  -d '{"text":"Your account is locked. Verify your OTP now at http://bit.ly/x","locale":"en-SG"}'
```

With clef down, `/v1/classify` returns `verdict: "unclear"` and a cautious
message. `/v1/pii/redact` requires OCR; with clef down it fails closed (502)
after OCR rather than returning an under-redacted image. Confirm no message
content appears in the server logs.
