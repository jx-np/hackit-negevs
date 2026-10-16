"""Tests for the PII decision step (pii/decide.py).

Runs without a live clef server: a stub client records calls and returns
canned answers. Covers threshold mapping, batching >64 boxes into multiple
calls with correct id<->box mapping, and fail-closed on clef error.
"""

from __future__ import annotations

import pytest

from app.clef_client import ClefError
from pii import decide as D


class _RecordingClient:
    """Stub clef client. `answer_fn(qid)` returns a true-probability per qid."""

    def __init__(self, answer_fn):
        self._answer_fn = answer_fn
        self.calls: list[dict] = []

    async def system_one(self, state, questions):
        self.calls.append(questions)
        return {qid: {"probability": self._answer_fn(qid)} for qid in questions}


class _RaisingClient:
    async def system_one(self, state, questions):
        raise ClefError("clef down")


def _boxes(texts: list[str]) -> list[dict]:
    return [{"box": [[0, 0], [1, 0], [1, 1], [0, 1]], "text": t, "score": 0.99} for t in texts]


# --- true-probability extraction -----------------------------------------


def test_true_probability_key_variants():
    assert D._true_probability({"probability": 0.8}) == 0.8
    assert D._true_probability({"true": 0.7}) == 0.7
    assert D._true_probability({"p_true": 0.6}) == 0.6
    assert D._true_probability({"value": 0.5}) == 0.5
    assert D._true_probability({"probabilities": {"true": 0.9}}) == 0.9
    assert D._true_probability({}) == 0.0
    assert D._true_probability("nope") == 0.0


# --- threshold mapping ----------------------------------------------------


@pytest.mark.asyncio
async def test_threshold_mapping():
    # box_0 => 0.9 (PII), box_1 => 0.3 (not PII) at default threshold 0.5
    probs = {"box_0": 0.9, "box_1": 0.3}
    client = _RecordingClient(lambda qid: probs[qid])
    result = await D.decide_pii(_boxes(["sensitive", "benign"]), client=client)
    assert result == [True, False]


@pytest.mark.asyncio
async def test_threshold_boundary_inclusive():
    # exactly at threshold (0.5) fires (>=)
    client = _RecordingClient(lambda qid: 0.5)
    result = await D.decide_pii(_boxes(["a"]), client=client, threshold=0.5)
    assert result == [True]


@pytest.mark.asyncio
async def test_custom_threshold():
    client = _RecordingClient(lambda qid: 0.7)
    result = await D.decide_pii(_boxes(["a"]), client=client, threshold=0.8)
    assert result == [False]


# --- batching -------------------------------------------------------------


@pytest.mark.asyncio
async def test_batching_splits_over_64():
    n = 150  # -> ceil(150/64) = 3 calls
    client = _RecordingClient(lambda qid: 0.9)
    result = await D.decide_pii(_boxes([f"t{i}" for i in range(n)]), client=client)
    assert len(result) == n
    assert all(result)
    assert len(client.calls) == 3
    # each batch has <= 64 questions, total == n
    assert sum(len(c) for c in client.calls) == n
    assert all(len(c) <= 64 for c in client.calls)


@pytest.mark.asyncio
async def test_batch_mapping_correct():
    # Only odd-indexed boxes are PII; verify mapping survives batching.
    n = 70  # 2 batches
    boxes = _boxes([f"t{i}" for i in range(n)])

    # qid is box_k within a batch; we instead drive by making only certain
    # boxes PII via text content. Map through recorded instructions.
    def answer_fn(qid):
        return 0.0  # overwritten below per-call via custom client

    # Custom client: PII iff the embedded text ends with an odd number.
    class _TextDrivenClient:
        def __init__(self):
            self.calls = []

        async def system_one(self, state, questions):
            self.calls.append(questions)
            out = {}
            for qid, q in questions.items():
                instr = q["instructions"]
                # text was appended after "Text: "
                text = instr.split("Text: ", 1)[1]
                num = int(text[1:])  # strip leading 't'
                out[qid] = {"probability": 0.9 if num % 2 == 1 else 0.1}
            return out

    client = _TextDrivenClient()
    result = await D.decide_pii(boxes, client=client)
    assert len(client.calls) == 2
    for i, pii in enumerate(result):
        assert pii == (i % 2 == 1)


@pytest.mark.asyncio
async def test_multi_image_packing():
    # Two images; questions packed across both into a single call (<=64).
    img0 = _boxes(["a0", "a1"])
    img1 = _boxes(["b0"])
    client = _RecordingClient(lambda qid: 0.9)
    result = await D.decide_pii_for_images([img0, img1], client=client)
    assert result == [[True, True], [True]]
    assert len(client.calls) == 1
    assert len(client.calls[0]) == 3


@pytest.mark.asyncio
async def test_empty_images():
    client = _RecordingClient(lambda qid: 0.9)
    result = await D.decide_pii_for_images([[], []], client=client)
    assert result == [[], []]
    # no clef call when there are no boxes
    assert len(client.calls) == 0


# --- fail closed ----------------------------------------------------------


@pytest.mark.asyncio
async def test_fail_closed_raises():
    with pytest.raises(ClefError):
        await D.decide_pii(_boxes(["x"]), client=_RaisingClient())
