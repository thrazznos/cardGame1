#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

if [ ! -x "$ROOT/tools/imagegen/.venv/bin/python" ]; then
  echo "Missing virtual environment at tools/imagegen/.venv" >&2
  echo "Re-run the local image generation setup." >&2
  exit 1
fi

mkdir -p \
  "$ROOT/tools/imagegen/custom_nodes" \
  "$ROOT/tools/imagegen/input" \
  "$ROOT/tools/imagegen/output" \
  "$ROOT/tools/imagegen/temp" \
  "$ROOT/tools/imagegen/user" \
  "$ROOT/tools/imagegen/models/checkpoints" \
  "$ROOT/tools/imagegen/models/diffusion_models" \
  "$ROOT/tools/imagegen/models/text_encoders" \
  "$ROOT/tools/imagegen/models/loras" \
  "$ROOT/tools/imagegen/models/controlnet" \
  "$ROOT/tools/imagegen/models/vae"

export PYTORCH_ENABLE_MPS_FALLBACK=1

exec "$ROOT/tools/imagegen/.venv/bin/python" "$ROOT/tools/imagegen/.vendor/ComfyUI/main.py" \
  --listen 127.0.0.1 \
  --port "${COMFYUI_PORT:-8188}" \
  --base-directory "$ROOT/tools/imagegen" \
  --disable-auto-launch \
  --force-fp16 \
  --fp32-vae \
  --use-pytorch-cross-attention
