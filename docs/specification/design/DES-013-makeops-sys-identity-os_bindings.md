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

* **Implements Requirements:** `REQ-000` (System constraints and security).
* **Applies Concepts:**
    * `PLAT-001` (Pure Execution and OS Bindings: Thin Bindings to C ABI).
    * `PLAT-010` (Security Context and Root Privileges).
* **Internal Package Dependencies:** None. Depends only on standard `Interfaces.C`.

## 3. Interface Semantics (.ads Contract)

* **Core Types & State:**
    * Native C types mapped via `Interfaces.C` (e.g., `C.unsigned` for POSIX `uid_t`).
* **Main Subprograms:**
    * `c_getuid`: A function matching the POSIX `uid_t getuid(void)` signature. Returns the real user ID of the calling process.
* **Invariants & Contracts (Conceptual):**
    * The package MUST be declared as a `private package` to physically prevent any higher-level domain code from invoking the unsafe C function directly.
    * The specification MUST use `pragma SPARK_Mode (Off)`, as external C functions are inherently unprovable by GNATprove and break Absence of Runtime Errors (AoRE) guarantees.

## 4. Implementation Guidelines (.adb details)

* **Implementation Scope:** A package body (`.adb` file) is strictly NOT required. The subprogram is linked externally using `pragma Import (C, c_getuid, "getuid")`. The `.ads` file is sufficient for defining the types and imports.

## 5. Verification Strategy

* **Static Proof (GNATprove):** Explicitly excluded (`SPARK_Mode (Off)`).
* **AUnit Test Scenarios:**
    * **Direct Testing:** Not required and actively discouraged. Thin bindings should not be unit-tested in isolation.
    * **Indirect Validation:** Validated entirely through the test suite of its parent thick wrapper (`MakeOps.Sys.Identity`), which provides a safe, boolean interface to this C function.