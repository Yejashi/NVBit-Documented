# Instrumenting Memory Operations

This guide builds the reasoning behind a memory tracer similar to the shipped
`mem_trace` tool.

## Goal

For each selected dynamic memory operation, record enough information to
identify:

- the kernel/function and instruction;
- opcode or instruction ID;
- whether the instruction is predicated on;
- the relevant memory-reference address;
- the kernel launch;
- optional lane/warp/thread information produced by the device routine.

## 1. Instrument the whole reachable scope

Start from the launched `CUfunction` and obtain related device functions:

```cpp
std::vector<CUfunction> funcs =
    nvbit_get_related_functions(ctx, entry);
funcs.push_back(entry);
```

Use an already-instrumented set so shared callees are processed only once.

## 2. Inspect decoded instructions

For each unique function:

```cpp
const std::vector<Instr*>& instrs =
    nvbit_get_instrs(ctx, func);
```

The filter should be based on decoded instruction/operand properties. Decide
which address spaces and instruction families your experiment includes.

A general-purpose tracer should make exclusions explicit rather than silently
dropping instruction classes.

## 3. Handle every relevant memory-reference operand

Do not code the assumption "one memory instruction means one address."

For each selected `Instr`, determine its memory-reference operands. If the
analysis needs all of them, insert a record path for each one and pass that
operand's index to `nvbit_add_call_arg_mref_addr64()`.

Modern 1.8 inherits fixes that removed an older incorrect fixed maximum on
memory-reference operands. Write loops from the decoded instruction data, not
from an obsolete constant.

## 4. Insert the trace call

The sequence is conceptually:

```cpp
nvbit_insert_call(instr, "instrument_mem", IPOINT_BEFORE);
nvbit_add_call_arg_guard_pred_val(instr);
nvbit_add_call_arg_const_val32(instr, opcode_id);
nvbit_add_call_arg_mref_addr64(instr, mref_idx);
nvbit_add_call_arg_launch_val64(instr, 0);
nvbit_add_call_arg_const_val64(
    instr, reinterpret_cast<uint64_t>(channel_dev));
```

The actual upstream example includes its own record layout and supporting
arguments. The important pattern is the separation between insertion and
argument construction.

## 5. Assign launch identity

Before the kernel executes:

```text
nvbit_set_at_launch(ctx, func, launch_id, ...)
nvbit_enable_instrumented(ctx, func, true)
```

Now every dynamic record can carry the launch ID without reinstrumenting the
function.

For graph launches, use the stream/launch-handle-aware path.

## 6. Produce records on the GPU

The device routine receives the dynamic address. It should return quickly for a
predicated-off operation when such operations are excluded.

Then it packages the desired fields and pushes the record through
`ChannelDev`.

Keep device records compact. Long strings such as SASS text should usually be
mapped to an integer static ID.

## 7. Consume on the host

`ChannelHost` owns a receiver thread that drains records.

The receiver can:

- map IDs back to static instruction/function metadata;
- aggregate counters;
- write a binary trace;
- feed another analysis pipeline.

If parsing/file I/O is expensive, consider decoupling channel draining from
heavy downstream work so the consumer can keep pace with the GPU.

## 8. Address-space semantics

A 64-bit effective address alone does not say whether an instruction targets
global, shared, local, or another memory space.

Persist sufficient static metadata to interpret the address later:

```text
instruction_id -> {
    opcode,
    memory space / operand role,
    width,
    function,
    static PC
}
```

Then dynamic records can remain compact.

## 9. Coalescing is downstream analysis

NVBit can give a tracer per-thread/lane effective addresses, but a GPU memory
system does not necessarily issue one memory transaction for every lane.

If your research question is cache/coalescing behavior, reconstruct requests
at the appropriate granularity (warp/wave instruction plus memory line/sector)
rather than treating every lane address as an independent cache access.

That analysis belongs after collection unless the injected routine deliberately
performs the aggregation on device.

## 10. TMA is a separate branch

TMA operations in NVBit 1.8 use TMA parameter handles and structured parsing.
Do not force them through the ordinary MREF loop and call the result complete.

See [Tracing TMA Operations](tma-tracing.md).

## 11. Validate the tracer

Use microbenchmarks where addresses are known analytically:

- contiguous vector load/store;
- stride-2/stride-N;
- shared-memory access;
- an instruction with multiple memory-reference operands if available;
- TMA microbenchmark on supported hardware.

Compare emitted addresses/counts with the kernel's expected indexing before
using the tracer on large applications.

## Performance caution

Memory tracing can generate enormous data volumes and substantial overhead.
The traced execution time is generally not a clean measurement of the
uninstrumented kernel's memory performance.

Use the trace to characterize behavior; use independent profiling/runs for
timing unless you have quantified perturbation.
