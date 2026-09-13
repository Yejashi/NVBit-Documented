# NVBit-Documented Agent Guide

## Project Purpose

This repository provides comprehensive, community-maintained documentation for NVIDIA NVBit.

The documentation target is:

* **NVBit version:** 1.8
* **Upstream repository:** `NVlabs/NVBit`
* **Authoritative SDK source:** official NVBit 1.8 GitHub Release artifact
* **Documentation repository:** `Yejashi/NVBit-Documented`
* **Primary working branch:** `documentation`

This repository is not the official NVBit documentation and is not maintained by NVIDIA.

The objective is to make NVBit understandable to both:

1. developers learning or using NVBit;
2. coding agents that need accurate architectural, API, lifecycle, and usage information.

Documentation quality is measured by technical accuracy, reproducibility, and usefulness—not by raw documentation volume.

---

# Source of Truth

Technical claims about NVBit must be grounded in authoritative evidence.

Use sources in approximately this order:

1. NVBit 1.8 release artifact
2. NVBit 1.8 public headers
3. NVBit 1.8 source distributed in the release
4. NVBit 1.8 official example tools
5. NVBit 1.8 test applications
6. NVBit 1.8 release notes
7. official `NVlabs/NVBit` repository content
8. NVBit MICRO 2019 paper
9. older NVBit releases or external material

The NVBit 1.8 release is authoritative when older sources disagree with current behavior.

Do not describe behavior from older versions as current without verifying it against 1.8.

Do not infer undocumented behavior solely from function names.

If behavior cannot be established confidently, state the uncertainty or leave the claim undocumented.

---

# Do Not Redistribute NVBit

This repository documents NVBit but should not become a redistributed copy of the NVBit SDK.

Do not commit:

* NVBit release archives;
* extracted NVBit SDK directories;
* NVBit binaries;
* generated libraries;
* object files;
* temporary analysis data;
* documentation build products;
* Doxygen XML output.

The build system should acquire the official NVBit 1.8 release artifact when needed.

Keep downloaded and generated files in ignored build/cache directories.

Do not modify, reinterpret, or replace NVIDIA's licensing terms.

---

# Documentation Stack

The documentation system uses:

* **Sphinx** — documentation generator
* **MyST Parser** — Markdown support for Sphinx
* **Doxygen** — extraction of C/C++/CUDA API information
* **Breathe** — integration of Doxygen XML with Sphinx
* **Furo** — HTML theme
* **Graphviz and/or Mermaid** — architecture diagrams where useful
* **GitHub Actions** — automated builds
* **GitHub Pages** — public hosting

The intended pipeline is:

```text
Official NVBit 1.8 release
          |
          v
      Extract SDK
          |
          v
       Doxygen
          |
       XML output
          |
          v
       Breathe
          |
          +------------------+
                             |
Handwritten MyST Markdown    |
          |                  |
          +------> Sphinx <--+
                     |
                     v
                   Furo
                     |
                     v
                  HTML site
                     |
                     v
                GitHub Pages
```

Sphinx is the public documentation frontend.

Doxygen HTML, if generated at all, is secondary and should not replace the Sphinx site.

---

# Repository Structure

The intended repository structure is approximately:

```text
NVBit-Documented/
├── AGENTS.md
├── README.md
├── EULA.txt
├── Doxyfile
├── requirements-docs.txt
├── .gitignore
│
├── docs/
│   ├── conf.py
│   ├── index.md
│   │
│   ├── getting-started/
│   ├── concepts/
│   ├── guides/
│   ├── examples/
│   ├── reference/
│   ├── development/
│   └── _static/
│
├── scripts/
│   ├── get-nvbit.sh
│   └── build-docs.sh
│
└── .github/
    └── workflows/
        └── docs.yml
```

This layout may evolve when justified by the actual documentation architecture.

Avoid unnecessary restructuring.

---

# Generated and Temporary Paths

Generated or downloaded content must not be manually edited or committed.

Examples include:

```text
_build/
build/
docs/_build/
doxygen/xml/
.external/
.cache/
nvbit-*/
*.tar.bz2
```

Check the repository's `.gitignore` for the canonical paths.

If a generated file needs to change, modify the source or generator configuration instead.

---

# Documentation Architecture

The documentation should be organized around user intent rather than mirroring the NVBit filesystem.

Major sections should generally include:

```text
Home
├── Getting Started
├── Concepts
├── Guides
├── Examples
├── API Reference
└── Troubleshooting
```

## Getting Started

Help a user progress from having no NVBit environment to successfully running a simple instrumentation tool.

Typical topics include:

* requirements;
* obtaining NVBit;
* building a tool;
* running a tool;
* first instrumentation example.

## Concepts

Explain how NVBit works.

Important areas may include:

* NVBit architecture;
* dynamic binary instrumentation;
* SASS;
* tool lifecycle;
* CUDA event callbacks;
* functions and related functions;
* instruction inspection;
* instrumentation insertion;
* instrumentation functions;
* instrumentation arguments;
* instrumentation enablement;
* host/device communication;
* channels.

Only document concepts supported by NVBit 1.8.

## Guides

Guides should be task-oriented.

Examples:

* instrument selected instructions;
* trace memory operations;
* pass register values to injected functions;
* obtain memory-reference addresses;
* filter kernels;
* instrument related functions;
* communicate records back to the host;
* avoid repeated instrumentation.

## Examples

Use the official NVBit 1.8 example tools as teaching material.

Explain:

* what the example demonstrates;
* how it is structured;
* which callbacks it implements;
* which NVBit APIs it uses;
* what executes on the host;
* what executes on the GPU;
* how data moves through the tool;
* what limitations or assumptions matter.

Do not rewrite every source file into prose.

## API Reference

API reference should be generated from NVBit headers using Doxygen and Breathe where practical.

Organize APIs semantically rather than exposing a raw filesystem dump.

Possible groups include:

* lifecycle callbacks;
* function/context APIs;
* instruction inspection;
* instrumentation insertion;
* call arguments;
* instrumentation control;
* instruction representation;
* communication utilities;
* architecture-specific APIs.

Use the actual NVBit 1.8 API to determine final groupings.

---

# Documentation Writing Rules

Write technical documentation, not marketing material.

Prefer direct descriptions.

Good:

> `nvbit_get_instrs()` provides the NVBit instruction representation associated with a CUDA function.

Avoid:

> NVBit conveniently provides a powerful function called `nvbit_get_instrs()` that makes it easy to access instructions.

Use exact API names.

Place code identifiers in backticks.

Define project-specific terminology before relying on it.

Prefer explicit execution flow over vague summaries.

Use cross-references rather than repeating the same explanation across multiple pages.

---

# What Documentation Should Explain

Documentation should add semantic information beyond what can be read directly from the source.

Prioritize:

* purpose;
* lifecycle;
* execution order;
* relationships between components;
* control flow;
* data flow;
* state transitions;
* ownership;
* lifetime;
* synchronization;
* invariants;
* limitations;
* prerequisites;
* common usage patterns;
* common failure modes.

Avoid low-value prose such as:

> `foo()` calls `bar()`.

unless the relationship itself is significant.

---

# Code Examples

Code examples must reflect verified NVBit 1.8 behavior.

Prefer small examples that isolate one concept.

When official NVBit examples establish a canonical pattern, follow that pattern.

Do not invent APIs or signatures.

Cross-check examples against the NVBit 1.8 headers.

Compile examples when practical.

Do not copy large portions of upstream source when a short excerpt or explanation is sufficient.

---

# NVBit Versioning

The documentation currently targets:

```text
NVBit 1.8
```

Do not silently update documentation to a newer release.

A version migration should be deliberate and should include:

1. changing the central NVBit version configuration;
2. obtaining the new release;
3. comparing API and behavior changes;
4. checking release notes;
5. updating documentation;
6. rebuilding API documentation;
7. validating examples;
8. reviewing outdated claims.

Pages describing version-specific behavior should say so explicitly where useful.

---

# Obtaining NVBit

The SDK should be retrieved from the official NVlabs/NVBit release.

Do not depend on the upstream Git working tree containing the SDK.

The acquisition process should:

1. use the configured NVBit version;
2. download the official release artifact;
3. verify its digest when supported;
4. extract it into an ignored directory;
5. expose the extracted location to Doxygen and other tooling.

Keep version configuration centralized rather than duplicating `1.8` across many scripts.

---

# Doxygen Rules

Doxygen primarily exists to generate machine-readable API information for Breathe.

Prefer XML output.

The Doxygen input set must be based on the actual NVBit 1.8 SDK layout.

Do not indiscriminately expose every internal symbol.

Prioritize public or user-relevant APIs.

Exclude:

* build directories;
* downloaded archives;
* generated files;
* irrelevant binary content.

When documentation requires an explanation beyond the available API comments, write that explanation in the Sphinx/MyST documentation and cross-reference the generated API entry.

---

# Sphinx and MyST Rules

Manual documentation should normally be written in Markdown through MyST.

Keep navigation intentional.

Avoid creating many tiny pages that provide little independent value.

Ensure headings form a coherent hierarchy.

Prefer Sphinx cross-references over hardcoded relative URLs when practical.

Do not globally suppress warnings to achieve a successful build.

Fix warnings at their source when feasible.

---

# Architecture Diagrams

Use diagrams where they materially improve understanding.

Good candidates include:

* overall NVBit architecture;
* instrumentation lifecycle;
* tool callback sequence;
* instruction instrumentation flow;
* channel communication flow.

Diagrams must agree with verified NVBit behavior.

Do not add diagrams solely for visual decoration.

Always accompany nontrivial diagrams with textual explanation.

---

# Agent Workflow

Agents should work hierarchically.

Do not attempt to document the entire repository in one pass.

Use this general workflow:

```text
inspect
   |
   v
establish evidence
   |
   v
form semantic model
   |
   v
implement documentation
   |
   v
build
   |
   v
independent validation
```

---

# Exploration Tasks

Exploration agents should perform narrowly scoped investigation.

Good exploration tasks:

* identify all lifecycle callbacks in NVBit 1.8;
* trace how `mem_trace` instruments memory instructions;
* enumerate public APIs in the core headers;
* identify how instrumentation arguments are encoded;
* trace channel communication from device to host;
* determine how related functions are instrumented;
* compare 1.8 behavior against older documentation.

Bad exploration task:

> Understand all of NVBit.

Return concise findings with evidence and relevant file/symbol locations.

Avoid repeatedly rereading the whole SDK when targeted searches are sufficient.

---

# Implementation Tasks

Implementation agents should receive concrete scopes.

Good:

> Create the Sphinx page explaining lifecycle callbacks using the verified callback inventory and execution-order findings.

Good:

> Add Breathe directives for the instruction instrumentation APIs and connect them to the corresponding concept page.

Bad:

> Finish the NVBit documentation.

Keep edits localized and reviewable.

---

# Testing Tasks

Documentation changes are not complete until validated.

Where relevant, run:

* Doxygen generation;
* Sphinx build;
* warnings-as-errors or equivalent strict checks where feasible;
* link/cross-reference checking;
* example compilation;
* clean rebuilds.

A successful edit is not equivalent to a successful documentation build.

---

# Clean-Build Requirement

The documentation must be reproducible from a fresh repository checkout.

A clean build must not depend on:

* an SDK manually extracted outside the project;
* an absolute path from one developer's machine;
* cached Doxygen output;
* generated files accidentally committed previously.

A clean validation should conceptually perform:

```text
fresh checkout
     |
download NVBit
     |
extract NVBit
     |
run Doxygen
     |
run Sphinx
     |
produce site
```

---

# GitHub Pages

The public documentation site should be built and deployed through GitHub Actions.

The workflow should:

1. check out the repository;
2. install documentation dependencies;
3. obtain the configured NVBit release;
4. generate Doxygen XML;
5. build Sphinx HTML;
6. upload the GitHub Pages artifact;
7. deploy it.

Do not commit generated HTML solely to serve GitHub Pages.

Use GitHub's supported Pages deployment actions.

---

# Git Discipline

Do not commit unrelated changes.

Keep generated files out of Git.

Before finishing work, inspect repository status.

Do not modify upstream NVBit content merely to make documentation generation easier unless there is a compelling reason and the change is confined to temporary/generated workspace data.

Do not overwrite user work.

---

# Accuracy Review

High-risk documentation should receive independent review.

Important areas include:

* callback lifecycle;
* instrumentation ordering;
* function discovery;
* instruction insertion;
* instrumentation arguments;
* memory-reference handling;
* channel synchronization;
* architecture-specific behavior;
* CUDA feature support.

Prefer a fresh agent or independent analysis for validation rather than having the author merely reread its own work.

---

# Known High-Level NVBit Model

The following is only a navigation model and must not replace inspection of NVBit 1.8:

```text
CUDA Application
       |
       v
     NVBit
       |
       +--> observes/intercepts CUDA activity
       |
       +--> discovers CUDA functions
       |
       +--> exposes decoded SASS instructions
       |
       +--> allows instrumentation calls to be inserted
       |
       v
Instrumented GPU Code
       |
       v
Injected Device Instrumentation
       |
       v
Tool-specific collection / communication
       |
       v
Host-side processing/output
```

Verify the details of this model against the NVBit 1.8 release before relying on it in user-facing documentation.

---

# Completion Standard

A documentation task should only be considered complete when:

* the technical claims have evidence;
* the relevant page is integrated into navigation;
* references resolve;
* Doxygen/Breathe content works if applicable;
* the documentation builds successfully;
* no generated or downloaded SDK content was accidentally committed;
* the documentation accurately describes NVBit 1.8;
* another developer or agent could use the page without having to rediscover the same behavior from scratch.

The goal is not to maximize documentation volume.

The goal is to turn an initially difficult-to-understand SDK into a precise, navigable, technically reliable body of documentation.
