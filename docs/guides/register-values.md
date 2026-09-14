# Recording Register Values

Register-value tracing uses the same insertion model as memory tracing but
selects register operands and passes their dynamic contents with
`nvbit_add_call_arg_reg_val()` or `nvbit_add_call_arg_ureg_val()`.

## Static selection

At instrumentation time:

1. choose the instructions of interest;
2. inspect decoded operands;
3. collect the register numbers relevant to the analysis;
4. insert one device call at the desired point.

Avoid extracting register numbers from formatted SASS when the decoded operand
representation already provides them.

## Before or after?

The insertion point changes the meaning of a register value.

If an instruction reads R8 and writes R12:

- `IPOINT_BEFORE` is appropriate for observing R8 as an input;
- observing the newly produced R12 requires post-instruction semantics and a
  correctly placed call.

For instructions with predication, also decide whether a predicated-off
instruction should create a record.

## Fixed versus variable register sets

If every selected call site passes the same number of registers, a fixed
device function signature is simplest.

If different instructions expose different numbers of interesting registers,
NVBit supports variadic argument construction. The shipped
`record_reg_vals` example demonstrates a pattern where register values are
appended as variadic parameters.

Always include a register count and enough static metadata for the receiver to
interpret the payload.

## Ordinary and uniform registers

Use the matching API for the operand class:

- `nvbit_add_call_arg_reg_val` for ordinary general registers;
- `nvbit_add_call_arg_ureg_val` for uniform registers.

Do not silently convert both into the same semantic category in downstream
analysis. A uniform value can be shared across the warp even though it is
delivered to the instrumentation routine as an argument.

## Trace design

A compact design stores static register identities once:

```text
instruction_id -> [register descriptors]
```

and dynamic records carry only the values:

```text
launch_id, instruction_id, lane/warp identity, value0, value1, ...
```

This avoids repeating operand names for every execution.

## Register pressure

Injected device code uses registers too. A register-heavy instrumentation
routine can alter the target kernel's register pressure and potentially its
occupancy or spills.

If the goal is only to capture a few values:

- keep the injected routine small;
- avoid large local arrays;
- push/aggregate efficiently;
- compare resource behavior with and without instrumentation when performance
  perturbation matters.
