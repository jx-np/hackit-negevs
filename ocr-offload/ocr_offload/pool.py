"""Process pool management for OCR jobs."""

from __future__ import annotations

import multiprocessing
import os
import threading
import traceback
from collections.abc import Callable
from concurrent.futures import Executor, ProcessPoolExecutor, wait
from concurrent.futures.process import BrokenProcessPool
from typing import Any

from .config import Settings
from .engine import EngineOptions
from .logging import get_logger

_engine = None
_logger = get_logger("pool")


class OcrJobError(Exception):
    """A failed OCR job whose detail string carries the worker-side traceback."""

    def __init__(self, detail: str):
        self.detail = detail
        super().__init__(detail)


def _initialize(options: EngineOptions) -> None:
    global _engine
    for name in (
        "OMP_NUM_THREADS",
        "OPENBLAS_NUM_THREADS",
        "MKL_NUM_THREADS",
        "NUMEXPR_NUM_THREADS",
    ):
        os.environ[name] = str(options.cpu_threads)
    # Keep model-download progress bars out of the service log.
    os.environ["TQDM_DISABLE"] = "1"
    os.environ["HF_HUB_DISABLE_PROGRESS_BARS"] = "1"
    from .engine import OcrEngine

    _engine = OcrEngine(options)


def _run(image_bytes: bytes) -> tuple[list[dict], int]:
    try:
        return _engine.extract_with_count(image_bytes)
    except Exception:
        raise OcrJobError(traceback.format_exc()) from None


def _warmup() -> tuple[str, str]:
    try:
        _engine.warmup()
        return _engine.loaded_models()
    except Exception:
        raise OcrJobError(traceback.format_exc()) from None


def _detail(error: BaseException) -> str:
    if isinstance(error, OcrJobError):
        return error.detail
    return f"{type(error).__name__}: {error}"


class OcrPool:
    """A self-healing process pool for OCR jobs."""

    def __init__(
        self,
        settings: Settings,
        executor_factory: Callable[[], Executor] | None = None,
    ) -> None:
        self.workers = settings.effective_workers
        self._options = EngineOptions.from_settings(settings)
        self._lock = threading.RLock()
        if executor_factory is None:
            context = multiprocessing.get_context("spawn")

            def make_executor() -> Executor:
                return ProcessPoolExecutor(
                    max_workers=self.workers,
                    mp_context=context,
                    initializer=_initialize,
                    initargs=(self._options,),
                )

            executor_factory = make_executor
        self._executor_factory = executor_factory
        self.executor = self._executor_factory()

    def _recreate(self) -> None:
        with self._lock:
            old_executor = self.executor
            self.executor = self._executor_factory()
            try:
                old_executor.shutdown(wait=False, cancel_futures=True)
            except (BrokenProcessPool, RuntimeError):
                pass

    def _observe_result(self, future: Any) -> None:
        try:
            error = future.exception()
        except BaseException:
            return
        if isinstance(error, BrokenProcessPool):
            _logger.warning("ocr process pool broken; recreating executor")
            self._recreate()

    def submit(self, image_bytes: bytes) -> Any:
        with self._lock:
            try:
                future = self.executor.submit(_run, image_bytes)
            except BrokenProcessPool:
                _logger.warning("ocr process pool broken; recreating executor")
                self._recreate()
                raise
            future.add_done_callback(self._observe_result)
            return future

    def warmup(self) -> tuple[int, list[str], tuple[str, str] | None]:
        """Load the model in every worker, probing one worker first.

        The probe surfaces a broken model or missing dependency without
        spawning the whole pool, and warms the shared model cache before the
        remaining workers start loading at once.
        """
        errors: list[str] = []
        succeeded = 0
        first_result = None
        try:
            remaining = self.workers
            while remaining > 0:
                batch = 1 if succeeded == 0 else remaining
                futures = [self.executor.submit(_warmup) for _ in range(batch)]
                done, not_done = wait(futures, timeout=600)
                for future in done:
                    error = future.exception()
                    if error is not None:
                        errors.append(_detail(error))
                    else:
                        succeeded += 1
                        if first_result is None:
                            first_result = future.result()
                if not_done:
                    errors.append(f"warmup timed out workers={len(not_done)}")
                remaining -= batch
                if succeeded == 0:
                    break
        except Exception as error:
            errors.append(_detail(error))
        return succeeded, errors, first_result

    def shutdown(self) -> None:
        with self._lock:
            self.executor.shutdown(wait=False, cancel_futures=True)


def create_pool(settings: Settings) -> OcrPool:
    """Create the service OCR pool."""
    return OcrPool(settings)
