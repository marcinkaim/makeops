<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# ARC-002 MakeOps.Core Namespace Architecture

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `ARC-002` |
| **Status** | `APPROVED` |
| **Date** | 2026-05-02 |
| **Target Namespace** | `MakeOps.Core.*` |

## 1. Domain Definition & Purpose

* **Goal:** This domain serves as the agnostic, mathematical heart of the MakeOps orchestration engine. It establishes a Data-Oriented Design (DOD) processing architecture that decouples the extraction of raw OS data (Frontends) from the semantic application of that data (Backends) using a strictly bounded, universal Intermediate Representation (IR).
* **Core Responsibility:** Physically defines the universal data exchange events (`Pipeline_Event`), provides the generic pipeline execution machinery, and structurally routes all subsequent domain logic across isolated Frontends (TOML, CLI, Env) and Backends (Project Resolution).

## 2. Boundaries & Constraints

* **Domain In-Scope:** Generic 5-phase data processing pipelines, Intermediate Representation (IR) structures, parsing abstractions, directed acyclic graph (DAG) resolution, and variable substitution engines.
* **Domain Out-of-Scope (Strict Bounds):** This namespace MUST NOT invoke native OS interfaces directly; all environment and file interactions MUST be routed through `MakeOps.Sys`. It MUST NOT construct dynamic Abstract Syntax Trees (AST) or allocate heap memory for parsed data. It MUST NOT manage top-level application orchestration or CLI intent resolution, which are delegated to `MakeOps.App`.

## 3. Traceability & Foundation

* **Implements Requirements:**
    * `REQ-001` (Project Configuration Handling):
        * `NFR-001-003`: Enforces the stream processing constraint by ensuring that the core logic operates on abstracted text streams rather than hardcoded file I/O operations.
    * `REQ-002` (Operation Orchestration):
        * `NFR-002-003`: Dictates that the internal engine utilizes DAG traversal algorithms to guarantee mathematical correctness, bounding the scope of the delegated Project Backend.
* **Applies Concepts:**
    * `MOD-002`: Universal 5-Phase Processing Pipeline - Dictates the fundamental structural split of this namespace into distinct Frontends (Phase 1-4) and Backends (Phase 5) communicating purely via IR.
    * `MOD-009`: Formal Verification & Static Memory Foundations - Imposes the Zero-AST constraint on the parsing subsystems, ensuring that data is processed mechanically without dynamic allocation.

## 4. Architectural Topology

**Components (Package Blueprints):**

* `MakeOps.Core.Pipeline` (`DES-XXX`): The essence of the core data domain defining the flat, pointer-free `Pipeline_Event` (IR) record. It acts as the universal data exchange standard and spatial tracker between any Frontend and Backend. The design MUST be mathematically pure (`pragma Pure`) and completely free of dynamic allocation structures.
* `MakeOps.Core.Pipeline.Runner` (`DES-YYY`): The semi-virtual conductor implementing the universal pipeline execution loop as an Ada `generic`. It is strictly responsible for driving the data flow through instantiated phases and propagating immediate Fail-Fast errors. The design MUST NOT orchestrate the CLI application itself; it must act exclusively as a mechanical processor waiting to be instantiated.

**Subsystems (Delegated Namespaces):**

* `MakeOps.Core.TOML.*` (`ARC-005`): Encapsulates the Frontend domain responsible for lexing, parsing, and normalizing MakeOps TOML configuration streams into the universal IR.
* `MakeOps.Core.CLI.*` (`ARC-006`): Encapsulates the Frontend domain responsible for scanning and normalizing raw POSIX command-line arguments into configuration properties and operational targets.
* `MakeOps.Core.Env.*` (`ARC-007`): Encapsulates the Frontend domain responsible for extracting and flattening host OS environment variables into the universal IR.
* `MakeOps.Core.Project.*` (`ARC-008`): Encapsulates the semantic Backend domain responsible for applying IR events to memory structures, mathematically resolving DAG operations, and managing physical POSIX execution.