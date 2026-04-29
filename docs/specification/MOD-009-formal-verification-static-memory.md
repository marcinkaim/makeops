<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# MOD-009 Formal Verification & Static Memory Foundations

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `MOD-009` |
| **Status** | `APPROVED` |
| **Date** | 2026-04-25 |
| **Tags** | SPARK, Silver Level, Ada 2022, Formal Verification, AoRE, Memory, BSS, Bounded Types |

## 1. Definition & Context
The Formal Verification & Static Memory Foundations defines the strict constraints and strategies for formal mathematical proof, data storage, and state management within the MakeOps architecture. 

In the context of the MakeOps project, the system must guarantee absolute reliability and security at the operating system boundary. By leveraging Ada 2022 and the SPARK formal verification subset, this model establishes how MakeOps achieves the mathematically proven Absence of Runtime Errors (AoRE). Crucially, this requires the complete elimination of dynamic heap allocation in favor of static memory sizing, unifying the rules of verification and memory management into a single, cohesive foundation.

## 2. Theoretical Basis
This model bridges the mathematics of formal static analysis with the physical layout of memory in POSIX-compliant operating systems.

### 2.1. Formal Verification and AoRE (Silver Level)
Formal verification is the process of using static mathematical analysis to prove the correctness of software algorithms relative to a formal property. MakeOps targets the **"Silver Level"** of SPARK verification, which mandates complete initialization of data, absence of aliasing, data flow analysis, and proving the Absence of Runtime Errors (AoRE). The SPARK toolset (GNATprove) mathematically guarantees that catastrophic events such as division by zero, array index out of bounds, integer overflows, and range constraint violations will never occur during program execution.

### 2.2. Deterministic Memory Allocation (Heap vs. BSS/Data)
In traditional systems, dynamic memory is allocated at runtime on the heap (e.g., via `malloc` or `new`). The heap introduces inherent non-determinism, including fragmentation, memory leaks, and the potential for `Out_Of_Memory` exceptions during unpredictable execution states.
Conversely, statically allocated data is placed in the `.bss` (uninitialized) or `.data` (initialized) segments of the compiled ELF binary. The operating system allocates and maps this memory exactly once when the executable is loaded into RAM. Therefore, memory exhaustion can only occur at startup, making the runtime footprint completely deterministic and predictable.

### 2.3. The Aliasing Problem
Memory pointers (access types in Ada) introduce "aliasing"—where multiple references point to the same memory location. Aliasing severely complicates formal verification because mutating data through one pointer implicitly changes the state observed through another, making mathematical assertions about data flow incredibly difficult or impossible to prove automatically.

## 3. Conceptual Model
To satisfy the SPARK constraints and guarantee AoRE, MakeOps applies strict rules for memory allocation, type definitions, and algorithmic control flow.

### 3.1. Zero-Heap and Bounded Types
MakeOps completely rejects dynamic heap allocation. The `new` keyword and dynamic access types (pointers) are forbidden. 
* **Package-Level Allocation (BSS/Data):** Global states, such as the Environment Dictionary or the Operations Graph, must be declared at the package level (e.g., inside the `MakeOps.Core.Graph` package body). At the operating system level, these variables are placed directly into the physical `.bss` (uninitialized) or `.data` (initialized) memory segments of the process. This provides a deterministic, mathematically provable memory footprint from the moment the OS loads the binary.
* **Bounded Structures:** All strings and arrays must use fixed, maximum capacities defined at compile-time (e.g., `Ada.Strings.Bounded`).
* **Index-Based Graphing:** To eliminate aliasing in complex structures (like the Directed Acyclic Graph), MakeOps uses strictly typed array indices (integers) instead of pointers to represent edges and relationships.

### 3.2. Deterministic Exception Handling (Monadic Result)
Because native exception propagation (`raise`) disrupts mathematically provable control flow, conceptual algorithmic exceptions (e.g., `Missing_Variable_Error`, `Cycle_Detected`) MUST NOT use Ada's exception mechanisms within the verified core. 
MakeOps implements a deterministic "Fail-Fast" approach using Discriminated Variant Records or Status Enumerations (e.g., `Operation_Result`), heavily mirroring the Monadic `Result` pattern. Native exceptions (like `System_Error`) are strictly reserved for unrecoverable OS-level panics outside the SPARK boundary.

### 3.3. Static Capacity Limits
To ensure that the bounded types generously cover standard DevOps use cases without causing bloat, the system enforces the following centralized architectural limits:
* `Max_Operations`: 64 (Maximum discrete operations in a `makeops.toml` file).
* `Max_Command_Length`: 4096 bytes (Maximum physical length of an executed binary path).
* `Max_Args_Per_Command`: 32 (Maximum number of arguments per execution).
* `Max_Arg_Length`: 1024 bytes (Maximum physical length of a single evaluated argument).
* `Max_Env_Vars`: 64 (Maximum number of user environment variables).
* `Max_Env_Var_Name_Length`: 64 bytes (Maximum length of an environment key).
* `Max_Env_Var_Value_Length`: 32768 bytes (Maximum length of an environment value).

### 3.4. The Boundary Isolation Pattern
POSIX OS interactions (like file system checks) are inherently non-deterministic and rely on standard Ada runtime exceptions. To maintain AoRE in the core logic, MakeOps employs the Boundary Isolation pattern exclusively at the OS Adapter layer. The adapters (`MakeOps.Sys.*`) expose SPARK-verified specifications (`.ads`) that return deterministic variants (Monadic Results). Crucially, **only** their implementations (`.adb`) are allowed to explicitly opt out of SPARK (`pragma SPARK_Mode (Off)`). This isolation layer safely traps native OS and hardware exceptions internally before they can pollute the verified core.

## 4. Engineering Impact

* **Constraints:**
    * The `MakeOps.Core` engine MUST be written strictly within the SPARK subset and verified with `GNATprove` configured for the **Silver Level** (Flow Analysis + AoRE). 
    * State-mutating procedures MUST explicitly declare their data flow using the SPARK `Depends` and `Global` contracts. 
    * Dynamic sizing, unbounded strings, and the `Ada.Exceptions` library are strictly forbidden in the domain logic.
* **Performance/Memory Risks:** Because every bounded string and array allocates its maximum capacity immediately, the base memory footprint of the binary is larger than a dynamic equivalent. However, this is capped at a few megabytes—a completely negligible cost on modern Linux servers.
* **Opportunities:** Achieving AoRE drastically reduces the volume of defensive unit tests required. The $O(1)$ memory allocation guarantees zero runtime overhead for garbage collection or heap management, resulting in blazing-fast execution speeds that are fully mathematically predictable.

## 5. References

**Internal Documentation:**
* [1] [MOD-002: Universal 5-Phase Processing Pipeline](./MOD-002-universal-processing-pipeline.md)
* [2] [MOD-004: Execution Plan Resolution](./MOD-004-execution-plan-resolution.md)
* [3] [MOD-007: Pure Execution OS Boundaries](./MOD-007-pure-execution-os-boundaries.md)
* [4] [MOD-011: Isolated OS Boundaries and Exception Handling](./MOD-011-isolated-os-boundaries.md)

**External Literature:**
* [5] [SPARK 2014 Reference Manual - AdaCore](https://docs.adacore.com/spark2014-docs/html/lrm/)
* [6] [Executable and Linkable Format (ELF) Specification - Section on .bss and .data segments](https://refspecs.linuxfoundation.org/elf/elf.pdf)