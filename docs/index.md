# NVBit 1.8 Documentation

Community-maintained documentation for the NVBit dynamic binary
instrumentation SDK, targeting NVBit 1.8.

## Contents

```{toctree}
:maxdepth: 2
:caption: Getting Started

getting-started/quickstart
```

```{toctree}
:maxdepth: 2
:caption: Concepts

concepts/architecture
concepts/lifecycle
concepts/instrumentation
```

```{toctree}
:maxdepth: 2
:caption: Guides

guides/instrument-memory
guides/channels
```

```{toctree}
:maxdepth: 2
:caption: Examples

examples/overview
```

```{toctree}
:maxdepth: 2
:caption: API Reference

reference/index
```

```{toctree}
:maxdepth: 2
:caption: Development

development/building
```

```{toctree}
:maxdepth: 2
:caption: Troubleshooting

troubleshooting
```

## About NVBit

NVBit is a research prototype dynamic binary instrumentation library for
NVIDIA GPUs. It allows tools to inspect and modify the compiled SASS code
of GPU functions at load time, without requiring recompilation of the
target application.

This documentation is organized to support three primary workflows:

* **Getting Started** — obtain NVBit 1.8, build a tool, and run a simple
  instrumentation example.
* **Concepts** — understand the architecture, callback lifecycle, and
  instrumentation model.
* **Guides** — task-oriented walkthroughs for common instrumentation
  scenarios such as memory tracing and channel communication.

## Source of truth

Technical claims about NVBit behavior are grounded in the NVBit 1.8
release in this order of preference:

1. NVBit 1.8 release artifact
2. NVBit 1.8 public headers
3. NVBit 1.8 source distributed in the release
4. NVBit 1.8 example tools
5. NVBit 1.8 release notes
6. official `NVlabs/NVBit` repository content
7. NVBit MICRO 2019 paper

When older sources conflict with NVBit 1.8, the 1.8 release is authoritative.
