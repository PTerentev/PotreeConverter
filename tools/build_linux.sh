#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILD_DIR="${ROOT_DIR}/build"
DIST_DIR="${BUILD_DIR}/binaries"

mkdir -p "$BUILD_DIR" "$DIST_DIR"

cd "$BUILD_DIR"

# Configure
cmake "$ROOT_DIR" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_RUNTIME_OUTPUT_DIRECTORY="$DIST_DIR"

# Build
cmake --build . --config Release -- -j"$(nproc)"