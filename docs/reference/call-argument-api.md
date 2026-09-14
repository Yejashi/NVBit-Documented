# Call-Argument API

After `nvbit_insert_call()`, a tool appends argument descriptors to the most
recently inserted call. Those descriptors tell NVBit what values the injected
device routine should receive at execution time.

## Argument families

| API family | Value delivered |
|---|---|
| `nvbit_add_call_arg_const_val32` | 32-bit constant selected by tool |
| `nvbit_add_call_arg_const_val64` | 64-bit constant selected by tool |
| `nvbit_add_call_arg_guard_pred_val` | dynamic guard predicate |
| `nvbit_add_call_arg_pred_val_at` | selected predicate value |
| `nvbit_add_call_arg_reg_val` | dynamic general-register value |
| `nvbit_add_call_arg_ureg_val` | dynamic uniform-register value |
| `nvbit_add_call_arg_cbank_val` | constant-bank value |
| `nvbit_add_call_arg_mref_addr64` | dynamic effective address for MREF |
| `nvbit_add_call_arg_launch_val64` | per-launch value |
| TMA handle/size API | runtime TMA parameter data in 1.8 |

Not every API is appropriate for every instruction. The `Instr` operand
metadata determines which sources are meaningful.

## Ordering contract

Given:

```cpp
nvbit_insert_call(instr, "f", IPOINT_BEFORE);
nvbit_add_call_arg_guard_pred_val(instr);
nvbit_add_call_arg_const_val32(instr, id);
nvbit_add_call_arg_reg_val(instr, reg);
```

the device routine must accept compatible parameters in the same order.

NVBit cannot infer your intended semantic field names.

## Constant arguments

A constant is embedded/associated with the instrumentation site and is ideal
for static IDs.

For pointer-shaped constants, the pointer's lifetime and device visibility are
the tool's responsibility.

## Predicate arguments

Guard-predicate and explicit-predicate arguments let the device routine observe
runtime control state.

Use them to distinguish a statically present instruction from work that is
dynamically predicated off.

## Register arguments

General and uniform registers have separate APIs. The register number comes
from static operand analysis, while the value is captured at dynamic
execution.

The optional variadic mode supports instruction-dependent value lists.

## Memory-reference arguments

`nvbit_add_call_arg_mref_addr64` takes a memory-reference index. An instruction
can have multiple MREF operands; use the index that matches the operand being
recorded.

The address is generated at runtime. Calling the API during instrumentation
does not read a current address on the host.

## Launch values

`nvbit_add_call_arg_launch_val64` creates a launch-specific input slot.
`nvbit_set_at_launch` supplies the value before the concrete launch.

For CUDA Graph nodes, stream and launch-handle information identify the node
launch whose slot is being set.

## TMA parameter handle

The 1.8 TMA path uses
`nvbit_add_call_arg_tma_param_handle_and_size(instr, ctx)`. The handle is
captured dynamically and is later interpreted on the host with
`nvbit_parse_tma_transfer_info`.

Do not substitute a conventional MREF address and assume equivalent semantics.

## Choosing an argument source

Ask where the desired value exists:

- known while walking `Instr` -> constant;
- register content at execution -> register/ureg;
- effective address at execution -> MREF;
- same value for all call sites in one launch -> launch value;
- TMA runtime transfer descriptor -> TMA handle.

That classification prevents many incorrect tool designs.
