# Instruction API

NVBit represents decoded SASS using `Instr` objects. The instruction API is
where a tool decides **which static instructions** to instrument and which
runtime values it will request later.

## Getting instructions

Use:

```cpp
const std::vector<Instr*>& instrs =
    nvbit_get_instrs(ctx, func);
```

The returned objects belong to NVBit. Treat them as descriptors used while
building instrumentation rather than application-owned objects to free.

## Categories of information

The release instruction representation exposes information in these broad
categories:

| Category | Typical use |
|---|---|
| SASS/opcode text | filters, diagnostics, static dictionaries |
| predicate metadata | predication-aware tracing |
| operands | register, uniform register, constant bank, memory references |
| instruction size/offset | PC mapping and trace identity |
| memory-reference metadata | address-argument insertion |
| raw SASS bytes | exact encoding analysis in 1.8 |

## Predicate metadata

A tool can determine whether an instruction is predicated and can retain
static predicate metadata. The dynamic predicate value is obtained separately
through a call argument.

Static predicate presence and dynamic predicate truth are not the same field.

## Operand traversal

Operand kinds can include values that need different runtime argument APIs:

- ordinary register -> `nvbit_add_call_arg_reg_val`;
- uniform register -> `nvbit_add_call_arg_ureg_val`;
- constant bank -> `nvbit_add_call_arg_cbank_val`;
- memory reference -> `nvbit_add_call_arg_mref_addr64`;
- TMA-specific parameter representation -> TMA 1.8 path.

Write operand walkers to branch on the decoded kind instead of assuming every
source is a general register.

## Memory-reference count

Do not hard-code an old maximum number of memory references per instruction.
The current release lineage removed an incorrect fixed-limit assertion.

Iterate what the decoded instruction exposes and explicitly select the MREF
index whose address should be passed.

## `getSassBinary()`

NVBit 1.8 adds `Instr::getSassBinary()` for retrieving the raw instruction
encoding as bytes through a callback.

This is useful when:

- a research tool needs exact machine bits;
- text SASS loses information needed by a custom decoder;
- a trace wants to be self-contained for later encoding analysis.

Raw encoding is architecture-specific. Store the GPU architecture and NVBit
version alongside it.

## Text versus binary SASS

Prefer textual SASS for:

- human-readable output;
- coarse opcode filters;
- diagnostics.

Prefer raw encoding only when the bit-level representation is part of the
research question. Decoding control bits or modifiers yourself couples the
tool to an ISA generation.

## TMA classification

TMA support introduces instruction/operand forms that older generic operand
walkers may not recognize.

When porting a pre-1.8 tool:

1. audit switches over operand kinds;
2. audit memory-instruction classification;
3. add a TMA branch where needed;
4. decide whether TMA is traced, explicitly unsupported, or ignored with a
   visible warning.

Silent omission produces deceptively incomplete memory traces.
