# Tool Support API

The tool support API is declared in `nvbit_tool.h`. It provides
host-side utilities for building NVBit tools.

## Categories

### Callback registration

Functions for registering tool callbacks with NVBit at initialization
time. Tools use these to receive lifecycle notifications from NVBit.

### Host-side utilities

Utilities for managing the host-side portion of a tool:

* Thread management for receiver threads
* File I/O and output formatting
* Host-side channel handling (`ChannelHost`)
* Pthread hook registration

### Context management

Functions for setting up and tearing down per-context tool state:

* Loading flush modules
* Allocating and freeing managed memory
* Synchronizing with device-side operations

```{doxygenfile} nvbit_tool.h
```

## Relationship to core API

The tool support API complements the core API (`nvbit.h`). While the
core API provides the device-side instrumentation interface, the tool
support API provides the host-side infrastructure needed to collect,
process, and report instrumentation data.
