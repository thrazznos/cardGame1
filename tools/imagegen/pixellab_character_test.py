#!/usr/bin/env python3
from __future__ import annotations

import argparse
import base64
import json
import re
import subprocess
import time
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUTPUT_DIR = ROOT / "tools" / "imagegen" / "output" / "pixellab"
CHARACTER_ID_RE = re.compile(r"Character ID:\*\* `([^`]+)`")
IMAGE_URL_RE = re.compile(r"\[([a-z-]+)\]\((https://[^)]+/rotations/[^)]+\.png[^)]*)\)")


def run_mcporter(args: list[str]) -> dict:
    result = subprocess.run(
        ["npx", "-y", "mcporter", *args],
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=True,
    )
    return json.loads(result.stdout)


def extract_text(payload: dict) -> str:
    return "\n".join(block.get("text", "") for block in payload.get("content", []) if block.get("type") == "text")


def save_preview_image(payload: dict, name_slug: str) -> list[Path]:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    saved: list[Path] = []
    for index, block in enumerate(payload.get("content", []), start=1):
        if block.get("type") != "image":
            continue
        data = block.get("data")
        mime = block.get("mimeType", "image/png")
        suffix = ".png" if mime == "image/png" else ".bin"
        target = OUTPUT_DIR / f"{name_slug}_preview_{index}{suffix}"
        target.write_bytes(base64.b64decode(data))
        saved.append(target)
    return saved


def create_character(description: str, name: str) -> str:
    payload = run_mcporter([
        "call",
        "pixellab.create_character",
        f"description={description}",
        f"name={name}",
        "mode=standard",
        "n_directions:4",
        "size:48",
        "view=side",
        "--output",
        "json",
    ])
    text = extract_text(payload)
    match = CHARACTER_ID_RE.search(text)
    if not match:
        raise SystemExit(f"Could not parse character id from response:\n{text}")
    return match.group(1)


def get_character_payload(character_id: str) -> dict:
    return run_mcporter([
        "call",
        "pixellab.get_character",
        f"character_id={character_id}",
        "--output",
        "json",
    ])


def poll_character(character_id: str, timeout: int) -> dict:
    deadline = time.time() + timeout
    while time.time() < deadline:
        payload = get_character_payload(character_id)
        text = extract_text(payload)
        print(text[:1000])
        if "Rotation Images:" in text:
            return payload
        time.sleep(20)
    raise SystemExit("Timed out waiting for PixelLab character generation.")


def download_rotations(text: str, name_slug: str) -> list[Path]:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    paths: list[Path] = []
    for direction, url in IMAGE_URL_RE.findall(text):
        target = OUTPUT_DIR / f"{name_slug}_{direction}.png"
        try:
            urllib.request.urlretrieve(url, target)
            paths.append(target)
        except Exception as exc:
            print(f"Warning: could not download {direction} rotation from signed URL: {exc}")
    return paths


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate a PixelLab character via MCP and save its preview/rotation images.")
    parser.add_argument("prompt", nargs="?", default=None, help="Character prompt/description")
    parser.add_argument("--name", default="PixelLab Test Drive")
    parser.add_argument("--character-id", default=None, help="Reuse an existing PixelLab character id instead of creating a new one")
    parser.add_argument("--timeout", type=int, default=900)
    args = parser.parse_args()

    slug = re.sub(r"[^a-z0-9]+", "_", args.name.lower()).strip("_") or "pixellab_character"
    if args.character_id:
        character_id = args.character_id
    else:
        if not args.prompt:
            raise SystemExit("Either provide a prompt or pass --character-id.")
        character_id = create_character(args.prompt, args.name)
        print(f"Queued character_id={character_id}")

    payload = poll_character(character_id, args.timeout)
    text = extract_text(payload)
    saved = save_preview_image(payload, slug)
    saved.extend(download_rotations(text, slug))
    for path in saved:
        print(f"Saved: {path}")


if __name__ == "__main__":
    main()
