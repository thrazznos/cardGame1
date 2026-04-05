#!/usr/bin/env python3
from __future__ import annotations

import argparse
import shutil
from pathlib import Path

from huggingface_hub import hf_hub_download

ROOT = Path(__file__).resolve().parents[2]
MODELS_DIR = ROOT / "tools" / "imagegen" / "models"

PRESETS = {
    "sdxl-base": [
        {
            "repo_id": "stabilityai/stable-diffusion-xl-base-1.0",
            "filename": "sd_xl_base_1.0.safetensors",
            "local_dir": MODELS_DIR / "checkpoints",
        },
    ],
    "flux-schnell-fp8": [
        {
            "repo_id": "Comfy-Org/flux1-schnell",
            "filename": "flux1-schnell-fp8.safetensors",
            "local_dir": MODELS_DIR / "diffusion_models",
        },
        {
            "repo_id": "comfyanonymous/flux_text_encoders",
            "filename": "clip_l.safetensors",
            "local_dir": MODELS_DIR / "text_encoders",
        },
        {
            "repo_id": "comfyanonymous/flux_text_encoders",
            "filename": "t5xxl_fp8_e4m3fn.safetensors",
            "local_dir": MODELS_DIR / "text_encoders",
        },
        {
            "repo_id": "madebyollin/taef1",
            "filename": "diffusion_pytorch_model.safetensors",
            "local_dir": MODELS_DIR / "vae",
            "rename_to": "taef1.safetensors",
        },
    ],
    "flux-schnell-ae-auth": [
        {
            "repo_id": "black-forest-labs/FLUX.1-schnell",
            "filename": "ae.safetensors",
            "local_dir": MODELS_DIR / "vae",
        },
    ],
}
PRESETS["all-core"] = PRESETS["sdxl-base"] + PRESETS["flux-schnell-fp8"]


def download_files(files: list[dict[str, object]]) -> None:
    for spec in files:
        repo_id = str(spec["repo_id"])
        filename = str(spec["filename"])
        target_dir = Path(spec["local_dir"])
        rename_to = spec.get("rename_to")
        target_dir.mkdir(parents=True, exist_ok=True)
        print(f"Downloading {repo_id}/{filename} -> {target_dir}")
        path = Path(
            hf_hub_download(
                repo_id=repo_id,
                filename=filename,
                local_dir=target_dir,
            )
        )
        if rename_to:
            renamed_path = target_dir / str(rename_to)
            if path != renamed_path:
                shutil.copy2(path, renamed_path)
                path = renamed_path
        print(f"Saved: {path}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Download local image-generation models.")
    parser.add_argument(
        "preset",
        nargs="?",
        default="all-core",
        choices=sorted(PRESETS.keys()),
        help="Model preset to download.",
    )
    args = parser.parse_args()
    download_files(PRESETS[args.preset])


if __name__ == "__main__":
    main()
