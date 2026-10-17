"""Pydantic request/response models.

These mirror the Go `checks.Assessment` contract (snake_case) so the Go side can
persist the classification result 1:1. Do not rename fields or change allowed
values without coordinating — they map onto Go constants and DB CHECK
constraints.
"""

from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, Field

Verdict = Literal["suspicious", "unclear", "likely_safe"]
Urgency = Literal["normal", "urgent"]
SignalCode = Literal[
    "urgency",
    "credential_request",
    "money_request",
    "suspicious_link",
    "prize_lottery",
    "authority_impersonation",
]


# --- Classification -------------------------------------------------------


class ClassifyRequest(BaseModel):
    text: str
    locale: str = "en-SG"


class Signal(BaseModel):
    code: SignalCode
    evidence_excerpt: str
    explanation: str


class RecommendedAction(BaseModel):
    scenario: str
    title: str
    urgency: Urgency


class Assessment(BaseModel):
    verdict: Verdict
    signals: list[Signal]
    uncertainty: str
    limitations: str
    recommended_actions: list[RecommendedAction]
    suggested_tags: list[str]


# --- Per-tag scoring ------------------------------------------------------
# Standalone aid beside /v1/classify: ONE choice question over the canonical
# tags. Tag slugs are the keys of `classify.tags.TAGS` (kept in sync with
# backend/seed.sql). `scores` is empty only in the degraded (clef-down) case,
# which is flagged by the top-level `degraded` boolean.


class ClassifyTagsRequest(BaseModel):
    text: str
    locale: str = "en-SG"


class ClassifyTagsResponse(BaseModel):
    # Highest-probability tag, or "" in the degraded case.
    best_tag: str
    # Probability per canonical tag slug (sums to 1), empty when degraded.
    scores: dict[str, float]
    confidence: float
    degraded: bool = False


# --- Category scoring -----------------------------------------------------
# Used by the Go post classifier to assign a published post's scam category
# (categories.slug) before it becomes publicly visible. Separate taxonomy from
# the tags above; keys come from `classify.category.CATEGORIES`, kept in sync
# with backend/seed.sql.


class ClassifyCategoryRequest(BaseModel):
    text: str
    locale: str = "en-SG"


class ClassifyCategoryResponse(BaseModel):
    # Highest-probability category slug, or "" in the degraded case.
    category: str
    # Probability per canonical category slug (sums to 1), empty when degraded.
    scores: dict[str, float]
    confidence: float
    degraded: bool = False


# --- PII redaction --------------------------------------------------------


class RedactRequest(BaseModel):
    image_base64: str
    media_type: Literal["image/jpeg", "image/png", "image/webp"]
    locale: str | None = Field(default=None)


class RedactResponse(BaseModel):
    redacted_image_base64: str
    media_type: str
    extracted_text: str
    pii_box_count: int
    total_box_count: int


class RedactResult(BaseModel):
    """Field names required by the Go `pii.Client` (CONTRACT.md).

    This is the wire shape for the `POST /v1/redact` multipart adapter. Field
    names deliberately differ from `RedactResponse` to match what the Go side
    decodes into `pii.Result`:
      extracted_text   -> redacted_text   (PII already replaced with [redacted])
      censored image   -> image_base64    (standard base64, non-empty)
      media_type       -> image_media_type
      pii_box_count    -> regions_redacted
    `total_box_count` has no Go equivalent and is intentionally dropped.
    """

    redacted_text: str
    image_base64: str
    image_media_type: str
    regions_redacted: int
