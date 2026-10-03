"""Cut screenshots/raw/film.mov (tool/site_film.sh) into the landing-page videos.

Writes site/vhsfin/media/intro.mp4 (tape into the deck, title card, picture up),
loop.mp4 (the movie playing), and poster.webp (intro's first frame). The TV and
shelf are cropped from the 1320x2868 capture and their edges melt into black.

Needs ffmpeg and Pillow. The intro starts on the first frame after the tape
sheet has slid off screen, found automatically; the loop follows at a fixed
offset into the movie.
"""

from __future__ import annotations

import io
import subprocess
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
FILM = ROOT / "screenshots" / "raw" / "film.mov"
OUT = ROOT / "site" / "vhsfin" / "media"

CROP = (1320, 2065, 0, 400)  # w, h, x, y on the capture: TV top to shelf bottom
SIZE = (800, 1252)           # output, same aspect
INTRO_LENGTH = 5.55         # tape flight, title card, picture
LOOP_AFTER = 16.95           # seconds from the intro start to the loop: the meadow
LOOP_LENGTH = 12.0           # ...then the bird


def frame_strip(t: float) -> Image.Image:
    """The strip under the shelf at time t, where the tape sheet slides out."""
    png = subprocess.run([
        "ffmpeg", "-loglevel", "error", "-ss", f"{t:.2f}", "-i", str(FILM), "-frames:v", "1",
        "-vf", "crop=1320:300:0:2160", "-f", "image2pipe", "-vcodec", "png", "-",
    ], capture_output=True, check=True).stdout
    return Image.open(io.BytesIO(png)).convert("L")


def sheet_cleared_at() -> float:
    """First moment after the tape sheet covers the shelf that it's fully gone.

    While the sheet is up the strip is its dark panel; once it has slid away the
    strip shows the lit shelf and tapes.
    """
    def lit(t: float) -> float:
        strip = frame_strip(t)
        return sum(1 for v in strip.tobytes() if v > 45) / (strip.width * strip.height)

    # Dark spells: the app's launch screen, then the tape sheet. The sheet is
    # the last one, so take the last dark-to-lit change.
    t, dark, cleared = 10.0, False, None
    while t < 70:
        value = lit(t)
        if value < 0.1:
            dark = True
        elif dark and value > 0.3:
            cleared, dark = t, False
        t += 0.25
    if cleared is not None:
        t = cleared
        # Step back to the exact frame, then one more for the sheet's edge.
        while lit(t - 0.05) > 0.3:
            t -= 0.05
        return round(t + 0.05, 2)
    raise SystemExit("Couldn't find the tape sheet in the film")


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
        start = sheet_cleared_at()
        print(f"intro starts at {start:.2f}s")
        encode(start, INTRO_LENGTH, mask, OUT / "intro.mp4")
        encode(start + LOOP_AFTER, LOOP_LENGTH, mask, OUT / "loop.mp4")
        frame = Path(tmp) / "poster.png"
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", str(OUT / "intro.mp4"),
                        "-frames:v", "1", str(frame)], check=True)
        Image.open(frame).save(OUT / "poster.webp", quality=88, method=6)
    for f in sorted(OUT.iterdir()):
        print(f"{f.stat().st_size / 1e6:5.2f} MB  {f.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
