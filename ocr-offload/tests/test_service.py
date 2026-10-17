import io
import os
import sys
import types

import pytest
from concurrent.futures import Future
from concurrent.futures.process import BrokenProcessPool

from fastapi.testclient import TestClient
from PIL import Image

from ocr_offload import main
from ocr_offload.config import Settings
from ocr_offload.engine import EngineOptions, OcrEngine, resolve_onnx_dirs
from ocr_offload.pool import OcrJobError, OcrPool


class StubPool:
    workers = 2

    def submit(self, _data):
        future = Future()
        future.set_result(
            (
                [
                    {
                        "box": [[0, 0], [1, 0], [1, 1], [0, 1]],
                        "text": "private",
                        "score": 0.9,
                    }
                ],
                1,
            )
        )
        return future

    def shutdown(self):
        pass

    def warmup(self):
        return 2, [], ("det", "rec")


def image_bytes():
    stream = io.BytesIO()
    Image.new("RGB", (4, 4)).save(stream, format="PNG")
    return stream.getvalue()


def client(monkeypatch):
    monkeypatch.setattr(
        main,
        "settings",
        main.settings.model_copy(update={"api_key": "", "max_image_bytes": 1024}),
    )
    monkeypatch.setattr(main, "create_pool", lambda _settings: StubPool())
    return TestClient(main.app)


def test_pool_recovers_after_broken_process(monkeypatch):
    class FakeExecutor:
        def __init__(self, broken=False):
            self.broken = broken
            self.closed = False

        def submit(self, _fn, _data):
            if self.broken:
                future = Future()
                future.set_exception(BrokenProcessPool("worker died"))
                return future
            future = Future()
            future.set_result(([], 0))
            return future

        def shutdown(self, **_kwargs):
            self.closed = True

    executors = iter([FakeExecutor(broken=True), FakeExecutor()])
    pool = OcrPool(Settings(workers=1), executor_factory=lambda: next(executors))
    first = pool.submit(b"image")
    try:
        first.result()
    except BrokenProcessPool:
        pass
    assert pool.submit(b"image").result() == ([], 0)
    pool.shutdown()


def test_busy_queue_returns_503(monkeypatch):
    monkeypatch.setattr(
        main,
        "settings",
        main.settings.model_copy(update={"api_key": "", "max_queue": 1}),
    )
    monkeypatch.setattr(main, "create_pool", lambda _settings: StubPool())
    with TestClient(main.app) as c:
        main.app.state.in_flight = 1
        response = c.post(
            "/v1/ocr", files={"image": ("test.png", image_bytes(), "image/png")}
        )
        assert response.status_code == 503


def test_api_key_required(monkeypatch):
    monkeypatch.setattr(
        main,
        "settings",
        main.settings.model_copy(update={"api_key": "secret", "max_image_bytes": 1024}),
    )
    monkeypatch.setattr(main, "create_pool", lambda _settings: StubPool())
    with TestClient(main.app) as c:
        files = {"image": ("test.png", image_bytes(), "image/png")}
        assert c.post("/v1/ocr", files=files).status_code == 401
        assert (
            c.post(
                "/v1/ocr", files=files, headers={"Authorization": "Bearer wrong"}
            ).status_code
            == 401
        )
        assert (
            c.post(
                "/v1/ocr", files=files, headers={"Authorization": "Bearer secret"}
            ).status_code
            == 200
        )


def test_http_ocr_and_health(monkeypatch):
    with client(monkeypatch) as c:
        assert c.get("/healthz").json() == {
            "status": "ok",
            "workers": 2,
            "ready": True,
            "engine": "paddle",
        }
        response = c.post(
            "/v1/ocr", files={"image": ("test.png", image_bytes(), "image/png")}
        )
        assert response.status_code == 200
        assert response.json()["total_box_count"] == 1
        assert response.json()["boxes"][0]["text"] == "private"


def test_input_validation(monkeypatch):
    with client(monkeypatch) as c:
        assert (
            c.post("/v1/ocr", files={"image": ("x.txt", b"x", "text/plain")}).json()[
                "detail"
            ]
            == "unsupported image media type"
        )
        assert (
            c.post("/v1/ocr", files={"image": ("x.png", b"bad", "image/png")}).json()[
                "detail"
            ]
            == "invalid image"
        )


def test_engine_count_and_min_score():
    class FakeOCR:
        def predict(self, _array):
            return [
                {
                    "rec_texts": ["hi", "low"],
                    "rec_scores": [0.9, 0.1],
                    "rec_polys": [
                        [[0, 0], [1, 0], [1, 1], [0, 1]],
                        [[2, 2], [3, 2], [3, 3], [2, 3]],
                    ],
                }
            ]

    engine = OcrEngine(min_score=0.5)
    engine._ocr = FakeOCR()
    kept, total = engine.extract_with_count(image_bytes())
    assert len(kept) == 1 and total == 2


def test_resolve_ocr_models():
    from ocr_offload.engine import resolve_ocr_models

    assert resolve_ocr_models("PP-OCRv6_medium") == (
        "PP-OCRv6_medium_det",
        "PP-OCRv6_medium_rec",
    )
    assert resolve_ocr_models("PP-OCRv6_small_rec") == (None, "PP-OCRv6_small_rec")
    assert resolve_ocr_models("PP-OCRv6_medium_det") == ("PP-OCRv6_medium_det", None)
    assert resolve_ocr_models("  ") == (None, None)


def test_resolve_onnx_dirs(tmp_path):
    options = EngineOptions(
        "PP-OCRv6_medium", 0.5, 4, onnx_det_dir="det", onnx_model_root="root"
    )
    assert resolve_onnx_dirs(options) == (
        "det",
        os.path.join("root", "PP-OCRv6_medium_rec_onnx"),
    )
    resolved = resolve_onnx_dirs(
        EngineOptions("PP-OCRv6_medium", 0.5, 4, onnx_model_root="/models")
    )
    assert resolved == (
        os.path.join("/models", "PP-OCRv6_medium_det_onnx"),
        os.path.join("/models", "PP-OCRv6_medium_rec_onnx"),
    )
    assert resolve_onnx_dirs(
        EngineOptions("PP-OCRv6_medium_rec", 0.5, 4, onnx_model_root="/models")
    ) == (
        None,
        os.path.join("/models", "PP-OCRv6_medium_rec_onnx"),
    )
    assert resolve_onnx_dirs(EngineOptions("x", 0.5, 4)) == (None, None)


def test_engine_options_from_settings():
    settings = Settings(
        engine="onnxruntime",
        onnx_det_dir="det",
        onnx_rec_dir="rec",
        onnx_model_root="root",
        ort_intra_op_threads=3,
        ort_inter_op_threads=2,
        rec_batch_size=6,
    )
    options = EngineOptions.from_settings(settings)
    assert options.engine == "onnxruntime"
    assert (options.onnx_det_dir, options.onnx_rec_dir, options.onnx_model_root) == (
        "det",
        "rec",
        "root",
    )
    assert (
        options.ort_intra_op_threads,
        options.ort_inter_op_threads,
        options.rec_batch_size,
    ) == (3, 2, 6)


def test_onnx_engine_kwargs(tmp_path, monkeypatch):
    captured = {}

    class FakeOCR:
        def predict(self, _array):
            pass

        def __init__(self, **kwargs):
            captured.update(kwargs)

    monkeypatch.setitem(
        sys.modules, "paddleocr", types.SimpleNamespace(PaddleOCR=FakeOCR)
    )
    det, rec = tmp_path / "det", tmp_path / "rec"
    det.mkdir()
    rec.mkdir()
    (det / "inference.onnx").touch()
    (rec / "inference.onnx").touch()
    engine = OcrEngine(
        EngineOptions(
            "PP-OCRv6_medium",
            0.5,
            4,
            engine="onnxruntime",
            onnx_det_dir=str(det),
            onnx_rec_dir=str(rec),
            rec_batch_size=6,
        )
    )
    engine.warmup()
    assert captured["engine"] == "onnxruntime"
    assert captured["engine_config"]["intra_op_num_threads"] == 4
    assert captured["text_detection_model_name"] == "PP-OCRv6_medium_det"
    assert captured["text_recognition_model_name"] == "PP-OCRv6_medium_rec"
    assert captured["text_detection_model_dir"] == str(det)
    assert captured["text_recognition_model_dir"] == str(rec)
    assert captured["device"] == "cpu"
    assert captured["text_recognition_batch_size"] == 6
    assert "enable_mkldnn" not in captured and "cpu_threads" not in captured


def test_onnx_engine_missing_model_fails(tmp_path, monkeypatch):
    class FakeOCR:
        def predict(self, _array):
            pass

    monkeypatch.setitem(
        sys.modules, "paddleocr", types.SimpleNamespace(PaddleOCR=FakeOCR)
    )
    with pytest.raises(ValueError, match="inference.onnx"):
        OcrEngine(
            EngineOptions(
                "PP-OCRv6_medium",
                0.5,
                4,
                engine="onnxruntime",
                onnx_det_dir=str(tmp_path),
                onnx_rec_dir=str(tmp_path),
            )
        ).warmup()


def test_engine_models_unknown_before_load():
    assert OcrEngine(min_score=0.5).loaded_models() == ("unknown", "unknown")


def test_ocr_job_error_is_opaque(monkeypatch):
    class FailingPool(StubPool):
        def submit(self, _data):
            future = Future()
            future.set_exception(
                OcrJobError("Traceback ...\nModuleNotFoundError: No module named 'x'")
            )
            return future

    monkeypatch.setattr(
        main, "settings", main.settings.model_copy(update={"warmup": True})
    )
    monkeypatch.setattr(main, "create_pool", lambda _settings: FailingPool())
    main.app.state.pool = None
    with TestClient(main.app) as c:
        response = c.post(
            "/v1/ocr", files={"image": ("test.png", image_bytes(), "image/png")}
        )
        assert response.status_code == 500
        assert response.json() == {"detail": "ocr failed"}


def test_warmup_failure_health(monkeypatch):
    class FailedWarmupPool(StubPool):
        def warmup(self):
            return 0, ["Traceback ... ImportError: boom"], None

    monkeypatch.setattr(
        main, "settings", main.settings.model_copy(update={"warmup": True})
    )
    monkeypatch.setattr(main, "create_pool", lambda _settings: FailedWarmupPool())
    main.app.state.pool = None
    with TestClient(main.app) as c:
        health = c.get("/healthz").json()
        assert health["status"] == "degraded"
        assert health["ready"] is False
        assert "ImportError: boom" in health["error"]


def test_warmup_stops_after_first_worker_fails():
    calls = []

    class FakeExecutor:
        def submit(self, _fn):
            calls.append(1)
            future = Future()
            future.set_exception(OcrJobError("Traceback ... ImportError: boom"))
            return future

        def shutdown(self, **_kwargs):
            pass

    pool = OcrPool(Settings(workers=4), executor_factory=FakeExecutor)
    succeeded, errors, models = pool.warmup()
    assert (succeeded, models) == (0, None)
    assert len(calls) == 1
    assert "ImportError: boom" in errors[0]


def test_warmup_loads_every_worker_after_probe():
    calls = []

    class FakeExecutor:
        def submit(self, _fn):
            calls.append(1)
            future = Future()
            future.set_result((["det", "rec"], 0))
            return future

        def shutdown(self, **_kwargs):
            pass

    pool = OcrPool(Settings(workers=4), executor_factory=FakeExecutor)
    succeeded, errors, models = pool.warmup()
    assert (succeeded, errors) == (4, [])
    assert len(calls) == 4
