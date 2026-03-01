<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# PLAT-006 Static Memory Model

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `PLAT-006` |
| **Status** | `APPROVED` |
| **Date** | 2026-02-23 |
| **Category** | Platform Model |
| **Tags** | Memory, Allocation, Bounded Types, SPARK, BSS, State |

## 1. Definition & Context
The Static Memory Model defines the strict constraints and strategies for data storage and state management within the MakeOps architecture. To satisfy the requirement for mathematical Absence of Runtime Errors (AoRE) using the SPARK verification toolset, the system completely rejects dynamic heap allocation. Instead, MakeOps relies exclusively on bounded data types and package-level static allocation (the BSS/Data segments) to guarantee predictable memory footprint and execution safety.

## 2. Theoretical Basis
The memory model leverages Ada's native support for fixed-size structures and operating system memory mapping, avoiding the non-deterministic nature of the heap.

### 2.1. Package-Level Allocation (BSS/Data Segment)
In traditional systems, large structures are either dynamically allocated on the heap (using `new` or `malloc`) or passed heavily via the call stack. In MakeOps, global states such as the Environment Dictionary or the Operations Graph are declared at the package level (e.g., inside the `MakeOps.Core.Graph` package body). At the operating system level, these variables are placed in the `.bss` or `.data` segments of the compiled ELF binary. The memory is mapped immediately when the OS loads the executable, meaning out-of-memory errors (`Storage_Error`) can only occur at startup, never during the actual execution of the program.

### 2.2. Bounded Types and Indexing
To avoid dynamic types like `Ada.Strings.Unbounded.Unbounded_String` or dynamic Vectors, all data structures use fixed capacities defined at compile-time. 
Furthermore, the use of memory pointers (access types in Ada) is forbidden. Pointers introduce aliasing, which complicates formal verification and can lead to memory leaks or cyclic references. Instead, relationships within data structures (such as edges in the Directed Acyclic Graph) are implemented using pure array indices (integers).

### 2.3. Architectural Constraints (Platform Limits)
Since all types must be bounded, the system establishes predefined limits that generously cover standard DevOps use cases while maintaining a deterministic memory footprint:
* `Max_Operations`: 64 (Maximum number of operations in a single `makeops.toml` graph).
* `Max_Command_Length`: 256 bytes (Maximum physical length of the `cmd` binary path).
* `Max_Args_Per_Command`: 32 (Maximum number of arguments per execution).
* `Max_Arg_Length`: 1024 bytes (Maximum physical length of a single evaluated argument).
* `Max_Env_Vars`: 64 (Maximum number of environment variables declared).
* `Max_Env_Var_Name_Length`: 64 bytes (Maximum physical length of an environment variable key).
* `Max_Env_Var_Value_Length`: 1024 bytes (Maximum physical length of an environment variable value).

## 3. Engineering Impact
* **Constraints:** Developers MUST use `Ada.Strings.Bounded` instead of unbounded variants. The `new` keyword and access types MUST NOT be used for data structures. State mutating procedures MUST explicitly declare their impact on package-level variables using SPARK `Global` and `Depends` contracts.
* **Performance Risks:** Since arrays and bounded strings always allocate their maximum defined capacity regardless of actual usage, the base memory footprint of the binary will be larger than a dynamically managed equivalent. However, on modern Desktop Linux environments, a static footprint of a few megabytes is completely negligible.
* **Opportunities:** This approach trivially solves the hardest problems in formal verification. Because memory ownership is static and array boundaries are fixed, GNATprove can mathematically guarantee the absence of memory leaks, double-frees, and segmentation faults with zero runtime overhead. The topological sorting algorithms can operate freely on array indices without violating memory safety invariants.

## 4. References

**Internal Documentation:**
* [1] [PLAT-005: SPARK Formal Verification and Ada 2022 Constraints](./PLAT-005-spark-formal-verification.md)
* [2] [MATH-001: Directed Acyclic Graph Model](./MATH-001-dag-model.md)
* [3] [ALG-001: Topological Sorting and Cycle Detection](./ALG-001-topological-sort.md)
* [4] [PLAT-011: Text Encoding and Memory Safety](./PLAT-011-text-encoding-model.md)