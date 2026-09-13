# Instrumenting Memory Operations

This guide walks through the instrumentation approach used by the
`mem_trace` example tool, which instruments memory-reference operations
in GPU kernels.

## Goal

Record every memory load and store executed by a kernel, including
predicate state, opcode, memory address, and launch-time context.

## Step 1: Discover functions

The tool uses `nvbit_get_related_functions()` to find all functions
reachable from the kernel entry point(s) of interest. This ensures
that memory operations in called device functions are also captured.

## Step 2: Duplicate guard

The tool maintains a `std::set` of function handles that have already
been processed. Before instrumenting a function, it checks whether the
function handle is already in the set. If so, the function is skipped.
This prevents duplicate instrumentation when a function is reachable
through multiple paths.

## Step 3: Get instructions

For each unique function, call `nvbit_get_instrs()` to obtain the list
of decoded SASS instructions.

## Step 4: Filter memory references

Iterate over the instruction list and filter for memory-reference
opcodes. The tool checks the opcode of each instruction to determine
whether it performs a load or store.

## Step 5: Insert instrumentation calls

For each memory-reference instruction, insert a call to the device
routine `instrument_mem` using `nvbit_insert_call()` with
`IPOINT_BEFORE`. The call arguments include:

* **Guard predicate** — ensures the instrumentation is only active when
  the tool is enabled for the current context.
* **Opcode** — the opcode of the memory instruction.
* **Memory-address** — the effective address being accessed.
* **Launch-value** — launch-time values (e.g., grid/block dimensions).
* **Channel pointer** — a pointer to the `ChannelDev` object for
  communication back to the host.

## Step 6: Enable instrumentation

Call `nvbit_enable_instrumented()` to activate the instrumentation for
the current context. NVBit will compile the modified GPU code with the
injected calls.

## Launch-time values

NVBit provides APIs to pass kernel launch parameters to device
instrumentation routines. These values are set at kernel launch time
and are available to the injected device routine during execution.
Tools should limit inferences about launch-time value availability to
the documented APIs.

## Caveats

* The `mem_trace` example is one approach to memory instrumentation.
  Other tools may use different filtering strategies or insertion
  points.
* Instrumentation adds overhead. The injected device routines execute
  alongside the original kernel code, which may affect performance
  measurements.
* Do not infer universal behavior from this example. Each tool's
  instrumentation strategy is independent.
