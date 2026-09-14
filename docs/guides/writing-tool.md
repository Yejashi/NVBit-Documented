# Writing an NVBit Tool

This guide gives an end-to-end design for a production-quality NVBit tool.
The goal is not to prescribe one source-file layout; it is to make the
lifecycle and ownership decisions explicit.

## 1. Define the dynamic event you need

Start with the output record, not with an NVBit callback.

Examples:

- dynamic instruction count per kernel;
- opcode + active predicate;
- register value at a selected instruction;
- memory-reference address per lane;
- TMA transfer metadata.

Classify every field as either:

- **static**: derivable once from `Instr` and function metadata;
- **launch-specific**: changes per kernel/node launch;
- **dynamic**: only exists when the GPU instruction executes.

That classification tells you which NVBit mechanism to use.

## 2. Define per-context state

A substantial tool often needs:

```cpp
struct CTXstate {
    std::set<CUfunction> instrumented;
    // channel state
    // receiver-thread state
    // tool module / helper CUfunction
    // function -> static metadata maps
    // launch bookkeeping
};
```

Maintain a `CUcontext -> CTXstate` map. Do not assume a process has exactly one
context.

Protect shared host state with a mutex where callbacks or receiver threads can
access it concurrently.

## 3. Split initialization correctly

Use `nvbit_at_ctx_init` to create host bookkeeping without doing CUDA memory
allocation.

Use `nvbit_tool_init` for context-specific CUDA allocations and channel setup.
The NVBit header explicitly warns against CUDA memory allocation during
`nvbit_at_ctx_init` because of deadlock risk.

If you create a receiver thread, register it with
`nvbit_set_tool_pthread()`.

## 4. Write the instrument-once routine

A good helper has one job: given a context and entry function, ensure the
desired call sites exist exactly once.

```text
instrument_function_if_needed(ctx, entry)
    |
    +--> get related functions
    +--> append entry itself
    |
    +--> for each function
          |
          +--> skip if already instrumented
          +--> get Instr vector
          +--> inspect/filter each Instr
          +--> insert call
          +--> append call arguments
```

Avoid mixing launch counters or output draining into this helper.

## 5. Make the device routine signature the contract

If host code appends:

```text
1. guard predicate        -> int
2. opcode ID              -> uint32_t/int
3. memory address         -> uint64_t
4. launch value           -> uint64_t
5. channel pointer        -> uint64_t/pointer
```

then the device routine must accept compatible parameters in the same order.

When changing one side, change and review the other side in the same patch.
Argument-order mismatches can compile yet produce nonsense at runtime.

## 6. Keep static metadata out of every record when possible

If an opcode string, function name, SASS string, or raw instruction bytes are
constant for a call site, assign a compact ID during instrumentation and keep
a host-side dictionary.

Then the dynamic record can carry:

```text
instruction_id, launch_id, predicate, address...
```

instead of repeatedly transmitting long strings. This is particularly
important for channel throughput.

## 7. Handle launch entry

On a recognized kernel launch entry:

1. recover the `CUfunction`;
2. check user filters;
3. instrument it if needed;
4. set any launch value with `nvbit_set_at_launch()`;
5. call `nvbit_enable_instrumented()` according to policy;
6. increment launch bookkeeping only after values needed by this launch have
   been copied/set.

If collection is sampled, instrument once and toggle enablement rather than
rebuilding call sites.

## 8. Handle launch completion deliberately

A CUDA launch can be asynchronous. If the tool needs to read a counter or
flush data after a kernel, it must establish completion using a synchronization
strategy appropriate to the tool.

Serialization can dramatically perturb application behavior. NVBit's modern
`mem_trace` direction avoids unnecessary default kernel serialization. Do not
add a global device synchronize after every launch unless the analysis truly
requires it.

## 9. Drain high-volume output

For traces, use a channel/receiver architecture:

```text
injected device function
        |
        v
ChannelDev::push(record)
        |
        v
channel buffer
        |
        v
ChannelHost receiver thread
        |
        v
decode / aggregate / persist
```

Keep receiver work efficient. Heavy parsing or file I/O may need buffering
beyond the channel thread itself.

## 10. Flush with an explicit helper path

For a tool-owned flush kernel, prefer the 1.8-era explicit module pattern:

- `nvbit_load_tool_module()`;
- `nvbit_find_function_by_name()`;
- `nvbit_launch_kernel()`.

This avoids relying on lazy loading of the tool's own CUDA kernel from a
callback-sensitive path.

See [Tool Modules and Tool Kernels](tool-modules.md).

## 11. Tear down in dependency order

At context termination, reason backward through ownership:

```text
no more producers
    -> outstanding GPU work complete
    -> final records flushed
    -> receiver stopped/joined
    -> channel memory freed
    -> module/context state released
```

Do not destroy an object while another host thread or GPU kernel can still
access it.

## 12. Validate in layers

A useful progression is:

1. tool loads and callbacks print;
2. static instruction filter selects expected sites;
3. injected routine increments a counter;
4. one dynamic field is correct;
5. channel path works for a tiny target;
6. high-volume target works;
7. multi-kernel and repeated-launch cases work;
8. multiple contexts/graphs if relevant;
9. compare output against an independent profiler or known microbenchmark.

This narrows failures much faster than beginning with a full trace schema.
