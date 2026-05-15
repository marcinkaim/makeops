<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# DES-013 MakeOps.Sys.Identity.OS_Bindings Package Design

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `DES-013` |
| **Status** | `APPROVED` |
| **Date** | 2026-03-04 |
| **Target Package** | `MakeOps.Sys.Identity.OS_Bindings` |

## 1. Scope & Responsibility

* **Goal:** Serves as the raw, unsafe Thin Binding layer to the Linux kernel and `glibc` strictly for querying the operating system user identity.
* **Responsibility:**
    * Maps POSIX C data types (e.g., `uid_t`) to Ada equivalents using `Interfaces.C`.
    * Imports the native C function `getuid` via `pragma Import`.
* **Out of Scope:** This package strictly excludes any business logic, error handling, or exception translation. It is completely unaware of the MakeOps domain or the `--allow-root` CLI flag. 

## 2. Traceability & Dependencies

* **Implements Requirements:**
    * `REQ-000` (System Constraints):
        * `F-000-003`: Provides the native OS bindings necessary to query the operating system user identity (`getuid`), fulfilling the foundational security checks.
* **Applies Concepts:**
    * `MOD-007` (Pure Execution OS Boundaries): Defines the requirement for unsafe thin bindings mapping directly to the C ABI.
    * `MOD-012` (Execution Context & Security Model): Supplies the fundamental POSIX function signature required to physically identify superuser execution.
* **Intra-Project Dependencies:**
    * `None`: This private thin-binding package acts as a foundational adapter to the OS (identity management) and must not depend on any other packages within the project's namespace.
* **Standard Library Dependencies:**
    * `Interfaces.C`: Utilized in the specification to map the native POSIX C data type (e.g., `uid_t`) and to establish C-ABI compatibility for the `pragma Import` binding (`getuid`).

## 3. Interface Semantics (.ads Contract)

* **Core Types & State:**
    * `uid_t`: A native POSIX integer type mapped via `Interfaces.C.unsigned` representing the User ID.
* **Main Subprograms:**
    * `c_getuid`: A thin binding to the POSIX `getuid` function. Returns the real user ID of the calling process as a `uid_t` scalar.
* **Formal Contracts & Invariants (SPARK):**
    * The package specification MUST be marked with the `pragma SPARK_Mode (Off)` constraint. As a thin binding layer directly exposing the Linux C ABI, it is fundamentally unprovable by GNATprove.
    * The package MUST be declared as a `private package` (i.e., `private package MakeOps.Sys.Identity.OS_Bindings`). This strict boundary isolation mathematically prevents any higher-level domain code from accidentally invoking unsafe C functions, restricting its consumption exclusively to its parent thick wrapper (`MakeOps.Sys.Identity`).

## 4. Implementation Guidelines (.adb details)

* **Algorithmic Flow & Models:** Not Applicable. This package acts as a purely declarative thin binding layer utilizing `pragma Import (C, ...)` to link external kernel functions. It must not contain an implementation body (`.adb`).
* **Memory & SPARK Constraints:** Not Applicable for an implementation body. Regarding the specification, it handles only primitive scalar types (`uid_t`). The package guarantees no hidden allocations and inherently complies with the Zero-Allocation constraints.
* **Boundary & Exception Handling:** Not Applicable for an implementation body. This package does not trap exceptions or translate error codes. The POSIX `getuid` function is guaranteed by the OS to always succeed and does not return failure codes.