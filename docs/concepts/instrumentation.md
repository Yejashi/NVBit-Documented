# Instrumentation Model

This page explains how NVBit tools instrument GPU code at the
instruction level, using the `mem_trace` example as a reference.

## Overview

NVBit exposes decoded SASS instructions as `Instr` objects. A tool can
inspect these objects, apply filters, and insert instrumentation calls
before or after specific instructions.

The general instrumentation flow is:

1. Discover the CUDA functions to instrument (all functions, related
   functions, or a filtered set).
2. For each function, obtain its instruction list.
3. Filter instructions by opcode, operands, or other properties.
4. Insert instrumentation calls at desired points.
5. Enable instrumentation for the tool.

## Duplicate guard

To avoid instrumenting the same function more than once (e.g., when a
function is called from multiple entry points), tools typically maintain
a set of already-instrumented function handles and skip duplicates.

## Instruction discovery

The function `nvbit_get_instrs()` provides the NVBit instruction
representation associated with a CUDA function. It returns a list of
`Instr` objects that the tool can iterate over.

## Memory-ref filtering

The `mem_trace` tool filters instructions to find memory-reference
operations. It checks the opcode of each instruction to identify loads
and stores.

## Insertion

Instrumentation calls are inserted using `nvbit_insert_call()`. The
tool specifies:

* The device routine to call
* The insertion point (`IPOINT_BEFORE` or `IPOINT_AFTER`)
* The guard predicate (conditions under which the call is injected)
* The opcode filter (which instruction opcodes trigger the insertion)

Example (conceptual):

```c
nvbit_insert_call(instr, IPOINT_BEFORE, device_func,
                  guard_predicate, opcode_filter,
                  memory_address_arg, launch_value_arg,
                  channel_ptr_arg);
```

## Launch-time values

NVBit provides APIs to pass launch-time values (e.g., grid dimensions,
block dimensions) as arguments to instrumentation calls. These values
are set at kernel launch time. Tools should not infer broader behavior
from this mechanism beyond what is documented.

## Enabling instrumentation

After inserting calls, the tool calls `nvbit_enable_instrumented()` to
activate instrumentation for the current context. This tells NVBit to
compile the modified GPU code with the injected calls included.

## Related functions

For tools that need to instrument functions called from a specific entry
point, `nvbit_get_related_functions()` returns the set of functions
reachable from a given function. The `mem_trace` tool uses this to
discover all functions related to a kernel entry point before applying
the instrumentation pipeline described above.
