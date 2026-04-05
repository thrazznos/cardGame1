#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import time
import urllib.error
import urllib.request
from pathlib import Path
from random import randint
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
WORKFLOWS_DIR = ROOT / "tools" / "imagegen" / "workflows"
DEFAULTS = {
    "__PROMPT__": "fantasy relic concept art, a brass dungeon key inset with a single glowing rune, clean silhouette, readable focal shape, dark neutral background, game asset concept",
    "__NEGATIVE__": "text, watermark, signature, border, frame, blurry, muddy, low contrast",
    "__CHECKPOINT__": "sd_xl_base_1.0.safetensors",
    "__UNET__": "flux1-schnell-fp8.safetensors",
    "__T5__": "t5xxl_fp8_e4m3fn.safetensors",
    "__CLIP__": "clip_l.safetensors",
    "__VAE__": "taef1.safetensors",
    "__WIDTH__": 1024,
    "__HEIGHT__": 1024,
    "__STEPS__": 12,
    "__CFG__": 7.0,
    "__SAMPLER__": "euler",
    "__SCHEDULER__": "normal",
    "__GUIDANCE__": 3.5,
    "__MAX_SHIFT__": 1.15,
    "__BASE_SHIFT__": 0.5,
    "__FILENAME_PREFIX__": "smoke/dungeon_steward",
}


def queue_prompt(server: str, workflow: dict[str, Any]) -> str:
    payload = json.dumps({"prompt": workflow}).encode("utf-8")
    request = urllib.request.Request(
        f"{server}/prompt",
        data=payload,
        headers={"Content-Type": "application/json"},
    )
    with urllib.request.urlopen(request) as response:
        data = json.load(response)
    return data["prompt_id"]


def fetch_history(server: str, prompt_id: str) -> dict[str, Any] | None:
    try:
        with urllib.request.urlopen(f"{server}/history/{prompt_id}") as response:
            data = json.load(response)
    except urllib.error.HTTPError as exc:
        if exc.code == 404:
            return None
        raise
    return data.get(prompt_id)


def substitute(value: Any, mapping: dict[str, Any]) -> Any:
    if isinstance(value, dict):
        return {k: substitute(v, mapping) for k, v in value.items()}
    if isinstance(value, list):
        return [substitute(v, mapping) for v in value]
    if isinstance(value, str):
        if value in mapping:
            return mapping[value]
        for key, replacement in mapping.items():
            if isinstance(replacement, str):
                value = value.replace(key, replacement)
        return value
    return value


def collect_image_paths(history: dict[str, Any]) -> list[Path]:
    results: list[Path] = []
    for node_output in history.get("outputs", {}).values():
        for image in node_output.get("images", []):
            subfolder = image.get("subfolder", "")
            results.append(ROOT / "tools" / "imagegen" / "output" / subfolder / image["filename"])
    return results


def main() -> None:
    parser = argparse.ArgumentParser(description="Run a saved ComfyUI workflow template with placeholder substitution.")
    parser.add_argument("workflow", help="Workflow filename under tools/imagegen/workflows/")
    parser.add_argument("--server", default="http://127.0.0.1:8188", help="ComfyUI base URL")
    parser.add_argument("--prompt", default=DEFAULTS["__PROMPT__"])
    parser.add_argument("--negative", default=DEFAULTS["__NEGATIVE__"])
    parser.add_argument("--filename-prefix", default=DEFAULTS["__FILENAME_PREFIX__"])
    parser.add_argument("--width", type=int, default=int(DEFAULTS["__WIDTH__"]))
    parser.add_argument("--height", type=int, default=int(DEFAULTS["__HEIGHT__"]))
    parser.add_argument("--steps", type=int, default=int(DEFAULTS["__STEPS__"]))
    parser.add_argument("--timeout", type=int, default=1800)
    parser.add_argument("--seed", type=int, default=None)
    parser.add_argument("--set", action="append", default=[], metavar="KEY=VALUE", help="Additional placeholder replacement, e.g. __SAMPLER__=euler")
    args = parser.parse_args()

    workflow_path = WORKFLOWS_DIR / args.workflow
    workflow = json.loads(workflow_path.read_text())

    mapping: dict[str, Any] = {
        **DEFAULTS,
        "__PROMPT__": args.prompt,
        "__NEGATIVE__": args.negative,
        "__WIDTH__": args.width,
        "__HEIGHT__": args.height,
        "__STEPS__": args.steps,
        "__FILENAME_PREFIX__": args.filename_prefix,
        "__SEED__": args.seed if args.seed is not None else randint(1, 2**31 - 1),
    }

    for item in args.set:
        if "=" not in item:
            raise SystemExit(f"Invalid --set value: {item}")
        key, raw = item.split("=", 1)
        try:
            mapping[key] = json.loads(raw)
        except json.JSONDecodeError:
            mapping[key] = raw

    resolved_workflow = substitute(workflow, mapping)
    prompt_id = queue_prompt(args.server, resolved_workflow)
    print(f"Queued prompt_id={prompt_id}")

    deadline = time.time() + args.timeout
    while time.time() < deadline:
        history = fetch_history(args.server, prompt_id)
        if history and history.get("outputs"):
            paths = collect_image_paths(history)
            if not paths:
                raise SystemExit("Workflow finished but no image outputs were found.")
            for path in paths:
                print(f"Generated: {path}")
            return
        time.sleep(2)

    raise SystemExit("Timed out waiting for ComfyUI generation to finish.")


if __name__ == "__main__":
    main()
