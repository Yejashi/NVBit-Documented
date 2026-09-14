# NVBit-Documented

Community-maintained, non-NVIDIA documentation for **NVBit 1.8**.

This project turns the NVBit 1.8 release package into a navigable manual for
people writing SASS-level dynamic instrumentation tools. The documentation is
built from two sources:

- handwritten guides that explain lifecycle, control flow, instrumentation,
  data movement, and example-tool design;
- API material extracted from the **official NVBit 1.8 release artifact** with
  Doxygen and integrated into Sphinx with Breathe.

This repository is independent of NVIDIA and is not official NVBit
documentation.

## What is documented

The documentation covers the full path from first use to non-trivial tooling:

- obtaining and validating the 1.8 release;
- the contents and roles of the release directories;
- how an NVBit tool is loaded into a CUDA process;
- context, tool, CUDA-event, CUDA Graph, and termination callbacks;
- discovery of kernels and related device functions;
- the `Instr` model, predicates, operands, memory references, and SASS bytes;
- insertion of device calls and the `nvbit_add_call_arg_*` families;
- launch-time values and CUDA Graph launch handles;
- register and uniform-register capture;
- device-to-host channels and receiver-thread registration;
- explicit tool modules and tool-kernel launching;
- conventional memory tracing and the 1.8 TMA tracing path;
- detailed walkthroughs of the shipped example tools;
- version-specific behavior that matters when porting older NVBit tools.

## Version and source of truth

The documentation target is **NVBit 1.8**. The build configuration is pinned
to the official x86_64 release asset and its SHA-256 digest in
`scripts/nvbit-release.env`.

The release archive is not committed to this repository. A clean build
downloads it from `NVlabs/NVBit`, verifies the digest, extracts it under the
ignored `.external/` directory, generates Doxygen XML from its public headers,
and then builds the Sphinx site.

When older tutorials or papers disagree with the 1.8 release, the 1.8 release
takes precedence.

## Build the site

Install the documentation dependencies and run:

```bash
python -m pip install -r requirements-docs.txt
./scripts/build-docs.sh
```

The generated site is written to:

```text
docs/_build/html/
```

The build uses `sphinx-build -W`, so unresolved references and documentation
warnings fail CI.

## NVBit environment requirements

NVBit itself runs on Linux on x86_64 or aarch64 hosts with supported NVIDIA
GPUs. NVBit 1.8 requires CUDA 12 or newer and a sufficiently recent host
compiler; consult the upstream release README for the exact support matrix.
The documentation build does **not** execute CUDA code and therefore can run on
a normal GitHub Actions runner.

## Documentation, not redistribution

Do not commit NVBit SDK archives, extracted release directories, binaries,
generated libraries, Doxygen XML, or built HTML. The repository documents the
SDK while leaving NVIDIA's release and license terms intact.

See `EULA.txt` for the NVBit license text distributed with this repository's
documentation setup.
