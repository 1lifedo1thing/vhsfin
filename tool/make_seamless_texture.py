#!/usr/bin/env python3
"""Make a photo texture tile without seams (used for assets/branding/walnut.jpg).

Each axis is cross-faded with a copy of itself shifted by half the tile, so the
left/right and top/bottom edges meet the same pixels when Flutter repeats it.

Needs Pillow and numpy:  pip install pillow numpy
Usage: python3 tool/make_seamless_texture.py SRC.jpg OUT.jpg
"""
import sys

import numpy as np
from PIL import Image


def _ramp(n: int, feather: float) -> np.ndarray:
    """0 at both edges, 1 across the middle, smoothstep in between."""
    d = np.minimum(np.arange(n), n - 1 - np.arange(n)) / (n * feather)
    d = np.clip(d, 0, 1)
    return d * d * (3 - 2 * d)


def seamless(a: np.ndarray, feather: float = 0.22) -> np.ndarray:
    h, w, _ = a.shape
    shifted = np.roll(a, w // 2, axis=1)
    m = _ramp(w, feather)[None, :, None]
    a = a * m + shifted * (1 - m)
    shifted = np.roll(a, h // 2, axis=0)
    m = _ramp(h, feather)[:, None, None]
    return a * m + shifted * (1 - m)


def main() -> None:
    src, out = sys.argv[1], sys.argv[2]
    a = np.asarray(Image.open(src).convert('RGB'), dtype=np.float32)
    tile = np.clip(seamless(a), 0, 255).astype(np.uint8)
    Image.fromarray(tile).save(out, quality=88, optimize=True, progressive=True)


if __name__ == '__main__':
    main()
