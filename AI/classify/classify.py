"""Scam classification: build clef questions, call clef, map to Assessment.

clef-flash decides only two things: the overall verdict (a `score` question)
and which signals fired (one `noul` question per signal code). Everything else
in the `Assessment` — explanations, evidence excerpts, uncertainty, limitations,
recommended actions, suggested tags — is deterministic Python that mirrors the
Go rules analyzer (`backend/internal/checks/analyzer.go`) verbatim so the two
code paths stay consistent.

Privacy: never log `text`, `state`, question instructions (they embed content),
or raw clef answers. Log only verdict label, signal count, status.
"""

from __future__ import annotations

import re

from app.clef_client import ClefClient, ClefError
from app.config import get_settings
from app.logging import get_logger

_logger = get_logger("classify")

# --- Constants ported verbatim from analyzer.go --------------------------

MAX_EXCERPT_RUNES = 80

LIMITATIONS_TEXT = (
    "This is automated guidance based on common scam patterns, not a guarantee. "
    'A "likely_safe" result is not a safety guarantee — treat any unexpected '
    "request for money, credentials, or personal details with caution and verify "
    "through official channels."
)

# Deterministic signal order from analyzer.go: textRules order first, then
# suspicious_link appended last.
SIGNAL_ORDER = [
    "urgency",
    "credential_request",
    "money_request",
    "prize_lottery",
    "authority_impersonation",
    "suspicious_link",
]

# clef question instructions per signal (PLAN §6.2).
SIGNAL_INSTRUCTIONS = {
    "urgency": "Does this message use urgency or pressure to make the reader act fast?",
    "credential_request": "Does it ask for passwords, OTPs, PINs, Singpass, or other login credentials?",
    "money_request": "Does it ask to transfer money, pay a fee, or share bank/card/payment details?",
    "suspicious_link": "Does it contain a link that looks risky (shortener, lookalike brand domain, raw IP, or unexpected URL)?",
    "prize_lottery": "Does it claim the reader won a prize, lottery, or unexpected reward?",
    "authority_impersonation": "Does it claim to be a bank, government agency, police, courier, or other authority?",
}

# Per-code explanations ported verbatim from analyzer.go textRules[].explanation.
# suspicious_link's Go explanation is built dynamically from matched link
# reasons; in the classify path clef only decides firing (no matched phrase), so
# we use a fixed, representative explanation (documented choice per PLAN §6.3).
SIGNAL_EXPLANATIONS = {
    "urgency": "Creates a false sense of urgency to pressure you into acting before you can think or verify.",
    "credential_request": "Asks for credentials, one-time codes, or account details. Legitimate organisations never ask for these.",
    "money_request": "Requests money, a transfer, or payment details — a common way scammers extract funds.",
    "prize_lottery": "Promises a prize or windfall you did not enter for, a classic lure to collect personal or payment details.",
    "authority_impersonation": "Claims to be from a bank, government agency, or delivery service to borrow their authority. Verify independently.",
    "suspicious_link": (
        "Contains a link that looks risky. Do not tap links in unexpected "
        "messages; go to the official site directly."
    ),
}

VERDICT_CRITERIA = ["likely_safe", "unclear", "suspicious"]

# --- Link sanitisation ported from analyzer.go --------------------------

_URL_REGEX = re.compile(r"(?i)\b((?:https?://|www\.)[^\s<>\"']+)")


def _host_of(raw_url: str) -> str:
    """Reduce a URL to its bare host (ported from analyzer.go hostOf)."""
    s = raw_url.strip()
    # strip scheme
    for scheme in ("http://", "https://", "HTTP://", "HTTPS://"):
        if s.lower().startswith(scheme.lower()):
            s = s[len(scheme) :]
            break
    # drop userinfo@
    if "@" in s:
        s = s.split("@", 1)[1]
    # cut at path/query/fragment
    for sep in ("/", "?", "#"):
        idx = s.find(sep)
        if idx != -1:
            s = s[:idx]
    # drop :port
    if ":" in s:
        s = s.split(":", 1)[0]
    # strip leading www.
    if s.lower().startswith("www."):
        s = s[4:]
    # trim trailing punctuation
    s = s.rstrip(".,);]!\"'")
    return s.lower()


def _sanitize_links(text: str) -> str:
    """Replace URLs with host-only, non-clickable `[link: host]` form."""

    def repl(match: re.Match) -> str:
        host = _host_of(match.group(1))
        if host:
            return f"[link: {host}]"
        return "[link]"

    return _URL_REGEX.sub(repl, text)


def _truncate_runes(text: str, limit: int) -> str:
    """Truncate to `limit` runes, appending an ellipsis if truncated."""
    if len(text) <= limit:
        return text
    return text[: limit - 1].rstrip() + "…"


def _evidence_excerpt(text: str) -> str:
    """Build a short, link-sanitised snippet of the message.

    clef gives no matched phrase, so we sanitise the whole message and take a
    length-bounded snippet (≤ MAX_EXCERPT_RUNES runes). Mirrors the sanitise +
    truncate tail of analyzer.go excerptAround.
    """
    sanitized = _sanitize_links(" ".join(text.split()))
    return _truncate_runes(sanitized, MAX_EXCERPT_RUNES)


# --- Deterministic field builders (ported from analyzer.go) --------------


def _uncertainty_for(verdict: str, signal_count: int) -> str:
    if verdict == "suspicious":
        return (
            "Multiple scam patterns were detected. This assessment is based on "
            "common patterns and may still miss or over-flag; when in doubt, "
            "verify through official channels."
        )
    if verdict == "likely_safe":
        return (
            "No common scam patterns were detected, but automated checks can miss "
            "novel or well-crafted scams. Stay cautious with unexpected requests."
        )
    # unclear
    if signal_count == 0:
        return (
            "There was not enough signal to reach a confident conclusion. Treat "
            "the message with caution."
        )
    return (
        "Some warning signs were detected but they are not conclusive. Verify "
        "independently before acting."
    )


def _recommended_actions(detected: set[str], verdict: str) -> list[dict]:
    actions: list[dict] = []
    if "credential_request" in detected:
        actions.append(
            {
                "scenario": "shared_credentials",
                "title": "Do not share passwords, OTPs, PINs, or Singpass details. No genuine bank or agency will ask for them.",
                "urgency": "urgent",
            }
        )
    if "money_request" in detected:
        actions.append(
            {
                "scenario": "sent_money",
                "title": "Do not transfer money or pay any fee. If you already have, contact your bank immediately to try to stop the transfer.",
                "urgency": "urgent",
            }
        )
    if "suspicious_link" in detected:
        actions.append(
            {
                "scenario": "clicked_link",
                "title": "Do not tap the link. Reach the organisation through its official app or website typed in yourself.",
                "urgency": "urgent",
            }
        )
    if "authority_impersonation" in detected:
        actions.append(
            {
                "scenario": "just_received",
                "title": "Verify the sender independently using an official contact number, not one provided in the message.",
                "urgency": "normal",
            }
        )
    if verdict != "likely_safe":
        actions.append(
            {
                "scenario": "just_received",
                "title": "Check with ScamShield (call 1799) or the official organisation before you act.",
                "urgency": "normal",
            }
        )
    if not actions:
        actions.append(
            {
                "scenario": "just_received",
                "title": "Nothing obvious stood out, but stay cautious with unexpected requests and verify through official channels.",
                "urgency": "normal",
            }
        )
    return actions


def _suggested_tags(detected: set[str]) -> list[str]:
    tags: list[str] = []
    if "credential_request" in detected:
        tags.extend(["phishing", "otp-scam"])
    if "authority_impersonation" in detected:
        tags.extend(["bank-impersonation", "delivery-scam"])
    if "prize_lottery" in detected:
        tags.append("prize-scam")
    if "money_request" in detected:
        tags.append("money-request")
    if "suspicious_link" in detected:
        tags.append("suspicious-link")
    # dedupe preserving first-seen order
    seen: set[str] = set()
    deduped: list[str] = []
    for tag in tags:
        if tag not in seen:
            seen.add(tag)
            deduped.append(tag)
    return deduped


def _map_verdict(score: float, low: float, high: float) -> str:
    if score < low:
        return "likely_safe"
    if score < high:
        return "unclear"
    return "suspicious"


def _fallback_assessment() -> dict:
    """Safe `unclear` assessment when clef is unreachable (PLAN §6.4)."""
    return {
        "verdict": "unclear",
        "signals": [],
        "uncertainty": (
            "The automated scam check could not complete, so this message could "
            "not be assessed. Treat it with caution and verify through official "
            "channels."
        ),
        "limitations": LIMITATIONS_TEXT,
        "recommended_actions": _recommended_actions(set(), "unclear"),
        "suggested_tags": [],
    }


def build_questions() -> dict:
    """Build the single-call clef question set: verdict score + per-signal noul."""
    questions: dict = {
        "verdict": {
            "type": "score",
            "instructions": "Rate how likely this message is a scam, from clearly safe to clearly a scam.",
            "criteria": VERDICT_CRITERIA,
        }
    }
    for code in SIGNAL_ORDER:
        questions[code] = {
            "type": "noul",
            "instructions": SIGNAL_INSTRUCTIONS[code],
        }
    return questions


def _true_probability(answer: object) -> float:
    """Extract a noul true-probability from a clef answer entry."""
    if isinstance(answer, int | float):
        return float(answer)
    if isinstance(answer, dict):
        for key in ("probability", "true", "prob"):
            if key in answer and isinstance(answer[key], int | float):
                return float(answer[key])
    return 0.0


def _score_value(answer: object) -> float:
    if isinstance(answer, int | float):
        return float(answer)
    if isinstance(answer, dict) and isinstance(answer.get("score"), int | float):
        return float(answer["score"])
    return 0.0


def assessment_from_answers(answers: dict, text: str) -> dict:
    """Map clef `answers` + original text into a full Assessment dict."""
    settings = get_settings()

    score = _score_value(answers.get("verdict"))
    verdict = _map_verdict(score, settings.verdict_low, settings.verdict_high)

    detected: set[str] = set()
    for code in SIGNAL_ORDER:
        if _true_probability(answers.get(code)) >= settings.signal_threshold:
            detected.add(code)

    excerpt = _evidence_excerpt(text)
    signals = [
        {
            "code": code,
            "evidence_excerpt": excerpt,
            "explanation": SIGNAL_EXPLANATIONS[code],
        }
        for code in SIGNAL_ORDER
        if code in detected
    ]

    return {
        "verdict": verdict,
        "signals": signals,
        "uncertainty": _uncertainty_for(verdict, len(detected)),
        "limitations": LIMITATIONS_TEXT,
        "recommended_actions": _recommended_actions(detected, verdict),
        "suggested_tags": _suggested_tags(detected),
    }


async def classify(text: str, locale: str = "en-SG", client: ClefClient | None = None) -> dict:
    """Classify message text into a full Assessment dict.

    On clef failure, returns the safe `unclear` fallback rather than raising,
    so the Go side can still show a cautious result (PLAN §6.4).
    """
    own_client = client is None
    clef = client or ClefClient()
    try:
        answers = await clef.system_one(text, build_questions())
    except ClefError:
        _logger.warning("classify falling back to unclear (clef unavailable)")
        return _fallback_assessment()
    finally:
        if own_client:
            await clef.aclose()

    assessment = assessment_from_answers(answers, text)
    _logger.info(
        "classify ok verdict=%s signals=%d",
        assessment["verdict"],
        len(assessment["signals"]),
    )
    return assessment
