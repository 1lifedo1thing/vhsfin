#!/usr/bin/env python3
"""Resize the checked-in TV master into platform assets (macOS, using sips).

No network or image-generation service is needed. Artwork source and prompts:
assets/branding/README.md. Run from any directory: python3 tool/generate_brand_assets.py
"""
import json
from collections import deque
from pathlib import Path
import shutil
import struct
import subprocess
import tempfile
import zlib

ROOT = Path(__file__).resolve().parents[1]
ICON_SOURCE = ROOT / 'assets/branding/crt-icon-ios-squircle-v3.png'
FOREGROUND_SOURCE = ROOT / 'assets/branding/crt-icon-cyan-cutout-v2.png'
ADAPTIVE_BACKGROUND = ROOT / 'assets/branding/adaptive-background.png'
ADAPTIVE_FOREGROUND = ROOT / 'assets/branding/adaptive-foreground.png'
BACKGROUND = '07090B'
ADAPTIVE_SIZE = 432
# The TV is nearly square, so its corners need room inside Android's circular
# 66dp safe area. At 54dp, the visible cabinet (including the knob and feet)
# fits inside that circle; the remaining space is transparent foreground.
ADAPTIVE_ARTWORK_SIZE = 54 / 108
LEGACY_ARTWORK_SIZE = 72 / 108


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


def write_solid_background(dest, size):
    pixel = bytes.fromhex(BACKGROUND)
    write_png(dest, size, size, [pixel * size for _ in range(size)], 2)


def extend_icon_edge(source, dest):
    """Make Apple's required opaque square without a dark corner behind the TV.

    The source's modeled casing supplies the visible edge. Pixels outside its
    transparent silhouette inherit the nearest casing color, which Apple then
    hides with its rounded-square mask.
    """
    width, height, color, rows = decode_png(source)
    if color != 6 or width != height:
        raise ValueError(f'{source} must be a square RGBA PNG')
    pixels = b''.join(rows)
    size = width * height
    output = bytearray(size * 3)
    seen = bytearray(size)
    queue = deque()
    for index in range(size):
        rgba = index * 4
        rgb = index * 3
        alpha = pixels[rgba + 3]
        if alpha >= 128:
            output[rgb:rgb + 3] = pixels[rgba:rgba + 3]
            seen[index] = 1
            x, y = index % width, index // width
            if (x == 0 or x == width - 1 or y == 0 or y == height - 1
                    or any(pixels[neighbor * 4 + 3] < 128 for neighbor in
                           (index - 1, index + 1, index - width, index + width)
                           if 0 <= neighbor < size)):
                queue.append(index)
    while queue:
        index = queue.popleft()
        x, y = index % width, index // width
        for neighbor in (index - 1 if x else -1,
                         index + 1 if x < width - 1 else -1,
                         index - width if y else -1,
                         index + width if y < height - 1 else -1):
            if neighbor < 0 or seen[neighbor]:
                continue
            seen[neighbor] = 1
            output[neighbor * 3:neighbor * 3 + 3] = output[index * 3:index * 3 + 3]
            queue.append(neighbor)
    write_png(dest, width, height,
              [output[y * width * 3:(y + 1) * width * 3] for y in range(height)], 2)


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


def clean_adaptive_foreground(path):
    width, height, color, rows = decode_png(path)
    if color != 6 or width != height:
        raise ValueError(f'{path} must be a square RGBA PNG')
    safe_radius_squared = (width * 66 / 108 / 2) ** 2
    cleaned = []
    for y, row in enumerate(rows):
        pixels = bytearray(row)
        for x in range(width):
            offset = x * 4
            alpha = pixels[offset + 3]
            if alpha < 16:
                pixels[offset:offset + 4] = b'\0\0\0\0'
            elif ((x - (width - 1) / 2) ** 2
                  + (y - (height - 1) / 2) ** 2) > safe_radius_squared:
                raise ValueError(f'{path} has visible artwork outside the Android safe circle')
        cleaned.append(pixels)
    write_png(path, width, height, cleaned, 6)


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
    write_solid_background(ADAPTIVE_BACKGROUND, ADAPTIVE_SIZE)
    fit_rgba_in_square(
        FOREGROUND_SOURCE,
        ADAPTIVE_FOREGROUND,
        ADAPTIVE_SIZE,
        artwork_size=round(ADAPTIVE_SIZE * ADAPTIVE_ARTWORK_SIZE),
    )
    clean_adaptive_foreground(ADAPTIVE_FOREGROUND)
    background = ROOT / 'android/app/src/main/res/drawable-nodpi/ic_launcher_background.png'
    foreground = ROOT / 'android/app/src/main/res/drawable-nodpi/ic_launcher_foreground.png'
    background.parent.mkdir(parents=True, exist_ok=True)
    sips('-z', str(ADAPTIVE_SIZE), str(ADAPTIVE_SIZE), str(ADAPTIVE_BACKGROUND), '--out', str(background))
    shutil.copyfile(ADAPTIVE_FOREGROUND, foreground)
    legacy_foreground = scratch / 'legacy_foreground.png'
    fit_rgba_in_square(
        FOREGROUND_SOURCE,
        legacy_foreground,
        ADAPTIVE_SIZE,
        artwork_size=round(ADAPTIVE_SIZE * LEGACY_ARTWORK_SIZE),
    )
    composite = scratch / 'launcher.png'
    composite_launcher(background, legacy_foreground, composite)
    for density, scale in [('mdpi', 1), ('hdpi', 1.5), ('xhdpi', 2), ('xxhdpi', 3), ('xxxhdpi', 4)]:
        mipmap = ROOT / f'android/app/src/main/res/mipmap-{density}/ic_launcher.png'
        splash = ROOT / f'android/app/src/main/res/drawable-{density}/splash_icon.png'
        sips('-z', str(round(48 * scale)), str(round(48 * scale)), str(composite), '--out', str(mipmap))
        fit_rgba_in_square(FOREGROUND_SOURCE, splash, round(192 * scale))


def main():
    if not shutil.which('sips'):
        raise SystemExit('This helper requires macOS sips. Generated assets are already checked in.')
    with tempfile.TemporaryDirectory() as scratch:
        scratch = Path(scratch)
        width, height, color, _ = decode_png(FOREGROUND_SOURCE)
        if color != 6 or width != height:
            raise ValueError(f'{FOREGROUND_SOURCE} must be a square RGBA PNG')
        ios_master = scratch / 'ios_master.png'
        extend_icon_edge(ICON_SOURCE, ios_master)
        export(ios_master, 'assets/icons/app_icon_1024.png', 1024)
        for size in (192, 512):
            export(ios_master, f'web/icons/Icon-{size}.png', size)
            export(ios_master, f'web/icons/Icon-maskable-{size}.png', size, inset=True)
        export(ios_master, 'web/icons/apple-touch-icon.png', 180)
        export_android_adaptive(scratch)
        for platform, catalog in [('ios', 'Runner'), ('macos', 'Runner')]:
            folder = Path(platform) / catalog / 'Assets.xcassets/AppIcon.appiconset'
            manifest = json.loads((ROOT / folder / 'Contents.json').read_text())
            for entry in manifest['images']:
                size = round(float(entry['size'].split('x')[0]) * float(entry['scale'].rstrip('x')))
                export(ios_master, folder / entry['filename'], size)
        # The launch screen isn't masked like the home-screen icon, so the
        # opaque icon's smeared corners would show around the TV. Use the
        # transparent casing on the storyboard's exact background instead.
        icon_size, _, icon_color, _ = decode_png(ICON_SOURCE)
        if icon_color != 6:
            raise ValueError(f'{ICON_SOURCE} must be an RGBA PNG')
        launch_background = scratch / 'launch_background.png'
        write_solid_background(launch_background, icon_size)
        launch_master = scratch / 'launch_master.png'
        composite_launcher(launch_background, ICON_SOURCE, launch_master)
        for scale in (1, 2, 3):
            suffix = '' if scale == 1 else f'@{scale}x'
            export(launch_master, f'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage{suffix}.png', 160 * scale)
    print('Updated Flutter, Android, iOS, macOS, and web brand assets.')


if __name__ == '__main__':
    main()
