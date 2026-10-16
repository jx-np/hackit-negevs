"""Privacy-safe logging setup.

HARD RULE (see ../AGENTS.md and PLAN.md §9): never log image bytes, OCR text,
per-box text, extracted_text, clef `state`, question instructions that embed
content, or raw messages. Log only ids, counts, latency, status, verdict label.

This module intentionally exposes a small helper surface so callers log
structured, content-free fields. There is no formatter that accepts raw
content — keep it that way.
"""

from __future__ import annotations

import logging

from .config import get_settings

_CONFIGURED = False


def setup_logging() -> None:
    global _CONFIGURED
    if _CONFIGURED:
        return
    level_name = get_settings().log_level.upper()
    level = getattr(logging, level_name, logging.INFO)
    logging.basicConfig(
        level=level,
        format="%(asctime)s %(levelname)s %(name)s %(message)s",
    )
    _CONFIGURED = True


def get_logger(name: str) -> logging.Logger:
    setup_logging()
    return logging.getLogger(name)
