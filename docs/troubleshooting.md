# Troubleshooting

NVBit failures tend to fall into three groups: loading/build compatibility,
callback/lifecycle mistakes, or incorrect instrumentation-data plumbing.

## Tool does not load

### Symptom

The target runs normally and no tool initialization output appears.

### Check

- use an absolute path in `LD_PRELOAD` or `CUDA_INJECTION64_PATH`;
- confirm the shared object exists and matches the host architecture;
- inspect dynamic-library errors from the loader;
- confirm the tool is linked against the intended NVBit release.

Do not debug instruction filters until you know the shared object actually
loaded.

## Tool loads but no kernels are instrumented

Confirm:

1. `nvbit_at_cuda_event` is reached;
2. the callback ID corresponds to a kernel launch form the application uses;
3. the launched `CUfunction` is recovered correctly;
4. `nvbit_get_instrs` returns instructions;
5. the filter selects at least one;
6. `nvbit_enable_instrumented` is true for the launch.

Log function names and selected static instruction counts before adding channel
complexity.

## Deadlock during context initialization

If the tool performs CUDA allocation in `nvbit_at_ctx_init`, move that
allocation to `nvbit_tool_init`.

The NVBit header explicitly warns that CUDA memory allocation during context
initialization can deadlock.

Also review any CUDA runtime call that may lazily load a tool-owned helper
kernel. Use the explicit tool-module APIs in 1.8 for helper kernels.

## Recursive or unexpected callbacks

A receiver/helper pthread owned by the tool may be issuing CUDA operations and
triggering the same callbacks used to observe the target.

Register it with `nvbit_set_tool_pthread()`.

Keep target-application and tool-internal CUDA work separate in logs.

## Duplicate records

If one static instruction appears to have two or more injected calls, check the
already-instrumented guard.

The same function may be:

- launched repeatedly;
- reachable from multiple entry kernels.

Instrument a `CUfunction` once per appropriate context/lifetime.

## Device routine receives garbage fields

First compare the device function signature against the exact order of
`nvbit_add_call_arg_*` calls.

Common mistakes:

- 32-bit constant paired with 64-bit parameter expectations;
- address and launch-ID arguments reversed;
- missing guard-predicate argument;
- wrong variadic count;
- treating a uniform register as a general register.

## Memory addresses look incomplete

Check whether the instruction has multiple memory-reference operands.

Do not assume `mref_index = 0` is always sufficient. The 1.8 lineage removed
older fixed-MREF assumptions; iterate decoded MREF operands.

Also distinguish the effective address stream from cache transactions or
coalesced requests.

## Channel hangs during teardown

Audit ownership/order:

1. are producer kernels finished?
2. is the final flush issued?
3. is the receiver still alive to consume it?
4. is the receiver joined before memory is freed?
5. is the helper kernel/module valid in this context?

A correct channel pipeline needs a synchronization protocol, not just a final
sleep.

## Receiver thread triggers CUDA callbacks

Register the receiver with `nvbit_set_tool_pthread()` immediately after the
channel/receiver is initialized.

## Graph launches have wrong launch IDs

For CUDA Graphs, do not reuse a non-graph assumption that one global value
implicitly maps to the next kernel.

Use `nvbit_at_graph_node_launch` and supply the stream/launch handle when
setting graph-node-specific launch values.

## TMA records cannot be parsed

Verify:

- the GPU is within the release's supported TMA scope (Hopper/Blackwell);
- the instruction is classified through the TMA path;
- `nvbit_add_call_arg_tma_param_handle_and_size` is used;
- the complete handle bytes and size reach the host;
- the full opcode/modifiers needed by the parser are preserved;
- the same `CUcontext` is supplied to the host parser.

Do not route a TMA record through the ordinary one-address MREF parser.

## Runtime version mismatch

If an API signature from an online tutorial differs from your build, stop and
inspect the local 1.8 `core/nvbit.h`.

Avoid combinations such as:

```text
1.8 libnvbit
+ copied 1.7 header
+ older channel.hpp
+ current example source
```

Use one release as a coherent SDK.

## Documentation build: SHA mismatch

`scripts/get-nvbit.sh` deletes the downloaded archive when its SHA-256 does not
match the pinned digest.

Possible causes include a partial/corrupt download or an upstream asset change.
Do not simply update the digest to make the build green. Verify the official
release asset first.

## Documentation build: Breathe symbol missing

A `doxygenfunction` or `doxygenfile` warning usually means:

- Doxygen did not see the expected release header;
- the symbol name is wrong for 1.8;
- the Breathe path does not point to `doxygen/xml`.

Run a clean build:

```bash
rm -rf .external doxygen docs/_build
./scripts/build-docs.sh
```

Because CI uses `sphinx-build -W`, unresolved API directives must be fixed
rather than ignored.

## Documentation build succeeds locally but not in CI

Reproduce the clean path. A local extracted SDK or generated Doxygen tree can
hide missing build dependencies or wrong paths.

The repository is considered reproducible only when a fresh checkout can
download, verify, extract, and build without manual SDK placement.
