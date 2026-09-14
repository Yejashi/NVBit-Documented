# Shipped Example Tools

The NVBit 1.8 release examples are the best executable map of how the APIs are
intended to fit together. They are more useful when read as a progression of
design patterns rather than as unrelated demos.

## Suggested reading order

| Order | Example | What to learn |
|---:|---|---|
| 1 | `instr_count` | callbacks, function discovery, insertion, enablement |
| 2 | `opcode_hist` | instruction classification and compact metadata |
| 3 | `instr_count_bb` | basic-block granularity |
| 4 | `record_reg_vals` | dynamic register values and variadic arguments |
| 5 | `mem_printf` | simple dynamic memory observation |
| 6 | `mem_trace` | channels, launch IDs, full tracing pipeline |
| 7 | `instr_count_cuda_graph` | graph-aware launch handling |
| 8 | `mem_trace_tma` | NVBit 1.8 TMA parameter/parse path |
| 9 | `mov_replace` | modifying semantics rather than only observing |
| — | `mem_read_shared` | focused shared-memory example |

## Common skeleton

Most tools share the same host-side shape:

```text
initialization
    |
context state
    |
kernel launch callback
    |
    +--> recover CUfunction
    +--> instrument if needed
    +--> enable/disable instrumented variant
    |
GPU executes injected routine
    |
result is counted, printed, or streamed
    |
context/tool teardown
```

Once this skeleton is familiar, the interesting part of each example is the
**argument source and output mechanism**.

## Counting examples

`instr_count` and `instr_count_bb` show that an analysis does not need to
stream one record per instruction. If the research question can be represented
by a counter or histogram, aggregating on device can be dramatically cheaper
than a full trace.

Use these examples to learn:

- predication policy;
- warp- versus thread-level counting choices;
- static instruction count versus dynamic executed count;
- launch-level reporting.

## Opcode histogram

`opcode_hist` demonstrates a useful trace optimization: map a static opcode or
instruction type to a compact integer ID and update an aggregate instead of
transmitting text from every dynamic execution.

The same idea generalizes to full tracers: keep a static dictionary and use
small IDs in dynamic records.

## Register values

`record_reg_vals` shows how decoded operands at instrumentation time determine
which registers should be read at execution time.

Study the relationship between:

- operand inspection;
- `nvbit_add_call_arg_reg_val()`;
- variadic arguments;
- receiver interpretation.

## Memory tools

`mem_printf` is conceptually simple but device `printf` does not scale to high
event rates.

`mem_trace` adds the important production pattern:

- multiple memory-reference operands;
- dynamic effective addresses;
- launch identifiers;
- `ChannelDev` and `ChannelHost`;
- a registered receiver thread;
- explicit flushing/teardown.

For serious trace collection, `mem_trace` is the central example.

## CUDA Graphs

`instr_count_cuda_graph` extends the counting model to graph-node launches.
Compare it line by line with the non-graph counter and focus on where
`nvbit_at_graph_node_launch()` and graph-aware launch values enter.

## TMA

`mem_trace_tma` is specific to NVBit 1.8's alpha TMA support. It illustrates
why TMA tracing is not simply another call to
`nvbit_add_call_arg_mref_addr64()`.

The TMA flow passes a runtime parameter handle to device instrumentation and
parses it on the host into structured transfer information.

## Instruction replacement

`mov_replace` is intentionally different from the observational examples. It
shows that NVBit can remove an original instruction and inject behavior that
replaces it.

Treat it as an advanced example: correctness depends on reproducing original
semantics, predication, and operand behavior.

## How to study an example

For each tool, answer these questions:

1. Which callbacks does it export?
2. Which state is process-wide and which is per context?
3. How does it find the entry `CUfunction`?
4. Does it include related functions?
5. Which `Instr` objects are selected?
6. Which `nvbit_add_call_arg_*` calls populate the device routine?
7. What does the device routine do per dynamic event?
8. Where does the result live?
9. How does the tool know the GPU is finished with that result?
10. How is teardown ordered?

Those questions turn example code into a reusable design pattern.
