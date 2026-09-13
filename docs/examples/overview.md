# Example Tools

This page provides an overview of the example tools included in the
NVBit 1.8 release.

## Purpose

The example tools demonstrate common instrumentation patterns and serve
as starting points for building custom analysis tools. Each tool is
self-contained and can be built and run independently.

## Example inventory

| Tool | Description |
|---|---|
| `instr_count` | Counts the total number of executed instructions in each kernel |
| `instr_count_bb` | Counts instructions at the basic-block level |
| `instr_count_cuda_graph` | Counts instructions in CUDA Graph kernels |
| `mem_printf` | Prints memory operation details from the device |
| `mem_read_shared` | Traces shared memory reads |
| `mem_trace` | Traces all memory loads and stores with channel-based host communication |
| `mem_trace_tma` | Traces TMA (Tensor Memory Accelerator) operations |
| `mov_replace` | Replaces specific move instructions |
| `opcode_hist` | Collects an opcode frequency histogram |
| `record_reg_vals` | Records register values at specific points |

## Common patterns

Across these examples, several patterns recur:

### Callback implementation

Tools register one or more NVBit callbacks (e.g., `nvbit_at_init`,
`nvbit_at_cuda_event`, `nvbit_at_term`) to receive lifecycle
notifications.

### Function discovery

Tools discover functions to instrument using either all functions in a
context, or a subset obtained via `nvbit_get_related_functions()`.

### Instruction filtering

Tools iterate over `nvbit_get_instrs()` results and filter by opcode,
operands, or other instruction properties.

### Insertion

Tools insert device routine calls at specific points using
`nvbit_insert_call()`, passing guard predicates and argument values.

### Host communication

Tools that need to report data to the host use NVBit channels
(`ChannelDev` / `ChannelHost`) to transfer records from device to host
code.

## Building and running

Reference commands from the NVBit 1.8 release README:

```bash
# Build a specific tool
cd tools/<tool_name>
make

# Run with a test application
LD_PRELOAD=./tools/<tool_name>/<tool_name>.so ./test-apps/vectoradd/vectoradd
```

These are reference commands only. They must not be executed on a
non-NVIDIA host.
