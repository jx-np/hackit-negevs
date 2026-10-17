"""Post scam-category prediction via a single clef `choice` question.

Asks clef-flash ONE `choice` question whose options are the canonical scam
categories (see `CATEGORIES`), and returns the probability it assigns to each.
The Go post classifier calls this to assign a published post's category, which
is what makes the post publicly visible.

Categories and tags are separate taxonomies: this endpoint returns a *category*
slug (`categories.slug`), while `/v1/classify/tags` returns *tag* slugs
(`tags.slug`). They overlap only on `phishing`.

Privacy: never log `text`, `state`, question instructions (they embed content),
or raw clef answers. Log only the category count, degraded status, and latency.
"""

from __future__ import annotations

from app.clef_client import MAX_QUESTIONS, ClefClient, ClefError
from app.logging import get_logger
from classify import choice

_logger = get_logger("category")

# Canonical scam categories. KEEP IN SYNC with backend/seed.sql `categories`.
# slug -> short, content-free description used as the choice option's meaning.
CATEGORIES: dict[str, str] = {
    "scam_call": "a scam delivered by a phone call",
    "scam_text": "a scam delivered by an SMS or text message",
    "phishing": "steals login credentials, passwords, or account access",
    "ecommerce": "a fake shop, order, refund, or delivery scam",
    "investment": "a fake investment, trading, or crypto opportunity",
    "job_scam": "a fake job offer, recruitment, or task-based scam",
    "impersonation": "pretends to be a person or organisation the reader trusts",
    "other": "none of the above, or the category is unclear",
}

# The single question id; clef returns its answer under this key.
CATEGORY_QUESTION_ID = "category"

# The question wording. Content-independent, so it is safe to keep as a constant.
_INSTRUCTIONS = (
    "Which scam category best fits this message? Choose the closest single match "
    "from the options."
)

# Keep the option count (and, trivially, the question count) within clef's caps.
assert len(CATEGORIES) <= MAX_QUESTIONS, "canonical category set exceeds clef question limit"


def build_questions() -> dict[str, dict]:
    """Build the single `choice` question: which category best fits the message.

    Exactly one question is emitted, so a prediction costs one decision pass
    regardless of how many categories there are.
    """
    return choice.build_question(CATEGORY_QUESTION_ID, _INSTRUCTIONS, CATEGORIES)


def scores_from_answers(answers: dict) -> dict:
    """Map a clef `answers` map to the response body (without `degraded`)."""
    best, scores, conf = choice.map_answer(answers.get(CATEGORY_QUESTION_ID), CATEGORIES)
    return {"category": best, "scores": scores, "confidence": conf}


def _degraded() -> dict:
    """No-signal result used when the model could not be reached."""
    return {"category": "", "scores": {}, "confidence": 0.0}


async def classify_category(
    text: str,
    locale: str = "en-SG",
    client: ClefClient | None = None,
) -> dict:
    """Predict the scam category of `text` with one clef question.

    Returns `{"category", "scores", "confidence", "degraded"}`. On clef failure
    returns a safe degraded result (`category: ""`, empty `scores`,
    `degraded: true`) rather than raising, mirroring the `/v1/classify`
    fallback. The message text and clef answers are never logged.
    """
    own_client = client is None
    clef = client or ClefClient()
    try:
        answers = await clef.system_one(text, build_questions())
    except ClefError:
        _logger.warning(
            "category scoring degraded (clef unavailable) categories=%d", len(CATEGORIES)
        )
        return {**_degraded(), "degraded": True}
    finally:
        if own_client:
            await clef.aclose()

    _logger.info("category scoring ok categories=%d", len(CATEGORIES))
    return {**scores_from_answers(answers), "degraded": False}
