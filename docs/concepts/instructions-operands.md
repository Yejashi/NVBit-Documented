# Instructions, Predicates, and Operands

`nvbit_get_instrs(ctx, func)` returns NVBit's decoded representation of the
SASS instructions that compose a `CUfunction`. Each element is an `Instr`
object describing a **static** machine instruction.

Understanding what is static and what becomes dynamic at execution time is
essential for correct tooling.

## Static instruction information

An `Instr` can be used to reason about properties such as:

- textual SASS and opcode;
- instruction offset/position;
- size;
- guard predicate;
- operands;
- whether operands represent registers, uniform registers, constant-bank
  references, memory references, or other encoded forms;
- architecture-specific information exposed by the release.

This data is available when the host tool instruments the function.

## Dynamic values are different

An `Instr` can tell you that an instruction reads a register or contains a
memory-reference operand. It does not mean the host can directly read the
runtime register value or effective memory address.

To capture those values, append an appropriate argument descriptor to an
inserted device call:

| Desired runtime value | Argument family |
|---|---|
| guard predicate | `nvbit_add_call_arg_guard_pred_val` |
| general register | `nvbit_add_call_arg_reg_val` |
| uniform register | `nvbit_add_call_arg_ureg_val` |
| constant-bank value | `nvbit_add_call_arg_cbank_val` |
| effective memory address | `nvbit_add_call_arg_mref_addr64` |
| per-launch value | `nvbit_add_call_arg_launch_val64` |

The resulting value is passed to the injected device routine when the
instrumented instruction executes.

## Predication

A SASS instruction may be guarded by a predicate. Dynamic tools need to
decide whether they want to count:

- the presence of the instruction in the static instruction stream; or
- an execution only when its guard evaluates true.

The first is a static count. The second requires the runtime guard predicate.

Shipped counting and tracing examples use the guard-predicate argument so
device routines can suppress records for predicated-off instructions when
that is the intended metric.

## Operands

Do not assume every instruction has the same number or arrangement of
operands. When instrumenting a register value or memory reference:

1. inspect the decoded operands;
2. identify the operand(s) relevant to the analysis;
3. append arguments using the corresponding NVBit API;
4. make the injected function signature match the order of appended arguments.

This is safer than inferring register numbers from textual SASS with ad-hoc
string parsing.

## Memory references

One SASS instruction can expose more than one memory-reference operand.
Modern NVBit removed an older fixed maximum-MREF assumption after correctness
fixes in the 1.7.7.x line.

For a general memory tracer:

```text
for each Instr
    determine number/relevant memory-reference operands
    for each memory-reference operand
        insert a trace call
        append that operand's runtime address
```

The operand index passed to `nvbit_add_call_arg_mref_addr64()` selects which
effective address the injected call should receive.

## Instruction binary encoding in 1.8

NVBit 1.8 adds `Instr::getSassBinary()`. It emits the machine-instruction
encoding byte by byte through a callback.

This is different from textual SASS:

- text is useful for human-readable opcode/modifier analysis;
- raw bytes are useful for tools that need exact encoding information or want
  to perform their own architecture-specific decoding.

Treat raw SASS encoding as architecture-specific data. A bit layout inferred
for one GPU generation should not automatically be applied to another.

## TMA operands

NVBit 1.8 introduces special treatment for Tensor Memory Accelerator
instructions. A TMA operation is not adequately represented by treating it as
a conventional scalar load/store with a single effective address.

The TMA path can expose a TMA parameter handle that is passed from device
instrumentation to the host and parsed into structured transfer information.
See [Tensor Memory Accelerator Support](tma.md).

## A good trace schema

If you persist dynamic instruction records, separate static and dynamic fields.

**Static per instruction**

- function ID/name;
- instruction offset/PC;
- opcode/text;
- operand metadata;
- optional raw SASS bytes.

**Dynamic per execution**

- launch ID;
- active/predicate information;
- register values;
- effective addresses;
- TMA transfer metadata.

Keeping that separation reduces trace duplication and makes later analysis
more explicit.
