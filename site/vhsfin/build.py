"""Build vhsfin.markdid.dev: the landing page plus Privacy, Terms, and Support.

Privacy and Terms render from docs/legal/*.md. Screenshots in img/ and og.png
come from tool/frame_screenshots.py. Fails on unresolved legal placeholders.
"""

from __future__ import annotations

import hashlib
import html
import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SITE = Path(__file__).resolve().parent
DIST = SITE / "dist"
LEGAL = ROOT / "docs" / "legal"
PLACEHOLDER = re.compile(r"\[(?:[A-Z][A-Z0-9_ -]{2,}|TODO|TBD)\]")

APP = "VHSFin"
HOST = "https://vhsfin.markdid.dev"
SUPPORT = "support+vhsfin@markdid.dev"
THEME = "#000000"
SOURCE = "https://github.com/markdid/vhsfin"
# Fill in when the listings are live; empty shows "coming soon".
APP_STORE = ""
PLAY_STORE = ""


def inline(markdown: str) -> str:
    result = html.escape(markdown, quote=True)
    result = re.sub(
        r"\[([^\]]+)\]\((https://[^)]+|mailto:[^)]+|/[^)]+)\)",
        lambda m: f'<a href="{m.group(2)}">{m.group(1)}</a>',
        result,
    )
    result = re.sub(r"`([^`]+)`", r"<code>\1</code>", result)
    return re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", result)


def render_markdown(source: str) -> str:
    """Small Markdown subset: #/##/### headings, paragraphs, - lists, | tables."""
    blocks: list[str] = []
    paragraph: list[str] = []
    items: list[str] = []
    rows: list[list[str]] = []

    def flush() -> None:
        if paragraph:
            blocks.append(f"<p>{inline(' '.join(paragraph))}</p>")
            paragraph.clear()
        if items:
            blocks.append("<ul>" + "".join(f"<li>{inline(i)}</li>" for i in items) + "</ul>")
            items.clear()
        if rows:
            head, *body = rows
            th = "".join(f"<th>{inline(c)}</th>" for c in head)
            tb = "".join("<tr>" + "".join(f"<td>{inline(c)}</td>" for c in r) + "</tr>" for r in body)
            blocks.append(f'<div class="table"><table><thead><tr>{th}</tr></thead><tbody>{tb}</tbody></table></div>')
            rows.clear()

    for raw in source.splitlines():
        line = raw.strip()
        if not line:
            flush()
        elif line.startswith("#"):
            flush()
            level = len(line) - len(line.lstrip("#"))
            title = line[level:].strip()
            anchor = re.sub(r"[^a-z0-9]+", "-", title.lower()).strip("-")
            blocks.append(f'<h{level} id="{anchor}">{inline(title)}</h{level}>')
        elif line.startswith("- "):
            if paragraph or rows:
                flush()
            items.append(line[2:])
        elif line.startswith("|"):
            if paragraph or items:
                flush()
            cells = [c.strip() for c in line.strip("|").split("|")]
            if not all(re.fullmatch(r":?-{3,}:?", c) for c in cells):
                rows.append(cells)
        else:
            if items or rows:
                flush()
            paragraph.append(line)
    flush()
    return "\n".join(blocks)


def asset_version(name: str) -> str:
    """Short content hash so browsers never mix a new page with an old stylesheet."""
    return hashlib.sha256((SITE / name).read_bytes()).hexdigest()[:10]


def page(title: str, content: str, *, description: str, path: str) -> str:
    canonical = f"{HOST}{path}"
    full_title = APP if path == "/" else f"{title} · {APP}"
    desc = html.escape(description, quote=True)
    og = (f'  <meta property="og:image" content="{HOST}/assets/og.png">\n'
          '  <meta name="twitter:card" content="summary_large_image">\n'
          if (SITE / "og.png").is_file() else '  <meta name="twitter:card" content="summary">\n')
    return f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="theme-color" content="{THEME}">
  <meta name="description" content="{desc}">
  <meta property="og:type" content="website">
  <meta property="og:site_name" content="{APP}">
  <meta property="og:title" content="{html.escape(full_title, quote=True)}">
  <meta property="og:description" content="{desc}">
  <meta property="og:url" content="{canonical}">
{og}  <link rel="canonical" href="{canonical}">
  <link rel="icon" href="/assets/favicon.png" type="image/png">
  <link rel="apple-touch-icon" href="/assets/favicon.png">
  <link rel="preload" href="/assets/fonts/Bungee-Regular.ttf" as="font" type="font/ttf" crossorigin>
  <link rel="stylesheet" href="/assets/style.css?v={asset_version("style.css")}">
  <script src="/assets/main.js?v={asset_version("main.js")}" defer></script>
  <title>{html.escape(full_title)}</title>
</head>
<body class="{'landing' if path == '/' else 'doc'}">
  <a class="skip" href="#main">Skip to content</a>
{'' if path == '/' else '  <header class="site-header"><a class="wordmark" href="/">VHSFIN</a></header>' + chr(10)}  <main id="main">{content}</main>
  <footer class="site-footer">
    <p>Made by Mark at <a href="https://markdid.dev">MarkDid</a> · <a href="https://x.com/_markdid">@_markdid on X</a></p>
    <nav aria-label="Footer"><a href="/privacy/">Privacy</a><a href="/terms/">Terms</a><a href="/support/">Support</a><a href="{SOURCE}">Source</a></nav>
    <p class="copyright">© 2026 MarkDid, LLC. <a href="https://peach.blender.org">Big Buck Bunny</a> © Blender Foundation, CC BY 3.0.</p>
  </footer>
</body>
</html>
"""


def store_button(url: str, label: str) -> str:
    if url:
        return f'<a class="store" href="{url}">{label}</a>'
    return f'<span class="store soon">{label}<small>Coming soon</small></span>'


def home() -> str:
    return f"""
  <section class="stage" aria-label="VHSFin playing Big Buck Bunny">
    <div class="pin">
      <div class="spot" aria-hidden="true"></div>
      <figure class="tv">
        <video class="intro" src="/assets/media/intro.mp4" poster="/assets/media/poster.webp" muted playsinline preload="auto" aria-hidden="true"></video>
        <video class="loop" src="/assets/media/loop.mp4" muted playsinline loop preload="auto" aria-hidden="true"></video>
      </figure>
      <span class="scroll-cue" aria-hidden="true"></span>
    </div>
  </section>
  <section class="about" id="about">
    <p class="kicker">Introducing</p>
    <h1>VHSFin</h1>
    <p class="tagline">A nostalgic, fully functioning<br>Jellyfin client.</p>
    <p class="copy">Your movies and shows become VHS tapes on a shelf. Pick one, watch it slide into the deck, and press play on a glowing CRT. Rewind, fast-forward, eject. Free, no ads, open source.</p>
    <div class="stores">{store_button(APP_STORE, "App Store")}{store_button(PLAY_STORE, "Google Play")}</div>
  </section>
"""


def write(path: str, content: str) -> None:
    out = DIST / path / "index.html" if path else DIST / "index.html"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(content, encoding="utf-8")


def main() -> None:
    policies = {
        "privacy": ("Privacy Policy", (LEGAL / "privacy-policy.md").read_text(encoding="utf-8")),
        "terms": ("Terms of Service", (LEGAL / "terms-of-service.md").read_text(encoding="utf-8")),
    }
    for name, (_, source) in policies.items():
        if PLACEHOLDER.search(source):
            raise SystemExit(f"Unresolved placeholder in {name} policy")
    if DIST.exists():
        shutil.rmtree(DIST)
    assets = DIST / "assets"
    assets.mkdir(parents=True)
    shutil.copy2(SITE / "style.css", assets / "style.css")
    shutil.copy2(SITE / "main.js", assets / "main.js")
    shutil.copytree(SITE / "media", assets / "media")
    for extra in ("img", "fonts"):
        if (SITE / extra).is_dir():
            shutil.copytree(SITE / extra, assets / extra)
    fonts = assets / "fonts"
    fonts.mkdir(exist_ok=True)
    for name in ("Bungee-Regular.ttf", "Nunito-Regular.ttf", "Nunito-Bold.ttf", "OFL-bungee.txt", "OFL-nunito.txt"):
        shutil.copy2(ROOT / "assets" / "fonts" / name, fonts / name)
    for single in ("favicon.png", "og.png"):
        if (SITE / single).is_file():
            shutil.copy2(SITE / single, assets / single)
    if (SITE / "robots.txt").is_file():
        shutil.copy2(SITE / "robots.txt", DIST / "robots.txt")

    write("", page(APP, home(), description="A nostalgic, fully functioning Jellyfin client. Your movies and shows as VHS tapes on a shelf, played on a glowing CRT.", path="/"))
    support = f"""<div class="doc-wrap"><p class="eyebrow">Need a hand?</p><h1>Support</h1>
  <p>Email <a href="mailto:{SUPPORT}">{SUPPORT}</a>. Tell us your device, your Jellyfin version, and what happened. Please leave out passwords and server addresses.</p>
  <h2>Can't connect?</h2>
  <ul><li>Use your server's full address, including the port, for example <code>http://192.168.1.20:8096</code>.</li>
  <li>Make sure your phone can reach the server: same Wi-Fi, or your VPN is on.</li>
  <li>On iPhone, allow local network access when asked, or turn it on in Settings, then VHSFin.</li></ul>
  <h2>A shelf looks empty?</h2>
  <p>VHS Only is on by default, so titles without sleeve art are hidden. Turn it off in the app's Settings to show everything.</p>
  <h2>Bugs and ideas</h2>
  <p>VHSFin is open source. You can also <a href="{SOURCE}/issues">open an issue on GitHub</a>.</p></div>"""
    write("support", page("Support", support, description=f"Get help with {APP}.", path="/support/"))
    for name, (title, source) in policies.items():
        body = f'<div class="doc-wrap"><article class="policy">{render_markdown(source)}</article></div>'
        write(name, page(title, body, description=f"{APP} {title.lower()} from MarkDid, LLC.", path=f"/{name}/"))


if __name__ == "__main__":
    main()
