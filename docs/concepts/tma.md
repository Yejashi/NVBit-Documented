# Tensor Memory Accelerator Support

NVBit 1.8 adds alpha support for tracing Tensor Memory Accelerator (TMA)
operations on Hopper and Blackwell GPUs.

TMA should be treated as a separate memory-observation path rather than forced
into the model of an ordinary scalar/vector SASS memory instruction.

## Why TMA is different

For a conventional load/store, a tracer can often attach an effective-address
argument for each memory-reference operand and record the resulting address.

A TMA instruction represents a higher-level transfer whose addressing and
shape depend on runtime parameter data. The useful result may include transfer
kind, source/destination spaces, shared-memory locations, tensor-map
information, dimensions, and a transfer width rather than one scalar address.

## 1.8 parameter-handle path

The 1.8 ecosystem uses a TMA parameter-handle argument to bridge device
execution and host-side parsing.

Conceptually:

```text
Instr identified as TMA memory operation
        |
        v
insert device instrumentation call
        |
        +--> nvbit_add_call_arg_tma_param_handle_and_size(instr, ctx)
        |
        v
device routine copies handle bytes into trace record
        |
        v
host receiver
        |
        +--> nvbit_parse_tma_transfer_info(...)
        |
        v
structured TMA transfer information
```

The host parser requires the context, opcode information, the captured handle
bytes, and their size.

## Keep the full opcode

TMA opcode modifiers can encode information needed to interpret the transfer.
Do not normalize the opcode so aggressively that dimensional information such
as a `.2D`-style modifier is lost before host-side parsing.

A robust tracer stores either the full opcode string or an unambiguous opcode
identifier that can reconstruct the exact parser input.

## TMA parameter operands

NVBit 1.8 can expose a TMA-specific operand representation rather than a set of
ordinary independent uniform-register operands. If a tool also wants those
underlying register values, inspect the TMA operand metadata and explicitly
capture the desired uniform registers.

Do not assume an older operand walker will automatically understand the new
operand kind.

## Structured results

Treat the parsed `TMATransferInfo_t` as structured transfer metadata. A trace
format should not flatten it prematurely into one "address" column.

A useful schema separates:

- instruction identity and opcode;
- raw TMA handle bytes (optional but useful for reproducibility);
- parsed transfer kind;
- source and destination memory spaces;
- shared-memory data/barrier addresses when relevant;
- tensor/tile metadata;
- derived transfer size.

The exact fields can evolve with NVBit's alpha support, so a durable serialized
format should be versioned.

## Scope and limitations

The 1.8 release notes explicitly describe TMA support as alpha and scope it to
Hopper and Blackwell. That has practical implications:

- test on the GPU generations the release claims to support;
- keep fallback behavior for non-TMA instructions;
- version traces with the NVBit release;
- do not assume the TMA representation is as stable as long-standing core
  instrumentation APIs.

See [Tracing TMA Operations](../guides/tma-tracing.md) for a task-oriented
workflow and [mem_trace_tma](../examples/mem-trace-tma.md) for the shipped
example.
