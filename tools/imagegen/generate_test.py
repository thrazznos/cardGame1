#!/usr/bin/env python3
from __future__ import annotations

import argparse
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_PROMPT = (
    "fantasy relic concept art, a brass dungeon key inset with a single glowing rune, "
    "clean silhouette, readable focal shape, dark neutral background, game asset concept"
)
WORKFLOW_BY_PRESET = {
    "sdxl": "sdxl_relic_concept_api.json",
    "flux": "flux_schnell_fp8_api.json",
}


def main() -> None:
    parser = argparse.ArgumentParser(description="Convenience wrapper for local image-generation smoke tests.")
    parser.add_argument("--preset", choices=sorted(WORKFLOW_BY_PRESET.keys()), default="sdxl")
    parser.add_argument("--prompt", default=DEFAULT_PROMPT)
    parser.add_argument("--timeout", type=int, default=1800)
    args = parser.parse_args()

    cmd = [
        str(ROOT / "tools" / "imagegen" / ".venv" / "bin" / "python"),
        str(ROOT / "tools" / "imagegen" / "run_workflow.py"),
        WORKFLOW_BY_PRESET[args.preset],
        "--prompt",
        args.prompt,
        "--timeout",
        str(args.timeout),
        "--filename-prefix",
        f"smoke/{args.preset}",
    ]
    subprocess.run(cmd, check=True)


if __name__ == "__main__":
    main()
