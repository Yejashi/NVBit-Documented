# -*- coding: utf-8 -*-
"""Sphinx configuration for NVBit-Documented."""

import os
import re

# ---------------------------------------------------------------------------
# Version derivation from scripts/nvbit-release.env
# ---------------------------------------------------------------------------

# conf.py lives in docs/, so go up one level to reach the repository root.
_repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

_version_file = os.path.join(_repo_root, "scripts", "nvbit-release.env")

with open(_version_file, "r") as _f:
    _nvbit_version = None
    for _line in _f:
        _match = re.search(r'^NVBIT_VERSION\s*=\s*"([^"]+)"', _line)
        if _match:
            _nvbit_version = _match.group(1)
            break
    if _nvbit_version is None:
        raise RuntimeError("NVBIT_VERSION not found in scripts/nvbit-release.env")

# ---------------------------------------------------------------------------
# Project metadata
# ---------------------------------------------------------------------------

project = "NVBit-Documented"
author = "NVBit-Documented community contributors"
copyright = "2025, NVBit-Documented community contributors"

version = _nvbit_version
release = _nvbit_version

# ---------------------------------------------------------------------------
# Extensions
# ---------------------------------------------------------------------------

extensions = [
    "myst_parser",
    "breathe",
]

# ---------------------------------------------------------------------------
# Source and exclude patterns
# ---------------------------------------------------------------------------

source_suffix = {
    ".rst": "restructuredtext",
    ".md": "markdown",
}

exclude_patterns = ["_build"]

# ---------------------------------------------------------------------------
# Breathe configuration
# ---------------------------------------------------------------------------

breathe_projects = {
    "nvbit": "../doxygen/xml",
}

breathe_default_project = "nvbit"

# ---------------------------------------------------------------------------
# HTML theme
# ---------------------------------------------------------------------------

html_theme = "furo"
html_title = f"{project} {release}"
