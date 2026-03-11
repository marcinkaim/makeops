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

* **Implements Requirements:** `REQ-002` (Operation Orchestration: Pre-flight executability checks).
* **Applies Concepts:**
    * `PLAT-001` (Pure Execution and OS Bindings: Adopting the Thin Bindings architectural pattern).
    * `PLAT-004` (Linux Environment and FS Adapters: Providing the underlying OS capability for the FS Facade).
* **Internal Package Dependencies:** None. Depends solely on standard `Interfaces.C`.

## 3. Interface Semantics (.ads Contract)

* **Core Types & State:**
    * Native C types mapped via `Interfaces.C` (e.g., `C.int`, `C.Strings.chars_ptr`).
    * `X_OK`: A static constant (typically `1` in POSIX/Linux) used as the `mode` mask to check for execute permissions.
* **Main Subprograms:**
    * `c_access`: A function matching the POSIX `access(const char *pathname, int mode)` signature. Returns `0` on success (access granted), or `-1` on error.
    * `c_chdir`: A function matching the POSIX `chdir(const char *path)` signature. Returns `0` on success, or `-1` on error.
    * `c_getcwd`: A function matching the POSIX `char *getcwd(char *buf, size_t size)` signature. Returns the pointer to the buffer on success, or `null` on error.
    * `c_realpath`: A function matching the POSIX `char *realpath(const char *path, char *resolved_path)` signature. Returns the pointer to the resolved path on success, or `null` on error.
* **Invariants & Contracts (Conceptual):**
    * The package MUST be declared as a `private package` to physically prevent domain logic (like `MakeOps.Core`) from invoking unsafe C file system functions directly.
    * The specification MUST use `pragma SPARK_Mode (Off)`, as external C functions are inherently unprovable by GNATprove and break Absence of Runtime Errors (AoRE) guarantees.

## 4. Implementation Guidelines (.adb details)

* **Implementation Scope:** A package body (`.adb` file) is strictly NOT required. The functions are linked externally using `pragma Import (C, c_access, "access")`, `pragma Import (C, c_chdir, "chdir")`, `pragma Import (C, c_getcwd, "getcwd")`, and `pragma Import (C, c_realpath, "realpath")`. The `.ads` file is sufficient for defining the types, constants, and the import directives.

## 5. Verification Strategy

* **Static Proof (GNATprove):** Explicitly excluded (`SPARK_Mode (Off)`).
* **AUnit Test Scenarios:**
    * **Direct Testing:** Not required and actively discouraged. Thin bindings should not be unit-tested in isolation as they interact directly with the OS file system.
    * **Indirect Validation:** Validated entirely through the test suite of its parent thick wrapper (`MakeOps.Sys.FS`), which safely passes converted strings and interprets the integer return codes.