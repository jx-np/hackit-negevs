"""FastAPI app: endpoint wiring, startup/shutdown.

This is the only process the Go backend talks to. It exposes:
  - GET  /healthz            — liveness probe.
  - POST /v1/classify        — scam classification -> full Assessment.
  - POST /v1/pii/redact      — OCR + PII decision + censor -> redacted image.

Privacy (PLAN.md §9): never log image bytes, OCR text, box text,
extracted_text, clef state, or raw messages. Log only ids, counts, latency,
status, verdict label.
"""

from __future__ import annotations

import base64
import binascii
import time
from contextlib import asynccontextmanager
from dataclasses import dataclass

from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.responses import JSONResponse

from classify.classify import classify as run_classify
from pii.censor import build_cleaned_text, censor_image
from pii.decide import decide_pii
from pii.ocr import OcrEngine

from .clef_client import ClefClient, ClefError
from .config import get_settings
from .logging import get_logger
from .schemas import (
    Assessment,
    ClassifyRequest,
    RedactRequest,
    RedactResponse,
    RedactResult,
)

# Media types the Go upload layer guarantees; decode defensively anyway.
_ALLOWED_MEDIA = {"image/jpeg", "image/png", "image/webp"}
# Guard against oversized bodies even though the Go side caps at 10 MiB.
_MAX_IMAGE_BYTES = 10 * 1024 * 1024

_logger = get_logger("main")


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Load the OCR model once at startup (expensive) and keep one clef client.
    app.state.ocr_engine = OcrEngine()
    app.state.clef_client = ClefClient()
    _logger.info("ai service starting")
    try:
        yield
    finally:
        await app.state.clef_client.aclose()
        _logger.info("ai service stopped")


app = FastAPI(title="ScamWatch AI service", lifespan=lifespan)


@app.get("/healthz")
async def healthz() -> dict:
    return {"status": "ok"}


@app.post("/v1/classify", response_model=Assessment)
async def classify_endpoint(req: ClassifyRequest) -> Assessment:
    assessment = await run_classify(req.text, locale=req.locale, client=app.state.clef_client)
    return Assessment(**assessment)


@dataclass
class _RedactOutcome:
    """Internal result of the OCR -> decide -> censor pipeline.

    Field names here are neutral; each endpoint maps them onto its own wire
    schema. `redacted_text` has PII already replaced with [redacted].
    """

    redacted_image: bytes
    media_type: str
    redacted_text: str
    pii_box_count: int
    total_box_count: int


async def _run_redaction(image_bytes: bytes, media_type: str) -> _RedactOutcome:
    """Shared OCR -> PII decide -> censor pipeline used by both redact routes.

    Fails closed: raises HTTPException(502) if the PII decision cannot complete
    so the caller never persists a possibly-under-redacted image. Never logs
    image bytes or OCR/box text — only counts, latency, status, media type.
    """
    started = time.monotonic()
    engine: OcrEngine = app.state.ocr_engine
    boxes = engine.extractImageWithBoundingBox(image_bytes)

    # No text found -> return the original image unchanged, nothing to redact.
    if not boxes:
        _logger.info(
            "redact done boxes=0 pii=0 media_type=%s latency_ms=%d",
            media_type,
            int((time.monotonic() - started) * 1000),
        )
        return _RedactOutcome(
            redacted_image=image_bytes,
            media_type=media_type,
            redacted_text="",
            pii_box_count=0,
            total_box_count=0,
        )

    # Fail closed: if the PII decision cannot complete, do NOT return a
    # possibly-under-redacted image (PLAN §5.4). Surface a 502 so the Go worker
    # marks the check failed.
    try:
        is_pii = await decide_pii(boxes, client=app.state.clef_client)
    except ClefError as exc:
        _logger.warning("pii redact failing closed (clef unavailable)")
        raise HTTPException(status_code=502, detail="pii decision unavailable") from exc

    redacted = censor_image(image_bytes, boxes, is_pii, media_type)
    cleaned_text = build_cleaned_text(boxes, is_pii)
    pii_count = sum(1 for v in is_pii if v)
    _logger.info(
        "redact done boxes=%d pii=%d media_type=%s latency_ms=%d",
        len(boxes),
        pii_count,
        media_type,
        int((time.monotonic() - started) * 1000),
    )
    return _RedactOutcome(
        redacted_image=redacted,
        media_type=media_type,
        redacted_text=cleaned_text,
        pii_box_count=pii_count,
        total_box_count=len(boxes),
    )


@app.post("/v1/redact", response_model=RedactResult)
async def redact_multipart_endpoint(
    image: UploadFile = File(...),
    locale: str = Form(""),
) -> RedactResult:
    """Multipart adapter required by the Go `pii.Client` (CONTRACT.md).

    Accepts raw image bytes in the `image` file part (not base64) plus a
    `locale` text part, runs the shared pipeline, and returns the Go field
    names. The declared part Content-Type is trusted but validated; the body
    size is capped defensively even though the Go upload layer already enforces
    10 MiB and the allowed media types.
    """
    media_type = (image.content_type or "").split(";", 1)[0].strip().lower()
    if media_type not in _ALLOWED_MEDIA:
        raise HTTPException(status_code=400, detail="unsupported image media type")

    image_bytes = await image.read()
    if not image_bytes:
        raise HTTPException(status_code=400, detail="empty image")
    if len(image_bytes) > _MAX_IMAGE_BYTES:
        raise HTTPException(status_code=400, detail="image too large")

    outcome = await _run_redaction(image_bytes, media_type)
    return RedactResult(
        redacted_text=outcome.redacted_text,
        image_base64=base64.b64encode(outcome.redacted_image).decode("ascii"),
        image_media_type=outcome.media_type,
        regions_redacted=outcome.pii_box_count,
    )


@app.post("/v1/pii/redact", response_model=RedactResponse)
async def redact_endpoint(req: RedactRequest) -> RedactResponse:
    try:
        image_bytes = base64.b64decode(req.image_base64, validate=True)
    except (binascii.Error, ValueError) as exc:
        raise HTTPException(status_code=400, detail="invalid base64 image") from exc

    outcome = await _run_redaction(image_bytes, req.media_type)
    return RedactResponse(
        redacted_image_base64=base64.b64encode(outcome.redacted_image).decode("ascii"),
        media_type=outcome.media_type,
        extracted_text=outcome.redacted_text,
        pii_box_count=outcome.pii_box_count,
        total_box_count=outcome.total_box_count,
    )


@app.exception_handler(ValueError)
async def value_error_handler(request, exc: ValueError) -> JSONResponse:
    return JSONResponse(status_code=400, content={"detail": str(exc)})


def main() -> None:
    import uvicorn

    settings = get_settings()
    uvicorn.run(
        app,
        host=settings.bind_host,
        port=settings.bind_port,
        log_level=settings.log_level.lower(),
    )


if __name__ == "__main__":
    main()
