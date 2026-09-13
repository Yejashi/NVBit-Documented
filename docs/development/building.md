# Building the Documentation

This page describes how to build the NVBit-Documented documentation
site from a clean repository checkout.

## Prerequisites

* Python 3 with `pip`
* Node.js (for Mermaid diagram rendering, if used)
* Graphviz (for architecture diagrams, if used)

## Documentation dependencies

Install the Python packages listed in `requirements-docs.txt`:

```bash
pip install -r requirements-docs.txt
```

## Build process

The build is orchestrated by `scripts/build-docs.sh`:

```bash
./scripts/build-docs.sh
```

The script performs the following steps:

1. Downloads the configured NVBit 1.8 release artifact.
2. Extracts it into an ignored build directory.
3. Runs Doxygen against the NVBit headers to generate XML output.
4. Builds Sphinx HTML from the Markdown source files into `_build/`.

## Clean build

A clean build must be reproducible from a fresh checkout:

```bash
rm -rf _build/ doxygen/xml/ nvbit-*/
./scripts/build-docs.sh
```

The script should not depend on:

* Manually extracted SDK directories
* Absolute paths from a specific developer's machine
* Cached Doxygen output
* Accidentally committed generated files

## What the build does (and does not do)

The documentation build:

* **Does** process NVBit headers through Doxygen to generate API XML.
* **Does** render Sphinx pages from MyST Markdown source.
* **Does not** execute any CUDA code.
* **Does not** build or run NVBit example tools.
* **Does not** build or run the test applications.

If you need to build and run NVBit tools, follow the instructions in
the [Quick Start](../getting-started/quickstart.md) guide. Those
instructions require an NVIDIA GPU and must not be executed on a
non-NVIDIA host.

## CI scope

The GitHub Actions workflow (`.github/workflows/docs.yml`) runs the
documentation build on every push and pull request to the
`documentation` branch. Its scope is limited to:

1. Checking out the repository
2. Installing documentation dependencies
3. Downloading the NVBit 1.8 release
4. Generating Doxygen XML
5. Building Sphinx HTML
6. Deploying to GitHub Pages

The CI workflow does not execute CUDA code or build NVBit tools.
