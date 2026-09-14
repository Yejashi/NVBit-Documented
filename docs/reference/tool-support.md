# Tool Support API

NVBit tools often need infrastructure beyond instruction insertion. The release
includes host/device support utilities for channels, tool threads, and
tool-owned GPU helpers.

## Channel types

`ChannelDev` is used from injected device code to push records.

`ChannelHost` is used by the host tool to receive those records, typically
through a dedicated receiver thread.

The channel abstraction is demonstrated by `mem_trace` and related examples.

## Tool pthread registration

Register receiver/helper threads with:

- `nvbit_set_tool_pthread`;
- `nvbit_unset_tool_pthread`.

Registered tool threads are excluded from normal callback generation when they
perform CUDA activity. This prevents the tool from recursively interpreting
its own CUDA calls as target-application events.

## Per-context ownership

Channel allocations and loaded tool modules belong to a CUDA context. Keep them
inside a context-state object and release them during `nvbit_at_ctx_term` after
producers/receivers are quiescent.

## Explicit tool modules

For a tool-owned CUDA helper:

1. load module bytes with `nvbit_load_tool_module`;
2. resolve the function with `nvbit_find_function_by_name`;
3. launch the resolved `CUfunction` with `nvbit_launch_kernel`.

This pattern was introduced in the 1.7.7 lineage and is part of 1.8. It avoids
depending on lazy helper-kernel loading from a callback-sensitive path.

## Tool support header

The release's tool-support declarations are rendered below.

```{doxygenfile} nvbit_tool.h
```

## Relationship to `nvbit.h`

Do not draw a strict "host API versus device API" boundary based only on header
filename. A real tool combines:

- callback/control interfaces;
- instruction and call-argument APIs;
- channel utilities;
- helper-module functions;
- CUDA types.

Use the conceptual pages to understand ownership and timing, then use generated
Doxygen to confirm exact 1.8 declarations.
