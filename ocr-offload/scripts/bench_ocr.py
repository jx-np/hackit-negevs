"""Benchmark local OCR latency without HTTP or the worker pool.

One process holds one copy of both models; real throughput also depends on
worker count and threads.
"""

from __future__ import annotations

import argparse
import glob
import statistics
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))


def _images(inputs: list[str]) -> list[Path]:
    result: list[Path] = []
    for item in inputs:
        matches = [Path(path) for path in glob.glob(item)] or [Path(item)]
        for path in matches:
            if path.is_dir():
                result.extend(sorted(p for p in path.iterdir() if p.is_file()))
            elif path.is_file():
                result.append(path)
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--images", nargs="+", required=True, help="Image paths, directories, or globs"
    )
    parser.add_argument("--model", help="Model name (defaults to OCR_MODEL)")
    parser.add_argument(
        "--mode",
        default="paddle,onnxruntime",
        help="Comma-separated paddle and/or onnxruntime",
    )
    parser.add_argument("--runs", type=int, default=3)
    parser.add_argument("--warmup", type=int, default=1)
    parser.add_argument("--onnx-root", type=Path)
    parser.add_argument("--threads", type=int)
    parser.add_argument("--rec-batch-size", type=int)
    args = parser.parse_args()

    from ocr_offload.config import get_settings
    from ocr_offload.engine import EngineOptions, OcrEngine

    settings = get_settings()
    images = _images(args.images)
    if not images:
        parser.error("no image files found")
    failed = False
    for mode in (part.strip() for part in args.mode.split(",")):
        if mode not in {"paddle", "onnxruntime"}:
            print(f"{mode}: SKIPPED/FAILED: unknown mode")
            failed = True
            continue
        options = EngineOptions.from_settings(settings)
        options = EngineOptions(
            model=args.model or options.model,
            min_score=options.min_score,
            cpu_threads=args.threads
            if args.threads is not None
            else options.cpu_threads,
            engine=mode,
            onnx_det_dir=options.onnx_det_dir,
            onnx_rec_dir=options.onnx_rec_dir,
            onnx_model_root=str(args.onnx_root)
            if args.onnx_root
            else options.onnx_model_root,
            ort_intra_op_threads=options.ort_intra_op_threads,
            ort_inter_op_threads=options.ort_inter_op_threads,
            rec_batch_size=args.rec_batch_size
            if args.rec_batch_size is not None
            else options.rec_batch_size,
        )
        try:
            engine = OcrEngine(options)
            engine.warmup()
            det, rec = engine.loaded_models()
            print(
                f"mode={mode} engine={engine.engine_label()} det={det} rec={rec} python={sys.executable}"
            )
            if mode == "onnxruntime":
                import onnxruntime as ort

                print(
                    f"onnxruntime={ort.__version__} providers={ort.get_available_providers()}"
                )
            timings: list[float] = []
            total_boxes = 0
            for image in images:
                for iteration in range(args.warmup + args.runs):
                    started = time.perf_counter()
                    boxes, _ = engine.extract_with_count(str(image))
                    elapsed = (time.perf_counter() - started) * 1000
                    if iteration >= args.warmup:
                        timings.append(elapsed)
                        total_boxes += len(boxes)
                        print(f"{image}: {elapsed:.2f} ms boxes={len(boxes)}")
            ordered = sorted(timings)
            p50 = statistics.median(ordered)
            print(
                f"{mode}: min={min(ordered):.2f} mean={statistics.mean(ordered):.2f} p50={p50:.2f} max={max(ordered):.2f} ms images={len(images)} boxes={total_boxes}"
            )
        except Exception as exc:
            print(f"{mode}: SKIPPED/FAILED: {exc}")
            failed = True
    return int(failed)


if __name__ == "__main__":
    raise SystemExit(main())
