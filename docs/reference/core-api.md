# Core API

The core NVBit API is declared in `nvbit.h`. It provides the primary
interface for building instrumentation tools.

## Categories

### Callback / lifecycle APIs

Functions and types for registering NVBit callbacks:

* `nvbit_at_init`
* `nvbit_at_ctx_init`
* `nvbit_tool_init`
* `nvbit_at_cuda_event`
* `nvbit_at_graph_node_launch`
* `nvbit_at_ctx_term`
* `nvbit_at_term`

See the [Lifecycle](../concepts/lifecycle.md) concept page for details
on callback triggers and ordering.

### Tool-module APIs

Functions for tool initialization and registration:

* `nvbit_load_tool_module()` — load and register the tool module
* Tool lifecycle hooks
* Pthread registration
* Context-level initialization

### Inspection APIs

Functions for discovering and analyzing GPU functions and their
instructions:

* `nvbit_get_instrs()` — obtain the instruction list for a CUDA function
* `nvbit_get_related_functions()` — find functions reachable from a
  given entry point
* Instruction filtering and opcode inspection

```{doxygenfunction} nvbit_get_instrs
```

```{doxygenfunction} nvbit_get_related_functions
```

### Insertion APIs

Functions for injecting device routine calls into GPU code:

* `nvbit_insert_call()` — insert a call before or after a specific
  instruction
* `nvbit_add_call_arg_mref_addr64()` — add a memory-reference address
  argument to an inserted call
* `nvbit_enable_instrumented()` — activate instrumentation for the
  current context
* Guard predicate APIs

```{doxygenfunction} nvbit_insert_call
```

```{doxygenfunction} nvbit_add_call_arg_mref_addr64
```

```{doxygenfunction} nvbit_enable_instrumented
```

### Device APIs

Utilities for device-side code execution within instrumentation
routines:

* Channel communication (`ChannelDev::push`, `ChannelDev::recv`)
* Thread synchronization primitives
* Launch-time value access

### Control APIs

Functions for managing tool behavior:

* Instrumentation enable/disable
* Context-level flags
* Tool state queries

```{doxygenfunction} nvbit_set_at_launch
```

## Related headers

The core API page focuses on `nvbit.h`. Additional types and constants
used by tools are defined in related headers:

* `instr_types.h` — SASS instruction types and opcodes
* `nvbit_reg_rw.h` — register read/write utilities
* `channel.hpp` — channel communication types and methods
