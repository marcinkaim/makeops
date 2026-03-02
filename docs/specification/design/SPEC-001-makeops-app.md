<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# SPEC-001 MakeOps.App Package Specification

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `SPEC-001` |
| **Status** | `APPROVED` |
| **Date** | 2026-03-02 |
| **Target Package** | `MakeOps.App` |

## 1. Scope & Responsibility

* **Goal:** Serves as the root namespace for the Application Layer and defines foundational types and constants representing the global application state and OS interface boundaries.
* **Responsibility:**
    * Defines standard POSIX exit codes to be returned to the operating system upon termination.
    * Defines the visual verbosity levels (logging levels) used across the application.
* **Out of Scope:** This package strictly defines types and constants. It does not contain the logic for the CLI parser (`MakeOps.App.CLI`) nor the implementation of the logging mechanisms (`MakeOps.App.Logging`).

## 2. Traceability & Dependencies

* **Implements Requirements:**
    * `REQ-000` (F-000-001: Standard POSIX exit codes).
    * `REQ-003` (F-003-002, F-003-004: Execution observability, logging levels, and exit status).
* **Applies Concepts:**
    * `PLAT-003` (System Signal Routing and Exit Codes).
    * `PLAT-012` (Logging and DX Model).
* **Internal Package Dependencies:** None. This is the foundation of the App subsystem.

## 3. Interface Semantics (.ads Contract)

* **Core Types & State:**
    * `Exit_Code`: A distinct integer type mapping to POSIX system exit statuses.
    * `Exit_Success`: A static constant representing successful termination (POSIX `0`).
    * `Exit_Failure`: A static constant representing generic failure termination (POSIX `1`).
    * `Log_Level`: An enumeration defining the diagnostic output granularity. Strictly limited to `Error`, `Info`, and `Debug`.
* **Main Subprograms:**
    * None.
* **Invariants & Contracts (Conceptual):**
    * The package MUST be marked with `pragma Preelaborate`. This allows the types and constants to be used early during the program's elaboration phase, while offering more flexibility than `pragma Pure` for future child packages (like `MakeOps.App.Logging`) that may need to maintain internal state or perform I/O.

## 4. Implementation Guidelines (.adb details)

* **Implementation Scope:** A package body (`.adb` file) is strictly NOT required and MUST NOT be created. The specifications in the `.ads` file are entirely sufficient for defining these static types and constants.

## 5. Verification Strategy

* **Static Proof (GNATprove):** Automatically proven. The declarations contain no complex logic or dynamic bounds, satisfying Absence of Runtime Errors (AoRE).
* **AUnit Test Scenarios:**
    * **Happy Path:** A trivial sanity test ensuring that `Exit_Success` equals `0` and `Exit_Failure` does not equal `0`, preserving POSIX compliance.