# Functions and Related Functions

NVBit exposes loaded GPU code through CUDA driver `CUfunction` handles. Tools
usually begin from the entry function associated with a kernel launch and then
decide whether to instrument only that function or also its reachable device
functions.

## Entry functions

A kernel launch callback gives the tool enough event-specific information to
identify the launched `CUfunction`. That handle becomes the key for:

- retrieving the function name and address;
- retrieving decoded SASS instructions;
- obtaining related functions;
- enabling or disabling the instrumented variant;
- attaching launch-time values.

Keep the `CUcontext` paired with the `CUfunction` when calling APIs whose
modern signatures are context-qualified.

## Related functions

`nvbit_get_related_functions(ctx, func)` returns device functions related to
the supplied function. Shipped tools commonly append the entry function itself
because the returned collection is used as the set of callees to process, not
as a replacement for the original kernel handle.

The canonical shape is:

```cpp
std::vector<CUfunction> funcs =
    nvbit_get_related_functions(ctx, func);
funcs.push_back(func);

for (CUfunction f : funcs) {
    // instrument f if this context has not seen it before
}
```

This matters for traces. Instrumenting only the entry function can omit memory
or arithmetic operations executed inside non-inlined device functions.

## Instrument once, execute many times

Instrumentation description is normally a one-time operation for a loaded
function. Kernel execution is not.

Maintain a set such as:

```text
already_instrumented[ctx] = { CUfunction ... }
```

and check it before inserting calls.

This solves two problems:

1. the same kernel may be launched repeatedly;
2. different kernels may reach the same device function.

Without a duplicate guard, injected calls can accumulate on a shared callee.

## Function identity and human-readable names

Use a `CUfunction` as the runtime identity; use names for diagnostics,
filtering, and output.

Names are not always ideal unique identifiers:

- templates can generate long mangled/demangled names;
- different modules can contain similar names;
- compiler-generated functions may appear;
- code loading can be context/module dependent.

If a tool stores metadata in maps, keying by `CUfunction` (and context where
needed) is generally safer than keying only by a string.

## Function addresses

NVBit exposes function-address information useful for producing virtual-PC
identifiers and mapping an instruction offset back to a kernel/function.
Modern NVBit APIs that query function properties take a `CUcontext` along with
the `CUfunction`.

A trace should clearly state whether its PC field is:

- function-relative offset;
- NVBit-reported function address plus offset;
- raw SASS address from another representation.

Do not mix these without documenting the transformation.

## Function configuration

Function configuration can be useful when correlating instrumentation with
resource use or launch properties. Keep configuration queries separate from
dynamic launch values: register count or static function configuration is not
the same object as grid/block dimensions for one launch.

## Filtering functions

Common filters include:

- kernel name allow/deny lists;
- launch index ranges;
- module or function address;
- instrumentation regions controlled by user markers.

Apply a filter at the narrowest correct stage. For example, a kernel-name
filter can avoid walking instructions for a launch the user never wanted to
trace.

## Relationship to enablement

Inserting calls establishes an instrumented version; whether it runs is
controlled separately with `nvbit_enable_instrumented()`.

Its modern signature includes a flag controlling whether enablement applies to
related functions. That detail should match how the tool populated and
instrumented its related-function set.

A useful invariant is:

> Every function that can execute an injected call for this launch is both
> instrumented exactly once and enabled according to the tool's policy.
