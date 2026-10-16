"""Censoring and cleaned-text assembly with Pillow.

For every box marked PII, draw a filled opaque rectangle over the box polygon's
bounding rectangle (default solid black, configurable). Produce the redacted
image bytes in the same media type the caller sent, plus cleaned extracted text
(box texts in reading order, PII boxes replaced with `[redacted]`).

Privacy: never log image bytes or box text.
"""

from __future__ import annotations

import io

from PIL import Image, ImageDraw

# media_type -> Pillow format name.
_FORMAT_BY_MEDIA = {
    "image/jpeg": "JPEG",
    "image/png": "PNG",
    "image/webp": "WEBP",
}

REDACTED_PLACEHOLDER = "[redacted]"
DEFAULT_FILL = (0, 0, 0)


def _bounding_rect(box: list[list[float]]) -> tuple[int, int, int, int]:
    xs = [p[0] for p in box]
    ys = [p[1] for p in box]
    return (
        int(min(xs)),
        int(min(ys)),
        int(round(max(xs))),
        int(round(max(ys))),
    )


def censor_image(
    image_bytes: bytes,
    boxes: list[dict],
    is_pii: list[bool],
    media_type: str,
    fill: tuple[int, int, int] = DEFAULT_FILL,
) -> bytes:
    """Return redacted image bytes with PII boxes filled.

    `boxes` and `is_pii` are parallel lists aligned by index. The output is
    re-encoded in the format matching `media_type` (defaults to PNG when the
    media type is unknown).
    """
    img = Image.open(io.BytesIO(image_bytes))
    fmt = _FORMAT_BY_MEDIA.get(media_type, "PNG")

    # JPEG cannot hold alpha; normalise mode per target format.
    if fmt == "JPEG" and img.mode not in ("RGB", "L"):
        img = img.convert("RGB")

    draw = ImageDraw.Draw(img)
    for box, pii in zip(boxes, is_pii, strict=False):
        if not pii:
            continue
        rect = _bounding_rect(box["box"])
        draw.rectangle(rect, fill=fill)

    out = io.BytesIO()
    save_kwargs: dict = {}
    if fmt == "JPEG":
        save_kwargs["quality"] = 95
    img.save(out, format=fmt, **save_kwargs)
    return out.getvalue()


def build_cleaned_text(boxes: list[dict], is_pii: list[bool]) -> str:
    """Concatenate box texts in reading order, PII replaced with [redacted]."""
    parts: list[str] = []
    for box, pii in zip(boxes, is_pii, strict=False):
        parts.append(REDACTED_PLACEHOLDER if pii else box.get("text", ""))
    return "\n".join(parts)
