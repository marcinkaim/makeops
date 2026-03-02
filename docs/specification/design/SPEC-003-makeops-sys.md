<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# SPEC-003 MakeOps.Sys Package Specification

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `SPEC-003` |
| **Status** | `APPROVED` |
| **Date** | 2026-03-02 |
| **Target Package** | `MakeOps.Sys` |

## 1. Scope & Responsibility

* **Goal:** Serves as the root namespace and foundational abstraction layer for all Operating System and hardware interactions.
* **Responsibility:**
    * Defines the base hardware and OS-level exception (`System_Error`) that acts as a fatal abort mechanism.
    * Defines fundamental system error codes mapping to native POSIX `errno` values.
* **Out of Scope:** This package strictly excludes concrete implementations of file system access, process management, or environment queries. These are explicitly delegated to its child packages (e.g., `MakeOps.Sys.FS`, `MakeOps.Sys.Processes`).

## 2. Traceability & Dependencies

* **Implements Requirements:**
    * `REQ-000` (System constraints and POSIX OS boundaries).
* **Applies Concepts:**
    * `PLAT-004` (Linux Environment and FS Adapters: Exception Isolation).
    * `PLAT-005` (SPARK Formal Verification: Reserving native exceptions purely for fatal, unrecoverable aborts outside the SPARK boundary).
* **Internal Package Dependencies:** None. This is the foundation of the OS boundary subsystem.

## 3. Interface Semantics (.ads Contract)

* **Core Types & State:**
    * `System_Error`: A native Ada exception. It represents a catastrophic, unrecoverable failure originating from the OS or kernel (e.g., hardware fault, complete memory exhaustion). 
    * `System_Error_Code`: An integer type designed to map directly to standard Linux `errno` values, allowing child packages to propagate specific kernel diagnostics if needed.
* **Main Subprograms:**
    * None.
* **Invariants & Contracts (Conceptual):**
    * The package MUST be marked with `pragma Preelaborate`. This prepares the data structures at link-time and allows child packages to safely depend on these types while implementing their own non-pure I/O operations.

## 4. Implementation Guidelines (.adb details)

* **Implementation Scope:** A package body (`.adb` file) is strictly NOT required and MUST NOT be created for this root namespace package. The declarations in the `.ads` file are entirely sufficient.

## 5. Verification Strategy

* **Static Proof (GNATprove):** Automatically proven. The declarations contain no complex logic, satisfying Absence of Runtime Errors (AoRE).
* **AUnit Test Scenarios:**
    * **Happy Path:** A trivial sanity test ensuring that `System_Error_Code` can hold typical POSIX `errno` ranges (e.g., positive integers).