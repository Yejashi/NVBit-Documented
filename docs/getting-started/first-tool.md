# Anatomy of a First Tool

A minimal useful NVBit tool is not a standalone CUDA program. It is a shared
library loaded into another CUDA process. The library exports NVBit callbacks
and contains or links device routines that NVBit can call from instrumented
SASS.

This page describes the pieces without reproducing a complete upstream
example.

## Host-side state

A counting tool usually needs at least:

- a counter or per-kernel counter array;
- a set of `CUfunction` handles already instrumented;
- optional configuration parsed once during initialization.

For context-sensitive resources such as channels, modules, or receiver
threads, store state **per `CUcontext`** rather than in one unqualified global
object.

## Instrument a function once

The core pattern is:

```cpp
void instrument_function_if_needed(CUcontext ctx, CUfunction func) {
    std::vector<CUfunction> functions =
        nvbit_get_related_functions(ctx, func);
    functions.push_back(func);

    for (CUfunction f : functions) {
        if (!already_instrumented.insert(f).second) {
            continue;
        }

        const std::vector<Instr*>& instrs = nvbit_get_instrs(ctx, f);
        for (const Instr* instr : instrs) {
            nvbit_insert_call(instr, "count_instr", IPOINT_BEFORE);
            nvbit_add_call_arg_guard_pred_val(instr);
            nvbit_add_call_arg_const_val64(
                instr, reinterpret_cast<uint64_t>(counter_ptr));
        }
    }
}
```

The important ordering rule is that `nvbit_insert_call()` creates the
injected call, and the following `nvbit_add_call_arg_*` calls append arguments
to that **last inserted call**.

The code above is schematic: the exact counter placement and device routine
signature are tool design choices.

## Device-side routine

The injected routine must have a signature matching the arguments assembled on
the host. A common counting routine receives the original instruction's guard
predicate plus a counter pointer.

It normally uses `extern "C"` to avoid a C++-mangled name and is compiled as
device code. The routine may execute once per active thread depending on how
it is written, so distinguish thread-level, warp-level, and instruction-level
quantities carefully.

## Launch callback

Instrumentation is commonly triggered when a kernel launch enters
`nvbit_at_cuda_event()`:

1. identify a supported launch callback ID;
2. recover the launched `CUfunction` from the callback parameters;
3. instrument it if this is the first encounter;
4. call `nvbit_enable_instrumented(ctx, func, true)` when the instrumented
   variant should execute.

The `apply_to_related` behavior of `nvbit_enable_instrumented()` matters when
you instrument callees as well as the entry function.

## Entry versus exit

`nvbit_at_cuda_event()` is invoked around CUDA driver calls:

- `is_exit == 0`: before the driver call;
- `is_exit == 1`: after the driver call.

Do setup that must affect the launch on entry. Do reporting that requires the
kernel to have finished only after establishing the required synchronization.
Do not assume a kernel launch API is globally synchronous.

## Why a duplicate set is required

Suppose kernels A and B both call device function C. If the tool blindly walks
each kernel's related functions and inserts instrumentation every time, C can
receive duplicate injected calls. A per-context or otherwise correctly scoped
set of already-instrumented `CUfunction` handles prevents this.

## The first debugging checklist

When a tool loads but produces no data, check in this order:

1. the shared library is actually loaded;
2. the expected CUDA launch callback is observed;
3. a valid `CUfunction` is recovered;
4. `nvbit_get_instrs()` returns instructions;
5. your filter selects at least one instruction;
6. argument order matches the device function signature;
7. `nvbit_enable_instrumented()` is true for the launch;
8. output is flushed or copied back before process exit.

Once this pattern is clear, memory tracing and register tracing are variations
on the same control structure rather than entirely new architectures.
