"""Fetch officially published PaddlePaddle PP-OCRv6 ONNX model files."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--models", nargs="+", required=True, help="Model tier(s) or _det/_rec names"
    )
    parser.add_argument(
        "--root", required=True, type=Path, help="Destination root directory"
    )
    parser.add_argument("--revision", help="Optional Hugging Face revision")
    parser.add_argument("--dry-run", action="store_true", help="Show planned downloads")
    args = parser.parse_args()

    from ocr_offload.engine import resolve_ocr_models

    names: list[str] = []
    for model in args.models:
        det, rec = resolve_ocr_models(model)
        names.extend(name for name in (det, rec) if name and name not in names)

    if not args.dry_run:
        try:
            from huggingface_hub import snapshot_download
        except ImportError:
            print(
                "huggingface_hub is required; install it with: python -m pip install huggingface_hub",
                file=sys.stderr,
            )
            return 1

    for name in names:
        repo = f"PaddlePaddle/{name}_onnx"
        target = args.root / f"{name}_onnx"
        if (target / "inference.onnx").is_file():
            status = "skipped (inference.onnx exists)"
        elif args.dry_run:
            status = "dry-run"
        else:
            snapshot_download(
                repo_id=repo,
                repo_type="model",
                local_dir=str(target),
                revision=args.revision,
            )
            status = "downloaded"
        print(f"{repo} -> {target}: {status}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
