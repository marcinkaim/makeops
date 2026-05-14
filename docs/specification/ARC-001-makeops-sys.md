<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# ARC-001 MakeOps.Sys Namespace Architecture

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `ARC-001` |
| **Status** | `APPROVED` |
| **Date** | 2026-05-01 |
| **Target Namespace** | `MakeOps.Sys` |

## 1. Domain Definition & Purpose

* **Goal:** This domain serves as the highly constrained "sandbox" and protective boundary (Facade) between the mathematically pure, SPARK-verified orchestration engine and the unpredictable host operating system. It translates OS-level volatility, unpredictable C-ABI behaviors, and standard Ada runtime exceptions into deterministic, safe data structures.
* **Core Responsibility:** Physically isolates and manages all raw interactions with Linux/POSIX subsystems, including process lifecycle management (`fork`/`execvp`), inter-process communication via pipes, signal routing, environment variable extraction, standard stream multiplexing, and file system queries.

## 2. Boundaries & Constraints

* **Domain In-Scope:** POSIX system calls, C-ABI data types, native Ada exception trapping (`Ada.Text_IO`, `Ada.Environment_Variables`), monotonic clock access, hardware interrupt handling, and raw file descriptors.
* **Domain Out-of-Scope (Strict Bounds):** This namespace MUST NOT contain application business logic, DAG resolution, or variable substitution logic. It MUST NOT parse configuration files (e.g., TOML). It MUST NOT autonomously abort the application (except for unrecoverable `System_Error` panics); it must gracefully return failure states to the higher-level orchestrator.

## 3. Traceability & Foundation

* **Implements Requirements:**
    * `REQ-000` (System Constraints):
        * `NFR-000-002`: Enforces the SPARK verification boundary by safely encapsulating unprovable C-bindings and preventing native exceptions from leaking into the core logic.
    * `REQ-002` (Operation Orchestration):
        * `NFR-002-001`: Provides the Pure Execution OS bindings necessary to spawn processes directly without intermediate shell scripts.
    * `REQ-003` (Execution Observability):
        * `NFR-003-001`: Exposes raw terminal streams and process execution status to satisfy real-time observability constraints.
* **Applies Concepts:**
    * `MOD-007` (Pure Execution OS Boundaries): Applies the Dual-Layer abstraction pattern (Thin Binding vs. Thick Wrapper) to safely call POSIX C functions.
    * `MOD-011` (Isolated OS Boundaries and Exception Handling): Employs the Boundary Isolation pattern, using `pragma SPARK_Mode (Off)` in bodies to trap exceptions and `pragma SPARK_Mode (On)` in specifications to return monadic `Result` types.
    * `MOD-012` (Execution Context & Security Model): Provides the foundational path resolution, CWD shifting (`chdir`), and UID checks (`getuid`) required to prevent workspace pollution.

## 4. Architectural Topology

**Components (Package Blueprints):**

* `MakeOps.Sys.Env` (`DES-005`): The safe OS Facade for querying host environment variables. It implements Graceful Degradation by trapping native OS exceptions and translating them into deterministic variant records. The design MUST guarantee the Absence of Runtime Errors (AoRE) and utilize bounded strings to comply with static memory limits.
* `MakeOps.Sys.FS` (`DES-006`): The exception-free file system adapter for path resolution and metadata checks. It manages safe working directory transitions and Pre-flight Executability Checks without propagating native I/O exceptions. The design MUST expose SPARK-verified interfaces utilizing deterministic status enumerations.
* `MakeOps.Sys.FS.OS_Bindings` (`DES-007`) **[Private]**: The unsafe "Thin Binding" layer to the Linux kernel and `glibc` strictly for file system metadata. It imports native C functions like `access`, `chdir`, and `realpath` using `Interfaces.C`. The design MUST explicitly opt out of SPARK verification using `pragma SPARK_Mode (Off)`.
* `MakeOps.Sys.Processes` (`DES-008`): The SPARK-safe "Thick Wrapper" for managing the lifecycle of POSIX processes. It safely orchestrates pipe creation, secure process spawning, and translates raw POSIX bitmasks into verified domain states. The design MUST securely isolate all underlying C-ABI pointers and null-termination logic from its public interface.
* `MakeOps.Sys.Processes.OS_Bindings` (`DES-009`) **[Private]**: The unsafe "Thin Binding" layer providing direct access to the core POSIX kernel process API. It maps raw kernel calls including `fork`, `execvp`, `pipe`, `poll`, and `waitpid`. The design MUST remain completely private and operate with SPARK verification disabled.
* `MakeOps.Sys.Terminal` (`DES-010`): The exception-proof facade for standard terminal streams (`stdout`, `stderr`). It suppresses native I/O library errors (e.g., broken pipes) and enforces automatic stream flushing for real-time observability. The design MUST NOT utilize dynamic memory allocation when writing byte streams.
* `MakeOps.Sys.Signals` (`DES-011`): The thread-aware OS adapter for hardware interrupt routing. It encapsulates Ada concurrency mechanisms to safely intercept system signals (like `SIGINT`) and converts them into deterministic state flags. The design MUST utilize a Protected Object to guarantee atomicity and prevent race conditions without blocking the main thread.
* `MakeOps.Sys.Identity` (`DES-012`): The fully verifiable OS Facade for querying the operating system user identity. It provides a deterministic boolean evaluation to check if the current process holds superuser (root) privileges. The design MUST securely hide the specific POSIX integer types (UID) from the higher-level domain logic.
* `MakeOps.Sys.Identity.OS_Bindings` (`DES-013`) **[Private]**: The unsafe "Thin Binding" layer for user identity queries. It imports the raw POSIX `getuid` C function. The design MUST be strictly excluded from SPARK verification.
* `MakeOps.Sys.Time` (`DES-014`): The safe, SPARK-friendly OS adapter for monotonic time and duration measurements. It encapsulates `Ada.Real_Time` to calculate elapsed execution time and non-blocking deadlines without throwing overflow exceptions. The design MUST prevent domain logic from performing unsafe arithmetic directly on volatile OS clock types.
* `MakeOps.Sys.File_Stream` (`DES-015`): The exception-free OS adapter for sequential, line-by-line text file reading. It wraps native `Ada.Text_IO` calls to trap `End_Error` and translate lines into bounded string variants. The caller MUST be required to manage the strict Open/Close resource lifecycle deterministically.

**Subsystems (Delegated Namespaces):**

* `None` (`N/A`): The `MakeOps.Sys` namespace currently acts as a flat structural domain for isolation layers, and all its components are managed directly within this architecture.