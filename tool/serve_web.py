#!/usr/bin/env python3
"""Serve Flutter web build and proxy cover lookups (CORS-safe)."""

from __future__ import annotations

import argparse
import json
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

UA = "vhsfin-proxy/0.1 (kids jellyfin client)"
IA = "https://archive.org"
VC = "https://vhscollector.com"
ROOT = Path(__file__).resolve().parents[1] / "build" / "web"


def title_slugs(title: str) -> list[str]:
    t = title.strip().lower()
    t = re.sub(r"\s*\(\d{4}\)\s*$", "", t)
    t = t.replace("'", "").replace("'", "")
    t = t.replace("&", " and ")
    t = re.sub(r"[^a-z0-9]+", "-", t).strip("-")
    if not t:
        return []
    out = [t]
    bare = re.sub(r"^(the|a|an)-", "", t)
    if bare and bare != t:
        out.append(bare)
    # Collapse "and" for alternate slugs used by some catalog pages.
    collapsed = t.replace("-and-", "-")
    if collapsed != t:
        out.append(collapsed)
    # de-dupe preserve order
    seen: set[str] = set()
    uniq: list[str] = []
    for s in out:
        if s not in seen:
            seen.add(s)
            uniq.append(s)
    return uniq


def _full_vhsimage_urls(chunk: str) -> list[str]:
    found = re.findall(
        r"(?:https://vhscollector\.com)?(/sites/default/files/vhsimages/[^\"'\s>]+\.jpg)",
        chunk,
        flags=re.I,
    )
    # Drop Drupal image-style derivatives.
    return [u for u in found if "/styles/" not in u]


def _image_from_field(html: str, field: str) -> str | None:
    idx = html.find(field)
    if idx < 0:
        return None
    chunk = html[idx : idx + 2500]
    urls = _full_vhsimage_urls(chunk)
    if not urls:
        hrefs = re.findall(
            r'href="((?:https://vhscollector\.com)?/sites/default/files/vhsimages/[^"]+\.jpg)"',
            chunk,
            flags=re.I,
        )
        urls = [u for u in hrefs if "/styles/" not in u]
    if not urls:
        return None
    path = urls[0]
    return path if path.startswith("http") else VC + path


def extract_collector_art(html: str) -> dict | None:
    """Prefer dedicated spine (+ front), else combined wraparound sleeve."""
    front = _image_from_field(html, "field--name-field-vhs-imgfront")
    spine = _image_from_field(html, "field--name-field-vhs-imgspine")
    comb = _image_from_field(html, "field--name-field-vhs-imgcomb")

    if spine:
        return {
            "imageUrl": spine,
            "frontImageUrl": front,
            "kind": "spine",
            "fraction": 1.0,
        }
    if comb:
        return {
            "imageUrl": comb,
            "frontImageUrl": front,
            "kind": "comb",
            "fraction": 0.09,
        }
    return None


def lookup_vhscollector(title: str) -> dict:
    for slug in title_slugs(title):
        url = f"{VC}/movie/{slug}"
        req = urllib.request.Request(url, headers={"User-Agent": UA})
        try:
            with urllib.request.urlopen(req, timeout=18) as resp:
                html = resp.read().decode("utf-8", "replace")
                status = resp.status
        except urllib.error.HTTPError as exc:
            if exc.code == 404:
                continue
            return {"ok": False, "error": f"HTTP {exc.code}", "slug": slug}
        except Exception as exc:  # noqa: BLE001
            return {"ok": False, "error": str(exc), "slug": slug}

        if status != 200:
            continue
        art = extract_collector_art(html)
        if art:
            print(f"[vc] HIT slug={slug} kind={art['kind']}", flush=True)
            return {"ok": True, "slug": slug, "page": url, **art}
        print(f"[vc] page ok but no spine/comb slug={slug}", flush=True)
    return {"ok": False, "error": "not_found"}


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)

    def end_headers(self) -> None:
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "*")
        self.send_header("Cache-Control", "no-cache")
        super().end_headers()

    def do_OPTIONS(self) -> None:  # noqa: N802
        self.send_response(204)
        self.end_headers()

    def do_GET(self) -> None:  # noqa: N802
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path == "/ia/search":
            self._proxy_search(parsed.query)
            return
        if parsed.path.startswith("/ia/metadata/"):
            ident = urllib.parse.unquote(parsed.path[len("/ia/metadata/") :])
            self._proxy_json(f"{IA}/metadata/{urllib.parse.quote(ident)}")
            return
        if parsed.path == "/ia/health":
            self._json(200, {"ok": True})
            return
        if parsed.path == "/vc/lookup":
            self._vc_lookup(parsed.query)
            return
        super().do_GET()

    def _vc_lookup(self, query: str) -> None:
        qs = urllib.parse.parse_qs(query)
        title = (qs.get("title") or [""])[0].strip()
        slug = (qs.get("slug") or [""])[0].strip()
        if not title and slug:
            title = slug.replace("-", " ")
        if not title:
            self._json(400, {"ok": False, "error": "missing title"})
            return
        result = lookup_vhscollector(title)
        self._json(200 if result.get("ok") else 404, result)

    def _proxy_search(self, query: str) -> None:
        qs = urllib.parse.parse_qs(query)
        q = (qs.get("q") or [""])[0]
        rows = (qs.get("rows") or ["8"])[0]
        if not q:
            self._json(400, {"error": "missing q"})
            return
        params = urllib.parse.urlencode(
            {
                "q": q,
                "fl[]": ["identifier", "title", "year", "mediatype"],
                "rows": rows,
                "output": "json",
            },
            doseq=True,
        )
        self._proxy_json(f"{IA}/advancedsearch.php?{params}", log_q=q)

    def _proxy_json(self, url: str, log_q: str | None = None) -> None:
        req = urllib.request.Request(url, headers={"User-Agent": UA})
        try:
            with urllib.request.urlopen(req, timeout=20) as resp:
                body = resp.read()
                status = resp.status
        except urllib.error.HTTPError as exc:
            body = exc.read()
            status = exc.code
            print(f"[ia] HTTP {status} {url}", file=sys.stderr)
        except Exception as exc:  # noqa: BLE001
            print(f"[ia] FAIL {exc} url={url}", file=sys.stderr)
            self._json(502, {"error": str(exc)})
            return

        if log_q is not None:
            try:
                data = json.loads(body.decode("utf-8"))
                n = data.get("response", {}).get("numFound", "?")
                docs = data.get("response", {}).get("docs", [])
                titles = [d.get("title", "?") for d in docs[:3]]
                print(f"[ia] q={log_q!r} numFound={n} sample={titles}", flush=True)
            except Exception:  # noqa: BLE001
                print(f"[ia] q={log_q!r} (unparseable body)", flush=True)

        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _json(self, status: int, payload: dict) -> None:
        body = json.dumps(payload).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt: str, *args) -> None:
        msg = fmt % args
        if "/ia/" in msg or "/vc/" in msg or (args and str(args[1]).startswith("4")):
            super().log_message(fmt, *args)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=8080)
    parser.add_argument(
        "--root",
        type=Path,
        default=Path(__file__).resolve().parents[1] / "build" / "web",
    )
    args = parser.parse_args()
    root = args.root.resolve()
    if not root.is_dir():
        print(f"missing web build at {root}; run flutter build web", file=sys.stderr)
        sys.exit(1)

    global ROOT
    ROOT = root
    server = ThreadingHTTPServer(("0.0.0.0", args.port), Handler)
    print(
        f"Serving {root} on http://0.0.0.0:{args.port} (proxies /ia/* /vc/*)",
        flush=True,
    )
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nbye")


if __name__ == "__main__":
    main()
