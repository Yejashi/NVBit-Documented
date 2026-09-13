# Channel Communication

This guide describes the channel communication mechanism used by the
`mem_trace` example tool to transfer records from device code back to
the host.

## Overview

The `mem_trace` tool uses NVBit's channel infrastructure to move
instrumentation records from the GPU device to the host. The mechanism
involves:

* A device-side `ChannelDev` object for pushing records
* A host-side `ChannelHost` object and receiver thread for pulling records
* A flush mechanism to ensure all records are delivered before context
  teardown

## Device-side record recording

The device routine `instrument_mem` records predicated memory accesses
by calling `ChannelDev::push()`. Each record contains information about
the memory operation (opcode, address, etc.).

## Device-side flush

When the tool requests a flush (e.g., during context termination), the
device-side flush routine:

1. Calls `__threadfence_system()` to ensure all prior memory writes are
   visible to the host.
2. Sends a doorbell notification to the host.
3. Waits for the host to acknowledge receipt.

## Host-side initialization

### Context initialization

When a CUDA context is initialized, the tool loads a flush module that
provides the device-side flush routine.

### Tool initialization

During tool initialization:

1. Allocate a managed `ChannelDev` object on the device.
2. Initialize a `ChannelHost` object on the host, associated with the
   device channel.
3. Start a receiver thread that calls `ChannelHost::recv()` in a loop,
   processing records as they arrive.
4. Register the tool's pthread hooks so that NVBit can invoke tool
   callbacks at the appropriate lifecycle points.

### Host receiver

The receiver thread continuously calls `recv()` on the `ChannelHost`.
When records are available, it processes them (e.g., writes to a file
or prints to stdout).

## Context termination

When a CUDA context is terminated:

1. The tool triggers a device-side flush, which performs the
   `__threadfence_system()`, doorbell notification, and ack wait
   sequence described above.
2. The host waits for the device flush to complete and synchronizes.
3. The host stops the receiver thread and joins it.
4. The host frees the channel state.

## Example-specific behavior

The channel behavior described here is specific to the `mem_trace`
example tool. It demonstrates a complete producer-consumer pattern:

* Device code pushes records → host thread pulls and processes them.

Other tools may use channels differently, or not use them at all.
This pattern should not be assumed to be a universal guarantee of NVBit
channel behavior.
