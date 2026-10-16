set -euo pipefail

docker run --gpus all --shm-size 32g -p 30000:30000 \
  -v "$HOME/.cache/huggingface:/root/.cache/huggingface" \
  --ipc=host \
  lmsysorg/sglang:dev-clef \
  sglang serve \
    --model-path Cloudflare/clef-flash \
    --host 0.0.0.0 \
    --port 30000
