# Callback Lifecycle

This page describes the NVBit callback mechanism and the set of
callbacks declared in the core header.

## Callback declarations

All callback types are declared in `nvbit.h`. A tool registers
callbacks by providing function pointers of the appropriate type during
initialization.

The NVBit 1.8 API defines the following callbacks:

| Callback | Trigger |
|---|---|
| `nvbit_at_init` | NVBit library initialization |
| `nvbit_at_ctx_init` | CUDA context initialization |
| `nvbit_tool_init` | Called before the first kernel launch |
| `nvbit_at_cuda_event` | CUDA driver events (kernel launches, etc.) |
| `nvbit_at_graph_node_launch` | CUDA Graph node launch |
| `nvbit_at_ctx_term` | CUDA context termination |
| `nvbit_at_term` | NVBit library termination |

## CUDA event callback

The `nvbit_at_cuda_event` callback receives a flag indicating whether
the event is an entry or exit point for a CUDA driver call:

* `is_exit = 0` — entry point (the driver call has not yet executed)
* `is_exit = 1` — exit point (the driver call has completed)

## Execution order

The NVBit 1.8 API specifies trigger conditions for each callback but
does not define a single total ordering among all callbacks. The
ordering depends on the CUDA driver events that occur during the
application lifecycle.

General patterns:

* `nvbit_at_init` fires first, before any context or tool state is
  created.
* `nvbit_at_ctx_init` fires during context setup.
* `nvbit_tool_init` is called before the first kernel launch.
* `nvbit_at_cuda_event` fires for each relevant CUDA driver call.
* `nvbit_at_graph_node_launch` fires when a graph node is launched.
* `nvbit_at_ctx_term` fires during context teardown.
* `nvbit_at_term` fires last, during library shutdown.

## Example: instr_count

The `instr_count` example tool implements three callbacks:

* `nvbit_at_init` — library-level setup
* `nvbit_at_cuda_event` — intercepts CUDA events to count instructions
* `nvbit_at_term` — finalization and output

It does not implement context-level or graph-launch callbacks. This
demonstrates that tools select only the callbacks relevant to their
analysis goals.
