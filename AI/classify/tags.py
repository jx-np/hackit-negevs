"""Per-tag scam scoring via a single clef `choice` question.

Asks clef-flash ONE `choice` question whose options are the canonical tags (see
`TAGS`), and returns the probability it assigns to each tag. One question
instead of one `score` question per tag keeps the decision-model cost minimal
(a single decision pass) while still scoring every tag.

This is a standalone scoring aid layered *beside* `/v1/classify`: it does not
feed the Go `Assessment` contract and never replaces the verdict/signals path.
The Go post classifier consumes this endpoint to attach tags to community posts.

Privacy: never log `text`, `state`, question instructions (they embed content),
or raw clef answers. Log only the tag count, degraded status, and latency.
"""

from __future__ import annotations

from app.clef_client import MAX_QUESTIONS, ClefClient, ClefError
from app.logging import get_logger
from classify import choice

_logger = get_logger("tags")

# Canonical community-scam tags. KEEP IN SYNC with backend/seed.sql `tags`.
# slug -> short, content-free description used as the choice option's meaning.
TAGS: dict[str, str] = {
    "bank-impersonation": "pretends to be a bank or bank staff",
    "otp-scam": "asks for a one-time password (OTP) or login code",
    "phishing": "steals login credentials or account access",
    "prize-scam": "claims the reader won a prize or unexpected reward",
    "delivery-scam": "pretends to be a parcel or courier company",
    "money-request": "asks to transfer money or share payment details",
    "suspicious-link": "contains a risky or unexpected URL",
    "government-impersonation": "pretends to be a government agency or official",
    "other": "none of the above, or the tag is unclear",
}

# The single question id; clef returns its answer under this key.
TAG_QUESTION_ID = "tag"

# The question wording. Content-independent, so it is safe to keep as a constant.
_INSTRUCTIONS = (
    "Which scam tag best fits this message? Choose the closest single match from the options."
)

# Keep the option count (and, trivially, the question count) within clef's caps.
assert len(TAGS) <= MAX_QUESTIONS, "canonical tag set exceeds clef question limit"


def build_questions() -> dict[str, dict]:
    """Build the single `choice` question: which tag best fits the message.

    Exactly one question is emitted, so a scoring request costs one decision
    pass regardless of how many tags there are.
    """
    return choice.build_question(TAG_QUESTION_ID, _INSTRUCTIONS, TAGS)


def scores_from_answers(answers: dict) -> dict:
    """Map a clef `answers` map to the response body (without `degraded`)."""
    best, scores, conf = choice.map_answer(answers.get(TAG_QUESTION_ID), TAGS)
    return {"best_tag": best, "scores": scores, "confidence": conf}


def _degraded() -> dict:
    """No-signal result used when the model could not be reached."""
    return {"best_tag": "", "scores": {}, "confidence": 0.0}


async def classify_tags(
    text: str,
    locale: str = "en-SG",
    client: ClefClient | None = None,
) -> dict:
    """Score every canonical tag against `text` with one clef question.

    Returns `{"best_tag", "scores", "confidence", "degraded"}`. On clef failure
    returns a safe degraded result (`best_tag: ""`, empty `scores`,
    `degraded: true`) rather than raising, mirroring the `/v1/classify`
    fallback. The message text and clef answers are never logged.
    """
    own_client = client is None
    clef = client or ClefClient()
    try:
        answers = await clef.system_one(text, build_questions())
    except ClefError:
        _logger.warning("tag scoring degraded (clef unavailable) tags=%d", len(TAGS))
        return {**_degraded(), "degraded": True}
    finally:
        if own_client:
            await clef.aclose()

    result = scores_from_answers(answers)
    print("tag scoring result=", result)

    _logger.info("tag scoring ok tags=%d", len(TAGS))
    return {**result, "degraded": False}
