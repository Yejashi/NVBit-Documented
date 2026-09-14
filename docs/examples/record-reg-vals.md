# Example: `record_reg_vals`

`record_reg_vals` demonstrates how to turn static operand information into
dynamic register values.

## Instrumentation-time analysis

The host walks selected `Instr` objects and determines which operands refer to
registers of interest.

It records the register numbers and inserts a call such that NVBit will pass
the current contents of those registers when the instruction executes.

This is preferable to trying to parse register names from formatted SASS.

## Dynamic argument construction

For each register number, the tool uses
`nvbit_add_call_arg_reg_val(instr, reg_num, ...)`.

The example supports a variable number of register arguments, which makes it a
useful reference for NVBit's variadic instrumentation argument support.

The host/device agreement should include:

- number of values;
- their order;
- whether each is a general or uniform register;
- the static instruction to which they belong.

## Predication

If the selected instruction is predicated, pass the guard value as well when
the output should reflect whether the instruction was logically active.

A register may contain a value even when the instruction is predicated off;
the trace semantics should say whether such a value is emitted or ignored.

## Insertion point semantics

A register read before an instruction and a register read after it can mean
different things.

Before modifying this example to trace destinations, verify that the chosen
insertion point corresponds to the value you intend to observe.

## Channel use

Register values can create high event volume, so the example uses a
device-to-host communication path rather than assuming occasional debug
printing is sufficient.

Apply the same compact-record rules as memory tracing: keep static register
descriptors on the host and transmit dynamic values by instruction ID.

## Extending to uniform registers

NVBit exposes a separate `nvbit_add_call_arg_ureg_val()` API. A generalized
register tracer should recognize the operand class and choose the matching
argument source.

This becomes more important for TMA-related instructions in NVBit 1.8, whose
parameter representation can involve uniform-register metadata.
