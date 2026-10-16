"""Tests for scam classification mapping (classify/classify.py).

All tests run WITHOUT a live clef server: ClefClient.system_one is mocked.
They assert the deterministic mapping of clef answers -> Assessment, exact
ported copy, deterministic ordering, and the unclear fallback on clef failure.
"""

from __future__ import annotations

import pytest

from app.clef_client import ClefError
from classify import classify as C


def _answers(score: float, **signal_probs: float) -> dict:
    """Build a clef answers map: verdict score + per-signal noul probabilities."""
    answers: dict = {"verdict": {"score": score}}
    for code in C.SIGNAL_ORDER:
        answers[code] = {"probability": signal_probs.get(code, 0.0)}
    return answers


# --- build_questions ------------------------------------------------------


def test_build_questions_shape():
    q = C.build_questions()
    # verdict + 6 signals
    assert len(q) == 1 + len(C.SIGNAL_ORDER)
    assert q["verdict"]["type"] == "score"
    assert q["verdict"]["criteria"] == C.VERDICT_CRITERIA
    for code in C.SIGNAL_ORDER:
        assert q[code]["type"] == "noul"
        assert q[code]["instructions"] == C.SIGNAL_INSTRUCTIONS[code]
    # within clef's 64-question limit
    assert 1 <= len(q) <= 64


# --- verdict thresholds ---------------------------------------------------


@pytest.mark.parametrize(
    "score,expected",
    [
        (0.0, "likely_safe"),
        (0.66, "likely_safe"),
        (0.67, "unclear"),  # == VERDICT_LOW -> not < low
        (1.0, "unclear"),
        (1.33, "unclear"),
        (1.34, "suspicious"),  # == VERDICT_HIGH -> not < high
        (2.0, "suspicious"),
    ],
)
def test_verdict_threshold_mapping(score, expected):
    out = C.assessment_from_answers(_answers(score), "hello")
    assert out["verdict"] == expected


def test_map_verdict_direct():
    assert C._map_verdict(0.5, 0.67, 1.34) == "likely_safe"
    assert C._map_verdict(0.67, 0.67, 1.34) == "unclear"
    assert C._map_verdict(1.34, 0.67, 1.34) == "suspicious"


# --- signal firing at threshold ------------------------------------------


def test_signal_fires_at_threshold():
    # default SIGNAL_THRESHOLD is 0.5
    out = C.assessment_from_answers(
        _answers(1.5, credential_request=0.5, urgency=0.49),
        "give me your OTP now",
    )
    codes = [s["code"] for s in out["signals"]]
    assert "credential_request" in codes
    assert "urgency" not in codes  # 0.49 < 0.5


def test_signals_deterministic_order():
    # Fire every signal; order must follow SIGNAL_ORDER exactly.
    probs = {code: 0.9 for code in C.SIGNAL_ORDER}
    out = C.assessment_from_answers(_answers(1.5, **probs), "text")
    codes = [s["code"] for s in out["signals"]]
    assert codes == C.SIGNAL_ORDER


def test_signal_explanations_exact():
    probs = {code: 0.9 for code in C.SIGNAL_ORDER}
    out = C.assessment_from_answers(_answers(1.5, **probs), "text")
    for sig in out["signals"]:
        assert sig["explanation"] == C.SIGNAL_EXPLANATIONS[sig["code"]]


# --- exact ported copy ----------------------------------------------------


def test_limitations_exact():
    out = C.assessment_from_answers(_answers(0.0), "safe text")
    assert out["limitations"] == C.LIMITATIONS_TEXT
    assert '"likely_safe"' in out["limitations"]


def test_uncertainty_strings():
    assert C._uncertainty_for("suspicious", 3).startswith("Multiple scam patterns")
    assert C._uncertainty_for("likely_safe", 0).startswith("No common scam patterns")
    assert C._uncertainty_for("unclear", 0).startswith("There was not enough signal")
    assert C._uncertainty_for("unclear", 2).startswith("Some warning signs")


# --- recommended actions --------------------------------------------------


def test_recommended_actions_fired_signals():
    detected = {"credential_request", "money_request", "suspicious_link", "authority_impersonation"}
    actions = C._recommended_actions(detected, "suspicious")
    scenarios = [a["scenario"] for a in actions]
    # order: shared_credentials, sent_money, clicked_link, just_received(auth),
    # then the always-on ScamShield step for non-likely_safe
    assert scenarios[0] == "shared_credentials"
    assert scenarios[1] == "sent_money"
    assert scenarios[2] == "clicked_link"
    assert "1799" in actions[-1]["title"]
    # urgency values are only normal|urgent
    assert all(a["urgency"] in ("normal", "urgent") for a in actions)


def test_recommended_actions_scamshield_only_when_not_safe():
    safe = C._recommended_actions(set(), "likely_safe")
    # no fired signals + likely_safe => fallback action only
    assert len(safe) == 1
    assert safe[0]["scenario"] == "just_received"
    assert "Nothing obvious stood out" in safe[0]["title"]

    unclear = C._recommended_actions(set(), "unclear")
    assert any("1799" in a["title"] for a in unclear)


# --- suggested tags -------------------------------------------------------


def test_suggested_tags_mapping_and_order():
    detected = {
        "credential_request",
        "authority_impersonation",
        "prize_lottery",
        "money_request",
        "suspicious_link",
    }
    tags = C._suggested_tags(detected)
    assert tags == [
        "phishing",
        "otp-scam",
        "bank-impersonation",
        "delivery-scam",
        "prize-scam",
        "money-request",
        "suspicious-link",
    ]


def test_suggested_tags_dedupe():
    # only credential_request -> phishing, otp-scam (no dupes)
    tags = C._suggested_tags({"credential_request"})
    assert tags == ["phishing", "otp-scam"]
    assert len(tags) == len(set(tags))


# --- evidence excerpt (link sanitisation + truncation) --------------------


def test_evidence_excerpt_sanitizes_links():
    text = "Verify at http://evil.example.com/login now"
    out = C._evidence_excerpt(text)
    assert "[link: evil.example.com]" in out
    assert "http://" not in out


def test_evidence_excerpt_truncates_to_80_runes():
    text = "x" * 200
    out = C._evidence_excerpt(text)
    assert len(out) <= C.MAX_EXCERPT_RUNES
    assert out.endswith("…")


def test_host_of_variants():
    assert C._host_of("https://www.Bank.com/path?x=1") == "bank.com"
    assert C._host_of("http://user:pass@host.co:8080/x") == "host.co"
    assert C._host_of("www.example.org.") == "example.org"


def test_sanitize_links_no_host():
    # a URL that reduces to an empty host yields the bare [link] form
    out = C._sanitize_links("go to http://.")
    assert "[link]" in out


# --- full assessment integration (mapping only) ---------------------------


def test_assessment_full_shape():
    probs = {"credential_request": 0.9, "urgency": 0.9}
    out = C.assessment_from_answers(_answers(1.5, **probs), "Send your OTP urgently")
    assert out["verdict"] == "suspicious"
    assert set(out.keys()) == {
        "verdict",
        "signals",
        "uncertainty",
        "limitations",
        "recommended_actions",
        "suggested_tags",
    }
    # evidence excerpt is the same sanitised snippet across fired signals
    excerpts = {s["evidence_excerpt"] for s in out["signals"]}
    assert len(excerpts) == 1


# --- clef failure fallback ------------------------------------------------


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


@pytest.mark.asyncio
async def test_classify_fallback_on_clef_error():
    out = await C.classify("some text", client=_RaisingClient())
    assert out["verdict"] == "unclear"
    assert out["signals"] == []
    assert out["suggested_tags"] == []
    assert out["limitations"] == C.LIMITATIONS_TEXT
    assert "could not complete" in out["uncertainty"]


@pytest.mark.asyncio
async def test_classify_happy_path_with_injected_client():
    client = _StubClient(_answers(1.5, credential_request=0.9))
    out = await C.classify("Send your OTP", client=client)
    assert out["verdict"] == "suspicious"
    assert [s["code"] for s in out["signals"]] == ["credential_request"]
    # injected client is NOT closed by classify (caller owns it)
    assert client.closed is False
