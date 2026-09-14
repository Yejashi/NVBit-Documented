# Tracing TMA Operations

NVBit 1.8 adds an alpha TMA tracing path for Hopper and Blackwell. This guide
shows how to integrate it without conflating TMA transfers with conventional
memory-reference addresses.

## 1. Detect TMA instructions

When walking `Instr` objects, identify instructions that NVBit classifies as
TMA memory operations.

Keep the full opcode representation available. The host-side TMA parser may
need dimensional/modifier information encoded in that opcode.

## 2. Insert a TMA-specific device call

For a TMA call site, append the TMA parameter handle and size:

```cpp
nvbit_insert_call(instr, "instrument_tma", IPOINT_BEFORE);
nvbit_add_call_arg_guard_pred_val(instr);
// add compact static identifiers as needed
nvbit_add_call_arg_tma_param_handle_and_size(instr, ctx);
// add channel/state pointer
```

Do not replace the TMA handle with a fabricated single MREF address.

## 3. Copy handle data into the record

The injected device routine should copy the runtime handle bytes/size into a
record that survives long enough to reach the host.

Because the handle representation is version-specific, store its actual length
rather than assuming a fixed meaningful size in downstream code.

## 4. Send through the channel

A TMA record can use the same `ChannelDev -> ChannelHost` transport as normal
memory records, but give it a record-type tag so the receiver can distinguish:

```text
NORMAL_MEMORY_RECORD
TMA_RECORD
CONTROL / FLUSH RECORD
...
```

Do not reinterpret a TMA payload through the ordinary memory-record struct.

## 5. Parse on the host

On the receiver side, call conceptually:

```cpp
TMATransferInfo_t info =
    nvbit_parse_tma_transfer_info(
        ctx,
        full_opcode,
        record.handle_bytes,
        record.handle_size);
```

The resulting object describes the transfer at a higher semantic level than a
single effective address.

## 6. Persist structured metadata

Useful output may include:

- whether the transfer is bulk/tensor;
- source and destination memory spaces;
- shared-memory data/barrier addresses;
- tensor/tile metadata;
- dimensions;
- transfer size.

Design the file format so fields can be added as NVBit's alpha TMA support
evolves.

A nested binary/JSON object or a versioned union is safer than a fixed table
whose columns assume one transfer shape.

## 7. Preserve raw evidence when feasible

For research tools, consider storing:

- NVBit version;
- GPU architecture;
- full SASS/opcode identifier;
- raw TMA handle bytes;
- parsed TMA structure.

The raw representation allows later re-parsing if the interpretation changes.

## 8. Handle TMA operand registers deliberately

NVBit 1.8 can represent TMA parameters through a TMA-specific operand
containing uniform-register information.

If your analysis requires those register values in addition to parsed transfer
metadata, explicitly append `nvbit_add_call_arg_ureg_val()` arguments for the
relevant uniform registers.

Do not assume a generic "all register operands" loop written for pre-1.8
instruction kinds sees the TMA parameter representation correctly.

## 9. Validate with controlled transfers

Before tracing an application:

1. run a TMA microbenchmark with a known tensor map and transfer size;
2. verify the parser reports the expected dimensions and memory spaces;
3. compare address/size outcomes with the kernel setup;
4. test more than one dimensional form;
5. test repeated launches to ensure handle lifetime/copying is correct.

TMA support is marked alpha, so validation against known transfers is
particularly important.

## 10. Keep the ordinary path intact

A complete 1.8 memory tracer is a union:

```text
if Instr is TMA:
    use TMA-handle path
else if Instr has conventional memory references:
    use mref-address path
else:
    do not emit memory record
```

This avoids both dropping TMA traffic and misclassifying ordinary loads/stores.
