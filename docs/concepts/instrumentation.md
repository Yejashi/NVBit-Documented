# Instrumentation Model

NVBit instrumentation is built as a sequence of **insert a call, then append
its arguments**. The call site is attached to a static `Instr`; the values
described by the argument APIs are materialized when that call site executes.

## The pipeline

A typical tool performs:

1. recover the launched `CUfunction`;
2. get related functions if callees must be covered;
3. skip functions already instrumented;
4. get each function's `Instr` vector;
5. filter instructions;
6. call `nvbit_insert_call()` at each selected instruction;
7. append arguments with `nvbit_add_call_arg_*`;
8. at launch time, enable the instrumented function.

## Insert first, append arguments second

The core insertion API has the conceptual form:

```cpp
nvbit_insert_call(instr, "device_function_name", IPOINT_BEFORE);
```

Arguments are separate API calls:

```cpp
nvbit_add_call_arg_guard_pred_val(instr);
nvbit_add_call_arg_const_val32(instr, opcode_id);
nvbit_add_call_arg_mref_addr64(instr, mref_idx);
nvbit_add_call_arg_launch_val64(instr, 0);
nvbit_add_call_arg_const_val64(
    instr, reinterpret_cast<uint64_t>(channel_dev));
```

Those arguments must correspond, in order and type, to the device routine's
parameters.

This is different from an API where `nvbit_insert_call()` receives an
arbitrary argument list directly.

## Insertion points

`IPOINT_BEFORE` runs the injected call before the original instruction.
`IPOINT_AFTER` runs it after.

Choose based on the value being observed or modified:

- input register values are usually observed before the instruction;
- a value produced by the instruction may need an after point or another
  strategy;
- a replacement tool may insert its own behavior and remove the original
  instruction.

Never assume before/after is interchangeable when register or predicate state
can change.

## The predicate argument is data

`nvbit_add_call_arg_guard_pred_val()` passes the instruction's guard predicate
value to the injected routine. It does not by itself mean NVBit silently skips
the call.

A device routine commonly starts by checking the passed value if the tool wants
predicated-off instructions excluded from its dynamic metric.

## Argument descriptors

At instrumentation time, calls such as
`nvbit_add_call_arg_mref_addr64()` and `nvbit_add_call_arg_reg_val()` describe
where NVBit should obtain a runtime value.

At execution time, the actual address/register content becomes an argument to
the injected routine.

This gives one static call site many dynamic observations.

## Enabling instrumented code

`nvbit_enable_instrumented(ctx, func, flag, apply_to_related)` controls whether
the instrumented or original version executes.

This call is normally made in the launch path after the function has been
instrumented. It is therefore possible to:

- instrument once but enable only selected launches;
- implement launch-range sampling;
- turn instrumentation on/off around application regions.

Do not repeatedly insert calls just to toggle collection. Separate
instrumentation construction from launch policy.

## Launch-time values

A tool can reserve a launch-value argument with
`nvbit_add_call_arg_launch_val64()` and then set the value for a concrete
launch with `nvbit_set_at_launch()`.

Typical uses include:

- monotonically increasing launch IDs;
- pointers or handles that differ per launch;
- graph-node-specific metadata.

CUDA Graph launches add stream/launch-handle identity; see
[CUDA Graphs](cuda-graphs.md).

## Related functions and enablement

If you instrument the entry kernel plus its related functions, make the
enablement policy consistent with that choice. `nvbit_enable_instrumented()`
has an `apply_to_related` parameter for this reason.

A mismatch can produce a trace in which the entry function is instrumented but
a callee unexpectedly executes its original version, or vice versa.

## Replacing an instruction

NVBit also supports tools that remove the original instruction after injecting
replacement behavior. `mov_replace` is the shipped example to study for this
pattern.

Replacement is much more correctness-sensitive than observation:

- preserve predication;
- reproduce operand semantics;
- preserve data dependencies;
- understand before/after state;
- test architecture/compiler combinations carefully.

## Instrumentation overhead

Injected calls change execution. Depending on the device routine, they can
alter register pressure, occupancy, memory traffic, synchronization, and
scheduling.

NVBit is ideal for functional/dynamic analysis, but a heavily instrumented
runtime should not automatically be interpreted as the uninstrumented
application's performance.

For performance studies, minimize payload, sample where possible, and validate
that the observation mechanism does not dominate the phenomenon being
measured.
