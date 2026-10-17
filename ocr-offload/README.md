# OCR Offload

Standalone CPU PaddleOCR HTTP service. On Linux, create/activate a Python 3.12 environment, then install everything into **that same interpreter**.

```bash
# 1. PaddlePaddle CPU wheel comes from its own index. Use `python -m pip` so the
#    module is installed for the interpreter you will actually run.
python -m pip install "paddlepaddle==3.3.0" -i https://www.paddlepaddle.org.cn/packages/stable/cpu/

# 2. Verify before continuing - PaddleX refuses to load any model without it.
python -c "import paddle; print(paddle.__version__)"

# 3. Then the service requirements.
python -m pip install -r requirements.txt

# 4. Run.
python -m ocr_offload.main
```

Step 2 matters: `paddleocr` and `paddlex` install cleanly on their own, so a missing `paddlepaddle` shows up only when a model is loaded, as `RuntimeError: Engine 'paddle_static' is unavailable because dependency 'paddlepaddle' is not installed.` (PaddleX tests this with `importlib.util.find_spec("paddle")`.) Installing into a different interpreter than the one running the service produces the same symptom.

Set `OCR_HTTP_ADDR`, `OCR_MODEL`, `OCR_MIN_SCORE`, `OCR_WORKERS`, `OCR_CPU_THREADS`, `OCR_MAX_QUEUE`, `OCR_API_KEY`, `OCR_MAX_IMAGE_BYTES`, `OCR_ENGINE`, `OCR_ONNX_DET_DIR`, `OCR_ONNX_REC_DIR`, `OCR_ONNX_MODEL_ROOT`, `OCR_ORT_INTRA_OP_THREADS`, `OCR_ORT_INTER_OP_THREADS`, `OCR_REC_BATCH_SIZE`, and `LOG_LEVEL` as needed; `.env` is also loaded and real environment variables win. Workers default to CPU count divided by threads per worker.

By default, startup loads the model in every worker and logs the resolved detection and recognition model names. A load or import failure is logged in full at startup, and `/healthz` reports `status: degraded` with an `error`; set `OCR_WARMUP=false` to skip startup loading. Request failures log the worker-side traceback while keeping response details opaque.

## Model names

`OCR_MODEL` accepts a tier name (`PP-OCRv6_tiny`, `PP-OCRv6_small`, `PP-OCRv6_medium`), which selects both halves of the pipeline, or one specific model:

- `_det` is **text detection**: it finds where text is, returning the bounding boxes.
- `_rec` is **text recognition**: it reads the characters inside each detected box.

The service sets PaddleOCR's `text_detection_model_name` and `text_recognition_model_name` from this, so a tier name such as `PP-OCRv6_medium` expands to `PP-OCRv6_medium_det` plus `PP-OCRv6_medium_rec`. A `_det` or `_rec` name on its own leaves PaddleOCR's default for the other half. The startup log reports the resolved pair as `det=... rec=...`.

## Faster CPU inference (ONNX Runtime)

PaddleOCR 3.5+ can run this same pipeline on ONNX Runtime. PaddlePaddle publishes ready-converted PP-OCRv6 tiny, small, and medium detection and recognition models, and its official PP-OCRv6 demo runs this way on CPU. Paddle remains the default when `OCR_ENGINE` is empty; `paddlepaddle` stays installed either way. PaddleOCR's “Inference Engine and Configuration” documentation lists the ONNX Runtime engine.

Install ONNX Runtime's CPU build into the **same interpreter** that runs the service:

```bash
python -m pip install onnxruntime
# On the pilot server:
/root/.pyenv/versions/ocr/bin/python -m pip install onnxruntime
```

Fetch an official model pair (the script skips halves whose `inference.onnx` already exists):

```bash
python scripts/fetch_onnx_models.py --models PP-OCRv6_medium --root /root/pyenv/ocr/models_onnx
```

Enable it and restart the service:

```bash
OCR_ENGINE=onnxruntime
OCR_ONNX_MODEL_ROOT=/root/pyenv/ocr/models_onnx
```

Alternatively set `OCR_ONNX_DET_DIR` and `OCR_ONNX_REC_DIR` explicitly. Each model directory must contain `inference.onnx` (PaddleX also reads `inference.yml`). `OCR_ORT_INTRA_OP_THREADS` defaults to `OCR_CPU_THREADS`; `OCR_ORT_INTER_OP_THREADS` defaults to ONNX Runtime's own default. ONNX Runtime ignores Paddle's `OCR_CPU_THREADS`-style options, so use the `OCR_ORT_*` keys for threads. `OCR_REC_BATCH_SIZE` optionally controls recognition batch size; the official demo uses 6 (one recognition pass for all text lines of an image), but measure before adopting it. Startup logs and `/healthz` report the active engine. Missing `inference.onnx` fails warmup loudly; `/healthz` reports `status: degraded` with the error.

Measure locally, without HTTP or the service worker pool:

```bash
python scripts/bench_ocr.py --images ./samples --mode paddle,onnxruntime --runs 5
```

For a deployment comparison, use the same images, `OCR_WORKERS`, and `OCR_CPU_THREADS`. Each worker process holds its own copy of both models in RAM, so real throughput also depends on worker count and threads.

For a model without a published ONNX build, convert both halves (repeat for recognition):

```bash
paddlex --install paddle2onnx
paddlex --paddle2onnx --paddle_model_dir ~/.paddlex/official_models/PP-OCRv6_medium_det --onnx_model_dir <root>/PP-OCRv6_medium_det_onnx --opset_version 7
```

The output directory must contain `inference.onnx` and `inference.yml`; PaddleX also keeps a `.cache` directory under the model directory. The older `enable_hpi` / `paddlex --install hpi-cpu` route uses OpenVINO and ONNX Runtime backends through the ultra-infer plugin; it is an alternative the official PP-OCRv6 demo does not use and is incompatible with an explicit `engine`.

## System dependencies (headless Linux)

PaddleX imports `cv2`, and the `opencv-python` distribution it installs is the non-headless build that links against `libGL.so.1`. On a server without graphics libraries, every OCR call fails at import with:

```text
ImportError: libGL.so.1: cannot open shared object file: No such file or directory
```

Install the runtime libraries before starting the service:

```bash
# Debian / Ubuntu
sudo apt-get update && sudo apt-get install -y libgl1 libglib2.0-0
# RHEL / Fedora / Amazon Linux
sudo dnf install -y mesa-libGL glib2
```

Alternatively, avoid the system packages by replacing the OpenCV wheel with the headless build:

```bash
python -m pip uninstall -y opencv-python opencv-contrib-python
python -m pip install opencv-python-headless
python -c "import cv2; print(cv2.__file__)"   # confirm it points at the headless build
```

If a later `pip install` reinstalls a non-headless OpenCV distribution as a dependency, prefer the system-library route above.

Point the AI service at this service with `OCR_SERVICE_URL` (for example `http://ocr-host:8098`). Set `OCR_API_KEY` and configure callers to send `Authorization: Bearer <key>`. Keep this service on a trusted private network and use authentication; health checks are intentionally open. Never expose it publicly without network controls.
