#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILD_DIR="${ROOT_DIR}/build/linux"
BUILD_TYPE="${BUILD_TYPE:-Release}"

find_tbb_file() {
	local name="$1"
	local path=""

	if command -v ldconfig >/dev/null 2>&1 && [[ "${name}" == *.so* ]]; then
		path="$(ldconfig -p 2>/dev/null | awk -v n="${name}" '$1 == n {print $NF; exit}')"
	fi

	if [[ -z "${path}" ]]; then
		local search_dirs=(
			/lib
			/lib64
			/lib/x86_64-linux-gnu
			/usr/lib
			/usr/lib64
			/usr/lib/x86_64-linux-gnu
			/usr/local/lib
			/usr/local/lib64
		)

		local dir
		for dir in "${search_dirs[@]}"; do
			if [[ -e "${dir}/${name}" ]]; then
				path="${dir}/${name}"
				break
			fi
		done
	fi

	if [[ -z "${path}" ]]; then
		path="$(find /lib /usr/lib /usr/local/lib -maxdepth 3 -name "${name}" 2>/dev/null | head -n 1 || true)"
	fi

	if [[ -n "${path}" ]]; then
		printf '%s\n' "${path}"
		return 0
	fi

	return 1
}

detect_tbb() {
	find_tbb_file "libtbb.so.12" >/dev/null
}

bundle_tbb_libs() {
	local dest="${BUILD_DIR}"
	mkdir -p "${dest}"

	local bundled=0
	local file
	for file in libtbb.so.12 libtbb.so libtbb.a; do
		local source=""
		if source="$(find_tbb_file "${file}")" && [[ -n "${source}" ]]; then
			cp -u "${source}" "${dest}/"
			bundled=1
		fi
	done

	if [[ "${bundled}" -eq 0 ]]; then
		echo "Warning: Unable to locate TBB libraries to bundle into ${dest}" >&2
	else
		echo "Bundled TBB libraries into ${dest}"
	fi
}

if ! command -v cmake >/dev/null 2>&1 || ! command -v make >/dev/null 2>&1 || ! detect_tbb; then
	if command -v apt-get >/dev/null 2>&1; then
		sudo apt-get update
		sudo apt-get install -y build-essential cmake libtbb-dev libtbb12
	else
		echo "Error: cmake, make, and Intel TBB must be installed or available on PATH." >&2
		echo "Please install the required packages manually (e.g., libtbb-dev and libtbb12) and re-run." >&2
		exit 1
	fi
fi

cmake -S "${ROOT_DIR}" -B "${BUILD_DIR}" -DCMAKE_BUILD_TYPE="${BUILD_TYPE}"
cmake --build "${BUILD_DIR}" --config "${BUILD_TYPE}" -- -j"$(nproc)"

bundle_tbb_libs
