<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# ARC-003 MakeOps.App Namespace Architecture

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `ARC-003` |
| **Status** | `APPROVED` |
| **Date** | 2026-05-02 |
| **Target Namespace** | `MakeOps.App` |

## 1. Domain Definition & Purpose

* **Goal:** This domain establishes the meta-orchestration, overall control flow, and developer experience (DX) boundaries of the MakeOps tool. It acts as the "brain" that wires together the mechanical data pipelines and raw OS executors into a cohesive, user-facing CLI application.
* **Core Responsibility:** Manages the absolute lifecycle of the `mko` process (Entry and Exit), evaluates top-level user intents, coordinates the sequential hand-offs between Sub-Orchestrators (Loaders, Resolvers, and Executors), and provides real-time, context-aware diagnostic outputs to the terminal.

## 2. Boundaries & Constraints

* **Domain In-Scope:** Meta-orchestration algorithms, global application state management, Command-Line Interface (CLI) interpretation, terminal UX/DX (ANSI formatting, UTF-8 emojis), and contextual error rendering.
* **Domain Out-of-Scope (Strict Bounds):** This namespace MUST NOT parse TOML syntax or manage POSIX bindings. It MUST NOT resolve DAG dependencies or perform mathematical variable substitution, as these are strictly delegated to `MakeOps.Core`. It MUST NOT execute external POSIX processes directly, relying on `MakeOps.Core.Project.Operation.Executor` for payload execution.

## 3. Traceability & Foundation

* **Implements Requirements:**
    * `REQ-003` (Execution Observability):
        * `F-003-005`: Enforces the semantic prefixing of internal diagnostic logs (e.g., `[mko:error]`).
        * `F-003-006` to `F-003-008`: Implements the visual verbosity levels by dynamically routing or suppressing terminal streams based on the global configuration.
        * `NFR-003-001`: Guarantees real-time transparency by ensuring output is streamed without artificial buffering.
* **Applies Concepts:**
    * `MOD-001` (Master Orchestration Lifecycle): Dictates the strict sequential execution algorithm (Intent Acquisition -> Context -> Domain -> Plan -> Execution) managed by the Orchestrator.
    * `MOD-016` (Observability and Visual Taxonomy Model): Governs the terminal formatting rules, standard colors, and stream separation implemented by the Logger.
    * `MOD-017` (Zero-Allocation Diagnostic Pattern): Dictates the Just-In-Time (JIT) file extraction heuristics used to dynamically render contextual error pointers.

## 4. Architectural Topology

**Components (Package Blueprints):**

* `MakeOps.App.Orchestrator` (`DES-[XXX]`): The Master Conductor responsible for executing the top-level 5-step lifecycle algorithm. It strictly coordinates Sub-Orchestrators (Loaders, Resolvers, Executors) without directly manipulating strings or graphs. The design MUST implement the top-level Fail-Fast barrier, immediately halting execution and delegating any returned domain errors to the diagnostic engine.
* `MakeOps.App.Main` (`DES-[XXX]`): The final executable entry point acting as the ultimate bridge between the pure SPARK domain and the OS. It performs elaboration, hooks POSIX signal handlers (e.g., `SIGINT`), invokes the Orchestrator, and casts the system's outcome into a standard POSIX exit code. The design MUST consist solely of an `.adb` body and operate outside of strict SPARK limits to securely manage OS runtime initialization.
* `MakeOps.App.Logger` (`DES-[XXX]`): The unified runtime log manager responsible for Developer Experience (DX) and stream observability. It enforces the "Neutral Happy Path" taxonomy by formatting text with ANSI colors, UTF-8 emoji markers, and distinct stream prefixes. The design MUST guarantee atomic writes for process stream multiplexing and strictly adhere to static bounded memory limits to prevent buffer overflows.
* `MakeOps.App.Diagnostics` (`DES-[XXX]`): The physical implementation of Contextual Error Rendering (Zero-AST Diagnostics). It utilizes a Just-In-Time (JIT) file re-open technique to dynamically seek and extract the exact textual context of a configuration failure based on spatial coordinates. The design MUST implement Graceful Degradation to ensure that a missing file during the JIT extraction does not crash the fallback reporting mechanism.

**Subsystems (Delegated Namespaces):**

* `MakeOps.App.Config.*` (`ARC-009`): Encapsulates global application preferences, the Hierarchical Configuration Cascade, and the `App_Config` target memory structures.
* `MakeOps.App.CLI.*` (`ARC-010`): Encapsulates the evaluation of user intent, parsing of `argv` arrays, routing of standalone CLI commands, and bridging the CLI pipeline with the application state.