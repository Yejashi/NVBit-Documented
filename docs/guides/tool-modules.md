# Tool Modules and Tool Kernels

NVBit 1.8 includes explicit APIs for loading a CUDA module owned by the tool,
resolving a function from that module, and launching it through NVBit.

These APIs were introduced to avoid problematic lazy loading and potential
deadlocks when a tool needs to run its own helper kernel from callback-driven
code.

## The three-step model

### 1. Load the tool module

`nvbit_load_tool_module(ctx, module_binary, &module)` loads the tool's device
module into the program context.

The module binary is commonly embedded into the host shared object at build
time so the tool can supply its bytes without opening a separate cubin at
runtime.

### 2. Resolve a helper function

`nvbit_find_function_by_name(ctx, module, "helper_name", &func)` obtains a
`CUfunction` for the tool kernel and avoids deferring resolution until the
first sensitive launch.

Store the resolved function in per-context state.

### 3. Launch through NVBit

`nvbit_launch_kernel()` accepts the context, resolved `CUfunction`, grid/block
dimensions, shared-memory size, stream, arguments, and launch-related
parameters needed to execute the helper.

Use the signature from the 1.8 `nvbit.h` in your checked-out release rather
than copying a stale signature from an older tutorial.

## Why not simply call a `__global__` helper?

A tool injected into an application's CUDA process has to coexist with NVBit's
interposition and callback lifecycle. Allowing the CUDA runtime/driver to lazily
load the tool's own kernel at an awkward point can create reentrancy or
deadlock hazards.

The explicit module APIs make the dependency visible and move module loading
to a controlled lifecycle stage.

## Channel flush use case

A common use is an explicit flush helper:

```text
nvbit_at_ctx_init / nvbit_tool_init
        |
        +--> load embedded module
        +--> find flush_channel CUfunction
        |
normal tracing
        |
context/flush point
        |
        +--> nvbit_launch_kernel(flush_channel, ...)
```

This makes channel-drain logic independent of lazy runtime kernel discovery.

## State to store

Per context, keep:

- `CUmodule tool_module`;
- `CUfunction flush_or_helper_func`;
- any argument storage whose address is supplied to the helper;
- the stream or synchronization policy used for helper execution.

Do not reuse a `CUfunction` resolved in one context as if it were universally
valid in another.

## Callback recursion

If helper work occurs from a dedicated host tool thread, register that thread
with `nvbit_set_tool_pthread()` so its CUDA calls are not mistaken for target
application activity.

Even when using `nvbit_launch_kernel()`, keep clear boundaries between
application events and tool-internal events.

## Porting an older tool

If an older NVBit tool contains a direct CUDA launch of a tool-owned flush
kernel inside a callback, review it for the explicit-module pattern when
porting to 1.8.

A safe porting checklist is:

1. compile the helper device code into an embeddable module binary;
2. load it once per context;
3. resolve helper functions once per context;
4. replace callback-path lazy launches with `nvbit_launch_kernel()`;
5. validate teardown/stream synchronization;
6. confirm the tool's own thread does not recursively enter callbacks.

This is one of the most practically important differences between older NVBit
examples found online and the current 1.8-era design.
