# Quick Start

This page walks through the steps to obtain NVBit 1.8, build an example
tool, and run it against a test application.

## Prerequisites

From the NVBit 1.8 release README:

* **OS:** Linux
* **Host CPU:** x86_64 or aarch64
* **CUDA:** >= 12.0
* **GCC:** >= 8.5
* **Compiler tools:** `nvcc` and `nvdisasm` must be accessible on `PATH`
* **GPU hardware:** SM 3.5 through SM 12.1
* **Driver:** <= 575.xx

## Artifact contents

The NVBit 1.8 release archive contains:

* `core/` — the core instrumentation library and headers
* Example tools:
  `instr_count`, `instr_count_bb`, `instr_count_cuda_graph`,
  `mem_printf`, `mem_read_shared`, `mem_trace`, `mem_trace_tma`,
  `mov_replace`, `opcode_hist`, `record_reg_vals`
* `test-apps/vectoradd` — a minimal CUDA test application

## Building

Reference build commands from the release README:

```bash
# Build the test application
cd test-apps/vectoradd
make

# Build an example tool
cd tools/instr_count
make
```

These commands are shown for reference. They must not be executed on a
non-NVIDIA host.

## Running

To instrument a test application with the `instr_count` example tool:

```bash
LD_PRELOAD=./tools/instr_count/instr_count.so ./test-apps/vectoradd/vectoradd
```

Alternatively, use the CUDA injection path:

```bash
CUDA_INJECTION64_PATH=./tools/instr_count/instr_count.so ./test-apps/vectoradd/vectoradd
```

These are reference commands only. They require an NVIDIA GPU and must not
be run on the current host.

## What happens

1. The host loads the tool shared library (`instr_count.so`) via
   `LD_PRELOAD` or `CUDA_INJECTION64_PATH`.
2. NVBit intercepts CUDA driver calls as the application loads GPU
   functions.
3. The tool's callbacks receive notifications and may instrument
   discovered functions.
4. The instrumented application runs on the GPU with the injected
   instrumentation calls.
