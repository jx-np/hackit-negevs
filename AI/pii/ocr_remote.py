"""Async remote OCR client and OCR engine factory."""
from __future__ import annotations

import time

import httpx

from app.config import Settings, get_settings
from app.logging import get_logger
from pii.ocr import OcrEngine

_logger = get_logger("ocr_remote")


class OcrUnavailableError(Exception):
    """Remote OCR could not provide a valid result."""


class OcrBadImageError(Exception):
    """Remote OCR rejected the image as invalid."""


class RemoteOcrEngine:
    def __init__(self, base_url: str, api_key: str = "", timeout: float = 60.0, transport=None):
        self.base_url = base_url.rstrip("/")
        self.api_key = api_key
        self._client = httpx.AsyncClient(timeout=timeout, transport=transport)

    async def aextract(self, image_bytes: bytes, media_type: str) -> list[dict]:
        headers = {"Authorization": f"Bearer {self.api_key}"} if self.api_key else {}
        started = time.monotonic()
        try:
            response = await self._client.post(
                f"{self.base_url}/v1/ocr", headers=headers,
                files={"image": ("image", image_bytes, media_type)},
            )
            if response.status_code == 400:
                raise OcrBadImageError()
            if response.status_code < 200 or response.status_code >= 300:
                raise OcrUnavailableError()
            payload = response.json()
            entries = payload["boxes"]
            if not isinstance(entries, list) or not isinstance(payload.get("total_box_count"), int):
                raise ValueError("invalid response")
            boxes = []
            for entry in entries:
                pts = entry["box"]
                if not isinstance(pts, list):
                    raise ValueError("invalid box")
                boxes.append({"box": [[float(point[0]), float(point[1])] for point in pts],
                              "text": str(entry["text"]), "score": float(entry["score"])})
            _logger.info("remote ocr done status=%d count=%d latency_ms=%d", response.status_code,
                         len(boxes), int((time.monotonic() - started) * 1000))
            return boxes
        except OcrBadImageError:
            raise
        except (httpx.HTTPError, ValueError, KeyError, TypeError, IndexError) as exc:
            _logger.warning("remote ocr unavailable")
            raise OcrUnavailableError() from exc

    async def aclose(self) -> None:
        await self._client.aclose()


def build_ocr_engine(settings: Settings | None = None):
    settings = settings or get_settings()
    if settings.ocr_service_url.strip():
        return RemoteOcrEngine(settings.ocr_service_url.strip(), settings.ocr_service_api_key,
                               settings.ocr_service_timeout_seconds)
    return OcrEngine()
