"""Tests for censoring and cleaned-text assembly (pii/censor.py).

Builds a small in-memory image, censors specific boxes, and asserts the PII
regions are filled while non-PII regions are untouched. Also checks that the
output media type is preserved and cleaned text replaces PII with [redacted].
"""

from __future__ import annotations

import io

from PIL import Image

from pii import censor as C


def _white_image_bytes(size=(100, 100), fmt="PNG") -> bytes:
    img = Image.new("RGB", size, (255, 255, 255))
    out = io.BytesIO()
    img.save(out, format=fmt)
    return out.getvalue()


def _box(x0, y0, x1, y1, text="t") -> dict:
    return {
        "box": [[x0, y0], [x1, y0], [x1, y1], [x0, y1]],
        "text": text,
        "score": 0.99,
    }


def test_fills_pii_box_only():
    image_bytes = _white_image_bytes()
    boxes = [_box(10, 10, 30, 30, "secret"), _box(60, 60, 80, 80, "public")]
    is_pii = [True, False]

    out = C.censor_image(image_bytes, boxes, is_pii, "image/png")
    img = Image.open(io.BytesIO(out)).convert("RGB")

    # Inside the PII box -> black.
    assert img.getpixel((20, 20)) == (0, 0, 0)
    # Inside the non-PII box -> untouched white.
    assert img.getpixel((70, 70)) == (255, 255, 255)
    # A corner far from any box -> untouched white.
    assert img.getpixel((95, 5)) == (255, 255, 255)


def test_custom_fill_color():
    image_bytes = _white_image_bytes()
    boxes = [_box(10, 10, 30, 30)]
    out = C.censor_image(image_bytes, boxes, [True], "image/png", fill=(255, 0, 0))
    img = Image.open(io.BytesIO(out)).convert("RGB")
    assert img.getpixel((20, 20)) == (255, 0, 0)


def test_media_type_preserved_png():
    out = C.censor_image(_white_image_bytes(fmt="PNG"), [], [], "image/png")
    assert Image.open(io.BytesIO(out)).format == "PNG"


def test_media_type_preserved_jpeg():
    out = C.censor_image(_white_image_bytes(fmt="JPEG"), [], [], "image/jpeg")
    assert Image.open(io.BytesIO(out)).format == "JPEG"


def test_media_type_preserved_webp():
    out = C.censor_image(_white_image_bytes(fmt="WEBP"), [], [], "image/webp")
    assert Image.open(io.BytesIO(out)).format == "WEBP"


def test_unknown_media_type_defaults_png():
    out = C.censor_image(_white_image_bytes(), [], [], "image/gif")
    assert Image.open(io.BytesIO(out)).format == "PNG"


def test_jpeg_with_alpha_source_converts():
    # RGBA source saved as PNG, re-encoded as JPEG should not raise.
    img = Image.new("RGBA", (40, 40), (255, 255, 255, 255))
    buf = io.BytesIO()
    img.save(buf, format="PNG")
    out = C.censor_image(buf.getvalue(), [_box(5, 5, 15, 15)], [True], "image/jpeg")
    assert Image.open(io.BytesIO(out)).format == "JPEG"


def test_cleaned_text_redacts_pii():
    boxes = [_box(0, 0, 1, 1, "John Tan"), _box(0, 0, 1, 1, "Hello there")]
    text = C.build_cleaned_text(boxes, [True, False])
    assert text == "[redacted]\nHello there"


def test_cleaned_text_all_safe():
    boxes = [_box(0, 0, 1, 1, "a"), _box(0, 0, 1, 1, "b")]
    text = C.build_cleaned_text(boxes, [False, False])
    assert text == "a\nb"
