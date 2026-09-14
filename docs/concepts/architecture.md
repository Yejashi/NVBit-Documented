# Architecture

NVBit sits between a CUDA application's host-side driver activity and the GPU
machine code that eventually executes. A tool can observe CUDA events, inspect
decoded SASS, describe code instrumentation, and then collect data produced by
the injected device routines.

## Components

```text
CUDA application
    |
    | CUDA driver activity
    v
NVBit runtime + tool callbacks
    |
    +--> CUcontext / CUfunction discovery
    +--> SASS decoding -> Instr objects
    +--> insertion requests + arguments
    +--> instrumented/original selection per launch
    |
    v
GPU function with injected calls
    |
    +--> device analysis routine
    |       |
    |       +--> counter / memory / channel
    |
    v
tool host-side processing
```

There are four distinct objects in this picture.

### The target application

This is the unmodified CUDA program the user wants to study. Its source code is
not required for ordinary NVBit instrumentation. The tool observes the
compiled functions that become available in the CUDA context.

### The NVBit tool

The tool is a shared library loaded into the application process. Its
host-side code exports callbacks such as `nvbit_at_ctx_init()`,
`nvbit_tool_init()`, and `nvbit_at_cuda_event()`.

These callbacks are not ordinary application callbacks registered through a
table. NVBit locates the exported callback symbols defined by the tool.

### The instrumented function

A `CUfunction` is the unit through which tools ask for related functions,
decoded instructions, configuration, and instrumentation enablement.

Calling `nvbit_get_instrs(ctx, func)` gives the static instruction
representation. Inserting calls does not mean those calls execute immediately;
they execute only when the corresponding instrumented function variant later
runs.

### The device instrumentation routine

This is GPU code invoked from the injected call site. It can receive values
derived from the executing instruction:

- the guard predicate;
- constants chosen by the host tool;
- ordinary or uniform register values;
- constant-bank values;
- runtime memory-reference addresses;
- launch-time values;
- TMA parameter information in the 1.8 TMA path.

This boundary is how a static host-side decision turns into dynamic execution
data.

## Instrumentation time versus execution time

A frequent NVBit mistake is to mix these phases.

**Instrumentation time**

- enumerate `Instr` objects;
- inspect opcodes and operands;
- choose insertion points;
- add argument descriptors.

**Launch time**

- attach launch-specific values with `nvbit_set_at_launch()`;
- select original versus instrumented code with
  `nvbit_enable_instrumented()`;
- handle CUDA Graph node-specific launch state where applicable.

**GPU execution time**

- materialize register values and memory addresses;
- execute the injected routine;
- update counters or push channel records.

`nvbit_add_call_arg_mref_addr64()`, for example, is called by the host while
instrumenting, but the effective address passed to the device routine is the
address generated when that SASS memory operation actually executes.

## Per-context design

CUDA applications can create multiple contexts. Resources tied to one
context—instrumented-function sets, tool modules, channels, and helper
functions—should be modeled as context state.

NVBit 1.8 also adds support for Green Context environments. The general rule
remains: avoid treating a process-wide global as equivalent to one CUDA
context unless the data is truly context-independent.

## Two communication styles

Small tools can keep counters in memory visible to the host and report them
after a launch. High-volume tools such as memory tracers generally need an
asynchronous device-to-host path. NVBit's channel utilities provide a
producer/consumer mechanism for this purpose.

Channels are a tool design facility, not part of the semantics of
`nvbit_insert_call()` itself. A tool may instrument code without using a
channel.

## Helper tool kernels

Recent NVBit releases include explicit APIs for device modules owned by the
tool. A tool can load an embedded module, resolve a helper `CUfunction`, and
launch it with NVBit's helper-kernel API. This is especially useful for tasks
such as channel flushing without relying on lazy CUDA module loading inside a
sensitive callback path.

See [Tool Modules and Tool Kernels](../guides/tool-modules.md).
