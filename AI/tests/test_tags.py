"""Tests for per-tag scam scoring (classify/tags.py + /v1/classify/tags).

The endpoint asks clef a SINGLE `choice` question over the canonical tags.
All tests run WITHOUT a live clef server: the client is injected/stubbed. They
assert the one-question guarantee, the deterministic clef answer -> scores
mapping, the tag taxonomy staying in sync with backend/seed.sql, and the
degraded fallback on outage.
"""

from __future__ import annotations

import pytest
from fastapi.testclient import TestClient

from app.clef_client import ClefError
from app.main import app
from classify import tags as T

# The canonical tags seeded in backend/seed.sql. If this set changes, update
# both the seed and classify/tags.TAGS.
CANONICAL_SEED_TAGS = {
    "bank-impersonation",
    "otp-scam",
    "phishing",
    "prize-scam",
    "delivery-scam",
    "money-request",
    "suspicious-link",
    "government-impersonation",
    "other",
}


def _choice_answer(
    choice: str = "phishing",
    confidence: float = 0.8,
    probs: dict | None = None,
) -> dict:
    """A clef answers map wrapping one choice answer under the tag question id."""
    if probs is None:
        probs = {slug: 0.0 for slug in T.TAGS}
        probs[choice] = 1.0
    return {
        T.TAG_QUESTION_ID: {
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


def test_tags_match_seed_taxonomy():
    assert set(T.TAGS) == CANONICAL_SEED_TAGS


def test_build_questions_is_a_single_choice_question():
    q = T.build_questions()
    # The whole point: exactly ONE question (one decision pass on the GPU).
    assert len(q) == 1
    assert set(q) == {T.TAG_QUESTION_ID}
    question = q[T.TAG_QUESTION_ID]
    assert question["type"] == "choice"
    # Options are the canonical tags, label -> description.
    assert set(question["criteria"]) == set(T.TAGS)
    assert question["criteria"] == T.TAGS
    # within clef's per-choice option limit
    assert 1 <= len(question["criteria"]) <= 26


# --- answer mapping -------------------------------------------------------


def test_scores_from_answers_passthrough():
    probs = {slug: 0.01 for slug in T.TAGS}
    probs["phishing"] = 0.93
    out = T.scores_from_answers(_choice_answer("phishing", confidence=0.8, probs=probs))
    assert out["best_tag"] == "phishing"
    assert out["confidence"] == 0.8
    assert set(out["scores"]) == set(T.TAGS)
    assert out["scores"]["phishing"] == 0.93
    assert sum(out["scores"].values()) == pytest.approx(sum(probs.values()))


def test_best_tag_falls_back_to_argmax_when_choice_missing():
    probs = {slug: 0.0 for slug in T.TAGS}
    probs["otp-scam"] = 1.0
    answer = {T.TAG_QUESTION_ID: {"type": "choice", "probabilities": probs}}
    out = T.scores_from_answers(answer)
    assert out["best_tag"] == "otp-scam"


def test_best_tag_ignores_unknown_choice_label():
    probs = {slug: 0.0 for slug in T.TAGS}
    probs["prize-scam"] = 1.0
    answer = {T.TAG_QUESTION_ID: {"type": "choice", "choice": "not-a-tag", "probabilities": probs}}
    out = T.scores_from_answers(answer)
    assert out["best_tag"] == "prize-scam"


def test_uniform_prior_when_probabilities_missing():
    answer = {T.TAG_QUESTION_ID: {"type": "choice", "choice": "phishing"}}
    out = T.scores_from_answers(answer)
    assert set(out["scores"]) == set(T.TAGS)
    assert out["scores"]["phishing"] == pytest.approx(1.0 / len(T.TAGS))
    assert sum(out["scores"].values()) == pytest.approx(1.0)
    # best_tag still echoes a valid server choice
    assert out["best_tag"] == "phishing"


def test_confidence_computed_when_missing():
    probs = {slug: 0.0 for slug in T.TAGS}
    probs["phishing"] = 1.0  # pmax 1.0 over K tags -> confidence 1.0
    answer = {T.TAG_QUESTION_ID: {"type": "choice", "probabilities": probs}}
    out = T.scores_from_answers(answer)
    assert out["confidence"] == pytest.approx(1.0)


# --- degraded fallback ----------------------------------------------------


@pytest.mark.asyncio
async def test_classify_tags_degraded_on_clef_error():
    out = await T.classify_tags("some text", client=_RaisingClient())
    assert out["degraded"] is True
    assert out["best_tag"] == ""
    assert out["scores"] == {}
    assert out["confidence"] == 0.0


@pytest.mark.asyncio
async def test_classify_tags_happy_path_does_not_close_injected_client():
    client = _StubClient(_choice_answer("phishing"))
    out = await T.classify_tags("send your otp", client=client)
    assert out["degraded"] is False
    assert out["best_tag"] == "phishing"
    # injected client is owned by the caller: not closed here
    assert client.closed is False


# --- endpoint -------------------------------------------------------------


def test_endpoint_returns_tag_scores():
    c = TestClient(app)
    app.state.clef_client = _StubClient(_choice_answer("phishing", confidence=0.9))
    resp = c.post("/v1/classify/tags", json={"text": "send your otp now", "locale": "en-SG"})
    assert resp.status_code == 200
    body = resp.json()
    assert set(body) == {"best_tag", "scores", "confidence", "degraded"}
    assert body["degraded"] is False
    assert body["best_tag"] == "phishing"
    assert set(body["scores"]) == set(T.TAGS)


def test_endpoint_degraded_on_outage():
    c = TestClient(app)
    app.state.clef_client = _RaisingClient()
    resp = c.post("/v1/classify/tags", json={"text": "anything"})
    assert resp.status_code == 200
    body = resp.json()
    assert body["degraded"] is True
    assert body["best_tag"] == ""
