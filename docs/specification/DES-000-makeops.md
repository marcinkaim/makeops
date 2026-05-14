<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# DES-000 MakeOps Root Package Design

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `DES-000` |
| **Status** | `APPROVED` |
| **Date** | 2026-03-02 |
| **Target Package** | `MakeOps` |

## 1. Scope & Responsibility

* **Goal:** Serves as the absolute root namespace for the entire MakeOps software suite and establishes global project identity.
* **Responsibility:**
    * Defines the top-level namespace hierarchy (`MakeOps.*`) ensuring no naming collisions with other Ada libraries.
    * Provides static metadata about the application (Project Name, Version).
* **Out of Scope:** This package strictly excludes any business logic, state management, orchestration capabilities, or OS interactions.

## 2. Traceability & Dependencies

* **Implements Requirements:**
    * `REQ-000` (System Constraints):
        * `NFR-000-001`: Ensures the root package complies with Ada 2022 standards by establishing a clean, purely declarative namespace.
        * `NFR-000-002`: Sets the absolute baseline for formal SPARK verification by enforcing mathematically pure states at the very top of the dependency tree.
* **Applies Concepts:**
    * `MOD-009` (Formal Verification & Static Memory Foundations): Establishes the absolute purity constraint at the root of the hierarchy to guarantee zero hidden state, enabling seamless Absence of Runtime Errors (AoRE) proofs across all child namespaces.
* **Internal Package Dependencies:**
    * None. This is the absolute root package of the MakeOps architecture and must not depend on any internal units.

## 3. Interface Semantics (.ads Contract)

* **Core Types & State:**
    * `Name`: A static string constant holding the formal name of the software suite (e.g., "MakeOps").
    * `Version`: A static string constant holding the current build or release version.
* **Main Subprograms:**
    * None. This package acts exclusively as a declarative metadata provider.
* **Formal Contracts & Invariants (SPARK):**
    * The package specification MUST be marked with the global `pragma Pure` constraint.
    * It mathematically guarantees to the GNATprove formal verification engine a complete absence of hidden state, side effects, and external data flow dependencies. The domain invariant relies entirely on the absolute immutability of the exposed string constants.

## 4. Implementation Guidelines (.adb details)

* **Algorithmic Flow & Models:** Not Applicable. This package acts as a pure declarative namespace and must not contain an implementation body (`.adb`).
* **Memory & SPARK Constraints:** Not Applicable for an implementation body. Regarding the specification, the static string constants must have a fixed, compile-time length, ensuring they are embedded directly into the static data segment of the compiled binary without any dynamic memory allocation (Zero-Allocation).
* **Boundary & Exception Handling:** Not Applicable. The package contains no executable algorithms and crosses no external OS boundaries.