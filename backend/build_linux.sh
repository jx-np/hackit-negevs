#!/usr/bin/env bash
# Cross-compile the Community Scam Shield API server for Linux amd64.
# Output: builds/hackit-16-backend-linux-amd64
#
# Usage:
#   ./build_linux.sh
#
# Run from the backend module directory (where go.mod lives). The script is
# location-independent: it cd's to its own directory first.
set -euo pipefail

# Move to the script's directory (the backend module root).
cd "$(dirname "$0")"

OUT_DIR="builds"
OUT_NAME="hackit-16-backend-linux-amd64"
OUT_PATH="${OUT_DIR}/${OUT_NAME}"

mkdir -p "${OUT_DIR}"

# Build metadata stamped into the binary (best-effort; empty if git is absent).
VERSION="$(git describe --tags --always --dirty 2>/dev/null || echo dev)"
COMMIT="$(git rev-parse --short HEAD 2>/dev/null || echo none)"
BUILD_TIME="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

echo "Building ${OUT_PATH}"
echo "  version=${VERSION} commit=${COMMIT} time=${BUILD_TIME}"

# CGO disabled -> fully static binary that runs on any linux/amd64 host.
# -trimpath removes local filesystem paths; -s -w strip debug info for size.
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
  go build \
    -trimpath \
    -ldflags "-s -w -X main.version=${VERSION} -X main.commit=${COMMIT} -X main.buildTime=${BUILD_TIME}" \
    -o "${OUT_PATH}" \
    ./cmd/api

echo "Done: ${OUT_PATH}"
ls -lh "${OUT_PATH}"
