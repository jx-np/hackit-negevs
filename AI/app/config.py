"""Environment-driven configuration with safe dev defaults.

Real environment variables (and an optional `.env` in the working directory)
win over the defaults here. Mirrors the keys documented in PLAN.md §8 and
`.env.example`.
"""

from __future__ import annotations

from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    # Server bind address (host:port or :port).
    ai_http_addr: str = ":8099"

    # clef-flash via SGLang. Call the SGLang server directly, not a gateway.
    clef_base_url: str = "http://localhost:30000"
    clef_model: str = "Cloudflare/clef-flash"
    clef_timeout_seconds: float = 30.0

    # OCR (CPU). PaddleOCR 3.x text-recognition model name (note the _rec
    # suffix; the bare tier name like "PP-OCRv6_small" has no engine binding).
    ocr_model: str = "PP-OCRv6_small_rec"
    ocr_min_score: float = 0.5

    # Decision thresholds.
    pii_threshold: float = 0.5
    signal_threshold: float = 0.5
    verdict_low: float = 0.67
    verdict_high: float = 1.34

    log_level: str = "info"

    @property
    def bind_host(self) -> str:
        host, _, _ = self.ai_http_addr.rpartition(":")
        return host or "0.0.0.0"

    @property
    def bind_port(self) -> int:
        _, _, port = self.ai_http_addr.rpartition(":")
        return int(port) if port else 8099


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()
