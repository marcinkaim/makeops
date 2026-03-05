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
    * `REQ-000` (Foundational pure logic architecture).
    * `REQ-002` (Operation Orchestration base data types).
* **Applies Concepts:**
    * `PLAT-005` (SPARK Formal Verification: Algorithmic Exceptions vs. Deterministic Implementation).
    * `PLAT-006` (Static Memory Model: Strong typing via specific integer derivations).
* **Internal Package Dependencies:** None. This is the foundation of the Core subsystem and depends only on the standard Ada library.

## 3. Interface Semantics (.ads Contract)

* **Core Types & State:**
    * `ID_Type`: A specific bounded integer derivation (`new Integer`). Enforces strong typing to prevent accidental mixing with standard integers when handling graph vertices and internal counters.
    * `Operation_Result`: An enumeration (`Success`, `Failure`, `Pending`) representing the deterministic outcome of core operations. It is critical for the "Fail-Fast" architecture, avoiding the use of `Ada.Exceptions` for standard control flow.
* **Main Subprograms:**
    * None.
* **Invariants & Contracts (Conceptual):**
    * The package MUST be marked with `pragma Pure`. This guarantees to the compiler and the SPARK prover that the package contains no hidden state, making it completely deterministic and safe for concurrent elaboration if needed.

## 4. Implementation Guidelines (.adb details)

* **Implementation Scope:** A package body (`.adb` file) is strictly NOT required and MUST NOT be created. The specifications in the `.ads` file are entirely sufficient for defining these foundational types.

## 5. Verification Strategy

* **Static Proof (GNATprove):** Automatically proven. The `pragma Pure` directive combined with static type declarations natively satisfies SPARK's Absence of Runtime Errors (AoRE) requirement.
* **AUnit Test Scenarios:**
    * **Happy Path:** A trivial sanity test ensuring the `Operation_Result` values are distinct and properly ordered if relied upon in generic evaluations.