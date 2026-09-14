# Quick Start

This page gets from an NVBit 1.8 release archive to a running example tool and
explains what each command is doing.

## 1. Requirements

For running NVBit tools, you need a supported Linux x86_64 or aarch64 system,
a supported NVIDIA GPU, CUDA 12 or newer, `nvcc`, `nvdisasm`, and a supported
host compiler. NVBit 1.8's upstream README contains the exact driver,
architecture, and compiler support matrix.

Building **this documentation** does not require an NVIDIA GPU because it only
reads headers and Markdown.

## 2. Obtain the official release

This documentation repository automates acquisition:

```bash
./scripts/get-nvbit.sh
```

The script:

1. reads the configured version, asset name, URL, and digest from
   `scripts/nvbit-release.env`;
2. downloads `nvbit-Linux-x86_64-1.8.tar.bz2`;
3. verifies its SHA-256 digest;
4. extracts it under `.external/`;
5. reports the resulting SDK directory.

Do not substitute the source-code tarball for the release asset. NVBit is
distributed as a release package containing the core library, headers, example
tools, and test applications.

## 3. Inspect the package

The important top-level content is:

```text
nvbit_release_x86_64/
├── core/       # public headers, libnvbit, and utilities used by tools
├── tools/      # example instrumentation tools
└── test-apps/  # small CUDA programs for exercising the examples
```

See [Release Package Layout](release-layout.md) before building a custom tool.

## 4. Build a test application

From the extracted release:

```bash
cd test-apps/vectoradd
make
```

This creates a small CUDA target that is useful because its behavior is easy
to understand independently of the instrumentation.

## 5. Build an example tool

For the smallest instrumentation pattern, start with `instr_count`:

```bash
cd tools/instr_count
make
```

The build produces a shared object that links against NVBit's core library.
The host process will load this shared object when the CUDA application starts.

## 6. Inject the tool

Two common loading mechanisms are:

```bash
LD_PRELOAD=/absolute/path/to/instr_count.so ./vectoradd
```

or:

```bash
CUDA_INJECTION64_PATH=/absolute/path/to/instr_count.so ./vectoradd
```

Use absolute paths while learning; they remove ambiguity about the process
working directory.

## 7. What happens at runtime

Loading the shared library does not by itself mean every SASS instruction has
been modified. The typical sequence is:

```text
process loads tool
      |
      v
NVBit initialization
      |
      v
CUDA context appears
      |
      v
kernel launch reaches nvbit_at_cuda_event
      |
      +--> discover kernel + related functions
      +--> inspect Instr objects
      +--> insert device calls (once per function)
      +--> choose instrumented/original variant
      |
      v
kernel executes
      |
      v
injected device routines execute at selected SASS instructions
      |
      v
tool reports counters/traces
```

Instrumentation is usually cached after the first encounter with a function.
A tool therefore needs a duplicate guard so a device function reachable from
multiple kernels is not instrumented repeatedly.

## 8. Move from counting to tracing

After `instr_count`, the most useful progression is:

- `opcode_hist`: instruction filtering and compact categorization;
- `record_reg_vals`: dynamic register values;
- `mem_trace`: memory references, launch-time values, channels, and receiver
  threads;
- `instr_count_cuda_graph`: graph-aware launch handling;
- `mem_trace_tma`: NVBit 1.8's TMA support.

Read [Writing an NVBit Tool](../guides/writing-tool.md) before adapting one of
these examples.

## 9. A common source of confusion

The host-side code does **not** directly receive a dynamic memory address by
calling `nvbit_get_instrs()`. At instrumentation time, an `Instr` describes
the static instruction. To obtain a runtime effective address, the host asks
NVBit to append an address argument to an inserted device call with
`nvbit_add_call_arg_mref_addr64()`. The value is materialized when the
instrumented instruction executes.

That static/dynamic distinction is central to NVBit.
