#!/usr/bin/env bash
#
# Serve Cloudflare/clef-flash with SGLang on a GPU host.
#
# This is a SEPARATE process from the AI API server (which stays CPU-only).
# Running this is an ops step — the Python app is just an HTTP client to it.
#
# Prerequisites:
#   - A capable GPU (single-GPU H200 example below; adjust --gpus / --shm-size
#     for your hardware).
#   - Docker with the NVIDIA container runtime.
#   - Model weights are fetched from Hugging Face into the mounted cache on
#     first run. KEEP WEIGHTS OUT OF GIT.
#
# After it starts, the server answers /v1/systemone at:
#   http://<host>:30000/v1/systemone
#
# Point the AI server's CLEF_BASE_URL at this port DIRECTLY (not a gateway):
# /v1/systemone may not be reachable through the SGLang model gateway.
set -euo pipefail

docker run --gpus all --shm-size 32g -p 30000:30000 \
  -v "$HOME/.cache/huggingface:/root/.cache/huggingface" \
  --ipc=host \
  lmsysorg/sglang:dev-clef \
  sglang serve \
    --model-path Cloudflare/clef-flash \
    --host 0.0.0.0 \
    --port 30000
