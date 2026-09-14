# API Reference

This section is a map of the NVBit 1.8 API from the perspective of tool
authors. It complements, rather than replaces, the Doxygen output generated
from the release headers during the documentation build.

## Reference groups

- [Core API](core-api.md) — lifecycle, function discovery, enablement, launch
  values, and tool-owned module helpers.
- [Instruction API](instruction-api.md) — `Instr`, predicates, operands,
  memory references, and raw SASS encoding.
- [Call-Argument API](call-argument-api.md) — values that can be supplied to
  injected device functions.
- [Tool Support API](tool-support.md) — channels, tool threads, and
  per-context support patterns.
- [Version Notes](version-notes.md) — behavior in 1.8 and recent changes that
  matter when porting older tools.

## Three API phases

The easiest way to find the right API is to ask when the operation occurs.

### Instrumentation time

Use APIs such as:

- `nvbit_get_related_functions`;
- `nvbit_get_instrs`;
- `nvbit_insert_call`;
- `nvbit_add_call_arg_*`.

These describe static call sites and where their future runtime arguments come
from.

### Launch time

Use:

- `nvbit_set_at_launch`;
- `nvbit_enable_instrumented`;
- `nvbit_at_graph_node_launch` for graph-specific launch identity.

These choose what happens for one launch without rebuilding the static
instrumentation.

### Tool runtime/support

Use:

- `ChannelDev` / `ChannelHost`;
- `nvbit_set_tool_pthread`;
- `nvbit_load_tool_module`;
- `nvbit_find_function_by_name`;
- `nvbit_launch_kernel`.

These support communication and tool-owned GPU work.

## Generated header reference

The documentation build downloads and extracts the official 1.8 artifact
before Doxygen runs. Breathe directives on the following pages therefore bind
to the release headers, not to hand-maintained copies in this repository.

If an API name or signature in prose appears to disagree with the generated
reference, verify the extracted 1.8 header first and file a documentation fix.
