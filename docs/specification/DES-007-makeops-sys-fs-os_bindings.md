<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# DES-007 MakeOps.Sys.FS.OS_Bindings Package Design

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `DES-007` |
| **Status** | `APPROVED` |
| **Date** | 2026-03-03 |
| **Target Package** | `MakeOps.Sys.FS.OS_Bindings` |

## 1. Scope & Responsibility

* **Goal:** Serves as the raw, unsafe Thin Binding layer to the Linux kernel and `glibc` strictly for low-level file system metadata and access queries.
* **Responsibility:**
    * Maps POSIX C data types (e.g., `int`, `char*`) to Ada equivalents using `Interfaces.C`.
    * Defines POSIX constants related to file access modes (specifically `F_OK` for existence checks, `R_OK` for read permissions, and `X_OK` for execution permissions).
    * Imports native C functions via `pragma Import` (specifically `access`, `chdir`, `getcwd`, and `realpath`)
* **Out of Scope:** This package strictly excludes any business logic, error handling, or exception translation. It does not evaluate XDG environment variables or concatenate paths. Process lifecycle bindings belong to `MakeOps.Sys.Processes.OS_Bindings`.

## 2. Traceability & Dependencies

* **Implements Requirements:**
    * `REQ-002` (Operation Orchestration & Execution):
        * `F-002-006`: Provides the native OS bindings necessary to perform pre-flight executability checks (specifically the `X_OK` mode for `access`) on resolved binaries prior to execution.
* **Applies Concepts:**
    * `MOD-007` (Pure Execution OS Boundaries): Defines the requirement for unsafe thin bindings directly mapping to the C ABI.
    * `MOD-011` (Isolated OS Boundaries and Exception Handling): Establishes the unprovable foundation where POSIX errors are generated before being trapped by the thick wrapper.
    * `MOD-012` (Execution Context & Security Model): Supplies the fundamental OS directives (`chdir`, `realpath`) required to shift the working directory and resolve the Configuration Anchor.
* **Intra-Project Dependencies:**
    * `None`: This private thin-binding package acts as a foundational adapter to the OS and must not depend on any other packages within the project's namespace.
* **Standard Library Dependencies:**
    * `Interfaces.C` & `Interfaces.C.Strings`: Utilized in the specification to map native POSIX C data types (e.g., `int`, `size_t`, `chars_ptr`) and to establish C-ABI compatibility for the `pragma Import` bindings (`access`, `chdir`, `getcwd`, `realpath`).

## 3. Interface Semantics (.ads Contract)

* **Core Types & State:**
    * `F_OK`, `X_OK`, `R_OK`: Static POSIX constants of type `Interfaces.C.int` used as mode masks to verify file existence, executability, and read permissions, respectively.
* **Main Subprograms:**
    * `c_access`: A thin binding to the POSIX `access` function. Returns `0` on success or `-1` on error.
    * `c_chdir`: A thin binding to the POSIX `chdir` function. Returns `0` on success or `-1` on error.
    * `c_getcwd`: A thin binding to the POSIX `getcwd` function. Returns a pointer to the buffer on success, or a null pointer on error.
    * `c_realpath`: A thin binding to the POSIX `realpath` function. Returns a pointer to the resolved absolute path on success, or a null pointer on error.
* **Formal Contracts & Invariants (SPARK):**
    * The package specification MUST be marked with the `pragma SPARK_Mode (Off)` constraint. As a thin binding layer directly exposing the Linux C ABI (glibc), it is fundamentally unprovable by GNATprove.
    * The package MUST be declared as a `private package` (i.e., `private package MakeOps.Sys.FS.OS_Bindings`). This strict boundary isolation mathematically prevents any higher-level domain code (such as `MakeOps.Core`) from accidentally invoking unsafe C functions, restricting its consumption exclusively to its parent thick wrapper.

## 4. Implementation Guidelines (.adb details)

* **Algorithmic Flow & Models:** Not Applicable. This package acts purely as a declarative thin binding layer to the Linux C ABI. It utilizes `pragma Import (C, ...)` for all its declared subprograms (`c_access`, `c_chdir`, `c_getcwd`, `c_realpath`) and explicitly must not contain an implementation body (`.adb`).
* **Memory & SPARK Constraints:** Not Applicable for an implementation body. Regarding the specification, it natively passes raw C pointers (`chars_ptr`) and relies on standard C types (`int`, `size_t`). The package guarantees no hidden allocations. The strict lifecycle management of these pointers (allocation and deallocation) is completely delegated to the parent wrapper.
* **Boundary & Exception Handling:** Not Applicable for an implementation body. This package does not trap exceptions or translate error codes. Native POSIX errors (signaled via `-1` or null pointer returns) must be caught and deterministically degraded by the parent thick wrapper.