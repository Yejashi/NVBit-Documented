# NVBit 1.8 and Recent Behavioral Changes

This page highlights changes that matter when reading older NVBit tutorials or
porting an existing tool. It is not a complete upstream changelog.

## NVBit 1.8

The 1.8 release adds several capabilities directly relevant to tool authors.

### TMA support

NVBit adds alpha support for Tensor Memory Accelerator tracing on Hopper and
Blackwell, including APIs that make TMA transfer addressing/metadata available
for host-side interpretation.

A pre-1.8 memory tracer can therefore be incomplete on TMA-heavy applications
unless it gains an explicit TMA path.

### Raw SASS binary encoding

`Instr::getSassBinary()` makes the instruction encoding available as bytes.
This enables tools that need bit-level ISA information without reconstructing
encoding from text.

### Green Context support

1.8 adds Green Context support. Tools should continue to keep context-owned
state scoped by `CUcontext` and avoid assuming one context per process.

### CUDA headers

The release updates its CUDA header baseline to CUDA 13.2.

## Important 1.7.7-lineage changes inherited by 1.8

### Explicit tool modules and helper launches

`nvbit_load_tool_module`, `nvbit_find_function_by_name`, and
`nvbit_launch_kernel` were added so tool-owned CUDA functions can be loaded
and launched explicitly, avoiding potential deadlocks from lazy loading.

This is particularly relevant to channel flush kernels.

### Less serialization in `mem_trace`

The example lineage was changed to avoid unnecessary kernel serialization by
default. Copying older examples that synchronize every launch can distort
stream concurrency and application behavior.

### Memory-reference limits

The 1.7.7.x fixes removed an incorrect assertion/fixed maximum assumption on
the number of MREF operands in an instruction.

General tracers should iterate decoded memory references rather than depend on
an old maximum constant.

### Channel compatibility cleanup

The 1.7.7.x line also included channel-side compatibility fixes. When using
1.8, prefer the channel header and examples from the 1.8 package rather than
mixing them with an older copied `channel.hpp`.

## Earlier graph/API changes still relevant to 1.8

Modern `nvbit_set_at_launch` supports a launch value and graph-aware
stream/launch-handle identity.

Several function-query APIs evolved to be explicitly context-qualified. If
old code fails to compile against 1.8, compare every NVBit function signature
with the 1.8 header before adding compatibility casts or wrappers.

## Porting checklist

When moving a tool from an older release to 1.8:

1. compile against **only** the 1.8 headers and library;
2. fix context-qualified function signatures;
3. review `nvbit_set_at_launch` and graph handling;
4. remove fixed-MREF assumptions;
5. register tool-owned threads;
6. migrate helper kernels to explicit module/load/launch APIs where relevant;
7. audit operand-kind switches for TMA;
8. decide whether to store `getSassBinary()` output;
9. validate on a small target before running a large trace.

## Avoid version mixing

An NVBit shared library, public headers, copied utilities, and example source
should come from the same release unless you intentionally maintain a
compatibility layer.

Many difficult-to-diagnose failures are caused by code that looks plausible
because it came from NVBit, but came from a different NVBit version.
