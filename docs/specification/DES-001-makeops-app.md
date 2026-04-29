<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# DES-001 MakeOps.App Package Design

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `DES-001` |
| **Status** | `APPROVED` |
| **Date** | 2026-03-02 |
| **Target Package** | `MakeOps.App` |

## 1. Scope & Responsibility

* **Goal:** Serves as the root namespace for the Application Layer and defines foundational types representing the global application state and user interface configuration.
* **Responsibility:**
    * Defines the visual verbosity levels (logging levels) used across the application.
* **Out of Scope:** This package strictly defines types and constants. It does not contain the logic for the CLI parser (`MakeOps.App.CLI`) nor the implementation of the logging mechanisms (`MakeOps.App.Logging`).

## 2. Traceability & Dependencies

* **Implements Requirements:**
    * `REQ-003` (F-003-002: Execution observability and logging levels).
* **Applies Concepts:**
    * `MOD-016` (Observability and Visual Taxonomy Model).
* **Internal Package Dependencies:** None. This is the foundation of the App subsystem.

## 3. Interface Semantics (.ads Contract)

* **Core Types & State:**
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
    * **Happy Path:** A trivial sanity test ensuring that the `Log_Level` enumeration is ordered correctly (e.g., `Error < Info` and `Info < Debug`) to support relational comparisons in logging and output filtering logic.