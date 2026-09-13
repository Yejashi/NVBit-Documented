# Troubleshooting

This page covers common issues encountered when building and using the
NVBit-Documented documentation site.

## NVBit SDK configuration

### SDK not found

**Symptom:** Doxygen fails with "input file not found" errors.

**Cause:** The NVBit 1.8 release has not been downloaded or extracted.

**Fix:** Run `./scripts/build-docs.sh` to download and extract the SDK.
Verify that the script's NVBit version configuration matches the
expected release (1.8).

### Wrong SDK version

**Symptom:** API references do not match the documented behavior.

**Cause:** An older or newer SDK version is present in the build
directory.

**Fix:** Remove any `nvbit-*` directories from the working tree and
re-run the build script. The script will download the configured
version.

### SDK extraction path

**Symptom:** Doxygen cannot locate headers.

**Cause:** The `Doxyfile` input paths do not match the extracted SDK
directory structure.

**Fix:** Verify that the `Doxyfile` `INPUT` directives point to the
correct `core/` subdirectory of the extracted SDK. Do not hardcode
absolute paths; use relative paths from the project root.

## Doxygen generation

### Doxygen not installed

**Symptom:** `./scripts/build-docs.sh` fails at the Doxygen step.

**Fix:** Install Doxygen:

```bash
# Debian/Ubuntu
sudo apt install doxygen graphviz

# Fedora
sudo dnf install doxygen graphviz
```

### Doxygen XML not generated

**Symptom:** Breathe directives resolve to empty content.

**Cause:** Doxygen failed silently or XML output was not placed in the
expected directory.

**Fix:** Run Doxygen manually to see error messages:

```bash
doxygen Doxyfile
```

Check that `doxygen/xml/` contains the expected XML files after
execution.

## Breathe integration

### Breathe not installed

**Symptom:** Sphinx build fails with "unknown directive: doxygenfile"
or similar.

**Fix:** Install Breathe and its dependencies:

```bash
pip install breathe sphinx
```

Ensure the version is compatible with your Sphinx installation.

### Breathe cross-references unresolved

**Symptom:** Sphinx build succeeds but cross-references between pages
are broken.

**Cause:** The `breathe_projects` configuration in `conf.py` does not
point to the correct Doxygen XML output directory.

**Fix:** Verify that `conf.py` contains:

```python
breathe_projects = {
    "nvbit": "doxygen/xml/"
}
breathe_default_project = "nvbit"
```

Adjust the path if your Doxygen output is in a different location.

### Missing API symbols

**Symptom:** Some expected symbols do not appear in the generated API
reference.

**Cause:** The `Doxyfile` input set does not include the relevant
headers, or the symbols are marked internal/private.

**Fix:** Check the `Doxyfile` `INPUT` and `RECURSIVE` settings. Ensure
the `core/` directory and its subdirectories are included. Symbols
marked `@internal` or `@private` in Doxygen comments are excluded by
default.

## Sphinx build issues

### Missing MyST extensions

**Symptom:** Sphinx fails to parse Markdown files with `toctree`,
`{note}`, or other MyST directives.

**Fix:** Install the MyST Parser and required extensions:

```bash
pip install myst-parser sphinxcontrib-mermaid
```

### Theme not found

**Symptom:** Sphinx build fails with "theme 'furo' not found".

**Fix:** Install the Furo theme:

```bash
pip install furo
```

### Warnings as errors

**Symptom:** The build fails due to documentation warnings.

**Fix:** Run the build without the `--fail-on-warning` flag to see the
warnings, then fix the underlying issues (broken cross-references,
missing figures, etc.).

## General advice

* Always start with a clean build (`rm -rf _build/ doxygen/xml/`) when
  troubleshooting persistent issues.
* Check that all Python dependencies are installed at the versions
  specified in `requirements-docs.txt`.
* Verify that the NVBit 1.8 release artifact is intact and matches the
  expected checksum (if a checksum is provided in the release notes).
* If you encounter issues specific to the NVBit SDK itself (not the
  documentation build), refer to the upstream
  [`NVlabs/NVBit`](https://github.com/NVlabs/NVBit) repository or
  the MICRO 2019 paper.
