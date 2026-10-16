"""PII decision step.

For each OCR box, ask clef-flash one `noul` question whether that box's text
contains PII. clef accepts at most 64 questions per call, so boxes are batched;
the box-index -> question-id mapping is preserved so answers reassemble
correctly. When multiple images are redacted in one request, questions are
packed across images (up to 64 per call) to minimise round-trips.

Fail closed: if the clef call fails, the caller must NOT return an
under-redacted image (see PLAN §5.4). This module surfaces ClefError.

Privacy: box text is embedded only in per-question `instructions`; `state` is a
fixed neutral framing string. Never log box text.
"""

from __future__ import annotations

import math

from app.clef_client import MAX_QUESTIONS, ClefClient
from app.config import get_settings
from app.logging import get_logger

_logger = get_logger("decide")

# Fixed neutral framing; the per-box text goes in each question's instructions.
STATE_FRAMING = "Classify each field for personally identifiable information."

INSTRUCTION_PREFIX = (
    "Does this text contain personally identifiable information such as a "
    "person's full name, phone number, email address, home or mailing address, "
    "national ID / NRIC / passport number, date of birth, bank account number, "
    "or payment card number? Answer true only if such personal data is present. "
    "Text: "
)


def _true_probability(answer: dict) -> float:
    """Extract the true-probability from a `noul` answer.

    noul answers return the probability the statement is true. Be defensive
    about the exact key used by the server.
    """
    if not isinstance(answer, dict):
        return 0.0
    for key in ("probability", "true", "p_true", "value"):
        val = answer.get(key)
        if isinstance(val, int | float):
            return float(val)
    probs = answer.get("probabilities")
    if isinstance(probs, dict):
        val = probs.get("true")
        if isinstance(val, int | float):
            return float(val)
    return 0.0


def _question_for(text: str) -> dict:
    return {"type": "noul", "instructions": INSTRUCTION_PREFIX + text}


async def decide_pii_for_images(
    image_boxes: list[list[dict]],
    client: ClefClient | None = None,
    threshold: float | None = None,
) -> list[list[bool]]:
    """Decide PII for boxes across one or more images.

    `image_boxes[i]` is the OCR box list for image `i`. Returns a parallel
    structure of booleans: `result[i][j]` is True if box j of image i is PII.

    Questions are packed across all images into clef calls of at most 64
    questions each. Raises ClefError on any clef failure (fail closed).
    """
    settings = get_settings()
    thr = threshold if threshold is not None else settings.pii_threshold
    client = client or ClefClient()

    # Flatten into a global list of (image_idx, box_idx, text).
    flat: list[tuple[int, int, str]] = []
    for i, boxes in enumerate(image_boxes):
        for j, box in enumerate(boxes):
            flat.append((i, j, box.get("text", "")))

    # Pre-fill result with False so empty images / empty boxes are handled.
    result: list[list[bool]] = [[False] * len(boxes) for boxes in image_boxes]
    if not flat:
        return result

    num_batches = math.ceil(len(flat) / MAX_QUESTIONS)
    for b in range(num_batches):
        chunk = flat[b * MAX_QUESTIONS : (b + 1) * MAX_QUESTIONS]
        questions: dict[str, dict] = {}
        qid_map: dict[str, tuple[int, int]] = {}
        for k, (i, j, text) in enumerate(chunk):
            qid = f"box_{k}"
            questions[qid] = _question_for(text)
            qid_map[qid] = (i, j)

        answers = await client.system_one(STATE_FRAMING, questions)

        for qid, (i, j) in qid_map.items():
            prob = _true_probability(answers.get(qid, {}))
            result[i][j] = prob >= thr

    pii_total = sum(sum(1 for v in row if v) for row in result)
    _logger.info(
        "pii decision done images=%d boxes=%d pii=%d batches=%d",
        len(image_boxes),
        len(flat),
        pii_total,
        num_batches,
    )
    return result


async def decide_pii(
    boxes: list[dict],
    client: ClefClient | None = None,
    threshold: float | None = None,
) -> list[bool]:
    """Single-image convenience wrapper around `decide_pii_for_images`."""
    result = await decide_pii_for_images([boxes], client=client, threshold=threshold)
    return result[0]
