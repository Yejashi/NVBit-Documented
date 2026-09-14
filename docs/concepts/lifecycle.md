# Callback Lifecycle

NVBit tools participate in the CUDA process through exported callback
functions. A tool implements the callbacks it needs; it does not have to
provide every callback.

The lifecycle matters because not every callback is a safe place to perform
the same CUDA operation.

## Callback map

| Callback | Role |
|---|---|
| `nvbit_at_init` | process/tool-library initialization |
| `nvbit_at_ctx_init` | a CUDA context has been created |
| `nvbit_tool_init` | tool setup before the first kernel launch in a context |
| `nvbit_at_cuda_event` | entry/exit notification around CUDA driver events |
| `nvbit_at_graph_node_launch` | a CUDA Graph kernel node is about to launch |
| `nvbit_at_ctx_term` | context teardown |
| `nvbit_at_term` | final tool/library teardown |

The exact application event stream determines how often the context- and
CUDA-event callbacks occur. Do not invent a single fixed global sequence for a
multi-context application.

## `nvbit_at_init`

Use this for process-wide initialization that does not require a CUDA context,
for example:

- parsing environment variables;
- initializing process-wide mutexes;
- opening configuration-independent host resources.

Keep context-specific CUDA objects out of this stage because a context may not
yet exist.

## `nvbit_at_ctx_init`

This callback is the natural place to allocate the **host-side bookkeeping
object** for a new `CUcontext`.

A crucial NVBit rule is that CUDA memory allocation should not be performed
from this callback. The 1.8 header warns that doing so can deadlock. If the
tool needs managed/device allocation, defer it to `nvbit_tool_init`.

A common pattern is:

```text
nvbit_at_ctx_init(ctx)
    |
    +--> allocate CTXstate on host
    +--> insert ctx -> CTXstate in map
    +--> record non-allocating metadata
```

## `nvbit_tool_init`

This callback exists specifically for initialization that needs to occur once
the context is ready for tool-side CUDA work. Channel-based tools typically use
it to:

- allocate managed/device channel state;
- initialize `ChannelHost`;
- start the receiver thread;
- register that thread with `nvbit_set_tool_pthread()`;
- finish context-specific resources that could not safely be initialized in
  `nvbit_at_ctx_init`.

Treat this callback as per-context initialization.

## `nvbit_at_cuda_event`

The signature includes:

- the current `CUcontext`;
- `is_exit`;
- a CUDA callback ID;
- an event name;
- event-specific parameter data;
- the CUDA result pointer.

The fundamental timing rule is:

- `is_exit == 0`: callback on driver-call entry;
- `is_exit == 1`: callback on driver-call exit.

For a kernel launch, entry is where a tool normally instruments the target
function, sets launch-time values, and chooses the instrumented variant.
Exit-side work is appropriate only when its synchronization assumptions are
explicit.

### Do not recursively instrument your own tool activity

If a receiver or helper thread issues CUDA operations, register it with
`nvbit_set_tool_pthread()`. NVBit then knows that CUDA events from that tool
thread should not recursively enter the normal tool callbacks.

This is especially important in channel-based tools.

## `nvbit_at_graph_node_launch`

CUDA Graphs separate graph construction/instantiation from individual node
execution. NVBit exposes a graph-node launch callback carrying the function,
stream, and a launch handle.

The callback is primarily important when the tool uses
`nvbit_set_at_launch()` and different graph nodes need different launch-time
values. For graph launches, the stream and launch handle identify the concrete
node launch to which that value belongs.

See [CUDA Graphs](cuda-graphs.md).

## `nvbit_at_ctx_term`

Context termination is where per-context resources are drained and destroyed.

A channel-based tool commonly needs to:

1. stop creating new records;
2. make sure outstanding kernel activity is complete according to the tool's
   synchronization design;
3. flush remaining channel records;
4. stop/join the receiver;
5. release device/managed allocations;
6. unload or forget context-specific helper-module state;
7. remove the context from the state map.

Ordering matters. Freeing channel memory before the producer and receiver are
finished creates use-after-free races.

## `nvbit_at_term`

Use final termination for process-wide output and resources that outlive all
contexts. Do not rely on it as the only cleanup point for resources owned by a
`CUcontext`.

## A realistic lifecycle

For a simple one-context application:

```text
tool shared object loaded
        |
nvbit_at_init
        |
CUDA context creation
        |
nvbit_at_ctx_init
        |
nvbit_tool_init
        |
        +---- kernel launch entry ----+
        |     nvbit_at_cuda_event     |
        |     instrument / enable     |
        |                             |
        |     GPU kernel executes     |
        |                             |
        |     launch exit             |
        +-----------------------------+
        |
(possibly many more CUDA events)
        |
nvbit_at_ctx_term
        |
nvbit_at_term
```

CUDA Graphs, multiple contexts, libraries, and helper threads add branches to
this picture; they do not remove the phase distinctions.
