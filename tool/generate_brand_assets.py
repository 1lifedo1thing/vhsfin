#!/usr/bin/env python3
"""Resize the checked-in masters into platform assets (macOS, using sips).

No network or image-generation service is needed. Artwork source and prompts:
assets/branding/README.md. Run from any directory: python3 tool/generate_brand_assets.py
"""
import json
from pathlib import Path
import shutil
import struct
import subprocess
import tempfile
import zlib

ROOT = Path(__file__).resolve().parents[1]
CASSETTE = ROOT / 'assets/branding/cassette-icon.png'
ICON_SHEET = ROOT / 'assets/icon.png'
FOREGROUND_SOURCE = ROOT / 'assets/tr_icon.png'
ADAPTIVE_BACKGROUND = ROOT / 'assets/branding/adaptive-background.png'
ADAPTIVE_FOREGROUND = ROOT / 'assets/branding/adaptive-foreground.png'
BACKGROUND = '1A100C'
ADAPTIVE_SIZE = 432
# Android adaptive key artwork sits in the inner 72dp of a 108dp layer.
SAFE_ZONE = 72 / 108


def sips(*args):
    subprocess.run(['sips', *args], check=True, capture_output=True)


def export(source, relative, size, inset=False):
    target = ROOT / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    artwork_size = round(size * 0.64) if inset else size
    sips('-z', str(artwork_size), str(artwork_size), str(source), '--out', str(target))
    if inset:
        sips('--padToHeightWidth', str(size), str(size), '--padColor', BACKGROUND, str(target))


def decode_png(path):
    data = Path(path).read_bytes()
    if data[:8] != b'\x89PNG\r\n\x1a\n':
        raise ValueError(f'{path} is not a PNG')
    offset = 8
    idat = b''
    width = height = color = None
    while offset < len(data):
        length = struct.unpack('>I', data[offset:offset + 4])[0]
        tag = data[offset + 4:offset + 8]
        chunk = data[offset + 8:offset + 8 + length]
        if tag == b'IHDR':
            width, height, bit, color, *_ = struct.unpack('>IIBBBBB', chunk)
            if bit != 8 or color not in (2, 6):
                raise ValueError(f'{path} must be 8-bit RGB or RGBA')
        elif tag == b'IDAT':
            idat += chunk
        elif tag == b'IEND':
            break
        offset += 12 + length
    channels = 3 if color == 2 else 4
    stride = 1 + width * channels
    raw = zlib.decompress(idat)

    def paeth(left, up, up_left):
        estimate = left + up - up_left
        distances = (abs(estimate - left), abs(estimate - up), abs(estimate - up_left))
        return (left, up, up_left)[distances.index(min(distances))]

    rows = []
    previous = bytes(stride - 1)
    for y in range(height):
        filter_type = raw[y * stride]
        scan = bytearray(raw[y * stride + 1:(y + 1) * stride])
        if filter_type == 1:
            for i, value in enumerate(scan):
                left = scan[i - channels] if i >= channels else 0
                scan[i] = (value + left) & 255
        elif filter_type == 2:
            for i, value in enumerate(scan):
                scan[i] = (value + previous[i]) & 255
        elif filter_type == 3:
            for i, value in enumerate(scan):
                left = scan[i - channels] if i >= channels else 0
                scan[i] = (value + ((left + previous[i]) // 2)) & 255
        elif filter_type == 4:
            for i, value in enumerate(scan):
                left = scan[i - channels] if i >= channels else 0
                up_left = previous[i - channels] if i >= channels else 0
                scan[i] = (value + paeth(left, previous[i], up_left)) & 255
        elif filter_type != 0:
            raise ValueError(f'unsupported PNG filter {filter_type} in {path}')
        rows.append(bytes(scan))
        previous = scan
    return width, height, color, rows


def write_png(path, width, height, rows, color):
    raw = b''.join(b'\x00' + bytes(row) for row in rows)

    def chunk(tag, payload):
        return (struct.pack('>I', len(payload)) + tag + payload
                + struct.pack('>I', zlib.crc32(tag + payload) & 0xffffffff))

    ihdr = struct.pack('>IIBBBBB', width, height, 8, color, 0, 0, 0)
    Path(path).write_bytes(
        b'\x89PNG\r\n\x1a\n'
        + chunk(b'IHDR', ihdr)
        + chunk(b'IDAT', zlib.compress(raw, 9))
        + chunk(b'IEND', b'')
    )


def extract_sheet_background(dest):
    width, height, color, rows = decode_png(ICON_SHEET)
    if color != 2 or width != height * 2:
        raise ValueError(f'{ICON_SHEET} must be a side-by-side RGB pair of squares')
    write_png(dest, height, height, [row[:height * 3] for row in rows], 2)


def pad_rgba_to_square(source, dest, canvas):
    width, height, color, rows = decode_png(source)
    if color != 6:
        raise ValueError(f'{source} must have an alpha channel')
    origin_x = (canvas - width) // 2
    origin_y = (canvas - height) // 2
    padded = [bytearray(canvas * 4) for _ in range(canvas)]
    for y, row in enumerate(rows):
        start = origin_x * 4
        padded[origin_y + y][start:start + width * 4] = row
    dest.parent.mkdir(parents=True, exist_ok=True)
    write_png(dest, canvas, canvas, padded, 6)


def fit_rgba_in_square(source, dest, canvas, artwork_size=None):
    fitted = artwork_size or canvas
    with tempfile.TemporaryDirectory() as scratch:
        fitted_path = Path(scratch) / 'fitted.png'
        sips('-Z', str(fitted), str(source), '--out', str(fitted_path))
        pad_rgba_to_square(fitted_path, dest, canvas)


def composite_launcher(background, foreground, dest):
    bg_w, bg_h, bg_color, bg_rows = decode_png(background)
    fg_w, fg_h, fg_color, fg_rows = decode_png(foreground)
    if (bg_w, bg_h) != (fg_w, fg_h) or bg_color != 2 or fg_color != 6:
        raise ValueError('launcher composite needs matching RGB background and RGBA foreground')
    out = []
    for y in range(bg_h):
        row = bytearray(bg_rows[y])
        fg = fg_rows[y]
        for x in range(bg_w):
            alpha = fg[x * 4 + 3]
            if alpha == 0:
                continue
            red, green, blue = fg[x * 4], fg[x * 4 + 1], fg[x * 4 + 2]
            i = x * 3
            if alpha == 255:
                row[i:i + 3] = red, green, blue
            else:
                inverse = 255 - alpha
                row[i] = (red * alpha + row[i] * inverse) // 255
                row[i + 1] = (green * alpha + row[i + 1] * inverse) // 255
                row[i + 2] = (blue * alpha + row[i + 2] * inverse) // 255
        out.append(row)
    write_png(dest, bg_w, bg_h, out, 2)


def export_android_adaptive(scratch):
    extract_sheet_background(ADAPTIVE_BACKGROUND)
    fit_rgba_in_square(
        FOREGROUND_SOURCE,
        ADAPTIVE_FOREGROUND,
        ADAPTIVE_SIZE,
        artwork_size=round(ADAPTIVE_SIZE * SAFE_ZONE),
    )
    background = ROOT / 'android/app/src/main/res/drawable-nodpi/ic_launcher_background.png'
    foreground = ROOT / 'android/app/src/main/res/drawable-nodpi/ic_launcher_foreground.png'
    background.parent.mkdir(parents=True, exist_ok=True)
    sips('-z', str(ADAPTIVE_SIZE), str(ADAPTIVE_SIZE), str(ADAPTIVE_BACKGROUND), '--out', str(background))
    shutil.copyfile(ADAPTIVE_FOREGROUND, foreground)
    composite = scratch / 'launcher.png'
    composite_launcher(background, foreground, composite)
    for density, scale in [('mdpi', 1), ('hdpi', 1.5), ('xhdpi', 2), ('xxhdpi', 3), ('xxxhdpi', 4)]:
        mipmap = ROOT / f'android/app/src/main/res/mipmap-{density}/ic_launcher.png'
        splash = ROOT / f'android/app/src/main/res/drawable-{density}/splash_icon.png'
        sips('-z', str(round(48 * scale)), str(round(48 * scale)), str(composite), '--out', str(mipmap))
        fit_rgba_in_square(FOREGROUND_SOURCE, splash, round(192 * scale))


def main():
    if not shutil.which('sips'):
        raise SystemExit('This helper requires macOS sips. Generated assets are already checked in.')
    export(CASSETTE, 'assets/icons/app_icon_1024.png', 1024)
    for size in (192, 512):
        export(CASSETTE, f'web/icons/Icon-{size}.png', size)
        export(CASSETTE, f'web/icons/Icon-maskable-{size}.png', size, inset=True)
    export(CASSETTE, 'web/icons/apple-touch-icon.png', 180)
    with tempfile.TemporaryDirectory() as scratch:
        export_android_adaptive(Path(scratch))
    for platform, catalog in [('ios', 'Runner'), ('macos', 'Runner')]:
        folder = Path(platform) / catalog / 'Assets.xcassets/AppIcon.appiconset'
        manifest = json.loads((ROOT / folder / 'Contents.json').read_text())
        for entry in manifest['images']:
            size = round(float(entry['size'].split('x')[0]) * float(entry['scale'].rstrip('x')))
            export(CASSETTE, folder / entry['filename'], size)
    for scale in (1, 2, 3):
        suffix = '' if scale == 1 else f'@{scale}x'
        export(CASSETTE, f'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage{suffix}.png', 160 * scale)
    print('Updated Flutter, Android, iOS, macOS, and web brand assets.')


if __name__ == '__main__':
    main()
