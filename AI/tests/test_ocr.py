"""Tests for OCR output normalisation (pii/ocr.py).

These run WITHOUT PaddleOCR installed: we drive `extractImageWithBoundingBox`
with fake OCR objects and assert the normaliser handles PaddleOCR 2.x and 3.x
result shapes and drops low-confidence boxes.
"""

from __future__ import annotations

import numpy as np
from PIL import Image

from pii import ocr as O


class _FakeResultObj:
    """Mimics a PaddleOCR 3.x result object exposing `.json`."""

    def __init__(self, payload: dict) -> None:
        self.json = {"res": payload}


class _FakeOcr:
    def __init__(self, result) -> None:
        self._result = result

    def predict(self, _array):
        return self._result


class _FakeLegacyOcr:
    def __init__(self, result) -> None:
        self._result = result

    def ocr(self, _array, cls=False):
        assert cls is False
        return self._result


def _engine_with(result, min_score=0.5) -> O.OcrEngine:
    eng = O.OcrEngine(min_score=min_score)
    eng._ocr = _FakeOcr(result)  # inject so _ensure_loaded() skips the import
    return eng


def _legacy_engine_with(result, min_score=0.5) -> O.OcrEngine:
    eng = O.OcrEngine(min_score=min_score)
    eng._ocr = _FakeLegacyOcr(result)
    return eng


# A tiny in-memory image so `extractImageWithBoundingBox` has a valid input;
# the fake OCR ignores the pixels and returns the canned `result`.
_IMG = np.zeros((8, 8, 3), dtype=np.uint8)


def test_normalizes_result_object_shape():
    payload = {
        "rec_texts": ["Hello", "World"],
        "rec_scores": [0.95, 0.80],
        "rec_polys": [
            [[0, 0], [10, 0], [10, 10], [0, 10]],
            [[20, 20], [30, 20], [30, 30], [20, 30]],
        ],
    }
    eng = _engine_with([_FakeResultObj(payload)])
    boxes = eng.extractImageWithBoundingBox(_IMG)

    assert len(boxes) == 2
    assert boxes[0] == {
        "box": [[0.0, 0.0], [10.0, 0.0], [10.0, 10.0], [0.0, 10.0]],
        "text": "Hello",
        "score": 0.95,
    }
    assert boxes[1]["text"] == "World"


def test_normalizes_paddleocr_2_legacy_result():
    result = [
        [
            [[[0, 0], [10, 0], [10, 10], [0, 10]], ("Hello", 0.95)],
            [[[20, 20], [30, 20], [30, 30], [20, 30]], ("World", 0.30)],
        ]
    ]
    boxes = _legacy_engine_with(result).extractImageWithBoundingBox(_IMG)

    assert len(boxes) == 1
    assert boxes[0] == {
        "box": [[0.0, 0.0], [10.0, 0.0], [10.0, 10.0], [0.0, 10.0]],
        "text": "Hello",
        "score": 0.95,
    }


def test_drops_low_score_boxes():
    payload = {
        "rec_texts": ["keep", "drop"],
        "rec_scores": [0.90, 0.30],
        "rec_polys": [
            [[0, 0], [1, 0], [1, 1], [0, 1]],
            [[2, 2], [3, 2], [3, 3], [2, 3]],
        ],
    }
    eng = _engine_with([_FakeResultObj(payload)], min_score=0.5)
    boxes = eng.extractImageWithBoundingBox(_IMG)
    assert [b["text"] for b in boxes] == ["keep"]


def test_plain_dict_shape_with_dt_polys_fallback():
    # Some versions emit a plain dict and only `dt_polys`.
    payload = {
        "rec_texts": ["x"],
        "rec_scores": [0.99],
        "dt_polys": [np.array([[0, 0], [5, 0], [5, 5], [0, 5]])],
    }
    eng = _engine_with([payload])
    boxes = eng.extractImageWithBoundingBox(_IMG)
    assert len(boxes) == 1
    assert boxes[0]["box"] == [[0.0, 0.0], [5.0, 0.0], [5.0, 5.0], [0.0, 5.0]]


def test_empty_result_returns_empty():
    eng = _engine_with([])
    assert eng.extractImageWithBoundingBox(_IMG) == []
    eng_none = _engine_with(None)
    assert eng_none.extractImageWithBoundingBox(_IMG) == []


def test_accepts_ndarray_and_pil_inputs():
    payload = {
        "rec_texts": ["a"],
        "rec_scores": [0.9],
        "rec_polys": [[[0, 0], [1, 0], [1, 1], [0, 1]]],
    }
    eng = _engine_with([_FakeResultObj(payload)])

    arr = np.zeros((10, 10, 3), dtype=np.uint8)
    assert len(eng.extractImageWithBoundingBox(arr)) == 1

    pil = Image.new("RGB", (10, 10), (255, 255, 255))
    assert len(eng.extractImageWithBoundingBox(pil)) == 1


def test_missing_score_defaults_zero_and_dropped():
    # Fewer scores than texts -> missing score treated as 0.0 and dropped.
    payload = {
        "rec_texts": ["a", "b"],
        "rec_scores": [0.99],
        "rec_polys": [[[0, 0], [1, 0], [1, 1], [0, 1]], [[2, 2], [3, 2], [3, 3], [2, 3]]],
    }
    eng = _engine_with([_FakeResultObj(payload)], min_score=0.5)
    boxes = eng.extractImageWithBoundingBox(_IMG)
    assert [b["text"] for b in boxes] == ["a"]
