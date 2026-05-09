<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# SCH-005 Project Semantic Backend Engine Schedule

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `SCH-005` |
| **Status** | `DRAFT` |
| **Date** | 2026-05-08 |
| **Target Stage** | Stage 5 |

## 1. Stage Context & Milestone

* **Objective & Rationale:** This stage represents the implementation of the core business logic and the primary mathematical engine of MakeOps. It bridges the gap between raw data ingestion and physical action by transforming Intermediate Representation (IR) events into validated project models, mathematically proving Directed Acyclic Graph (DAG) acyclicity, and orchestrating the POSIX process lifecycle. This stage is prioritized now because the fundamental frontends and the universal pipeline infrastructure are already established, allowing us to focus on the high-integrity transformation and execution logic.
* **Defining Milestone:** The project semantic backend is fully realized and integrated. The milestone is reached when the system successfully consumes a project-level IR stream, populates the `Project_Config` record, resolves a complex dependency graph via Topological Sorting, and executes the resulting queue through the `Executor`, providing real-time I/O multiplexing and standard POSIX exit status reporting.

## 2. Stage Prerequisites

* **Entry Gating:**
  * `SCH-000` (Foundations and Identity) MUST be `COMPLETED`.
  * `SCH-001` (OS Abstraction Layer Facade) MUST be `COMPLETED`.
  * `SCH-002` (Universal Processing Pipeline) MUST be `COMPLETED`.
  * `SCH-003` (Configuration Frontend Pipelines) MUST be `COMPLETED`.
  * `SCH-004` (CLI Frontend and Normalization) MUST be `COMPLETED`.
  * `ARC-008` (MakeOps.Core.Project Namespace Architecture) MUST be `APPROVED`.
  * `MOD-004` (Execution Plan Resolution) MUST be `APPROVED`.
  * `MOD-005` (Asynchronous Execution and Multiplexing) MUST be `APPROVED`.
  * `MOD-018` (Project Configuration Schema Model) MUST be `APPROVED`.

## 3. Scope of Work (Execution Batches)

### Batch 1: Project Data Model & Semantic Mapping
Implements the static memory structures for project configuration and the Phase 5 Applier responsible for schema validation.

* `MakeOps.Core.Project.Config` (Ref: `ARC-008`) -> Target `DES-030`
* `MakeOps.Core.Project.Config.Applier` (Ref: `ARC-008`) -> Target `DES-031`

### Batch 2: Mathematical Resolution & Substitution
Implements the topological sorting algorithms and the lazy variable substitution engine.

* `MakeOps.Core.Project.Config.Variable_Substitution` (Ref: `ARC-008`) -> Target `DES-032`
* `MakeOps.Core.Project.Operation.Graph_Builder` (Ref: `ARC-008`) -> Target `DES-033`
* `MakeOps.Core.Project.Operation.Resolver` (Ref: `ARC-008`) -> Target `DES-034` - *Depends on Batch 1*

### Batch 3: Physical Execution Engine
Implements the real-time event loop for process spawning, multiplexing, and reaping.

* `MakeOps.Core.Project.Operation.Executor` (Ref: `ARC-008`) -> Target `DES-035` - *Depends on Batch 2*

## 4. Logistical & Integration Notes

* **Integration Strategy:**
  * The `Graph_Builder` and `Variable_Substitution` algorithms MUST be implemented as mathematically pure components (`pragma Pure`) to simplify SPARK verification of complex logic.
  * The `Executor` MUST strictly utilize the safe `MakeOps.Sys.Processes` thick wrappers to interact with the OS, maintaining the formal verification boundary.
* **Verification Notes:**
  * SPARK Silver Level verification is mandatory for the `Resolver` and its internal algorithms to prove the Absence of Runtime Errors (AoRE) during topological sorting and string interpolation.
  * AUnit tests for the `Executor` MUST verify the "Strict Child Coupling" and "Grace Period" watchdog mechanisms to ensure the tool does not deadlock on orphaned background processes.