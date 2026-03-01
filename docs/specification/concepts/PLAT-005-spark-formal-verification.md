<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# PLAT-005 SPARK Formal Verification and Ada 2022 Constraints

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `PLAT-005` |
| **Status** | `APPROVED` |
| **Date** | 2026-02-23 |
| **Category** | Platform Model |
| **Tags** | SPARK, Ada 2022, Formal Verification, AoRE, Contracts, Static Analysis |

## 1. Definition & Context
Formal verification is the process of using static mathematical analysis to prove the correctness of software algorithms relative to a certain formal specification or property. 

In the context of the **MakeOps** project, the system is engineered using Ada 2022 and the SPARK formal verification subset. Rather than relying solely on empirical unit testing to find bugs, MakeOps employs the GNATprove toolset to mathematically guarantee the program's stability before it is even compiled. This approach ensures that the orchestrator is inherently immune to common system crashes, such as segmentation faults, buffer overflows, or unhandled null references.

## 2. Theoretical Basis
The platform's safety model is built upon three pragmatic pillars of the SPARK and Ada ecosystems, targeting the "Silver Level" of formal verification.

### 2.1. Ada 2022 Safe Subsetting and Constraints
Ada enforces strict engineering disciplines by design. To satisfy the requirements of formal verification, the MakeOps architecture strictly forbids the use of dynamic heap allocation (pointers/access types). Instead, the system relies entirely on package-level static allocation (BSS/Data segments) and statically bounded types with strict bounds checking. The specific details of this memory strategy and the exact platform capacity limits are defined in **PLAT-006**. By forbidding implicit type conversions (strong typing) and bounding all array and string structures, the language itself eliminates the root causes of typical memory corruption vulnerabilities found in C/C++ tools.

### 2.2. Absence of Runtime Errors (AoRE)
The primary goal of using SPARK in MakeOps is achieving the Absence of Runtime Errors (AoRE). GNATprove statically analyzes the control and data flow of the application to mathematically prove that certain catastrophic events will **never** occur during execution. These include:
* Division by zero.
* Array index out of bounds (crucial for the Level 1 Lexer in `ALG-004`).
* Integer overflows or underflows.
* Range constraint violations.

### 2.3. Pragmatic Contracts (Pre/Post-conditions and Data Flow)
Instead of writing exhaustive functional proofs, the project employs lightweight, pragmatic contracts:
* **Data Flow Contracts (`Depends`):** Used in state machines (like `ALG-005`) to explicitly declare which global states are mutated by which inputs, preventing accidental side-effects.
* **Pre/Post-conditions:** Used at the boundaries of the `MakeOps.Sys` OS Adapters (e.g., `PLAT-001`). For instance, a `Pre => Command_Name'Length > 0` contract on the `execvp` wrapper forces the compiler to reject any caller that cannot mathematically prove the string is non-empty.

### 2.4. Algorithmic Exceptions vs. Deterministic Implementation
In the conceptual Knowledge-Based Analysis (KBA) documents (e.g., the `ALG` series), the term "Exception" is used abstractly to denote a "Fail-Fast" interruption of the algorithm (e.g., `Missing_Variable_Error`, `Cycle_Detected`). However, due to the SPARK restrictions on control flow, these conceptual exceptions MUST NOT be implemented using Ada's native `raise` and `exception` keywords within the verifiable core (`MakeOps.Core`). Instead, they must be realized using deterministic return types, such as Discriminated Records (Variant Records) or Status Enumerations (e.g., `Operation_Result`), effectively mimicking the Monadic `Result` pattern. Native exceptions (e.g., `MakeOps.Sys.System_Error`) are strictly reserved for unrecoverable hardware or OS-level panics outside the SPARK boundary, functioning purely as a fatal abort mechanism.

## 3. Engineering Impact

* **Constraints:**
    * **Core Logic Verification:** The core algorithms and orchestration engine (`MakeOps.Core`) MUST be written strictly within the SPARK subset. The use of dynamic exceptions for control flow and unbounded aliasing is strictly forbidden to guarantee AoRE. Functions calling contract-equipped procedures MUST statically satisfy all pre-conditions.
    * **Boundary Isolation Pattern:** Because native OS interactions (like file system queries) are inherently non-deterministic and rely on standard Ada exceptions, the architecture MUST employ the Boundary Isolation pattern at the OS Adapter layer (`MakeOps.Sys`). The package bodies (`.adb`) of these adapters MUST be marked with `pragma SPARK_Mode (Off)`, allowing them to internally catch hardware or OS exceptions. These bodies must safely translate the exceptions into predictable, verifiable data structures defined in their `SPARK_Mode (On)` specifications (`.ads`).
* **Performance Risks:** None at runtime. SPARK contracts and assertions are used strictly for static analysis and can be compiled out of the final release binary, guaranteeing zero-overhead while maintaining 100% verified safety. The only "cost" is increased compile-time analysis duration.
* **Opportunities:** Achieving AoRE drastically reduces the required volume of defensive unit tests. Instead of writing dozens of test cases for edge-case string lengths in the TOML parser, the SPARK prover automatically validates the algorithmic boundaries, accelerating the development of a highly robust tool.

## 4. References

**Internal Documentation:**
* [1] [ALG-004: Event-Driven TOML Lexer](./ALG-004-event-driven-toml-lexer.md)
* [2] [ALG-005: Event-Driven Semantic Analyzer](./ALG-005-event-driven-semantic-analyzer.md)
* [3] [PLAT-001: Pure Execution and OS Bindings](./PLAT-001-pure-execution-posix.md)
* [4] [PLAT-006: Static Memory Model](./PLAT-006-static-memory-model.md)