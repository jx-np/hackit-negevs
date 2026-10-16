"""OCR via PaddleOCR (CPU).

Loads a PaddleOCR model once and exposes `extractImageWithBoundingBox`, which
normalises PaddleOCR 2.x and 3.x output into a simple list of
`{box, text, score}` dicts. Boxes below a configurable recognition-confidence
floor are dropped before the PII decision step.

Privacy: never log recognised text or image bytes. Log only counts and status.
"""

from __future__ import annotations

import io
from typing import Any

import numpy as np
from PIL import Image

from app.config import get_settings
from app.logging import get_logger

_logger = get_logger("ocr")


def _to_ndarray(image: Any) -> np.ndarray:
    """Accept an image path (str), raw bytes, PIL.Image, or ndarray -> ndarray.

    Returns an RGB ndarray suitable for PaddleOCR.
    """
    if isinstance(image, np.ndarray):
        return image
    if isinstance(image, bytes | bytearray):
        pil = Image.open(io.BytesIO(bytes(image))).convert("RGB")
        return np.array(pil)
    if isinstance(image, Image.Image):
        return np.array(image.convert("RGB"))
    if isinstance(image, str):
        pil = Image.open(image).convert("RGB")
        return np.array(pil)
    raise TypeError(f"unsupported image type: {type(image)!r}")


def _normalize_result(result: Any) -> list[dict]:
    """Normalise PaddleOCR 2.x/3.x output into [{box, text, score}].

    PaddleOCR 3.x `predict()` returns a list of result objects; each exposes a
    dict-like payload under `.json["res"]` (or is itself a dict) carrying
    parallel lists: `rec_texts`, `rec_scores`, and polygon coords under
    `rec_polys` (falling back to `dt_polys`). PaddleOCR 2.x `ocr()` returns
    nested [polygon, (text, score)] entries. Handle both shapes.
    """
    boxes: list[dict] = []
    if result is None:
        return boxes

    for item in result:
        if _is_legacy_line(item):
            poly, (text, score) = item
            boxes.append(
                {"box": _poly_to_points(poly), "text": text, "score": float(score)}
            )
            continue

        payload: Any = None
        # PaddleOCR 3.x result object exposes `.json`
        json_attr = getattr(item, "json", None)
        if isinstance(json_attr, dict):
            payload = json_attr.get("res", json_attr)
        elif isinstance(item, dict):
            payload = item.get("res", item)
        else:
            # Some versions store the dict under attribute access
            payload = getattr(item, "res", None)

        if not isinstance(payload, dict):
            if isinstance(item, list | tuple):
                boxes.extend(_normalize_result(item))
            continue

        texts = payload.get("rec_texts") or []
        scores = payload.get("rec_scores") or []
        polys = payload.get("rec_polys")
        if polys is None:
            polys = payload.get("dt_polys") or []

        for idx, text in enumerate(texts):
            score = float(scores[idx]) if idx < len(scores) else 0.0
            poly = polys[idx] if idx < len(polys) else None
            box = _poly_to_points(poly)
            boxes.append({"box": box, "text": text, "score": score})

    return boxes


def _is_legacy_line(item: Any) -> bool:
    """Return whether an item has PaddleOCR 2.x [polygon, (text, score)] shape."""
    if not isinstance(item, list | tuple) or len(item) != 2:
        return False
    recognition = item[1]
    return (
        isinstance(recognition, list | tuple)
        and len(recognition) == 2
        and isinstance(recognition[0], str)
        and isinstance(recognition[1], int | float | np.number)
    )


def _poly_to_points(poly: Any) -> list[list[float]]:
    """Normalise a polygon into a list of 4 [x, y] corner points."""
    if poly is None:
        return []
    if isinstance(poly, np.ndarray):
        poly = poly.tolist()
    points: list[list[float]] = []
    for pt in poly:
        if isinstance(pt, np.ndarray):
            pt = pt.tolist()
        points.append([float(pt[0]), float(pt[1])])
    return points


class OcrEngine:
    """Wraps a PaddleOCR instance loaded once at startup (reuse it)."""

    def __init__(self, model_name: str | None = None, min_score: float | None = None) -> None:
        settings = get_settings()
        self._model_name = model_name or settings.ocr_model
        self._min_score = min_score if min_score is not None else settings.ocr_min_score
        self._ocr: Any = None

    def _ensure_loaded(self) -> Any:
        if self._ocr is None:
            # Imported lazily so tests can run without the heavy dependency.
            from paddleocr import PaddleOCR

            if callable(getattr(PaddleOCR, "predict", None)):
                self._ocr = PaddleOCR(
                    text_recognition_model_name=self._model_name,
                    use_doc_orientation_classify=False,
                    use_doc_unwarping=False,
                    use_textline_orientation=False,
                )
                loaded_model = self._model_name
            else:
                self._ocr = PaddleOCR(use_angle_cls=False, show_log=False)
                loaded_model = "default (legacy PaddleOCR)"
            _logger.info("ocr model loaded model=%s", loaded_model)
        return self._ocr

    def extractImageWithBoundingBox(self, image: Any) -> list[dict]:
        """Run OCR and return one entry per detected text box.

        Accepts an image path (str), raw bytes, a PIL.Image, or an ndarray.
        Returns a list of dicts:
          {"box": [[x0,y0],[x1,y1],[x2,y2],[x3,y3]], "text": str, "score": float}
        Boxes with recognition confidence below OCR_MIN_SCORE are dropped.
        """
        ocr = self._ensure_loaded()
        array = _to_ndarray(image)
        predict = getattr(ocr, "predict", None)
        if callable(predict):
            result = predict(array)
        else:
            result = ocr.ocr(array, cls=False)
        boxes = _normalize_result(result)
        kept = [b for b in boxes if b["score"] >= self._min_score]
        _logger.info(
            "ocr done total=%d kept=%d min_score=%.2f",
            len(boxes),
            len(kept),
            self._min_score,
        )
        return kept
