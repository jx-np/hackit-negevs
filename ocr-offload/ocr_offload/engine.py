"""PaddleOCR engine wrapper."""

from __future__ import annotations

import io
import os
from dataclasses import dataclass, replace
from typing import Any

import numpy as np
from PIL import Image

from .config import Settings, get_settings
from .logging import get_logger

_logger = get_logger("ocr")


def resolve_ocr_models(name: str) -> tuple[str | None, str | None]:
    """Resolve a PaddleOCR tier or component model name."""
    name = name.strip()
    if not name:
        return None, None
    if name.endswith("_rec"):
        return None, name
    if name.endswith("_det"):
        return name, None
    return f"{name}_det", f"{name}_rec"


@dataclass(frozen=True)
class EngineOptions:
    model: str
    min_score: float
    cpu_threads: int
    engine: str = ""
    onnx_det_dir: str = ""
    onnx_rec_dir: str = ""
    onnx_model_root: str = ""
    ort_intra_op_threads: int = 0
    ort_inter_op_threads: int = 0
    rec_batch_size: int = 0

    @classmethod
    def from_settings(cls, settings: Settings) -> "EngineOptions":
        return cls(
            model=settings.model,
            min_score=settings.min_score,
            cpu_threads=settings.cpu_threads,
            engine=settings.engine,
            onnx_det_dir=settings.onnx_det_dir,
            onnx_rec_dir=settings.onnx_rec_dir,
            onnx_model_root=settings.onnx_model_root,
            ort_intra_op_threads=settings.ort_intra_op_threads,
            ort_inter_op_threads=settings.ort_inter_op_threads,
            rec_batch_size=settings.rec_batch_size,
        )


def resolve_onnx_dirs(options: EngineOptions) -> tuple[str | None, str | None]:
    det_dir = options.onnx_det_dir.strip() or None
    rec_dir = options.onnx_rec_dir.strip() or None
    if options.onnx_model_root.strip():
        det_name, rec_name = resolve_ocr_models(options.model)
        root = options.onnx_model_root.strip()
        if det_dir is None and det_name:
            det_dir = os.path.join(root, f"{det_name}_onnx")
        if rec_dir is None and rec_name:
            rec_dir = os.path.join(root, f"{rec_name}_onnx")
    return det_dir, rec_dir


def _to_ndarray(image: Any) -> np.ndarray:
    if isinstance(image, np.ndarray):
        return image
    if isinstance(image, bytes | bytearray):
        return np.array(Image.open(io.BytesIO(bytes(image))).convert("RGB"))
    if isinstance(image, Image.Image):
        return np.array(image.convert("RGB"))
    if isinstance(image, str):
        return np.array(Image.open(image).convert("RGB"))
    raise TypeError(f"unsupported image type: {type(image)!r}")


def _normalize_result(result: Any) -> list[dict]:
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
        json_attr = getattr(item, "json", None)
        if isinstance(json_attr, dict):
            payload = json_attr.get("res", json_attr)
        elif isinstance(item, dict):
            payload = item.get("res", item)
        else:
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
            boxes.append({"box": _poly_to_points(poly), "text": text, "score": score})
    return boxes


def _is_legacy_line(item: Any) -> bool:
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
    if poly is None:
        return []
    if isinstance(poly, np.ndarray):
        poly = poly.tolist()
    points = []
    for pt in poly:
        if isinstance(pt, np.ndarray):
            pt = pt.tolist()
        points.append([float(pt[0]), float(pt[1])])
    return points


class OcrEngine:
    """Lazily initialized PaddleOCR engine."""

    def __init__(
        self,
        options: EngineOptions | None = None,
        model_name: str | None = None,
        min_score: float | None = None,
        cpu_threads: int | None = None,
    ) -> None:
        if options is None:
            options = EngineOptions.from_settings(get_settings())
        overrides = {
            "model": model_name,
            "min_score": min_score,
            "cpu_threads": cpu_threads,
        }
        overrides = {
            key: value for key, value in overrides.items() if value is not None
        }
        if overrides:
            options = replace(options, **overrides)
        self._options = options
        self._model_name = options.model
        self._min_score = options.min_score
        self._cpu_threads = options.cpu_threads
        self._ocr: Any = None
        self._loaded_det = "unknown"
        self._loaded_rec = "unknown"

    def _ensure_loaded(self) -> Any:
        if self._ocr is None:
            from paddleocr import PaddleOCR

            if self._options.engine.strip().lower() == "onnxruntime" and callable(
                getattr(PaddleOCR, "predict", None)
            ):
                det_model, rec_model = resolve_ocr_models(self._model_name)
                det_dir, rec_dir = resolve_onnx_dirs(self._options)
                missing = []
                if not det_dir:
                    missing.append("detector directory")
                elif not os.path.isfile(os.path.join(det_dir, "inference.onnx")):
                    missing.append(os.path.join(det_dir, "inference.onnx"))
                if not rec_dir:
                    missing.append("recognizer directory")
                elif not os.path.isfile(os.path.join(rec_dir, "inference.onnx")):
                    missing.append(os.path.join(rec_dir, "inference.onnx"))
                if missing:
                    raise ValueError(
                        "OCR_ENGINE=onnxruntime requires "
                        "OCR_ONNX_DET_DIR/OCR_ONNX_REC_DIR (or OCR_ONNX_MODEL_ROOT) "
                        "pointing at directories containing inference.onnx; missing: "
                        + ", ".join(missing)
                    )
                if not det_model or not rec_model:
                    raise ValueError(
                        "OCR_ENGINE=onnxruntime requires a model tier resolving both "
                        "detector and recognizer names"
                    )
                intra = self._options.ort_intra_op_threads or self._cpu_threads
                engine_config = {"device_type": "cpu"}
                if intra > 0:
                    engine_config["intra_op_num_threads"] = intra
                if self._options.ort_inter_op_threads > 0:
                    engine_config["inter_op_num_threads"] = (
                        self._options.ort_inter_op_threads
                    )
                kwargs = {
                    "engine": "onnxruntime",
                    "engine_config": engine_config,
                    "device": "cpu",
                    "use_doc_orientation_classify": False,
                    "use_doc_unwarping": False,
                    "use_textline_orientation": False,
                    "text_detection_model_name": det_model,
                    "text_detection_model_dir": det_dir,
                    "text_recognition_model_name": rec_model,
                    "text_recognition_model_dir": rec_dir,
                }
                if self._options.rec_batch_size > 0:
                    kwargs["text_recognition_batch_size"] = self._options.rec_batch_size
                self._ocr = PaddleOCR(**kwargs)
                loaded_det, loaded_rec = det_model, rec_model
            elif self._options.engine.strip().lower() not in {"", "paddle"}:
                raise ValueError(f"unsupported OCR engine: {self._options.engine}")
            elif callable(getattr(PaddleOCR, "predict", None)):
                common = {
                    "use_doc_orientation_classify": False,
                    "use_doc_unwarping": False,
                    "use_textline_orientation": False,
                    "enable_mkldnn": True,
                }
                if self._cpu_threads:
                    common["cpu_threads"] = self._cpu_threads
                det_model, rec_model = resolve_ocr_models(self._model_name)
                model_kwargs = {
                    key: value
                    for key, value in (
                        ("text_detection_model_name", det_model),
                        ("text_recognition_model_name", rec_model),
                    )
                    if value is not None
                }
                try:
                    self._ocr = PaddleOCR(**model_kwargs, **common)
                    loaded_det, loaded_rec = det_model, rec_model
                except (ValueError, KeyError):
                    _logger.warning(
                        "ocr model invalid, using default model=%s", self._model_name
                    )
                    self._ocr = PaddleOCR(**common)
                    loaded_det = loaded_rec = "default (invalid OCR_MODEL)"
            else:
                self._ocr = PaddleOCR(use_angle_cls=False, show_log=False)
                loaded_det = loaded_rec = "default (legacy PaddleOCR)"
            _logger.info(
                "ocr model loaded det=%s rec=%s engine=%s",
                loaded_det,
                loaded_rec,
                self.engine_label(),
            )
            self._loaded_det = loaded_det
            self._loaded_rec = loaded_rec
        return self._ocr

    def warmup(self) -> None:
        """Load the OCR model without processing an image."""
        self._ensure_loaded()

    def loaded_models(self) -> tuple[str, str]:
        """Return the resolved model names, or unknown before loading."""
        return self._loaded_det, self._loaded_rec

    def engine_label(self) -> str:
        return (
            "onnxruntime"
            if self._options.engine.strip().lower() == "onnxruntime"
            else "paddle"
        )

    def extract_with_count(self, image: Any) -> tuple[list[dict], int]:
        ocr = self._ensure_loaded()
        array = _to_ndarray(image)
        predict = getattr(ocr, "predict", None)
        result = predict(array) if callable(predict) else ocr.ocr(array, cls=False)
        boxes = _normalize_result(result)
        kept = [box for box in boxes if box["score"] >= self._min_score]
        _logger.info(
            "ocr done total=%d kept=%d min_score=%.2f",
            len(boxes),
            len(kept),
            self._min_score,
        )
        return kept, len(boxes)

    def extractImageWithBoundingBox(self, image: Any) -> list[dict]:
        return self.extract_with_count(image)[0]
