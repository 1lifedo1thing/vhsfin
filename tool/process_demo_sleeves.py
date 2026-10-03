"""Turn generated demo-shelf sleeves into app assets.

Input:  a folder of <slug>-front.png and <slug>-spine.png (1024x1536 each; the
        spine stands on a flat #808080 background).
Output: assets/demo_sleeves/<slug>-front.webp and <slug>-spine.webp

Usage:  python3 tool/process_demo_sleeves.py <folder>   (needs Pillow)
"""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "demo_sleeves"
SLUGS = ["bbb", "elephants", "sintel", "tears", "cosmos", "caminandes", "spring"]
HEIGHT = 1080  # ~3x the inspect sheet's cover height


def crop_spine(image: Image.Image) -> Image.Image:
    """Cut the spine strip out of its flat grey backdrop."""
    rgb = image.convert("RGB")
    grey = Image.new("RGB", rgb.size, (128, 128, 128))
    diff = ImageChops.difference(rgb, grey).convert("L").point(lambda v: 255 if v > 22 else 0)
    box = diff.getbbox()
    if box is None:
        raise SystemExit("No spine found against the grey background")
    left, top, right, bottom = box
    inset = 3  # drop the antialiased fringe
    return rgb.crop((left + inset, top + inset, right - inset, bottom - inset))


def fit_height(image: Image.Image, height: int = HEIGHT) -> Image.Image:
    return image.resize((round(image.width * height / image.height), height), Image.LANCZOS)


def main() -> None:
    source = Path(sys.argv[1]) if len(sys.argv) > 1 else None
    if source is None or not source.is_dir():
        raise SystemExit(__doc__)
    OUT.mkdir(parents=True, exist_ok=True)
    for slug in SLUGS:
        front, spine = source / f"{slug}-front.png", source / f"{slug}-spine.png"
        if not (front.is_file() and spine.is_file()):
            print(f"skip {slug}: missing source")
            continue
        fit_height(Image.open(front).convert("RGB")).save(OUT / f"{slug}-front.webp", quality=84, method=6)
        strip = crop_spine(Image.open(spine))
        fit_height(strip).save(OUT / f"{slug}-spine.webp", quality=86, method=6)
        print(f"{slug}: spine {strip.width}x{strip.height} (1:{strip.height / strip.width:.1f})")


if __name__ == "__main__":
    main()
