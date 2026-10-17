"""Configuration for the OCR service."""

from __future__ import annotations

import os
from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """OCR service settings loaded from environment variables."""

    model_config = SettingsConfigDict(
        env_prefix="OCR_",
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    http_addr: str = ":8098"
    model: str = "PP-OCRv6_small_rec"
    min_score: float = 0.5
    workers: int = 0
    cpu_threads: int = 4
    max_queue: int = 64
    api_key: str = ""
    max_image_bytes: int = 10485760
    log_level: str = "info"
    warmup: bool = True
    engine: str = ""
    onnx_det_dir: str = ""
    onnx_rec_dir: str = ""
    onnx_model_root: str = ""
    ort_intra_op_threads: int = 0
    ort_inter_op_threads: int = 0
    rec_batch_size: int = 0

    @property
    def bind_host(self) -> str:
        """Return the host portion of the HTTP address."""
        host, _, _ = self.http_addr.rpartition(":")
        return host or "0.0.0.0"

    @property
    def bind_port(self) -> int:
        """Return the port portion of the HTTP address."""
        _, _, port = self.http_addr.rpartition(":")
        return int(port) if port else 8098

    @property
    def effective_workers(self) -> int:
        """Return the configured worker count or a CPU-based default."""
        if self.workers > 0:
            return self.workers
        return max(1, (os.cpu_count() or 1) // max(1, self.cpu_threads))

    @property
    def effective_engine(self) -> str:
        return self.engine.strip().lower() or "paddle"


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    """Load and cache service settings."""
    return Settings()
