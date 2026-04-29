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
    * `REQ-000` (Serves as the foundational unit for the system architecture).
* **Applies Concepts:**
    * `MOD-009` (Strict adherence to SPARK constraints via package purity).
* **Internal Package Dependencies:** None. This is the root package; it must not depend on any other unit.

## 3. Interface Semantics (.ads Contract)

* **Core Types & State:**
    * `Name`: A static string constant holding the formal name of the software ("MakeOps").
    * `Version`: A static string constant holding the current build/release version (e.g., "0.1.0-alpha").
* **Main Subprograms:**
    * None.
* **Invariants & Contracts (Conceptual):**
    * The package MUST be marked with `pragma Pure`. This guarantees to the compiler and the SPARK prover that the package contains no hidden state, no variables, and safely allows universal elaboration across all child subsystems.

## 4. Implementation Guidelines (.adb details)

* **Implementation Scope:** A package body (`.adb` file) is strictly NOT required and MUST NOT be created. The specifications in the `.ads` file are entirely sufficient for static constants.

## 5. Verification Strategy

* **Static Proof (GNATprove):** Automatically proven. The `pragma Pure` directive natively satisfies SPARK's Absence of Runtime Errors (AoRE) requirement for this unit.
* **AUnit Test Scenarios:**
    * **Happy Path:** A trivial test in the suite ensuring that the `Version` string length is greater than 0, preventing accidental releases with empty version metadata.