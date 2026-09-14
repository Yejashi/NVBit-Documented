# Core API

The primary NVBit tool interface is declared in `nvbit.h`.

This page groups the most important entry points by purpose and includes
Doxygen-rendered declarations for the core instrumentation functions already
used throughout this manual.

## Lifecycle callbacks

A tool may export the callbacks it needs:

- `nvbit_at_init`;
- `nvbit_at_ctx_init`;
- `nvbit_tool_init`;
- `nvbit_at_cuda_event`;
- `nvbit_at_graph_node_launch`;
- `nvbit_at_ctx_term`;
- `nvbit_at_term`.

The callback lifecycle and CUDA-allocation restrictions are explained in
[Callback Lifecycle](../concepts/lifecycle.md).

## Function discovery

### `nvbit_get_related_functions`

Returns related device functions for a supplied `CUfunction`. Tools commonly
append the entry function itself before walking the resulting set.

```{doxygenfunction} nvbit_get_related_functions
```

### `nvbit_get_instrs`

Returns the decoded `Instr` vector for a function.

```{doxygenfunction} nvbit_get_instrs
```

Use a duplicate guard before inserting instrumentation because the same
function can be encountered through repeated launches or multiple callers.

## Inserting instrumentation

### `nvbit_insert_call`

Creates a call to a named device routine before or after an `Instr`.

```{doxygenfunction} nvbit_insert_call
```

Arguments are appended separately through `nvbit_add_call_arg_*` APIs. They
are not passed as an arbitrary list to `nvbit_insert_call` itself.

## Memory-reference address

### `nvbit_add_call_arg_mref_addr64`

Requests the runtime 64-bit effective address for one memory-reference operand.

```{doxygenfunction} nvbit_add_call_arg_mref_addr64
```

The `id`/index matters for instructions exposing more than one memory
reference.

## Enablement

### `nvbit_enable_instrumented`

Selects whether the instrumented or original version executes for a function.

```{doxygenfunction} nvbit_enable_instrumented
```

The 1.8 signature also exposes whether enablement should apply to related
functions. Match this policy to the set of functions you instrumented.

## Launch-time values

### `nvbit_set_at_launch`

Sets the value used by a launch-value argument. Graph-aware use can include a
stream and launch handle.

```{doxygenfunction} nvbit_set_at_launch
```

Reserve the input in the injected call with
`nvbit_add_call_arg_launch_val64()`.

## Tool-thread registration

`nvbit_set_tool_pthread()` and `nvbit_unset_tool_pthread()` mark host threads
owned by the tool. CUDA activity from a registered tool thread does not trigger
the tool's normal target callbacks.

This is critical for channel receiver/helper threads.

## Tool-owned modules

NVBit 1.8 provides:

- `nvbit_load_tool_module` — load a module binary into a context;
- `nvbit_find_function_by_name` — resolve a tool kernel from that module;
- `nvbit_launch_kernel` — launch a resolved tool function through NVBit.

Use these for helper kernels such as explicit channel flush routines.

## Function metadata

The API also exposes function names, addresses, configurations, and related
metadata. Modern releases qualify several function-query APIs with the
`CUcontext`; do not copy pre-1.7 signatures from old tutorials.

## Advanced control

Other core APIs support instruction removal/replacement, register handling,
CFG access, tool configuration, and architecture-specific functionality.

Before using an advanced function, read the generated 1.8 declaration and
study the closest shipped example. The versioned header is authoritative.
