"""Endpoint tests for the PII redaction routes (app/main.py).

Covers the `POST /v1/redact` multipart adapter required by the Go `pii.Client`
(see backend/internal/pii/CONTRACT.md) and the existing `POST /v1/pii/redact`
JSON endpoint, asserting both drive the same OCR -> decide -> censor pipeline
and that the multipart route returns the Go field names.

The heavy OCR model and the clef client are stubbed via `app.state`, so these
run without PaddleOCR weights or a live clef server. The real lifespan is
bypassed by constructing the TestClient without entering startup, then setting
`app.state` directly.
"""

from __future__ import annotations

import base64
import io

import pytest
from fastapi.testclient import TestClient
from PIL import Image

from app.clef_client import ClefError
from app.main import app
from pii.ocr_remote import OcrUnavailableError


def _png_bytes(size=(100, 100)) -> bytes:
    img = Image.new("RGB", size, (255, 255, 255))
    out = io.BytesIO()
    img.save(out, format="PNG")
    return out.getvalue()


def _box(x0, y0, x1, y1, text="t") -> dict:
    return {
        "box": [[x0, y0], [x1, y0], [x1, y1], [x0, y1]],
        "text": text,
        "score": 0.99,
    }


class _StubOcr:
    """Returns a fixed box list; never loads PaddleOCR."""

    def __init__(self, boxes: list[dict]):
        self._boxes = boxes

    def extractImageWithBoundingBox(self, image):  # noqa: N802 (match real API)
        return list(self._boxes)

    async def aextract(self, image_bytes, media_type):
        return list(self._boxes)


class _RaisingOcr(_StubOcr):
    async def aextract(self, image_bytes, media_type):
        raise OcrUnavailableError()


class _StubClef:
    """Marks a box PII iff its text starts with 'secret'. Never calls clef."""

    async def system_one(self, state, questions):
        out = {}
        for qid, q in questions.items():
            text = q["instructions"].split("Text: ", 1)[1]
            out[qid] = {"probability": 0.9 if text.startswith("secret") else 0.1}
        return out


class _RaisingClef:
    async def system_one(self, state, questions):
        raise ClefError("clef down")


@pytest.fixture
def client():
    # Bypass lifespan (which would construct a real OcrEngine); inject stubs.
    c = TestClient(app)
    app.state.ocr_engine = _StubOcr([_box(10, 10, 30, 30, "secret name"), _box(60, 60, 80, 80, "hello")])
    app.state.clef_client = _StubClef()
    return c


# --- POST /v1/redact (multipart adapter, Go field names) ------------------


def test_multipart_redact_returns_go_fields(client):
    resp = client.post(
        "/v1/redact",
        data={"locale": "en-SG"},
        files={"image": ("upload.png", _png_bytes(), "image/png")},
    )
    assert resp.status_code == 200
    body = resp.json()
    # Exactly the Go contract field names.
    assert set(body) == {"redacted_text", "image_base64", "image_media_type", "regions_redacted"}
    assert body["image_media_type"] == "image/png"
    assert body["regions_redacted"] == 1  # one "secret" box
    # PII box replaced, non-PII box text preserved.
    assert body["redacted_text"] == "[redacted]\nhello"
    # image_base64 must be non-empty and valid standard base64 of an image.
    assert body["image_base64"]
    img_bytes = base64.b64decode(body["image_base64"], validate=True)
    img = Image.open(io.BytesIO(img_bytes)).convert("RGB")
    # The PII region is censored (black); the non-PII region is untouched.
    assert img.getpixel((20, 20)) == (0, 0, 0)
    assert img.getpixel((70, 70)) == (255, 255, 255)


def test_multipart_redact_empty_locale_ok(client):
    resp = client.post(
        "/v1/redact",
        data={"locale": ""},
        files={"image": ("upload.png", _png_bytes(), "image/png")},
    )
    assert resp.status_code == 200


def test_multipart_redact_rejects_bad_media_type(client):
    resp = client.post(
        "/v1/redact",
        data={"locale": "en-SG"},
        files={"image": ("upload.gif", _png_bytes(), "image/gif")},
    )
    assert resp.status_code == 400


def test_multipart_redact_rejects_empty_image(client):
    resp = client.post(
        "/v1/redact",
        data={"locale": "en-SG"},
        files={"image": ("upload.png", b"", "image/png")},
    )
    assert resp.status_code == 400


def test_multipart_redact_requires_image_part(client):
    resp = client.post("/v1/redact", data={"locale": "en-SG"})
    assert resp.status_code == 422  # FastAPI validation: missing required file


def test_multipart_redact_fails_closed_on_clef_outage(client):
    app.state.clef_client = _RaisingClef()
    resp = client.post(
        "/v1/redact",
        data={"locale": "en-SG"},
        files={"image": ("upload.png", _png_bytes(), "image/png")},
    )
    assert resp.status_code == 502


def test_ocr_unavailable_returns_502(client):
    app.state.ocr_engine = _RaisingOcr([])
    resp = client.post("/v1/redact", data={"locale": ""}, files={"image": ("upload.png", _png_bytes(), "image/png")})
    assert resp.status_code == 502


def test_multipart_redact_no_text_returns_original(client):
    app.state.ocr_engine = _StubOcr([])  # OCR finds nothing
    resp = client.post(
        "/v1/redact",
        data={"locale": "en-SG"},
        files={"image": ("upload.png", _png_bytes(), "image/png")},
    )
    assert resp.status_code == 200
    body = resp.json()
    assert body["regions_redacted"] == 0
    assert body["redacted_text"] == ""
    assert body["image_base64"]  # original image echoed back, still non-empty


# --- POST /v1/pii/redact (existing JSON endpoint still works) -------------


def test_json_redact_still_works(client):
    resp = client.post(
        "/v1/pii/redact",
        json={"image_base64": base64.b64encode(_png_bytes()).decode(), "media_type": "image/png"},
    )
    assert resp.status_code == 200
    body = resp.json()
    assert set(body) == {
        "redacted_image_base64",
        "media_type",
        "extracted_text",
        "pii_box_count",
        "total_box_count",
    }
    assert body["pii_box_count"] == 1
    assert body["total_box_count"] == 2
    assert body["extracted_text"] == "[redacted]\nhello"


def test_json_redact_rejects_invalid_base64(client):
    resp = client.post(
        "/v1/pii/redact",
        json={"image_base64": "!!!not-base64!!!", "media_type": "image/png"},
    )
    assert resp.status_code == 400
