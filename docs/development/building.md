# Building the Documentation

The documentation build is intentionally release-driven: a clean checkout
downloads the exact NVBit 1.8 binary release artifact before API extraction.

## Requirements

Install:

- Python 3;
- Doxygen;
- Graphviz;
- the packages in `requirements-docs.txt`.

For example on Ubuntu:

```bash
sudo apt-get install doxygen graphviz
python -m pip install -r requirements-docs.txt
```

No NVIDIA GPU is required because the docs build does not execute CUDA.

## One-command build

From the repository root:

```bash
./scripts/build-docs.sh
```

The script performs:

```text
scripts/get-nvbit.sh
    |
    +--> download configured 1.8 asset
    +--> SHA-256 verification
    +--> extract under .external/
    |
Doxygen
    |
    +--> parse release core headers
    +--> write doxygen/xml
    |
Sphinx + MyST + Breathe
    |
    +--> handwritten Markdown
    +--> generated API declarations
    +--> docs/_build/html
```

## Release configuration

`scripts/nvbit-release.env` is the single source for:

- NVBit version;
- release asset filename;
- download URL;
- SHA-256 digest;
- extracted directory name.

Changing the documented NVBit version is therefore a deliberate release update,
not a silent "download latest" operation.

## Clean rebuild

To ensure no cached release or generated output is masking a problem:

```bash
rm -rf .external doxygen docs/_build
./scripts/build-docs.sh
```

This should succeed without manually copying any NVBit files into the repo.

## Doxygen

`Doxyfile` points at the extracted release's `core/` headers and emits XML
only. Breathe reads that XML during the Sphinx build.

Do not commit Doxygen XML. Regenerate it from the pinned release.

## Sphinx

The site uses:

- Sphinx;
- MyST Parser for Markdown;
- Breathe for Doxygen XML;
- Furo for HTML presentation.

CI runs `sphinx-build -W`, making warnings fatal. New pages should therefore
be added to a toctree, links should resolve, and Breathe directives should name
symbols that exist in the pinned release.

## GitHub Actions

The documentation workflow runs on pushes and pull requests targeting the
`documentation` branch.

For a direct push it:

1. checks out the branch;
2. installs Doxygen/Graphviz and Python dependencies;
3. downloads/verifies/extracts NVBit 1.8;
4. generates Doxygen XML;
5. builds Sphinx;
6. uploads/deploys the Pages artifact.

A successful CI build is therefore also a validation that the pinned upstream
release asset remains downloadable and matches the expected digest.

## What CI does not validate

The docs workflow does not:

- compile every NVBit example;
- run a CUDA application;
- execute on every supported GPU architecture;
- validate runtime semantics of a custom tool.

Runtime claims should still be checked against the release source/examples and,
where practical, exercised on supported NVIDIA hardware.
