# Example: `instr_count`

`instr_count` is the best starting point because it exercises the NVBit
instrumentation lifecycle without the complexity of a large device-to-host
trace.

## Purpose

The tool counts dynamic GPU instructions for kernel launches. The important
lesson is not the arithmetic; it is how a tool turns static SASS call sites
into a dynamic count.

## Host-side flow

The tool's launch path conceptually does:

```text
kernel launch entry
      |
      +--> recover CUfunction
      |
      +--> instrument_function_if_needed
      |       |
      |       +--> related functions
      |       +--> duplicate guard
      |       +--> nvbit_get_instrs
      |       +--> insert counting calls
      |
      +--> nvbit_enable_instrumented(..., true)
      |
      v
kernel executes
```

The injected routine updates a counter; the host reports the result at an
appropriate synchronization/reporting point.

## Predicated instructions

An instruction can be present in the SASS stream but have its guard predicate
evaluate false for some lanes.

A dynamic instruction metric must define whether it counts:

- all visits to the static instruction position;
- only lanes whose guard is true;
- once per warp when at least one lane executes;
- once per active thread.

The example exposes configuration around counting behavior. When building a
research tool, write the counting unit into the output metadata instead of
leaving it implicit.

## Why related functions matter

If the kernel calls a non-inlined device function, dynamic instructions inside
that function still contribute to execution.

Walking `nvbit_get_related_functions()` and appending the kernel itself gives a
more complete count than instrumenting only the entry function.

The duplicate set prevents a shared callee from receiving another injected
counter call every time it is reached from a new kernel.

## Why counting is cheaper than tracing

The device routine can aggregate many dynamic events into a small amount of
state. That avoids transmitting one record for every instruction.

This is a general design principle:

> If your final statistic is associative/reducible, consider aggregating on the
> GPU instead of recording the entire event stream.

A histogram, opcode count, or region count may not need a channel at all.

## What to copy into a new tool

Good patterns to reuse:

- callback structure;
- related-function walk;
- duplicate guard;
- guard-predicate handling;
- separation between instrumentation and launch enablement.

Things to redesign for your own metric:

- counter width and location;
- warp/thread aggregation;
- launch synchronization;
- reset/report policy;
- filters.

## Next example

After understanding `instr_count`, read
[`mem_trace`](mem-trace.md). It uses the same launch/instrumentation skeleton
but replaces one compact counter with a stream of dynamic memory records.
