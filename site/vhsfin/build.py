"""Build vhsfin.markdid.dev: the landing page plus Privacy, Terms, and Support.

Privacy and Terms render from docs/legal/*.md. Screenshots in img/ and og.png
come from tool/frame_screenshots.py. Fails on unresolved legal placeholders.
"""

from __future__ import annotations

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
THEME = "#07090B"
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
  <link rel="stylesheet" href="/assets/style.css">
  <title>{html.escape(full_title)}</title>
</head>
<body class="{'landing' if path == '/' else 'doc'}">
  <a class="skip" href="#main">Skip to content</a>
  <header class="site-header"><a class="wordmark" href="/"><img src="/assets/favicon.png" width="28" height="28" alt="">{APP}</a>
    <nav aria-label="Main"><a href="/support/">Support</a><a href="/privacy/">Privacy</a><a href="{SOURCE}">Source</a></nav></header>
  <main id="main">{content}</main>
  <footer class="site-footer"><span>© 2026 <a href="https://markdid.dev">MarkDid, LLC</a></span>
    <nav aria-label="Footer"><a href="/support/">Support</a><a href="/privacy/">Privacy</a><a href="/terms/">Terms</a><a href="{SOURCE}">Source</a><a href="mailto:{SUPPORT}">{SUPPORT}</a></nav></footer>
</body>
</html>
"""


def store_buttons() -> str:
    def button(url: str, label: str) -> str:
        if url:
            return f'<a class="button" href="{url}">{label}</a>'
        return f'<span class="button soon" aria-disabled="true">{label}<small>Coming soon</small></span>'
    return (button(APP_STORE, "App Store") + button(PLAY_STORE, "Google Play")
            + f'<a class="button ghost" href="{SOURCE}">Source code</a>')


def phone(name: str, alt: str, cls: str = "", lazy: bool = True) -> str:
    loading = ' loading="lazy"' if lazy else ""
    return (f'<figure class="phone {cls}"><img src="/assets/img/{name}.webp" width="640" '
            f'height="1391" alt="{alt}"{loading}></figure>')


def home() -> str:
    return f"""
  <section class="hero wrap" aria-labelledby="hero-title">
    <div class="hero-copy">
      <p class="eyebrow">A Jellyfin client</p>
      <h1 id="hero-title">Movie night,<br>rewound.</h1>
      <p class="lede">Your movies and shows as VHS tapes on a shelf. Pick one, watch it slide into the deck, and press play on a glowing CRT.</p>
      <div class="actions">{store_buttons()}</div>
      <ul class="facts" aria-label="Quick facts"><li>Free</li><li>No ads</li><li>No tracking</li><li>Open source</li></ul>
    </div>
    <div class="hero-phones">
      {phone("living-room", "The living room: a chrome CRT TV above a walnut shelf of VHS tapes", "back", lazy=False)}
      {phone("playing", "Big Buck Bunny playing on the CRT", "front", lazy=False)}
    </div>
  </section>

  <div class="band"><ul><li>Pick a tape</li><li>Insert</li><li>Press play</li><li>Be kind, rewind</li></ul></div>

  <section class="features wrap" aria-labelledby="features-title">
    <h2 id="features-title">The video store, <em>in your living room.</em></h2>
    <div class="grid">
      <article>{phone("tape", "Tape info for Big Buck Bunny with Back and Insert Tape keys")}
        <h3>Every title gets a tape</h3><p>Movies and shows sit on the shelf as spines, with real VHS sleeve art where it exists.</p></article>
      <article>{phone("remote", "A remote with rewind, pause, fast-forward, full screen, and eject")}
        <h3>A remote that clunks</h3><p>Rewind, fast-forward, and eject with mechanical sounds and haptics. Full screen when you want it.</p></article>
      <article>{phone("settings", "Settings with two shelf styles and six TV cabinets")}
        <h3>Six TVs, two shelves</h3><p>Set up the living room you remember: chrome, crimson, wood-grain knobs, and more.</p></article>
    </div>
  </section>

  <section class="split wrap" aria-labelledby="jellyfin-title">
    {phone("connect", "The welcome screen asking for a Jellyfin server address, username, and password")}
    <div>
      <p class="eyebrow">Bring your own server</p>
      <h2 id="jellyfin-title">Your Jellyfin. <em>Your tapes.</em></h2>
      <p>VHSFin connects to a <a href="https://jellyfin.org">Jellyfin</a> server you already run, at home or anywhere you can reach it. Choose which libraries go on the shelf, and set up a kid-friendly account for the little ones.</p>
      <p>It comes with no media, no subscriptions, and no account with us. We never see what you watch. <a href="/privacy/">Read the privacy policy</a>.</p>
      <p class="fine">VHSFin is an independent app, not affiliated with the Jellyfin project.</p>
    </div>
  </section>

  <section class="open wrap" aria-labelledby="open-title">
    <h2 id="open-title">Open source, <em>like your server.</em></h2>
    <p>VHSFin is free software under the GPL. Read the code, report a bug, or build it yourself, including a self-hosted web version.</p>
    <a class="button ghost" href="{SOURCE}">View on GitHub</a>
  </section>

  <section class="more wrap" aria-labelledby="more-title">
    <p class="eyebrow">More from MarkDid</p>
    <h2 id="more-title">Other apps from <em>the studio.</em></h2>
    <div class="cards">
      <a class="card" href="https://rollback.markdid.dev"><strong>ROLL BACK</strong><span>A dice game with a very small wizard who knows how every turn could have gone.</span><small>Out now on Android</small></a>
      <a class="card" href="https://pabo.markdid.dev"><strong>pabo.</strong><span>Talk your way into another language: conversation practice in Korean, Japanese, and Mandarin.</span><small>Coming soon to iPhone</small></a>
      <a class="card" href="https://markdid.dev"><strong>markdid.dev</strong><span>Apps, devices, and the software between them, from MarkDid, LLC.</span><small>Visit the studio</small></a>
    </div>
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

    write("", page(APP, home(), description="Movie night, rewound. A free, open-source Jellyfin client that puts your movies and shows on a shelf of VHS tapes.", path="/"))
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
