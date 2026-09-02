#!/usr/bin/env python3
"""Serve Flutter web build and proxy Internet Archive JSON (CORS-safe)."""

from __future__ import annotations

import argparse
import json
import sys
import urllib.error
import urllib.parse
import urllib.request
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

UA = "vhsfin-proxy/0.1 (kids jellyfin client)"
IA = "https://archive.org"


class Handler(SimpleHTTPRequestHandler):
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
        super().do_GET()

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
        # Keep access log quiet except IA + errors.
        msg = fmt % args
        if "/ia/" in msg or args and str(args[1]).startswith("4"):
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

    Handler.directory = str(root)
    server = ThreadingHTTPServer(("0.0.0.0", args.port), Handler)
    print(f"Serving {root} on http://0.0.0.0:{args.port} (IA proxy /ia/*)", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nbye")


if __name__ == "__main__":
    main()
