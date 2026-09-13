#!/usr/bin/env bash
set -euo pipefail

# Resolve the script's directory to find nvbit-release.env relative to the repo root.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source version/asset configuration.
source "${REPO_ROOT}/scripts/nvbit-release.env"

# Cache directory for downloaded archives and extracted SDK.
CACHE_DIR="${REPO_ROOT}/.external"
ARCHIVE="${CACHE_DIR}/${NVBIT_ASSET}"

mkdir -p "${CACHE_DIR}"

# Idempotent: if a valid extracted SDK already exists, reuse it.
EXTRACTED="${CACHE_DIR}/${NVBIT_EXTRACTED_DIR}"
if [ -d "${EXTRACTED}" ]; then
  echo "[get-nvbit] SDK already extracted at ${EXTRACTED}, reusing."
else
  # Download if archive is not present.
  if [ ! -f "${ARCHIVE}" ]; then
    echo "[get-nvbit] Downloading ${NVBIT_URL} ..."
    curl -fsSL -o "${ARCHIVE}" "${NVBIT_URL}"
  fi

  # Verify SHA-256 digest before extraction.
  echo "[get-nvbit] Verifying SHA-256 of ${ARCHIVE} ..."
  ACTUAL_SHA256="$(sha256sum "${ARCHIVE}" | awk '{print $1}')"
  if [ "${ACTUAL_SHA256}" != "${NVBIT_SHA256}" ]; then
    echo "[get-nvbit] ERROR: SHA-256 mismatch!"
    echo "  expected: ${NVBIT_SHA256}"
    echo "  actual:   ${ACTUAL_SHA256}"
    rm -f "${ARCHIVE}"
    exit 1
  fi
  echo "[get-nvbit] SHA-256 OK."

  # Extract the archive.
  echo "[get-nvbit] Extracting to ${CACHE_DIR} ..."
  tar xjf "${ARCHIVE}" -C "${CACHE_DIR}"
fi

# Confirm the expected extracted directory exists.
if [ ! -d "${EXTRACTED}" ]; then
  echo "[get-nvbit] ERROR: Expected directory ${EXTRACTED} not found after extraction."
  exit 1
fi

echo "[get-nvbit] SDK ready at ${EXTRACTED}"
