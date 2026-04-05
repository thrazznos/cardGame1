#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import mimetypes
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, unquote, urlparse

THIS_FILE = Path(__file__).resolve()
REPO_ROOT = THIS_FILE.parents[3]
STATIC_DIR = THIS_FILE.parent / "static"
MANIFEST_PATH = REPO_ROOT / "tools" / "imagegen" / "catalog" / "imagegen_concept_art_manifest.json"
ALLOWED_ROOTS = [
    (REPO_ROOT / "tools" / "imagegen" / "output").resolve(),
    (REPO_ROOT / "tools" / "imagegen" / "derivatives").resolve(),
]


def is_allowed(path: Path) -> bool:
    resolved = path.resolve()
    for root in ALLOWED_ROOTS:
        try:
            resolved.relative_to(root)
            return True
        except ValueError:
            continue
    return False


class Handler(BaseHTTPRequestHandler):
    def _send_bytes(self, status: int, body: bytes, content_type: str) -> None:
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _send_json(self, status: int, payload: dict) -> None:
        body = json.dumps(payload, indent=2).encode("utf-8")
        self._send_bytes(status, body, "application/json; charset=utf-8")

    def _serve_static(self, rel: str) -> None:
        target = (STATIC_DIR / rel).resolve()
        try:
            target.relative_to(STATIC_DIR.resolve())
        except ValueError:
            self._send_json(403, {"error": "Forbidden"})
            return
        if not target.exists() or not target.is_file():
            self._send_json(404, {"error": f"Static file not found: {rel}"})
            return
        ctype, _ = mimetypes.guess_type(str(target))
        self._send_bytes(200, target.read_bytes(), ctype or "application/octet-stream")

    def do_HEAD(self) -> None:
        parsed = urlparse(self.path)
        if parsed.path == "/file":
            qs = parse_qs(parsed.query)
            path_value = qs.get("path", [None])[0]
            if not path_value:
                self._send_json(400, {"error": "Missing path query parameter"})
                return
            rel = Path(unquote(path_value))
            if rel.is_absolute() or ".." in rel.parts:
                self._send_json(400, {"error": "Path must be repo-relative and may not contain .."})
                return
            target = (REPO_ROOT / rel).resolve()
            if not is_allowed(target):
                self._send_json(403, {"error": "Path outside allowed roots"})
                return
            if not target.exists() or not target.is_file():
                self._send_json(404, {"error": f"File not found: {rel.as_posix()}"})
                return
            self.send_response(200)
            self.end_headers()
            return
        self.send_response(200)
        self.end_headers()

    def do_GET(self) -> None:
        parsed = urlparse(self.path)
        if parsed.path == "/api/manifest":
            if not MANIFEST_PATH.exists():
                self._send_json(404, {"error": "Manifest not found"})
                return
            self._send_bytes(200, MANIFEST_PATH.read_bytes(), "application/json; charset=utf-8")
            return

        if parsed.path == "/file":
            qs = parse_qs(parsed.query)
            path_value = qs.get("path", [None])[0]
            if not path_value:
                self._send_json(400, {"error": "Missing path query parameter"})
                return
            rel = Path(unquote(path_value))
            if rel.is_absolute() or ".." in rel.parts:
                self._send_json(400, {"error": "Path must be repo-relative and may not contain .."})
                return
            target = (REPO_ROOT / rel).resolve()
            if not is_allowed(target):
                self._send_json(403, {"error": "Path outside allowed roots"})
                return
            if not target.exists() or not target.is_file():
                self._send_json(404, {"error": f"File not found: {rel.as_posix()}"})
                return
            ctype, _ = mimetypes.guess_type(str(target))
            self._send_bytes(200, target.read_bytes(), ctype or "application/octet-stream")
            return

        rel = parsed.path.lstrip("/")
        if parsed.path in ("", "/"):
            rel = "index.html"
        self._serve_static(rel)


def main() -> None:
    parser = argparse.ArgumentParser(description="Browse the concept-art manifest and generated assets.")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8091)
    args = parser.parse_args()
    server = ThreadingHTTPServer((args.host, args.port), Handler)
    print(f"Serving concept-art browser at http://{args.host}:{args.port}")
    print(f"Manifest: {MANIFEST_PATH}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down.")
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
