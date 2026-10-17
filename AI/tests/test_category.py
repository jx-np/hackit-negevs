"""Tests for scam-category prediction (classify/category.py + /v1/classify/category).

The endpoint asks clef a SINGLE `choice` question over the canonical categories.
All tests run WITHOUT a live clef server: the client is injected/stubbed. They
assert the one-question guarantee, the deterministic clef answer -> category
mapping, the category taxonomy staying in sync with backend/seed.sql, and the
degraded fallback on outage.
"""

from __future__ import annotations

import pytest
from fastapi.testclient import TestClient

from app.clef_client import ClefError
from app.main import app
from classify import category as C

# The canonical categories seeded in backend/seed.sql. If this set changes,
# update both the seed and classify/category.CATEGORIES.
CANONICAL_SEED_CATEGORIES = {
    "scam_call",
    "scam_text",
    "phishing",
    "ecommerce",
    "investment",
    "job_scam",
    "impersonation",
    "other",
}


def _choice_answer(
    choice: str = "phishing",
    confidence: float = 0.8,
    probs: dict | None = None,
) -> dict:
    """A clef answers map wrapping one choice answer under the category question."""
    if probs is None:
        probs = {slug: 0.0 for slug in C.CATEGORIES}
        probs[choice] = 1.0
    return {
        C.CATEGORY_QUESTION_ID: {
            "type": "choice",
            "choice": choice,
            "confidence": confidence,
            "probabilities": probs,
        }
    }


class _RaisingClient:
    async def system_one(self, state, questions):
        raise ClefError("clef down")

    async def aclose(self):
        pass


class _StubClient:
    def __init__(self, answers):
        self._answers = answers
        self.closed = False

    async def system_one(self, state, questions):
        return self._answers

    async def aclose(self):
        self.closed = True


# --- taxonomy + question shape --------------------------------------------


def test_categories_match_seed_taxonomy():
    assert set(C.CATEGORIES) == CANONICAL_SEED_CATEGORIES


def test_build_questions_is_a_single_choice_question():
    q = C.build_questions()
    # Exactly ONE question (one decision pass on the GPU).
    assert len(q) == 1
    assert set(q) == {C.CATEGORY_QUESTION_ID}
    question = q[C.CATEGORY_QUESTION_ID]
    assert question["type"] == "choice"
    assert set(question["criteria"]) == set(C.CATEGORIES)
    assert question["criteria"] == C.CATEGORIES
    assert 1 <= len(question["criteria"]) <= 26


# --- answer mapping -------------------------------------------------------


def test_scores_from_answers_passthrough():
    probs = {slug: 0.01 for slug in C.CATEGORIES}
    probs["phishing"] = 0.93
    out = C.scores_from_answers(_choice_answer("phishing", confidence=0.8, probs=probs))
    assert out["category"] == "phishing"
    assert out["confidence"] == 0.8
    assert set(out["scores"]) == set(C.CATEGORIES)
    assert out["scores"]["phishing"] == 0.93


def test_category_falls_back_to_argmax_when_choice_missing():
    probs = {slug: 0.0 for slug in C.CATEGORIES}
    probs["impersonation"] = 1.0
    answer = {C.CATEGORY_QUESTION_ID: {"type": "choice", "probabilities": probs}}
    out = C.scores_from_answers(answer)
    assert out["category"] == "impersonation"


def test_category_ignores_unknown_choice_label():
    probs = {slug: 0.0 for slug in C.CATEGORIES}
    probs["investment"] = 1.0
    answer = {
        C.CATEGORY_QUESTION_ID: {
            "type": "choice",
            "choice": "not-a-category",
            "probabilities": probs,
        }
    }
    out = C.scores_from_answers(answer)
    assert out["category"] == "investment"


def test_uniform_prior_when_probabilities_missing():
    answer = {C.CATEGORY_QUESTION_ID: {"type": "choice", "choice": "phishing"}}
    out = C.scores_from_answers(answer)
    assert set(out["scores"]) == set(C.CATEGORIES)
    assert out["scores"]["phishing"] == pytest.approx(1.0 / len(C.CATEGORIES))
    assert out["category"] == "phishing"


def test_confidence_computed_when_missing():
    probs = {slug: 0.0 for slug in C.CATEGORIES}
    probs["phishing"] = 1.0  # pmax 1.0 over K categories -> confidence 1.0
    answer = {C.CATEGORY_QUESTION_ID: {"type": "choice", "probabilities": probs}}
    out = C.scores_from_answers(answer)
    assert out["confidence"] == pytest.approx(1.0)


# --- degraded fallback ----------------------------------------------------


@pytest.mark.asyncio
async def test_classify_category_degraded_on_clef_error():
    out = await C.classify_category("some text", client=_RaisingClient())
    assert out["degraded"] is True
    assert out["category"] == ""
    assert out["scores"] == {}
    assert out["confidence"] == 0.0


@pytest.mark.asyncio
async def test_classify_category_happy_path_does_not_close_injected_client():
    client = _StubClient(_choice_answer("phishing"))
    out = await C.classify_category("send your otp", client=client)
    assert out["degraded"] is False
    assert out["category"] == "phishing"
    assert client.closed is False


# --- endpoint -------------------------------------------------------------


def test_endpoint_returns_category():
    c = TestClient(app)
    app.state.clef_client = _StubClient(_choice_answer("impersonation", confidence=0.9))
    resp = c.post("/v1/classify/category", json={"text": "send your otp", "locale": "en-SG"})
    assert resp.status_code == 200
    body = resp.json()
    assert set(body) == {"category", "scores", "confidence", "degraded"}
    assert body["degraded"] is False
    assert body["category"] == "impersonation"
    assert set(body["scores"]) == set(C.CATEGORIES)


def test_endpoint_degraded_on_outage():
    c = TestClient(app)
    app.state.clef_client = _RaisingClient()
    resp = c.post("/v1/classify/category", json={"text": "anything"})
    assert resp.status_code == 200
    body = resp.json()
    assert body["degraded"] is True
    assert body["category"] == ""
