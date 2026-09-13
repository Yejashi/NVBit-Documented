# NVBit-Documented

Community-maintained, non-NVIDIA documentation for **NVBit 1.8**.

This repository documents the NVIDIA NVBit dynamic binary instrumentation
SDK. It is **not** an official NVIDIA product and is maintained independently
by the community.

## Scope

* **Target SDK:** NVBit 1.8
* **Upstream repository:** [`NVlabs/NVBit`](https://github.com/NVlabs/NVBit)
* **Authoritative source:** the official NVBit 1.8 GitHub Release artifact

All technical claims in this documentation are grounded in the NVBit 1.8
release headers, source, and example tools.

## Documentation, not redistribution

This repository documents NVBit but **does not redistribute** the SDK.

* SDK archives, extracted SDK directories, binaries, and generated build
  products are excluded from version control via `.gitignore`.
* The SDK is acquired at build time through the scripts in `scripts/`.
* Do not commit release archives, generated libraries, object files, or
  Doxygen XML output.

## Building the documentation

The documentation is built with Sphinx, fed by Doxygen XML generated from
NVBit 1.8 headers.

```bash
./scripts/build-docs.sh
```

The script downloads the configured NVBit 1.8 release, extracts it into an
ignored directory, runs Doxygen, then builds Sphinx HTML into `_build/`.

## Environment note

The NVBit 1.8 release requires a Linux x86_64 or aarch64 host with an
NVIDIA GPU, CUDA >= 12, and GCC >= 8.5. This documentation repository is
**not** an NVIDIA development environment. Commands shown in these pages
that involve building or running NVBit tools are reference instructions
only and must not be executed on a non-NVIDIA host.

## License

NVBit is distributed under its own End User License Agreement (see
`EULA.txt`). This documentation repository is licensed separately and does
not convey any rights to the NVBit SDK itself.
