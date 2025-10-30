#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILD_DIR="${ROOT_DIR}/build/linux"
BUILD_TYPE="${BUILD_TYPE:-Release}"

detect_tbb() {
	cmake -P /dev/stdin <<'EOF' >/dev/null 2>&1
find_package(TBB QUIET)
EOF
}

if ! command -v cmake >/dev/null 2>&1 || ! command -v make >/dev/null 2>&1 || ! detect_tbb; then
	if command -v apt-get >/dev/null 2>&1; then
		sudo apt-get update
		sudo apt-get install -y build-essential cmake libtbb-dev
	else
		echo "Error: cmake, make, and Intel TBB must be installed or available on PATH." >&2
		echo "Please install the required packages manually (e.g., libtbb-dev) and re-run." >&2
		exit 1
	fi
fi

cmake -S "${ROOT_DIR}" -B "${BUILD_DIR}" -DCMAKE_BUILD_TYPE="${BUILD_TYPE}"
cmake --build "${BUILD_DIR}" --config "${BUILD_TYPE}" -- -j"$(nproc)"
