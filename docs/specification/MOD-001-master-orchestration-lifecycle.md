<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# MOD-001 Master Orchestration Lifecycle

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `MOD-001` |
| **Status** | `APPROVED` |
| **Date** | 2026-04-06 |
| **Tags** | Orchestration, Control Flow, Lifecycle, Fail-Fast, Main |

## 1. Definition & Context
The Master Orchestration Lifecycle defines the absolute top-level execution algorithm for the MakeOps (`mko`) tool. It represents the highest layer of the control flow, orchestrating the sequence of events from the moment the operating system invokes the binary until a final POSIX exit code is returned.

In the context of the MakeOps architecture, this model establishes a strict Delegation Pattern. The Master Orchestrator does not parse strings, construct graphs, or spawn OS processes directly. Instead, it acts as the central conductor, sequentially invoking specialized Sub-Orchestrators (Loaders, Resolvers, and Executors) and securely managing the data hand-offs between them. 

## 2. Theoretical Basis
This lifecycle relies on strict sequential execution and explicit failure boundaries, rejecting reactive or event-driven spaghetti architectures at the macro level.

### 2.1. Sequential Determinism
In deep tech and mathematically verifiable environments, global control flow must be highly predictable. By enforcing a rigid, linear sequence of phases, the system guarantees that execution dependencies are always met (e.g., the global configuration cascade is fully resolved before the project TOML is evaluated). This eliminates entire classes of race conditions and uninitialized state errors.

### 2.2. The Fail-Fast Paradigm at the Macro Boundary
A core engineering principle of MakeOps is "Fail-Fast"—aborting execution at the exact moment an invalid state is detected. The Master Orchestrator serves as the ultimate safety net. It evaluates the deterministic return types (variant records or enumerations) from every Sub-Orchestrator. If any sub-system reports a domain error (e.g., a cyclic graph or a missing variable), the Master Orchestrator halts the forward sequence immediately, preventing invalid data from reaching the critical OS execution boundaries.

## 3. Conceptual Model
The Master Orchestration Lifecycle is modeled as a strictly linear 5-step sequential pipeline, wrapped within a global diagnostic error-handling boundary.

### 3.1. The 5-Step Execution Sequence
The orchestrator routes data through the following conceptual phases:

1. **Intention Acquisition (`MakeOps.App.CLI.Loader`):**
   * *Action:* The orchestrator requests the parsing of raw operating system arguments (`argv`).
   * *Result:* Yields application flags, target operations, or built-in system actions (e.g., Print Help).
2. **Context Establishment (`MakeOps.App.Config.Loader`):**
   * *Action:* If the intention requires execution, the orchestrator triggers the Configuration Cascade, merging global TOML preferences, OS environment variables, and CLI flags.
   * *Result:* Yields the final `App_Config` (including Log Level) and sets the physical Current Working Directory (CWD).
3. **Domain Knowledge Acquisition (`MakeOps.Core.Project.Config.Loader`):**
   * *Action:* The orchestrator triggers the reading and syntactic parsing of the project's specific `makeops.toml` file.
   * *Result:* Yields the static, raw `Project_Config` record containing the operations dictionary and environment variables.
4. **Plan Resolution (`MakeOps.Core.Project.Operation.Resolver`):**
   * *Action:* The orchestrator passes the static `Project_Config` and the target operations (from Step 1) to the Resolver. The Resolver performs the mathematical Topological Sort and Lazy Variable Substitution.
   * *Result:* Yields a fully validated, linear `Execution_Queue`.
5. **Physical Execution (`MakeOps.Core.Project.Operation.Executor`):**
   * *Action:* The orchestrator hands the `Execution_Queue` to the POSIX engine, which applies path translation heuristics and multiplexes the OS processes.
   * *Result:* Yields the final integer POSIX Exit Code.

### 3.2. Global Diagnostic Delegation
If any step from 1 to 4 returns a domain error containing spatial coordinates (Line and Column numbers), the Master Orchestrator interrupts the 5-step sequence. It delegates the error details to the Contextual Error Rendering mechanism (Zero-Allocation Diagnostics). After the diagnostic visual is printed to the terminal, the Orchestrator safely terminates the program with a non-zero exit code.

## 4. Engineering Impact

* **Constraints:**
    * The `MakeOps.App.Orchestrator` package MUST NOT contain logic for evaluating TOML structures or traversing arrays. Its code MUST consist almost entirely of subroutine calls to the defined Loaders, Resolver, and Executors.
    * The Orchestrator MUST handle all domain errors using standard conditional logic (e.g., evaluating returned variant records). It MUST NOT rely on native Ada exceptions (`raise`) for standard control flow.
* **Performance/Memory Risks:** The Orchestrator itself incurs $O(1)$ memory overhead, as it merely passes references/records between Sub-Orchestrators. 
* **Opportunities:** This strict procedural layout creates a pristine architectural core. Because the Orchestrator is totally decoupled from I/O mechanisms, its control flow logic can be easily mocked, thoroughly unit-tested, and mathematically proven via SPARK to never encounter deadlocks or bypass safety checks.

## 5. References

**Internal Documentation:**
* [1] [REQ-000: System Constraints](./REQ-000-system-constraints.md)
* [2] [REQ-002: Operation Orchestration & Execution](./REQ-002-operation-orchestration.md)
* [3] [MOD-002: Universal 5-Phase Processing Pipeline](./MOD-002-universal-processing-pipeline.md)
* [4] [MOD-003: Hierarchical Configuration Cascade](./MOD-003-hierarchical-configuration-cascade.md)
* [5] [MOD-004: Execution Plan Resolution](./MOD-004-execution-plan-resolution.md)
* [6] [MOD-005: Asynchronous Execution and Multiplexing](./MOD-005-asynchronous-execution.md)

**External Literature:**
* [7] Gray, J. (1986). *Why Do Computers Stop and What Can Be Done About It?* Symposium on Reliability in Distributed Software and Database Systems. (The foundational text on the "Fail-Fast" paradigm).
* [8] [POSIX.1-2017 - IEEE Std 1003.1: System Interfaces (exit, _Exit - terminate a process)](https://pubs.opengroup.org/onlinepubs/9699919799/functions/exit.html)