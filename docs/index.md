# NVBit 1.8 Documentation

NVBit is a dynamic binary instrumentation framework for NVIDIA GPU machine
code. It lets a tool inspect decoded SASS instructions, inject calls to
device-side analysis routines, choose whether instrumented variants execute,
and collect the resulting data on the host.

This manual targets **NVBit 1.8** and is written around the behavior and
examples shipped with that release.

```{admonition} Start here
:class: tip
If you have never written an NVBit tool, read **Quick Start**, **Architecture**,
**Callback Lifecycle**, and **Writing an NVBit Tool** in that order.
```

## Getting Started

```{toctree}
:maxdepth: 2
:caption: Getting Started

getting-started/quickstart
getting-started/release-layout
getting-started/first-tool
```

## Concepts

```{toctree}
:maxdepth: 2
:caption: Concepts

concepts/architecture
concepts/lifecycle
concepts/functions
concepts/instructions-operands
concepts/instrumentation
concepts/cuda-graphs
concepts/tma
```

## Guides

```{toctree}
:maxdepth: 2
:caption: Guides

guides/writing-tool
guides/call-arguments
guides/instrument-memory
guides/register-values
guides/channels
guides/tool-modules
guides/tma-tracing
```

## Shipped examples

```{toctree}
:maxdepth: 2
:caption: Examples

examples/overview
examples/instr-count
examples/mem-trace
examples/record-reg-vals
examples/mem-trace-tma
```

## API reference

```{toctree}
:maxdepth: 2
:caption: API Reference

reference/index
reference/core-api
reference/instruction-api
reference/call-argument-api
reference/tool-support
reference/version-notes
```

## Development and troubleshooting

```{toctree}
:maxdepth: 2
:caption: Development

development/building
troubleshooting
```

## The mental model

An NVBit tool has two cooperating halves:

1. **Host-side control code** receives NVBit callbacks, discovers
   `CUfunction` objects, inspects their `Instr` objects, inserts
   instrumentation calls, supplies launch-time state, and processes results.
2. **Device-side instrumentation code** is invoked from the modified GPU
   instruction stream. It sees values that the host requested through
   `nvbit_add_call_arg_*` APIs and can count, trace, modify, or communicate
   those values.

A typical tool therefore has three different timescales that should not be
confused:

- **instrumentation time**: inspect SASS and declare injected calls;
- **kernel-launch time**: choose whether instrumentation is active and attach
  launch-specific values;
- **device execution time**: injected routines run for the threads/warps that
  execute the selected instructions.

The rest of this manual makes those boundaries explicit.

## Source of truth

The build downloads the official NVBit 1.8 x86_64 release archive, verifies
its SHA-256 digest, and extracts it before running Doxygen. Technical claims in
the handwritten documentation are intended to agree with the same release,
with the public headers and shipped examples used as primary evidence.

The project does not treat older tutorials as normative when 1.8 behavior has
changed.
