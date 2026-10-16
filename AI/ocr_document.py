"""Run the real OCR engine on a local image and visualize the detected boxes.

Prints each recognized text region (text + confidence + box) to the terminal
and, by default, opens a window drawing every box with a text + confidence
label on top of the image. Pass ``--save out.png`` to also write the overlay to
a file, and ``--no-window`` to skip opening the window (useful on headless
machines or when you only want the saved file).
"""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image

from pii.ocr import OcrEngine


def _box_bounds(box: list[list[float]]) -> tuple[float, float, float, float]:
    """Return (min_x, min_y, max_x, max_y) for a polygon's corner points."""
    xs = [pt[0] for pt in box]
    ys = [pt[1] for pt in box]
    return min(xs), min(ys), max(xs), max(ys)


def _render(image_path: Path, boxes: list[dict], save: Path | None, show: bool) -> None:
    """Draw labelled boxes over the image and show and/or save the result."""
    import matplotlib

    if not show:
        matplotlib.use("Agg")  # non-interactive backend; no display needed

    import matplotlib.pyplot as plt
    from matplotlib.patches import Polygon

    with Image.open(image_path) as img:
        rgb = img.convert("RGB")

    fig, ax = plt.subplots()
    ax.imshow(rgb)
    ax.set_title(f"{image_path.name} - {len(boxes)} region(s)")
    ax.set_axis_off()

    for index, item in enumerate(boxes, start=1):
        box = item["box"]
        if len(box) < 3:
            continue
        polygon = Polygon(
            box,
            closed=True,
            fill=False,
            edgecolor="red",
            linewidth=1.5,
        )
        ax.add_patch(polygon)

        min_x, min_y, _, _ = _box_bounds(box)
        label = f"{index}. {item['text']} ({item['score']:.2f})"
        ax.text(
            min_x,
            min_y - 2,
            label,
            fontsize=8,
            color="white",
            va="bottom",
            ha="left",
            bbox={"facecolor": "red", "alpha": 0.7, "pad": 1, "edgecolor": "none"},
        )

    fig.tight_layout()

    if save is not None:
        fig.savefig(save, dpi=150, bbox_inches="tight")
        print(f"Saved overlay to {save}")

    if show:
        plt.show()
    else:
        plt.close(fig)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Run OCR on a local image and visualize each detected text region."
    )
    parser.add_argument("image", type=Path, help="path to a document image")
    parser.add_argument(
        "--save",
        type=Path,
        default=None,
        help="also write the labelled overlay to this image path",
    )
    parser.add_argument(
        "--no-window",
        action="store_true",
        help="do not open a window (useful on headless machines)",
    )
    args = parser.parse_args()

    if not args.image.is_file():
        parser.error(f"image file not found: {args.image}")

    boxes = OcrEngine().extractImageWithBoundingBox(str(args.image))
    print(f"Detected {len(boxes)} text region(s) in {args.image.name}:")
    for index, item in enumerate(boxes, start=1):
        print(f"\n[{index}] confidence={item['score']:.3f} box={item['box']}")
        print(item["text"])

    if not boxes:
        print("No text was detected above the configured OCR_MIN_SCORE.")

    _render(args.image, boxes, save=args.save, show=not args.no_window)


if __name__ == "__main__":
    main()
