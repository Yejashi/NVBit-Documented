# Architecture

This page presents a high-level model of how NVBit fits into the
execution pipeline of a CUDA application.

## Model

```text
CUDA Application
       |
       v
     NVBit
       |
       +--> observes / intercepts CUDA driver activity
       |
       +--> discovers CUDA functions and exposes decoded SASS instructions
       |
       +--> allows tools to modify instrumented GPU code
       |
       v
Instrumented GPU Code
       |
       v
Injected Device Instrumentation
       |
       v
Tool-specific collection / host-side processing
```

## Step by step

1. **Application.** The user's CUDA application calls CUDA driver or
   runtime APIs.
2. **NVBit observation.** NVBit hooks into the CUDA driver layer and
   observes function loads, context creation/teardown, kernel launches,
   and other driver events.
3. **Function discovery and instruction exposure.** For each CUDA
   function discovered, NVBit decodes the compiled SASS and exposes it
   to tools as `Instr` objects.
4. **Tool instrumentation.** A tool may inspect the `Instr` objects,
   apply filters, and insert instrumentation calls (e.g., calls to a
   device routine) before or after existing instructions.
5. **Modified GPU code.** The instrumented SASS is compiled and loaded
   onto the GPU. At runtime, the injected device routine executes
   alongside the original kernel code.
6. **Data collection.** The device routine may record data to managed
   memory or channels. A host-side receiver thread collects and
   processes these records.

## Scope of this model

This is a navigation model intended to orient the reader. Detailed
behavior for each step is covered in later sections (lifecycle,
instrumentation, channels).

NVBit operates at the compiled SASS level. It does not require
application source code and works with binaries compiled by `nvcc` or
other compilers, subject to the hardware compatibility constraints
listed in the Quick Start guide.
