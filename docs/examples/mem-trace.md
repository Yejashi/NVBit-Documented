# Example: `mem_trace`

`mem_trace` is the most important example for understanding a full NVBit data
collection pipeline. It combines static instruction inspection, dynamic
effective addresses, launch-time metadata, device-to-host channels, a receiver
thread, and explicit teardown.

## What the tool records

At a high level, each dynamic memory event can be associated with:

- an instruction/opcode identifier;
- predicate state;
- an effective memory address;
- launch identity;
- thread/warp information produced by the injected code.

The exact record struct is an implementation detail; the architectural pattern
is broadly reusable.

## Static instrumentation path

The tool finds the entry function and related functions, then walks their
`Instr` objects.

For each selected memory reference, it inserts a call before the instruction
and appends arguments representing:

1. guard predicate;
2. static opcode/instruction identifier;
3. dynamic memory-reference address;
4. launch-time value;
5. channel state.

The important detail is that the memory address is not known on the host at
instrumentation time. `nvbit_add_call_arg_mref_addr64()` tells NVBit which
runtime MREF address to pass later.

## Multiple MREF operands

The tracer must account for instructions exposing multiple memory-reference
operands.

Do not carry forward older code that assumes a global fixed maximum. The
1.8-era API lineage removed an incorrect maximum-MREF assertion.

The robust rule is: inspect the instruction, iterate the relevant MREF
operands, and preserve the operand index in the instrumentation logic.

## Launch IDs

A static call site can execute in many kernel launches. `mem_trace` uses a
launch-time argument so dynamic records can be associated with the correct
launch without reinserting the call.

This demonstrates the distinction:

```text
instrument once -> add launch-value slot
launch N         -> set value N
launch N+1       -> set value N+1
```

## Channel pipeline

A trace event is pushed through `ChannelDev`. `ChannelHost` drains the data on
a receiver thread.

The receiver thread is registered with `nvbit_set_tool_pthread()` so CUDA work
performed by the tool thread does not recursively trigger target callbacks.

This is not optional bookkeeping; it is part of making a callback-driven tool
non-reentrant.

## Flush path

Before channel resources are destroyed, final records must reach the receiver.

Modern NVBit provides explicit tool-module and helper-kernel APIs so a flush
kernel can be loaded/resolved deliberately and launched through NVBit rather
than relying on lazy CUDA loading in a sensitive callback.

When adapting `mem_trace`, preserve the release's current flush strategy rather
than copying an older online version blindly.

## Asynchrony

A tracer can become accidentally correct by synchronizing after every launch,
but that serializes streams and can distort application behavior.

The modern example lineage avoids unconditional default kernel serialization.
If your analysis needs launch-complete ordering, state that requirement and
implement the narrowest synchronization that guarantees it.

## Static dictionaries

For large traces, do not put long SASS/opcode/function strings in every
dynamic record.

During instrumentation, assign IDs:

```text
instruction_id -> function, PC, opcode, operands, SASS
```

Then channel records need only the ID plus dynamic fields.

This can reduce channel traffic substantially and makes trace formats cleaner.

## Research interpretation

The memory trace observes addresses produced by the instrumented program. It
does not directly give you cache transactions, coalescing, hit/miss outcomes,
or DRAM requests.

Those require either:

- reconstruction from the address stream at the relevant request granularity;
- hardware counters;
- or a cache/memory model.

Keep "dynamic memory references" and "memory-system transactions" distinct in
analysis.
