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
    * `REQ-003` (Execution Observability):
        * `F-003-002`: Defines the visual verbosity levels (logging levels) used to control diagnostic output granularity across the application.
* **Applies Concepts:**
    * `MOD-016` (Observability and Visual Taxonomy Model): Establishes the foundational data types (e.g., `Log_Level` enumeration) required to enforce the "Neutral Happy Path" and route or suppress terminal streams dynamically.
* **Intra-Project Dependencies:**
    * `None`: This package serves as the foundational root for the Application Layer and must not depend on any other packages within the project's namespace.
* **Standard Library Dependencies:**
    * `None`: This package operates entirely on domain types (enumerations) and does not import any standard libraries.

## 3. Interface Semantics (.ads Contract)

* **Core Types & State:**
    * `Log_Level`: An enumeration defining the diagnostic output granularity. Strictly limited to `Error`, `Info`, and `Debug`.
* **Main Subprograms:**
    * None. This package acts exclusively as a declarative provider of application-layer types.
* **Formal Contracts & Invariants (SPARK):**
    * The package specification MUST be marked with the `pragma Preelaborate` constraint. This allows the types and constants to be safely utilized early during the program's elaboration phase, providing more flexibility than `pragma Pure` for future child packages (like `MakeOps.App.Logger`) that may maintain internal state.
    * It maintains no mutable global state. The rigorous domain invariant is enforced natively through the type system—the `Log_Level` enumeration guarantees that the configuration state can only hold one of the strictly assigned values, making mathematically undefined verbosity levels impossible.

## 4. Implementation Guidelines (.adb details)

* **Algorithmic Flow & Models:** Not Applicable. This package acts as a declarative namespace for foundational application types and must not contain an implementation body (`.adb`).
* **Memory & SPARK Constraints:** Not Applicable for an implementation body. Regarding the specification, it guarantees a constant, minimal memory footprint and a complete absence of dynamic heap allocation during runtime.
* **Boundary & Exception Handling:** Not Applicable. The package contains no executable algorithms and crosses no external OS boundaries.