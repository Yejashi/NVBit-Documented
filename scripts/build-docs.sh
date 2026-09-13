#!/usr/bin/env bash
set -euo pipefail

# Resolve repo root.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Obtain the NVBit SDK.
"${REPO_ROOT}/scripts/get-nvbit.sh"

# Source version configuration (build-docs.sh only needs the version string).
source "${REPO_ROOT}/scripts/nvbit-release.env"

# Export variables for downstream tooling (Doxyfile, docs/conf.py, etc.).
export NVBIT_VERSION
export NVBIT_SDK_DIR="${REPO_ROOT}/.external/${NVBIT_EXTRACTED_DIR}"

# Run Doxygen to generate XML for Breathe.
echo "[build-docs] Running Doxygen ..."
mkdir -p doxygen
doxygen "${REPO_ROOT}/Doxyfile"

# Build Sphinx documentation (warnings as errors).
echo "[build-docs] Building Sphinx documentation ..."
sphinx-build -W -b html "${REPO_ROOT}/docs" "${REPO_ROOT}/docs/_build/html"

echo "[build-docs] Documentation built successfully at docs/_build/html"
