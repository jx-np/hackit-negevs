"""Shared helpers for System One `choice` questions over a fixed option set.

Both the per-tag scorer (`classify.tags`) and the category scorer
(`classify.category`) ask the decision model exactly ONE `choice` question whose
options are a fixed slug -> meaning map, then map the answer to a probability per
option. Keeping that mapping here avoids duplicating it (and its defensive
parsing) across the two modules.

Privacy: these helpers never log; callers own that responsibility.
"""

from __future__ import annotations


def build_question(question_id: str, instructions: str, options: dict[str, str]) -> dict[str, dict]:
    """Wrap `options` (label -> meaning) in a single `choice` question."""
    return {
        question_id: {
            "type": "choice",
            "instructions": instructions,
            "criteria": dict(options),
        }
    }


def probabilities(answer: dict, options: dict[str, str]) -> dict[str, float]:
    """Per-option probability keyed by option label; uniform prior if absent.

    The returned map always contains every option and, unless the model reported
    all-zero (or no) probabilities, sums to 1.
    """
    raw = answer.get("probabilities") if isinstance(answer, dict) else None
    out: dict[str, float] = {}
    for slug in options:
        val = raw.get(slug, 0.0) if isinstance(raw, dict) else 0.0
        out[slug] = (
            float(val) if isinstance(val, int | float) and not isinstance(val, bool) else 0.0
        )
    if not any(out.values()):
        uniform = 1.0 / len(options)
        return {slug: uniform for slug in options}
    return out


def best_option(answer: dict, options: dict[str, str], scores: dict[str, float]) -> str:
    """The chosen option: prefer the server's `choice`, else the argmax."""
    choice = answer.get("choice") if isinstance(answer, dict) else None
    if isinstance(choice, str) and choice in options:
        return choice
    return max(scores, key=scores.get)


def confidence(scores: dict[str, float]) -> float:
    """Normalized-entropy confidence over the option distribution.

    Mirrors the System One definition: `(p_max - 1/K) / (1 - 1/K)`, 1.0 when
    there is a single option.
    """
    n = len(scores)
    if n <= 1:
        return 1.0
    pmax = max(scores.values())
    return (pmax - 1.0 / n) / (1.0 - 1.0 / n)


def map_answer(answer: object, options: dict[str, str]) -> tuple[str, dict[str, float], float]:
    """Map one clef `choice` answer to `(best, scores, confidence)`.

    `best` is always one of the option labels, `scores` always covers every
    option, and `confidence` falls back to the normalized-entropy value when the
    model did not report one.
    """
    a = answer if isinstance(answer, dict) else {}
    scores = probabilities(a, options)
    conf = a.get("confidence")
    if not (isinstance(conf, int | float) and not isinstance(conf, bool)):
        conf = confidence(scores)
    return best_option(a, options, scores), scores, float(conf)
