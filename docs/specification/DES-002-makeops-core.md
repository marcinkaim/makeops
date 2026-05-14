<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# DES-002 MakeOps.Core Package Design

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `DES-002` |
| **Status** | `APPROVED` |
| **Date** | 2026-03-02 |
| **Target Package** | `MakeOps.Core` |

## 1. Scope & Responsibility

* **Goal:** Serves as the root namespace for the core business logic and orchestration engine, defining fundamental, platform-independent domain types.
* **Responsibility:**
    * Defines universal identifiers used for internal calculations and graph node indexing.
    * Defines common status enumerations to enforce a Functional Core style, replacing native exceptions with deterministic return types.
* **Out of Scope:** This package strictly excludes any concrete algorithmic implementations (like DAG resolution), Application/CLI state management, or OS-level interactions.

## 2. Traceability & Dependencies

* **Implements Requirements:**
    * `REQ-000` (System Constraints):
        * `F-000-001`: Provides the foundational pure logic architecture and base types for standard POSIX exit status mappings.
    * `REQ-002` (Operation Orchestration & Execution):
        * `F-002-001`: Defines the fundamental domain types required for identifying and tracking operational targets within the orchestration engine.
* **Applies Concepts:**
    * `MOD-009` (Formal Verification & Static Memory Foundations): Utilizes strong typing and specific integer derivations to enforce algorithmic determinism and replace native Ada exceptions with verifiable return types.
* **Internal Package Dependencies:**
    * None. This is the root namespace of the Core subsystem and depends only on the standard Ada library.

## 3. Interface Semantics (.ads Contract)

* **Core Types & State:**
    * `ID_Type`: A specific bounded integer derivation used as a universal identifier for graph node indexing and internal calculations, preventing accidental mixing with standard integers.
    * `Operation_Result`: An enumeration (`Success`, `Failure`, `Pending`) representing the deterministic outcome of core business logic operations.
* **Main Subprograms:**
    * None. This package serves exclusively as a declarative provider of foundational domain types.
* **Formal Contracts & Invariants (SPARK):**
    * The package specification MUST be marked with the `pragma Pure` constraint.
    * It mathematically guarantees to the SPARK prover a complete absence of hidden state, variables, or side effects. The use of the `Operation_Result` enumeration ensures that undefined operational outcomes are mathematically impossible, satisfying the "Fail-Fast" architectural requirements.

## 4. Implementation Guidelines (.adb details)

* **Algorithmic Flow & Models:** Not Applicable. This package acts as a pure declarative namespace for foundational domain types and must not contain an implementation body (`.adb`).
* **Memory & SPARK Constraints:** Not Applicable for an implementation body. Regarding the specification, it strictly enforces the Static Memory Model by providing type blueprints that do not consume heap memory and guarantee zero dynamic memory allocation at runtime (Zero-Allocation).
* **Boundary & Exception Handling:** Not Applicable. This package establishes the "Functional Core" boundary by defining the types used to isolate higher-level logic from native Ada exceptions.