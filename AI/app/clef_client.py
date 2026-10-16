"""Thin async client for the clef-flash `/v1/systemone` decision endpoint.

Shared by both concerns (PII decision and scam classification). The decision
model takes a `state` plus 1–64 typed questions and returns a probability per
option per question in a single forward pass — there is nothing to parse beyond
reading the structured `answers` map.

Privacy: never log `state`, question instructions (they embed content), or raw
answers. Log only question ids, counts, latency, and status.
"""

from __future__ import annotations

import time

import httpx

from .config import get_settings
from .logging import get_logger

_logger = get_logger("clef_client")

MIN_QUESTIONS = 1
MAX_QUESTIONS = 64


class ClefError(RuntimeError):
    """Raised when the clef call fails (non-2xx, timeout, or transport error).

    Callers translate this into a safe failure:
      - PII: fail closed (HTTP 502) rather than under-redact.
      - Classification: return an `unclear` fallback assessment.
    """


class ClefClient:
    def __init__(
        self,
        base_url: str | None = None,
        model: str | None = None,
        timeout: float | None = None,
    ) -> None:
        settings = get_settings()
        self._base_url = (base_url or settings.clef_base_url).rstrip("/")
        self._model = model or settings.clef_model
        self._timeout = timeout if timeout is not None else settings.clef_timeout_seconds
        self._client: httpx.AsyncClient | None = None

    async def _get_client(self) -> httpx.AsyncClient:
        if self._client is None:
            self._client = httpx.AsyncClient(base_url=self._base_url, timeout=self._timeout)
        return self._client

    async def aclose(self) -> None:
        if self._client is not None:
            await self._client.aclose()
            self._client = None

    async def system_one(self, state: str, questions: dict) -> dict:
        """Call /v1/systemone and return the parsed `answers` map.

        Validates the question count is within clef's [1, 64] limit; callers
        that need more must batch. Raises ClefError on any failure.
        """
        count = len(questions)
        if count < MIN_QUESTIONS or count > MAX_QUESTIONS:
            raise ValueError(
                f"questions count {count} out of range [{MIN_QUESTIONS}, {MAX_QUESTIONS}]"
            )

        payload = {
            "model": self._model,
            "state": state,
            "questions": questions,
        }

        client = await self._get_client()
        started = time.monotonic()
        try:
            response = await client.post("/v1/systemone", json=payload)
            response.raise_for_status()
            data = response.json()
        except httpx.HTTPStatusError as exc:
            elapsed_ms = (time.monotonic() - started) * 1000
            _logger.warning(
                "clef systemone failed status=%s questions=%d latency_ms=%.1f",
                exc.response.status_code,
                count,
                elapsed_ms,
            )
            raise ClefError(f"clef returned status {exc.response.status_code}") from exc
        except (httpx.TimeoutException, httpx.TransportError) as exc:
            elapsed_ms = (time.monotonic() - started) * 1000
            _logger.warning(
                "clef systemone transport error questions=%d latency_ms=%.1f",
                count,
                elapsed_ms,
            )
            raise ClefError("clef transport error") from exc

        elapsed_ms = (time.monotonic() - started) * 1000
        _logger.info("clef systemone ok questions=%d latency_ms=%.1f", count, elapsed_ms)

        answers = data.get("answers")
        if not isinstance(answers, dict):
            raise ClefError("clef response missing 'answers' map")
        return answers
