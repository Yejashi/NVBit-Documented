# Example: `mem_trace_tma`

`mem_trace_tma` demonstrates the TMA-specific instrumentation introduced in
NVBit 1.8.

The important lesson is architectural: TMA transfer information is captured
through a runtime parameter handle and parsed into a structured description on
the host.

## Why this is not ordinary `mem_trace`

An ordinary memory instruction can often be represented by one or more runtime
effective addresses.

A TMA instruction can describe a multi-dimensional/bulk transfer. Reducing it
to one address would discard the transfer semantics the tool is trying to
observe.

## Instrumentation path

For a TMA instruction, the tool uses a TMA-specific argument source rather
than only `nvbit_add_call_arg_mref_addr64()`:

```text
TMA Instr
  |
  +--> insert TMA instrumentation function
  +--> pass guard/static IDs
  +--> pass TMA parameter handle + size
  +--> pass channel/state
```

The injected function packages the handle data into a record.

## Receiver path

On the host, the receiver gives the captured handle to
`nvbit_parse_tma_transfer_info()` together with the context and opcode
information.

The result is a `TMATransferInfo_t` containing structured information about the
transfer.

Keep the full opcode/modifiers available because dimensions can be encoded in
the opcode form used by the parser.

## Trace schema

A TMA record should be typed separately from a normal memory record. Good
fields include:

- launch and instruction identity;
- full opcode/static metadata;
- TMA handle size;
- raw handle bytes if reproducibility is important;
- parsed transfer data.

Do not force every TMA transfer into a fixed "address + width" record used for
ordinary load/store instructions.

## Hardware scope

The 1.8 release describes TMA support as alpha and targets Hopper and
Blackwell. A tool should therefore make unsupported architectures explicit
instead of silently pretending a TMA trace is complete.

## What to reuse

The example is the right reference for:

- detecting TMA operations with 1.8;
- passing the TMA handle;
- parsing it on the host;
- integrating TMA records with a channel;
- handling new operand forms.

For conventional global/shared/local memory instructions, retain the ordinary
`mem_trace` path.
