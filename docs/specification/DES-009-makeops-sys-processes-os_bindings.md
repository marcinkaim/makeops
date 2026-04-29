<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# DES-009 MakeOps.Sys.Processes.OS_Bindings Package Design

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `DES-009` |
| **Status** | `APPROVED` |
| **Date** | 2026-03-03 |
| **Target Package** | `MakeOps.Sys.Processes.OS_Bindings` |

## 1. Scope & Responsibility

* **Goal:** Serves as the raw, unsafe Thin Binding layer to the Linux kernel and `glibc` strictly for process and IPC lifecycle management.
* **Responsibility:**
    * Maps POSIX C data types (e.g., `int`, `char**`, `struct pollfd`) to Ada equivalents using `Interfaces.C`.
    * Imports native C functions via `pragma Import` (e.g., `fork`, `execvp`, `pipe`, `poll`, `waitpid`).
* **Out of Scope:** This package strictly excludes any business logic, error handling, or exception translation. It is completely unaware of the MakeOps domain. File system bindings (like `access`) are excluded and belong to `MakeOps.Sys.FS.OS_Bindings` (if created).

## 2. Traceability & Dependencies

* **Implements Requirements:**
    * `REQ-002` (Operation Orchestration: Pure Execution).
* **Applies Concepts:**
    * `MOD-007` (Pure Execution OS Boundaries: Thin Bindings to C ABI).
    * `MOD-005` (Asynchronous Execution and Multiplexing: `poll` definitions).
    * `MOD-006` (POSIX IPC and Stream Routing: `pipe` definitions).
    * `MOD-008` (System Signal Routing: `waitpid` macros and kill signals).
* **Internal Package Dependencies:** None. Depends only on standard `Interfaces.C`.

## 3. Interface Semantics (.ads Contract)

* **Core Types & State:**
    * Native C types mapped via `Interfaces.C` (e.g., `C.int`, `C.Strings.chars_ptr`, `C.Strings.chars_ptr_array`).
    * `struct_pollfd`: An Ada record with a `pragma Convention (C)` matching the memory layout of the POSIX `pollfd` structure.
* **Main Subprograms:**
    * Subprograms directly matching the POSIX C API: `c_pipe`, `c_fork`, `c_execvp`, `c_dup2`, `c_fcntl`, `c_poll`, `c_read`, `c_waitpid`, `c_kill`, `c_close`. (Prefixes or explicit naming conventions may be used to differentiate from Ada keywords).
* **Invariants & Contracts (Conceptual):**
    * The package MUST be declared as a `private package` to physically prevent any higher-level domain code (like `MakeOps.Core`) from invoking unsafe C functions directly.
    * The specification MUST use `pragma SPARK_Mode (Off)`, as external C functions are inherently unprovable by GNATprove and break Absence of Runtime Errors (AoRE) guarantees if misused.

## 4. Implementation Guidelines (.adb details)

* **Implementation Scope:** A package body (`.adb` file) is strictly NOT required. All subprograms are linked externally using `pragma Import (C, [Ada_Name], "[C_Name]")`. The `.ads` file is sufficient for defining types and imports.

## 5. Verification Strategy

* **Static Proof (GNATprove):** Explicitly excluded (`SPARK_Mode (Off)`).
* **AUnit Test Scenarios:**
    * **Direct Testing:** Not required and actively discouraged. Thin bindings should not be unit-tested in isolation, as they modify the raw OS state.
    * **Indirect Validation:** Validated entirely through the test suite of its parent thick wrapper (`MakeOps.Sys.Processes`), which provides safe inputs and handles the outputs of these C functions.