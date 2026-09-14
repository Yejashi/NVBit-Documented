# CUDA Graphs

CUDA Graphs change the launch model from a simple one-driver-call-per-kernel
sequence to graph construction, instantiation, and later execution of graph
nodes. NVBit 1.8 exposes graph-aware mechanisms so a tool can associate
instrumentation state with an individual node launch.

## Why ordinary launch handling is not enough

A conventional launch tool may attach a value immediately before
`cuLaunchKernel` and assume that value identifies the execution that follows.
A graph can contain multiple kernel nodes prepared earlier and launched as
part of a graph execution.

The tool therefore needs an identity for the concrete graph-node launch.

## Graph node callback

`nvbit_at_graph_node_launch(ctx, func, stream, launch_handle)` is called for a
graph node launch and supplies:

- the CUDA context;
- the node's `CUfunction`;
- the stream;
- an NVBit launch handle.

The stream and launch handle are important when launch-specific tool arguments
must differ across graph nodes.

## Launch-time values

The modern `nvbit_set_at_launch()` interface accepts the value to attach and,
for graph-aware use, can also use a stream and launch handle.

The conceptual relationship is:

```text
instrumentation time
    |
    +--> add launch-value argument slot
          nvbit_add_call_arg_launch_val64(...)

graph-node launch
    |
    +--> nvbit_at_graph_node_launch(...)
          |
          +--> nvbit_set_at_launch(..., stream, launch_handle)

device execution
    |
    +--> injected function receives that node's value
```

This avoids treating one process-global variable as if it uniquely described
all nodes executing from a graph.

## Instrumentation still belongs to functions

Graph support does not replace the normal function instrumentation model.
A node still refers to a `CUfunction` whose instructions can be instrumented
and whose instrumented variant can be enabled.

Use the graph callback for node-specific launch state, not as a reason to
reinsert the same instruction calls every time the graph executes.

## Example to study

The 1.8 release includes `instr_count_cuda_graph`. Compare it with
`instr_count` to see which parts of a basic tool stay the same and which parts
are graph-specific.

The key lesson is architectural: separate **static instrumentation of the
function** from **dynamic identity of one node launch**.
