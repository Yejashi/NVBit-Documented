# Passing Values to Instrumentation Calls

The `nvbit_add_call_arg_*` APIs define the interface between a static
instrumentation site and the values received by its device routine.

The key rule is simple:

> Call `nvbit_insert_call()` first, then append arguments in exactly the order
> expected by the injected function.

## Constants

Use constant-value arguments for metadata known at instrumentation time.

Typical uses:

- compact opcode IDs;
- instruction IDs;
- mode flags;
- pointers whose address is stable for the needed lifetime.

Conceptually:

```cpp
nvbit_insert_call(instr, "instrument", IPOINT_BEFORE);
nvbit_add_call_arg_const_val32(instr, opcode_id);
nvbit_add_call_arg_const_val64(instr, state_ptr);
```

A constant pointer is only safe if the pointed-to object remains valid for all
executions of that call site.

## Guard predicate

`nvbit_add_call_arg_guard_pred_val(instr)` supplies the dynamic value of the
instruction's guard predicate.

Use it when a trace/count should distinguish an instruction that is present in
the instruction stream from one whose predicated operation actually executes.

The device routine still needs to apply the policy, for example:

```cpp
if (!pred) return;
```

## General registers

`nvbit_add_call_arg_reg_val(instr, reg_num)` passes the runtime contents of a
general register.

The register number should come from decoded operand metadata, not from fragile
text parsing.

The API also supports marking arguments as variadic. `record_reg_vals` is the
example to study when the number of interesting registers depends on the
instrumented instruction.

## Uniform registers

`nvbit_add_call_arg_ureg_val(instr, reg_num)` is the corresponding mechanism
for uniform-register values.

Do not treat uniform registers as ordinary per-thread registers in your trace
schema. Their execution semantics and intended consumers differ.

## Constant-bank values

`nvbit_add_call_arg_cbank_val(instr, bank_id, bank_offset)` requests the
runtime value associated with a constant-bank location.

The `mov_replace` example demonstrates why this matters: an operand that looks
like an input value may originate from a constant bank rather than from a
general register.

## Memory-reference addresses

`nvbit_add_call_arg_mref_addr64(instr, mref_index)` supplies the dynamic
64-bit effective address for one memory-reference operand.

Important consequences:

- call it once for each memory-reference operand you intend to observe;
- do not assume `mref_index == 0` is always the only address;
- the address exists at execution time, not when the host walks `Instr`;
- the interpretation of address space still comes from the instruction and
  operand metadata.

A tracer can choose one injected call per memory reference or design another
recording strategy, but it must preserve which MREF each address belongs to.

## Launch-time values

`nvbit_add_call_arg_launch_val64(instr, 0)` reserves a value that is filled in
for a particular launch by `nvbit_set_at_launch()`.

This is appropriate for values that are:

- identical for all instrumented sites in one launch;
- different across launches;
- not known when the function was first instrumented.

A launch sequence number is the classic example.

For CUDA Graph nodes, pair `nvbit_set_at_launch()` with the stream and launch
handle supplied by `nvbit_at_graph_node_launch()`.

## TMA handle and size

NVBit 1.8 adds a TMA-specific call-argument path used by TMA tracers:
`nvbit_add_call_arg_tma_param_handle_and_size(instr, ctx)`.

The injected device routine receives/copies the runtime handle data, which can
later be parsed on the host with `nvbit_parse_tma_transfer_info()`.

This is intentionally separate from ordinary `mref_addr64` handling.

## Argument order example

Suppose the injected routine conceptually expects:

```cpp
instrument_mem(int pred,
               uint32_t opcode_id,
               uint64_t address,
               uint64_t launch_id,
               ChannelDev* channel);
```

Then the host must append those five arguments in that exact order.

When debugging corrupt records, compare these two sequences before suspecting
the channel implementation.

## Variadic arguments

NVBit's register/value argument APIs can support variadic use cases. Use this
only when the device routine is deliberately written to consume a variable
payload.

For a trace format, still include an explicit count or schema version so the
receiver knows how many values follow.

## Lifetime checklist

For any pointer passed as a constant argument, answer:

1. who allocated it?
2. is it host, device, or managed memory?
3. is the address valid in the injected device code?
4. does it outlive every launch using the instrumented call site?
5. when is it freed relative to channel flushing and context termination?

Most pointer-related instrumentation bugs are ownership/lifetime bugs rather
than NVBit insertion bugs.
