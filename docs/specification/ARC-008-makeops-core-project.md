<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# ARC-008 MakeOps.Core.Project Namespace Architecture

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `ARC-008` |
| **Status** | `APPROVED` |
| **Date** | 2026-05-03 |
| **Target Namespace** | `MakeOps.Core.Project` |

## 1. Domain Definition & Purpose

* **Goal:** This domain serves as the semantic Backend and the primary mathematical engine of the MakeOps orchestration architecture. It bridges the gap between pure data parsing and physical execution, transforming agnostic Intermediate Representation (IR) events into validated domain structures, mathematically proving their logical soundness (DAG acyclicity), and orchestrating their physical invocation via the OS interfaces.
* **Core Responsibility:** Manages Phase 5 (The Applier) of the Universal Processing Pipeline to populate the static `Project_Config` memory records. It acts as a Transformation Sub-Orchestrator to resolve dependencies via Topological Sorting, securely substitutes dynamic variables, and finally operates as the Executive Sub-Orchestrator to spawn, multiplex, and reap POSIX child processes.

## 2. Boundaries & Constraints

* **Domain In-Scope:** Operations Graph (DAG) construction, semantic schema validation, Cycle Detection (DFS algorithms), Lazy Variable Substitution (String Interpolation), Real-Time I/O Multiplexing event loops, and POSIX process lifecycle orchestration.
* **Domain Out-of-Scope (Strict Bounds):** This namespace MUST NOT perform direct string parsing or lexical analysis of TOML files (delegated to Frontends). It MUST NOT directly invoke unsafe C-ABI kernel bindings (e.g., calling `execvp` or `pipe` via `Interfaces.C`); all OS interactions MUST route through the safe `MakeOps.Sys` thick wrappers to maintain formal verification boundaries. It MUST NOT format terminal text with ANSI colors or emojis, delegating all UI/DX concerns to `MakeOps.App.Logger`.

## 3. Traceability & Foundation

* **Implements Requirements:**
    * `REQ-002` (Operation Orchestration & Execution):
        * `F-002-002`: Implements the automatic resolution and sequential execution of prerequisite operations defined in the `deps` arrays.
        * `F-002-004`: Enforces dynamic substitution of declared environment variables within operational commands prior to process spawning.
        * `NFR-002-003`: Dictates the use of Directed Acyclic Graph (DAG) traversal algorithms to guarantee mathematical execution ordering.
* **Applies Concepts:**
    * `MOD-004`: Execution Plan Resolution - Governs the Resolver's use of topological sorting, Virtual Root injection, and memoized lazy substitution mechanisms.
    * `MOD-005`: Asynchronous Execution and Multiplexing - Dictates the Executor's stateful event loop, asynchronous `poll` mechanics, and Strict Child Coupling invariants to prevent deadlocks.
    * `MOD-018`: Project Configuration Schema Model - Enforces the strict, String-Only schema validation rules used by the Applier during Phase 5 IR consumption.

## 4. Architectural Topology

**Components (Package Blueprints):**

* `MakeOps.Core.Project.Config` (`DES-[XXX]`): The static data repository defining the `Project_Config` structures. It provides the memory-safe dictionaries and operation arrays necessary to store user-defined tasks and environmental constants. The design MUST rely exclusively on statically bounded arrays and integer indices, completely avoiding dynamic pointers to represent graph edges, ensuring AoRE compliance.
* `MakeOps.Core.Project.Config.Applier` (`DES-[XXX]`): The Phase 5 semantic Applier for the project domain. It consumes incoming `Pipeline_Event`s, verifies them against the normative schema, and safely populates the `Project_Config` memory records. The design MUST strictly reject unknown keys or invalid structures (e.g., nested tables) to enforce immediate Fail-Fast domain boundaries.
* `MakeOps.Core.Project.Config.Variable_Substitution` (`DES-[XXX]`) **[Private]**: The mathematical engine for safe string interpolation. It evaluates `${VAR}` markers against project and OS environments, employing cycle detection to prevent infinite recursion. The design MUST implement rigorous bounds-checking against physical limits and enforce the Terminal-Value security policy for OS variables to prevent interpolation injection vulnerabilities.
* `MakeOps.Core.Project.Operation.Graph_Builder` (`DES-[XXX]`) **[Private]**: The algorithmic engine for dependency resolution. It processes raw operation arrays using a state-tracking Depth-First Search (DFS) to topologically sort the dependencies and mathematically prove the absence of cycles. The design MUST be mathematically pure (`pragma Pure`) and heavily verified via SPARK to guarantee termination and deterministic ordering.
* `MakeOps.Core.Project.Operation.Resolver` (`DES-[XXX]`): The Transformation Sub-Orchestrator bridging static knowledge and physical action. It coordinates the private Graph Builder and Variable Substitution algorithms to transform raw user intents into a fully validated, linear `Execution_Queue`. The design MUST act as the sole protective entry point to the private algorithms, shielding them from external orchestration state.
* `MakeOps.Core.Project.Operation.Executor` (`DES-[XXX]`): The operational Executive Sub-Orchestrator representing the core runtime engine. It sequentially applies Configuration Anchor heuristics, invokes the OS boundary to spawn child processes, and manages real-time I/O multiplexing loops (`poll`). The design MUST strictly enforce POSIX IPC stream routing (`MOD-006`) and Grace Period timeouts to guarantee safe, deadlock-free execution lifecycles.

**Subsystems (Delegated Namespaces):**

* `None` (`N/A`): This namespace constitutes the terminal semantic backend of the core engine and contains no further delegated architectural sub-branches.