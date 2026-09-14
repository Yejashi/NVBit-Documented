# Release Package Layout

The NVBit GitHub repository and the NVBit **release package** are not
interchangeable. Tool development should be anchored to the release package
because that is where the versioned core library, public headers, and examples
are distributed together.

## Core

`core/` is the center of the SDK. User-facing material includes the main
NVBit API, instruction representation, register helpers, and utilities used by
the examples.

Commonly encountered interfaces include:

- `nvbit.h` — callbacks, function discovery, instruction access,
  instrumentation insertion, call-argument construction, launch control, and
  tool-module helpers;
- instruction-related headers — `Instr`, operand descriptions, predicates,
  memory-reference metadata, and opcode information;
- register read/write support used by examples that observe or replace
  register values;
- `utils/channel.hpp` — the device/host channel abstraction used by
  high-volume tracing examples.

The documentation build runs Doxygen over this release directory rather than
a separately cloned SDK tree.

## Tools

The 1.8 package includes examples that cover different instrumentation
patterns rather than merely different output formats.

| Example | Main idea |
|---|---|
| `instr_count` | inject a lightweight counting call |
| `instr_count_bb` | aggregate work at basic-block granularity |
| `instr_count_cuda_graph` | handle CUDA Graph launches |
| `opcode_hist` | classify instructions and collect dynamic counts |
| `record_reg_vals` | pass runtime register values to injected code |
| `mem_printf` | inspect memory operations with direct device output |
| `mem_read_shared` | focus on shared-memory behavior |
| `mem_trace` | stream memory records to a host receiver |
| `mem_trace_tma` | handle TMA-specific operands and transfer metadata |
| `mov_replace` | demonstrate instruction replacement rather than observation |

The examples are especially valuable because they show which API calls belong
to instrumentation time, launch time, and device execution time.

## Test applications

`test-apps/` contains CUDA programs intended to make the examples easy to
exercise. `vectoradd` is the usual first target because the program is small
and its expected output is obvious.

A test application is a target program, not part of the NVBit tool. The same
tool shared object can be injected into other CUDA applications subject to
NVBit's compatibility constraints.

## Generated tool artifacts

When an example is built, its directory may contain a combination of host
objects, device-code objects or cubins, and the final shared object. Those
artifacts are generated from the release and should not be copied into this
documentation repository.

Some modern examples also embed a device module in the tool and explicitly
load/find/launch a helper kernel with NVBit's tool-module APIs. That pattern is
covered in [Tool Modules and Tool Kernels](../guides/tool-modules.md).

## Why the package matters for documentation

Several NVBit APIs have evolved across releases. A header copied from an older
tutorial may compile differently or encode outdated assumptions about
channels, graph launches, memory-reference operands, or helper kernels.

This project therefore treats the extracted 1.8 package as the primary
versioned object:

```text
release archive
    |
    +--> headers --------> Doxygen/Breathe reference
    |
    +--> examples -------> behavioral patterns explained in guides
    |
    +--> test apps ------> reproducible learning targets
```

When creating a custom tool, keep the tool source next to or pointed at one
known NVBit release instead of mixing headers and libraries from different
versions.
