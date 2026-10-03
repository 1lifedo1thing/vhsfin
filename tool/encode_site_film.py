"""Cut screenshots/raw/film.mov (tool/site_film.sh) into the landing-page videos.

Writes site/vhsfin/media/intro.mp4 (tape into the deck, title card, picture up),
loop.mp4 (the movie playing), and poster.webp (intro's first frame). The TV and
shelf are cropped from the 1320x2868 capture and their edges melt into black.

Needs ffmpeg and Pillow. Adjust the cut points if you re-record the film.
"""

from __future__ import annotations

import subprocess
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
FILM = ROOT / "screenshots" / "raw" / "film.mov"
OUT = ROOT / "site" / "vhsfin" / "media"

CROP = (1320, 2065, 0, 400)  # w, h, x, y on the capture: TV top to shelf bottom
SIZE = (800, 1252)           # output, same aspect
INTRO = (37.80, 5.55)        # start, duration: tape flight, title card, picture
LOOP = (54.75, 12.0)         # the meadow, then the bird


def edge_mask(path: Path) -> None:
    """Black frame, transparent middle, soft edges: overlaid on every frame."""
    w, h = SIZE
    inset = round(w * 0.025)
    hole = Image.new("L", SIZE, 0)
    ImageDraw.Draw(hole).rounded_rectangle((inset, inset, w - inset, h - inset), inset * 2, fill=255)
    alpha = hole.filter(ImageFilter.GaussianBlur(inset)).point(lambda v: 255 - v)
    frame = Image.new("RGBA", SIZE, (0, 0, 0, 255))
    frame.putalpha(alpha)
    frame.save(path)


def encode(start: float, duration: float, mask: Path, out: Path) -> None:
    w, h, x, y = CROP
    graph = (
        f"[0:v]fps=30,crop={w}:{h}:{x}:{y},scale={SIZE[0]}:{SIZE[1]}:flags=lanczos,"
        # The app's near-black room becomes true black, so no box shows on the page.
        "colorlevels=rimin=0.055:gimin=0.055:bimin=0.055[v];"
        "[v][1:v]overlay=0:0,format=yuv420p"
    )
    subprocess.run([
        "ffmpeg", "-loglevel", "error", "-y", "-ss", str(start), "-t", str(duration),
        "-i", str(FILM), "-i", str(mask), "-filter_complex", graph, "-an",
        "-c:v", "libx264", "-preset", "slow", "-crf", "24", "-profile:v", "high",
        "-movflags", "+faststart", str(out),
    ], check=True)


def main() -> None:
    if not FILM.is_file():
        raise SystemExit(f"Record the film first: tool/site_film.sh ({FILM} missing)")
    OUT.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        mask = Path(tmp) / "mask.png"
        edge_mask(mask)
        encode(*INTRO, mask, OUT / "intro.mp4")
        encode(*LOOP, mask, OUT / "loop.mp4")
        frame = Path(tmp) / "poster.png"
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", str(OUT / "intro.mp4"),
                        "-frames:v", "1", str(frame)], check=True)
        Image.open(frame).save(OUT / "poster.webp", quality=88, method=6)
    for f in sorted(OUT.iterdir()):
        print(f"{f.stat().st_size / 1e6:5.2f} MB  {f.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
