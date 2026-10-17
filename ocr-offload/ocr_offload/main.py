"""FastAPI application for OCR requests."""

from __future__ import annotations

import asyncio
import hmac
import io
import platform
import sys
import time
from contextlib import asynccontextmanager

from fastapi import FastAPI, File, Header, HTTPException, Request, UploadFile
from PIL import Image, UnidentifiedImageError

from .config import get_settings
from .logging import configure_logging, get_logger
from .pool import OcrJobError, create_pool

settings = get_settings()
configure_logging(settings.log_level)
logger = get_logger("http")


@asynccontextmanager
async def lifespan(app: FastAPI):
    if not settings.api_key:
        logger.warning("OCR service is unauthenticated")
    if getattr(app.state, "pool", None) is None:
        app.state.pool = create_pool(settings)
    logger.info(
        "ocr service starting python=%s executable=%s workers=%s engine=%s",
        platform.python_version(),
        sys.executable,
        getattr(app.state.pool, "workers", settings.effective_workers),
        settings.effective_engine,
    )
    if settings.warmup:
        ok, errors, models = await asyncio.to_thread(app.state.pool.warmup)
        if errors:
            for detail in errors:
                logger.error("ocr warmup failed detail=%s", detail)
            app.state.ocr_ready = False
            app.state.ocr_error = errors[0][:2000]
        else:
            det, rec = models or ("n/a", "n/a")
            logger.info(
                "ocr warmup ok workers=%d det=%s rec=%s engine=%s",
                ok,
                det,
                rec,
                settings.effective_engine,
            )
            app.state.ocr_ready = True
            app.state.ocr_error = ""
    else:
        app.state.ocr_ready = None
        app.state.ocr_error = ""
    app.state.queue_lock = asyncio.Lock()
    app.state.in_flight = 0
    yield
    pool = getattr(app.state, "pool", None)
    if pool is not None and callable(getattr(pool, "shutdown", None)):
        pool.shutdown()


app = FastAPI(lifespan=lifespan)


@app.get("/healthz")
async def healthz(request: Request):
    pool = getattr(request.app.state, "pool", None)
    ready = getattr(request.app.state, "ocr_ready", None)
    response = {
        "status": "degraded" if ready is False else "ok",
        "workers": getattr(pool, "workers", settings.effective_workers),
        "ready": ready,
        "engine": settings.effective_engine,
    }
    if ready is False:
        response["error"] = getattr(request.app.state, "ocr_error", "")
    return response


def _detail_text(error: BaseException | str) -> str:
    """Make exception details safe and bounded for logs."""
    detail = error if isinstance(error, str) else f"{type(error).__name__}: {error}"
    detail = " | ".join(detail.splitlines())
    detail = "".join(char if ord(char) >= 32 else " " for char in detail)
    return detail[:2000]


@app.post("/v1/ocr")
async def ocr(
    request: Request,
    image: UploadFile = File(...),
    authorization: str | None = Header(default=None),
):
    if settings.api_key and not hmac.compare_digest(
        authorization or "", f"Bearer {settings.api_key}"
    ):
        raise HTTPException(status_code=401, detail="unauthorized")
    if image.content_type not in {"image/jpeg", "image/png", "image/webp"}:
        raise HTTPException(status_code=400, detail="unsupported image media type")
    data = await image.read(settings.max_image_bytes + 1)
    if not data:
        raise HTTPException(status_code=400, detail="empty image")
    if len(data) > settings.max_image_bytes:
        raise HTTPException(status_code=400, detail="image too large")
    try:
        with Image.open(io.BytesIO(data)) as decoded:
            decoded.verify()
    except (UnidentifiedImageError, OSError, ValueError):
        raise HTTPException(status_code=400, detail="invalid image") from None

    started = time.perf_counter()
    pool = getattr(request.app.state, "pool", None)
    if pool is None:
        raise HTTPException(status_code=500, detail="ocr failed")
    async with request.app.state.queue_lock:
        if request.app.state.in_flight >= settings.max_queue:
            raise HTTPException(status_code=503, detail="ocr busy")
        request.app.state.in_flight += 1
    try:
        try:
            future = pool.submit(data)
            boxes, total = await asyncio.wrap_future(future)
        finally:
            request.app.state.in_flight -= 1
        logger.info(
            "request complete status=200 media_type=%s total=%d kept=%d latency_ms=%.1f",
            image.content_type,
            total,
            len(boxes),
            (time.perf_counter() - started) * 1000,
        )
        return {"boxes": boxes, "total_box_count": total}
    except HTTPException:
        raise
    except Exception as error:
        detail = (
            _detail_text(error.detail)
            if isinstance(error, OcrJobError)
            else _detail_text(error)
        )
        logger.error(
            "ocr failed error=%s detail=%s media_type=%s latency_ms=%.1f",
            type(error).__name__,
            detail,
            image.content_type,
            (time.perf_counter() - started) * 1000,
        )
        raise HTTPException(status_code=500, detail="ocr failed") from None


def main() -> None:
    import uvicorn

    uvicorn.run(
        "ocr_offload.main:app",
        host=settings.bind_host,
        port=settings.bind_port,
        log_level=settings.log_level,
    )


if __name__ == "__main__":
    main()
