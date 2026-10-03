"""Frame raw demo-shelf captures into store and website images.

Input:  screenshots/raw/{iphone,ipad}/0N-*.png  (tool/store_screenshots.sh)
Output: fastlane/screenshots/ios/en-US/        App Store, iPhone 6.9" + iPad 13"
        fastlane/metadata/android/en-US/images/ Play phone shots, feature graphic, icon
        site/vhsfin/img/                        website WebP images

Needs Pillow: python3 -m pip install pillow
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "screenshots" / "raw"
IOS_OUT = ROOT / "fastlane" / "screenshots" / "ios" / "en-US"
PLAY_OUT = ROOT / "fastlane" / "metadata" / "android" / "en-US" / "images"
SITE_OUT = ROOT / "site" / "vhsfin" / "img"
FONTS = ROOT / "assets" / "fonts"

INK = (230, 236, 238)
MUTED = (152, 164, 171)
ACCENT = (111, 224, 230)
LINE = (39, 45, 51)

# Gradient stops (position 0 = centre, 1 = farthest corner).
STOPS = [(0.0, (24, 52, 56)), (0.35, (12, 20, 24)), (0.75, (5, 7, 9)), (1.0, (2, 3, 3))]

CAPTIONS = [
    ("MOVIE NIGHT,\nREWOUND.", "Your Jellyfin library as a shelf of tapes."),
    ("PICK A TAPE.", "Every movie and show gets a spine."),
    ("PRESS PLAY.", "Watch it glow on a classic CRT."),
    ("BE KIND.\nREWIND.", "A remote with REW, FF, and eject."),
    ("SIX TVS.\nTWO SHELVES.", "Set up the living room you remember."),
    ("BRING YOUR\nOWN JELLYFIN.", "Free. No ads. No tracking."),
]


def lerp(a: tuple[int, ...], b: tuple[int, ...], t: float) -> tuple[int, ...]:
    return tuple(round(x + (y - x) * t) for x, y in zip(a, b))


def gradient_color(t: float) -> tuple[int, ...]:
    for (p0, c0), (p1, c1) in zip(STOPS, STOPS[1:]):
        if t <= p1:
            return lerp(c0, c1, (t - p0) / (p1 - p0))
    return STOPS[-1][1]


def radial_background(size: tuple[int, int], centre: tuple[float, float] = (0.5, 0.4)) -> Image.Image:
    """Dark radial glow, computed small and scaled up (it's smooth anyway)."""
    w, h = size
    sw, sh = 240, max(1, round(240 * h / w))
    cx, cy = centre[0] * sw, centre[1] * sh
    far = max(((x - cx) ** 2 + (y - cy) ** 2) ** 0.5 for x in (0, sw) for y in (0, sh))
    small = Image.new("RGB", (sw, sh))
    px = small.load()
    for y in range(sh):
        for x in range(sw):
            t = ((x - cx) ** 2 + (y - cy) ** 2) ** 0.5 / far
            px[x, y] = gradient_color(t)
    return small.resize(size, Image.BICUBIC)


def font(name: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(FONTS / name), size)


def fit_font(draw: ImageDraw.ImageDraw, text: str, name: str, size: int, max_width: int) -> ImageFont.FreeTypeFont:
    while size > 10:
        f = font(name, size)
        if draw.multiline_textbbox((0, 0), text, font=f, spacing=size * 0.12)[2] <= max_width:
            return f
        size -= 2
    return font(name, size)


def rounded(image: Image.Image, radius: int) -> Image.Image:
    mask = Image.new("L", image.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, *image.size), radius, fill=255)
    out = image.convert("RGBA")
    out.putalpha(mask)
    return out


def place_screen(canvas: Image.Image, shot: Image.Image, box_width: int, top: int, radius_ratio: float) -> None:
    w = box_width
    h = round(shot.height * w / shot.width)
    screen = shot.convert("RGB").resize((w, h), Image.LANCZOS)
    radius = round(w * radius_ratio)
    left = (canvas.width - w) // 2
    border = max(3, w // 260)

    glow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(glow).rounded_rectangle(
        (left - border, top - border, left + w + border, top + h + border),
        radius + border, fill=(*ACCENT, 70))
    glow = glow.filter(ImageFilter.GaussianBlur(w // 18))
    canvas.alpha_composite(glow)

    frame = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(frame).rounded_rectangle(
        (left - border, top - border, left + w + border, top + h + border),
        radius + border, fill=(*LINE, 255))
    canvas.alpha_composite(frame)
    canvas.alpha_composite(rounded(screen, radius), (left, top))


def compose(shot: Image.Image, size: tuple[int, int], caption: tuple[str, str], *,
            screen_width: float, radius_ratio: float) -> Image.Image:
    w, h = size
    canvas = radial_background(size).convert("RGBA")
    draw = ImageDraw.Draw(canvas)
    title, sub = caption
    margin = round(w * 0.07)

    title_font = fit_font(draw, title, "Bungee-Regular.ttf", round(w * 0.085), w - 2 * margin)
    sub_font = fit_font(draw, sub, "Nunito-SemiBold.ttf", round(w * 0.04), w - 2 * margin)
    y = round(h * 0.05)
    spacing = title_font.size * 0.12
    tb = draw.multiline_textbbox((0, 0), title, font=title_font, align="center", spacing=spacing)
    # Reserve two title lines on every slide so the screens line up in the set.
    block = draw.multiline_textbbox((0, 0), "A\nA", font=title_font, spacing=spacing)
    block_h = block[3] - block[1]
    title_y = y + (block_h - (tb[3] - tb[1])) / 2
    draw.multiline_text(((w - (tb[2] - tb[0])) / 2 - tb[0], title_y - tb[1]), title, font=title_font,
                        fill=INK, align="center", spacing=spacing)
    y += block_h + round(title_font.size * 0.45)
    sb = draw.textbbox((0, 0), sub, font=sub_font)
    draw.text(((w - (sb[2] - sb[0])) / 2 - sb[0], y - sb[1]), sub, font=sub_font, fill=MUTED)
    y += sb[3] - sb[1] + round(h * 0.035)

    box_width = round(w * screen_width)
    # Shrink the screen if it would run off the bottom.
    max_h = h - y - round(h * 0.03)
    if shot.height * box_width / shot.width > max_h:
        box_width = round(max_h * shot.width / shot.height)
    place_screen(canvas, shot, box_width, round(y), radius_ratio)
    return canvas.convert("RGB")


def feature_graphic(playing: Image.Image, size: tuple[int, int] = (1024, 500)) -> Image.Image:
    """Wordmark left, the CRT playing on the right (Play feature graphic, og:image)."""
    if size != (1024, 500):
        base = feature_graphic(playing)
        canvas = radial_background(size, centre=(0.7, 0.45))
        scale = min(size[0] / 1024, size[1] / 500)
        fitted = base.resize((round(1024 * scale), round(500 * scale)), Image.LANCZOS)
        canvas.paste(fitted, ((size[0] - fitted.width) // 2, (size[1] - fitted.height) // 2))
        return canvas
    canvas = radial_background(size, centre=(0.7, 0.45)).convert("RGBA")
    draw = ImageDraw.Draw(canvas)
    draw.text((64, 150), "VHSFIN", font=font("Bungee-Regular.ttf", 92), fill=INK)
    draw.text((68, 270), "Movie night, rewound.", font=font("Nunito-Bold.ttf", 38), fill=ACCENT)
    draw.text((68, 322), "A Jellyfin client with a VHS player.", font=font("Nunito-SemiBold.ttf", 26), fill=MUTED)
    # Crop the TV (top part of the playing capture) and fit it on the right.
    w, h = playing.size
    tv = playing.crop((0, round(h * 0.13), w, round(h * 0.58))).convert("RGB")
    tv_h = 440
    tv = tv.resize((round(tv.width * tv_h / tv.height), tv_h), Image.LANCZOS)
    # Feather the crop's edges so the room behind the TV melts into the gradient.
    mask = Image.new("L", tv.size, 0)
    inset = tv_h // 10
    ImageDraw.Draw(mask).rounded_rectangle(
        (inset, inset, tv.width - inset, tv.height - inset), inset, fill=255)
    tv = tv.convert("RGBA")
    tv.putalpha(mask.filter(ImageFilter.GaussianBlur(inset * 0.7)))
    canvas.alpha_composite(tv, (size[0] - tv.width - 20, 30))
    return canvas.convert("RGB")


def main() -> None:
    iphone = sorted((RAW / "iphone").glob("0*.png"))
    ipad = sorted((RAW / "ipad").glob("0*.png"))
    if len(iphone) != len(CAPTIONS):
        raise SystemExit(f"Expected {len(CAPTIONS)} iPhone captures in {RAW / 'iphone'}")

    for out in (IOS_OUT, PLAY_OUT / "phoneScreenshots", SITE_OUT):
        out.mkdir(parents=True, exist_ok=True)
        for old in out.glob("*"):
            if old.suffix in {".png", ".webp"}:
                old.unlink()

    for i, (path, caption) in enumerate(zip(iphone, CAPTIONS), start=1):
        shot = Image.open(path)
        compose(shot, (1320, 2868), caption, screen_width=0.78, radius_ratio=0.1).save(
            IOS_OUT / f"iPhone_{i:02}.png", optimize=True)
        compose(shot, (1080, 1920), caption, screen_width=0.66, radius_ratio=0.1).save(
            PLAY_OUT / "phoneScreenshots" / f"{i:02}.png", optimize=True)
        web = shot.convert("RGB")
        web.resize((640, round(640 * web.height / web.width)), Image.LANCZOS).save(
            SITE_OUT / f"{path.stem[3:]}.webp", quality=82, method=6)

    for i, (path, caption) in enumerate(zip(ipad, CAPTIONS), start=1):
        compose(Image.open(path), (2064, 2752), caption, screen_width=0.8, radius_ratio=0.03).save(
            IOS_OUT / f"iPad_{i:02}.png", optimize=True)

    feature_graphic(Image.open(iphone[2])).save(PLAY_OUT / "featureGraphic.png", optimize=True)
    feature_graphic(Image.open(iphone[2]), (1200, 630)).save(SITE_OUT.parent / "og.png", optimize=True)
    Image.open(ROOT / "assets" / "icons" / "app_icon_1024.png").convert("RGB").resize(
        (512, 512), Image.LANCZOS).save(PLAY_OUT / "icon.png", optimize=True)
    print(f"Framed {len(iphone)} iPhone, {len(ipad)} iPad, Play, and site images.")


if __name__ == "__main__":
    main()
