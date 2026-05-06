<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# ARC-004 MakeOps.Tests Namespace Architecture

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `ARC-004` |
| **Status** | `APPROVED` |
| **Date** | 2026-05-02 |
| **Target Namespace** | `MakeOps.Tests` |

## 1. Domain Definition & Purpose

* **Goal:** This domain establishes the empirical verification (dynamic testing) layer of the MakeOps project. While the core architecture relies heavily on formal mathematical proofs (SPARK AoRE), empirical unit testing is mandatory to validate OS-boundary behaviors, C-ABI bindings, and complex state transitions that cannot be statically proven. This domain ensures that testing infrastructure is robust, automated, and strictly separated from production artifacts.
* **Core Responsibility:** Manages the integration of the AUnit testing framework, orchestrates the standalone test runner executable, aggregates individual test suites into a master execution tree, and enforces the physical separation of test code from the production binary.

## 2. Boundaries & Constraints

* **Domain In-Scope:** AUnit test cases, test suites, mock environments, test assertions (`pragma Assert`), and the standalone `test_runner` executable.
* **Domain Out-of-Scope (Strict Bounds):** This namespace MUST NOT be compiled into or linked with the production `mko` binary. Packages within this domain MUST NOT be subjected to strict SPARK verification constraints (`pragma SPARK_Mode (On)` is explicitly disabled here), as testing OS boundaries inherently requires stateful mocks, uncontrolled I/O, and intentional fault injection that violate pure mathematical proofs.

## 3. Traceability & Foundation

* **Implements Requirements:**
    * `REQ-000` (System Constraints):
        * `NFR-000-005`: Enforces the use of the AUnit framework for unit testing and dictates the isolation of the build process via a dedicated GPR configuration.
* **Applies Concepts:**
    * `MOD-009`: Formal Verification & Static Memory Foundations - While SPARK proves the *Absence of Runtime Errors*, this testing domain applies the complementary empirical validation to prove *Functional Correctness* at the unprovable system boundaries (e.g., POSIX interactions).

## 4. Architectural Topology

**Components (Package Blueprints):**

* `MakeOps.Tests` (`DES-004`): The root namespace and main aggregation hub for the project's empirical testing infrastructure. It collects all child unit test scenarios using the AUnit framework and acts as the master `Suite` provider. The design MUST maintain a static instantiation of test cases to safely build the test tree without unnecessary dynamic heap allocation.
* `Test_Runner` (Entry Point): The standalone executable entry point (`test_runner.adb`) that invokes the AUnit text reporter and executes the master suite. It is structurally independent and MUST be compiled exclusively via the dedicated `makeops_tests.gpr` project file to ensure absolute isolation from the production `mko` application.

**Subsystems (Delegated Namespaces):**

* `MakeOps.Tests.*` -> Governed symmetrically by individual `VER-[XXX]` Verification Specifications. To maintain a pragmatic and navigable repository, child test packages (e.g., `MakeOps.Tests.Sys_Processes`) are structured as a flat namespace. Every production package documented in a `DES-[XXX]` document has a corresponding `VER-[XXX]` document that defines its empirical AUnit test scenarios and SPARK proofing strategy.