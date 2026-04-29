<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# MOD-015 CLI Interface and Argument Normalization

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `MOD-015` |
| **Status** | `APPROVED` |
| **Date** | 2026-04-23 |
| **Tags** | CLI, Arguments, POSIX, FSM, Normalization, Options, Operations |

## 1. Definition & Context
The CLI Interface and Argument Normalization model defines the formal specification of the arguments, flags, and operational targets accepted by the `mko` executable.

In the context of the MakeOps architecture, the Command Line Interface is treated as a primary data source for the Hierarchical Configuration Cascade. To maintain a modern Developer Experience (DX) and guarantee mathematical determinism, this model enforces the normalization of raw OS strings into distinct semantic classes: Options (Configuration) and Operations (Positional Targets). This process ensures that the CLI frontend remains a "dumb pipe" that feeds the validated internal state.

## 2. Theoretical Basis
This model is built upon POSIX-compliant argument conventions and Finite State Machine (FSM) parsing theory.

### 2.1. POSIX Argument Conventions
Unix-like systems traditionally differentiate between options (modifiers prefixed with `-` or `--`) and positional arguments (unprefixed strings). 
* **Options:** Modify the internal state or behavior of the tool.
* **Positional Arguments:** Define the "nouns" or "targets" upon which the tool acts.
MakeOps adheres to this standard signature: `mko [OPTIONS] [OPERATIONS...]`.

### 2.2. Atomic vs. Composite Flags
CLI tokens can be atomic (e.g., `--help`) or composite (e.g., `--log-level=debug`). To simplify the parsing logic and ensure SPARK verifiability, the normalization process must decompose composite tokens into simple key-value pairs before they reach the semantic application phase.

### 2.3. Halting vs. Execution Intents
In CLI design, some flags are "Halting"—they trigger an immediate action (like printing version info) and prevent the system from entering the orchestration loop. Identifying these intents early is critical to prevent unnecessary resource allocation (like opening configuration files).

## 3. Conceptual Model
The model utilizes a two-stream normalization approach to separate tool configuration from project targets.

### 3.1. Normalization Taxonomy (Data Structures)
The CLI Frontend partitions tokens into three semantic categories, producing two distinct outputs:
* **Config Overrides:** Normalized key-value pairs (e.g., `--log-level`) that populate the highest level of the Configuration Cascade.
* **`Intent_Queue`:** A prioritized list of user requests. It contains:
    * **Halting Actions:** High-priority system intents (e.g., `--help`, `--version`) that signal the Orchestrator to stop before entering the project domain.
    * **Unresolved Targets:** Positional arguments (e.g., `build`, `test`) representing the raw entry points for the DAG resolution. These are NOT yet sorted by dependencies.

### 3.2. Empty Target Heuristic (Domain Rule)
If the user invokes `mko` without any positional arguments (operations) and no halting flags, the system MUST NOT proceed with a null execution. The default behavior is to treat an empty target list as an implicit request for the usage manual, effectively triggering the same state as the `--help` flag.

### 3.3. Dual-Branch Normalization (Control Flow)
The Phase 4 Normalizer for the CLI frontend splits the data flow into two internal branches to feed the Master Orchestrator:
1.  **The Config Branch:** Normalizes flags into universal `Property_Event` records. These are merged into the `App_Config` to set the global state (e.g., Log Level, Working Directory).
2.  **The Intent Branch:** Assembles the `Intent_Queue`.
    * If the queue contains **Halting Actions**, the Orchestrator routes directly to a Command Executor.
    * If it contains **Unresolved Targets**, they are handed over to the **Resolver** (Cluster 6), which transforms this "intent" into the final, mathematically ordered **`Execution_Queue`**.

## 4. Engineering Impact
This model dictates the implementation of the specialized CLI instantiation of the 5-Phase Pipeline.

* **Constraints:**
    * **Phase 1 (Reader):** MUST safely retrieve the `argv` array from the OS boundary without making assumptions about its length.
    * **Phase 2 (Lexer):** MUST decompose composite flags (e.g., `--key=val` $\rightarrow$ `--key`, `val`) into distinct tokens.
    * **Phase 3 (Parser):** MUST be implemented as a non-recursive FSM. It MUST classify tokens based on prefixes and positional order.
    * **Phase 4 (Normalizer):** MUST perform a bounds check on every argument byte-length against `Max_Arg_Length` before emitting IR events.
* **Performance/Memory Risks:** Processing `argv` is $O(N)$ and occurs in-memory. The primary risk is buffer overflow when handling extremely long argument strings provided by a malicious caller, which is mitigated by strict bounded string limits.
* **Opportunities:** By forcing CLI arguments through the universal pipeline, the Master Orchestrator can handle "Print Help" and "Run Operation" using the same mechanical event loop, drastically reducing architectural branching.

## 5. References

**Internal Documentation:**
* [1] [MOD-002: Universal 5-Phase Processing Pipeline](./MOD-002-universal-processing-pipeline.md)
* [2] [MOD-003: Hierarchical Configuration Cascade](./MOD-003-hierarchical-configuration-cascade.md)
* [3] [MOD-009: SPARK Verification & Static Memory Model](./MOD-009-formal-verification-static-memory.md)
* [4] [MOD-012: Execution Context & Security Model](./MOD-012-execution-context-security-model.md)
* [5] [REQ-002: Operation Orchestration & Execution](./REQ-002-operation-orchestration.md)
* [6] [REQ-003: Execution Observability](./REQ-003-execution-observability.md)

**External Literature:**
* [7] [POSIX.1-2017 - IEEE Std 1003.1: Utility Conventions (Section 12.2: Utility Syntax Guidelines)](https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap12.html)