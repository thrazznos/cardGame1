# Local image generation toolchain

This repo contains a local Apple Silicon image-generation setup rooted in `tools/imagegen/`.

Installed stack:
- ComfyUI source checkout in `tools/imagegen/.vendor/ComfyUI`
- Python 3.11 virtual environment in `tools/imagegen/.venv`
- local model storage in `tools/imagegen/models/`
- local input/output directories in `tools/imagegen/input/` and `tools/imagegen/output/`
- saved workflow templates in `tools/imagegen/workflows/`
- prompt templates in `tools/imagegen/prompts/`

Primary commands:
- Launch ComfyUI:
  - `bash tools/imagegen/launch_comfyui.sh`
- Download all core local models (SDXL + FLUX Schnell FP8 stack):
  - `tools/imagegen/.venv/bin/python tools/imagegen/download_models.py all-core`
- Download only FLUX Schnell FP8 stack:
  - `tools/imagegen/.venv/bin/python tools/imagegen/download_models.py flux-schnell-fp8`
- Run a workflow template with custom prompt:
  - `tools/imagegen/.venv/bin/python tools/imagegen/run_workflow.py sdxl_relic_concept_api.json --prompt "your prompt here"`
- Run the convenience smoke test wrapper:
  - `tools/imagegen/.venv/bin/python tools/imagegen/generate_test.py --preset sdxl`
  - `tools/imagegen/.venv/bin/python tools/imagegen/generate_test.py --preset flux`

Workflow files:
- `tools/imagegen/workflows/sdxl_relic_concept_api.json`
- `tools/imagegen/workflows/flux_schnell_fp8_api.json`

Prompt templates:
- `tools/imagegen/prompts/dungeon_steward_prompt_templates.md`

PixelLab MCP:
- Home mcporter config now includes a `pixellab` server entry.
- Hermes home config now includes a native `mcp_servers.pixellab` entry for future sessions.
- Generate and download a quick PixelLab character test drive:
  - `python3 tools/imagegen/pixellab_character_test.py "a dj charmed by a cat" --name "DJ Charmed by a Cat"`

Notes:
- The launch script is configured for Apple Silicon MPS.
- Large local artifacts are intentionally gitignored.
- Default server URL is `http://127.0.0.1:8188`.
- Current local FLUX setup uses the FP8 Schnell checkpoint plus separate text encoders. In this repo's current ComfyUI stack, the lightweight bundled `taef1` VAE is rejected by `VAELoader`, so successful default FLUX runs require `ae.safetensors`.
- If you authenticate to Hugging Face and accept the Black Forest Labs license, run: `tools/imagegen/.venv/bin/python tools/imagegen/download_models.py flux-schnell-ae-auth` to fetch `ae.safetensors`.
- `tools/imagegen/run_workflow.py flux_schnell_fp8_api.json ...` now prefers `ae.safetensors` automatically when present and fails fast with an actionable message when it is missing, instead of queueing a doomed FLUX prompt.
