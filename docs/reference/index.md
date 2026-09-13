# API Reference

This section contains API reference material for NVBit 1.8.

APIs are organized into the following categories:

* **Core API** — the main `nvbit.h` interface: lifecycle callbacks,
  function and instruction inspection, instrumentation insertion, device
  utilities, and control APIs.
* **Instruction types** — definitions for instruction representation
  and SASS opcodes.
* **Register read/write** — APIs for accessing register state.
* **Channel** — device-to-host communication infrastructure.
* **Tool support** — the `nvbit_tool.h` interface for tool module
  registration and host-side utilities.

```{toctree}
:maxdepth: 1

core-api
tool-support
```

## Breathe integration

The reference pages below use MyST `doxygenfile::` directives to
include API documentation generated from NVBit 1.8 headers by Doxygen
and integrated via Breathe.

```{note}
The Sphinx configuration (`conf.py`) must define the Breathe and
Doxygen integration paths before these pages will render correctly.
If you encounter unresolved directives, ensure that Doxygen XML has
been generated and that `breathe_default_members` and
`breathe_member_order` are configured appropriately.
```
