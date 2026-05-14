<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# DES-003 MakeOps.Sys Package Design

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `DES-003` |
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
    * `REQ-000` (System Constraints):
        * `F-000-001`: Defines the standard POSIX exit codes and the base system exception necessary to communicate with the host operating system.
    * `REQ-003` (Execution Observability):
        * `F-003-004`: Provides the distinct `Exit_Code` data type used to report the final execution status of the orchestrator to the environment.
* **Applies Concepts:**
    * `MOD-008` (System Signal Routing): Establishes the static constants (`Exit_Success`, `Exit_Failure`) representing standardized POSIX exit statuses required for consistent pipeline integration.
    * `MOD-009` (Formal Verification & Static Memory Foundations): Enforces strong typing for error codes to prevent mixing them with standard operational integers, supporting the overall AoRE architecture.
    * `MOD-011` (Isolated OS Boundaries and Exception Handling): Defines the baseline `System_Error` exception serving as the ultimate fallback mechanism for unrecoverable hardware or OS-level panics.
* **Internal Package Dependencies:**
    * None. This is the absolute foundation of the Operating System boundary subsystem (`MakeOps.Sys`) and relies exclusively on the standard Ada library.

## 3. Interface Semantics (.ads Contract)

* **Core Types & State:**
    * `System_Error`: A native Ada exception representing a catastrophic, unrecoverable failure originating from the OS or kernel (e.g., hardware fault, complete memory exhaustion).
    * `System_Error_Code`: An integer type designed to map directly to standard Linux `errno` values.
    * `Exit_Code`: A distinct, strongly typed integer mapping to POSIX system exit statuses.
    * `Exit_Success` / `Exit_Failure`: Static constants representing successful termination (POSIX `0`) and generic failure termination (POSIX `1`).
* **Main Subprograms:**
    * None. This package serves exclusively as a declarative provider of foundational system types.
* **Formal Contracts & Invariants (SPARK):**
    * The package specification MUST be marked with the `pragma Preelaborate` constraint, ensuring safe, deterministic data structure preparation at link-time without initialization side effects.
    * Domain invariants are strictly enforced through strong typing (e.g., preventing `Exit_Code` from being conflated with standard integers). The package provides a pure static baseline and does not ingest or mutate any external state.

## 4. Implementation Guidelines (.adb details)

* **Algorithmic Flow & Models:** Not Applicable. This is a foundational namespace package for system abstractions and must not contain an implementation body (`.adb`).
* **Memory & SPARK Constraints:** Not Applicable for an implementation body. Regarding the specification, all defined types are static scalars or exceptions, strictly complying with the Zero-Allocation constraints.
* **Boundary & Exception Handling:** Not Applicable for an implementation body. However, the `System_Error` declared in the specification serves as the primary boundary abstraction used by child packages (e.g., `MakeOps.Sys.Processes`) to signal unrecoverable OS panics that fall outside the bounds of graceful degradation.