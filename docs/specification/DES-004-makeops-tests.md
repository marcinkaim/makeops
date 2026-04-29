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
    * `REQ-000` (AC-000-002: All unit tests run successfully and return a passing result).
* **Applies Concepts:**
    * `MOD-009` (Formal Verification & Static Memory Foundations: Unit tests serve as the empirical validation layer, complementing static mathematical proofs).
* **Internal Package Dependencies:** Depends on all `MakeOps.*` packages that require empirical testing.
* **External Dependencies:** The `AUnit` framework.

## 3. Interface Semantics (.ads Contract)

* **Core Types & State:**
    * None.
* **Main Subprograms:**
    * `Suite`: A function returning an `AUnit.Test_Suites.Access_Test_Suite`. This is the master function called by the `test_runner` to obtain the complete tree of all registered unit tests in the project.
* **Invariants & Contracts (Conceptual):**
    * The testing infrastructure is exempt from the `pragma Pure` and strict SPARK AoRE constraints, as it is not part of the production `mko` binary.

## 4. Implementation Guidelines (.adb details)

* **Implementation Scope:** The package body (`.adb`) is responsible for instantiating the master `Test_Suite` object and dynamically adding child suites (e.g., `MakeOps.Tests.Lexer.Suite`) as they are developed.
* **Execution Context:** This package is explicitly executed via `source/tests/test_runner.adb` and compiled using the `makeops_tests.gpr` project file.
* **Compiler Constraints:** Ensure that the test runner is always compiled with assertions enabled (`-gnata`) so that internal `pragma Assert` statements within the tested packages are actively evaluated during the test run.

## 5. Verification Strategy

* **Static Proof (GNATprove):** Not required. SPARK verification is typically disabled or ignored for the AUnit test harnesses.
* **AUnit Test Scenarios:**
    * **Happy Path:** Running the compiled `test_runner` binary (via `make test`) returns an exit code of `0`, confirming that the test suite is properly wired and all registered tests pass.