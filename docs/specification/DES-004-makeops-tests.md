<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# DES-004 MakeOps.Tests Package Design

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `DES-004` |
| **Status** | `APPROVED` |
| **Date** | 2026-03-02 |
| **Target Package** | `MakeOps.Tests` |

## 1. Scope & Responsibility

* **Goal:** Serves as the root namespace and main aggregation point for the AUnit test suite.
* **Responsibility:**
    * Defines the master test suite that collects and registers all unit test scenarios across the project.
    * Provides the entry point for the standalone `test_runner` executable.
* **Out of Scope:** This package strictly contains testing infrastructure and test cases. It MUST NOT contain any production business logic or orchestration algorithms.

## 2. Traceability & Dependencies

* **Implements Requirements:**
    * `REQ-000` (System Constraints):
        * `NFR-000-005`: Enforces the use of the AUnit framework for unit testing and dictates the isolation of the build process via a dedicated GPR configuration.
* **Applies Concepts:**
    * `MOD-009` (Formal Verification & Static Memory Foundations): Clarifies that while the core system targets AoRE, the testing infrastructure itself operates outside strict formal proof boundaries to enable robust empirical validation.
* **Internal Package Dependencies:**
    * `MakeOps.Tests.Base` through `MakeOps.Tests.Sys_File_Stream`: Imports child unit test packages in order to aggregate their individual test cases into the master execution suite.

## 3. Interface Semantics (.ads Contract)

* **Core Types & State:**
    * None. This package serves exclusively as a declarative namespace and entry point for the testing suite.
* **Main Subprograms:**
    * `Suite`: Instantiates and returns the master `AUnit.Test_Suites.Access_Test_Suite` containing all registered unit tests for the MakeOps project.
* **Formal Contracts & Invariants (SPARK):**
    * This package is explicitly excluded from the SPARK formal verification boundary. It does not enforce `pragma Pure` or `pragma Preelaborate`, as it serves as an aggregation point for the AUnit framework, which inherently requires dynamic state management and object-oriented dispatching.

## 4. Implementation Guidelines (.adb details)

* **Algorithmic Flow & Models:** The implementation serves as the central registration hub for the empirical testing framework, utilizing a single, linear initialization sequence.
    * `Suite`: Instantiates the root AUnit test suite object. It must sequentially aggregate and register the test cases from all imported child packages (e.g., `Base`, `Sys_Env`, `Sys_FS`) by appending their statically allocated access pointers to the master suite builder.
* **Memory & SPARK Constraints:** While the testing infrastructure is exempt from the strict system-wide Zero-Allocation constraints, it still minimizes heap usage where possible. Individual test cases MUST be statically instantiated as `aliased` variables at the package body level. Dynamic memory allocation (using the `new` keyword) is strictly limited to the creation of the root `Test_Suite` object itself to satisfy AUnit framework architectural requirements.
* **Boundary & Exception Handling:** Not Applicable. The package operates entirely within the isolated AUnit test execution context and does not interact directly with native OS boundaries or perform exception translation.