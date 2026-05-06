<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# ARC-010 MakeOps.App.CLI Namespace Architecture

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `ARC-010` |
| **Status** | `APPROVED` |
| **Date** | 2026-05-03 |
| **Target Namespace** | `MakeOps.App.CLI` |

## 1. Domain Definition & Purpose

* **Goal:** This domain serves as the primary gateway for user interaction, responsible for understanding and routing the immediate intent behind the `mko` command invocation. It acts as the critical junction where raw arguments extracted from the OS are translated into actionable directives, determining whether the orchestrator should execute a complex project graph or perform a simple, built-in system action.
* **Core Responsibility:** Manages the instantiation of the CLI pipeline (connecting the `MakeOps.Core.CLI` frontend to the internal intent appliers) and operates as the first Input Sub-Orchestrator in the lifecycle. It explicitly segregates standalone application commands (like displaying manuals) from project-oriented execution targets, providing dedicated executors for the former.

## 2. Boundaries & Constraints

* **Domain In-Scope:** User intent evaluation, Halting vs. Execution routing, generation of the `Intent_Queue`, parsing pipeline instantiation, and execution of built-in standalone commands (e.g., `--help`, `--version`).
* **Domain Out-of-Scope (Strict Bounds):** This namespace MUST NOT perform direct lexical parsing of the `argv` array; it relies strictly on `MakeOps.Core.CLI` to normalize the input. It MUST NOT manage the Hierarchical Configuration Cascade or maintain the global `App_Config` state. It MUST NOT attempt to resolve or execute project dependencies (DAG), as operational targets are merely collected here and passed downstream to `MakeOps.Core.Project.Operation.Resolver`.

## 3. Traceability & Foundation

* **Implements Requirements:**
    * `REQ-003` (Execution Observability):
        * `F-003-001`: Implements the top-level interface capable of accepting operational targets and distinguishing them from global configuration flags.
* **Applies Concepts:**
    * `MOD-015`: CLI Interface and Argument Normalization - Enforces the Dual-Branch Normalization logic, explicitly separating the Config Branch (passed to `MakeOps.App.Config`) from the Intent Branch managed within this namespace.
    * `MOD-001`: Master Orchestration Lifecycle - Dictates this namespace's role as Phase 1 (Intention Acquisition) in the overarching 5-step sequence, ensuring that Halting actions instantly bypass the remaining pipeline.

## 4. Architectural Topology

**Components (Package Blueprints):**

* `MakeOps.App.CLI.Loader` (`DES-[XXX]`): The Input Sub-Orchestrator responsible for determining the user's immediate intent. It instantiates the generic pipeline with the CLI frontend, routing the output to the `CLI_Intent_Applier` to assemble the `Intent_Queue`. The design MUST implement the Empty Target Heuristic (defaulting to the usage manual if no targets are provided) and cleanly separate structural CLI flags from positional execution targets.
* `MakeOps.App.CLI.Command` (`DES-[XXX]`): The static data repository defining the standalone actions supported by the MakeOps application. It declares the enumerations and structures representing non-project intents (e.g., `Print_Help`, `Print_Version`). The design MUST be strictly declarative and mathematically pure to allow safe routing by the Orchestrator without side-effects.
* `MakeOps.App.CLI.Command.Executor` (`DES-[XXX]`): The specialized executor for built-in, standalone application commands that bypass the project graph entirely. It ensures the application prints the requested system information (such as license details or help text) directly to the terminal. The design MUST ensure the application terminates cleanly and deterministically without initializing the heavier POSIX execution engine.

**Subsystems (Delegated Namespaces):**

* `None` (`N/A`): This namespace operates as a terminal routing and execution domain for the command line interface and contains no further delegated architectural sub-branches.