<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# ARC-000 MakeOps Namespace Architecture

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `ARC-000` |
| **Status** | `APPROVED` |
| **Date** | 2026-05-01 |
| **Target Namespace** | `MakeOps` |

## 1. Domain Definition & Purpose

* **Goal:** This domain establishes the absolute, state-free foundation and top-level namespace hierarchy for the entire MakeOps software suite. It acts as the architectural anchor point, ensuring that all subsequent domain logic, application interfaces, and operating system boundaries are strictly categorized and insulated from global naming collisions.
* **Core Responsibility:** Physically manages the global project identity (such as Name and Version metadata) and provides the structural routing (via delegated child namespaces) for all other system capabilities.

## 2. Boundaries & Constraints

* **Domain In-Scope:** Static application metadata constants and top-level namespace declarations.
* **Domain Out-of-Scope (Strict Bounds):** This root namespace MUST NOT contain any operational logic, orchestration algorithms, or state-mutating procedures. It MUST NOT interact with the file system, allocate dynamic memory, read CLI arguments, or invoke native POSIX C-ABI bindings.

## 3. Traceability & Foundation

* **Implements Requirements:**
    * `REQ-000` (System Constraints):
        * `NFR-000-001`: Ensures the root package complies with Ada 2022 standards by establishing a clean, purely declarative namespace.
        * `NFR-000-002`: Sets the absolute baseline for formal SPARK verification by enforcing mathematically pure states at the very top of the dependency tree.
* **Applies Concepts:**
    * `MOD-009`: Formal Verification & Static Memory Foundations - Applies the strict `pragma Pure` constraint to the root package to guarantee zero hidden state, enabling seamless Absence of Runtime Errors (AoRE) proofs across all child namespaces.

## 4. Architectural Topology

**Components (Package Blueprints):**

* `MakeOps` (`DES-000`): This is the absolute root namespace and declarative anchor for the entire MakeOps software suite. It securely encapsulates global project identity by exposing static, unchangeable metadata constants such as the application name and release version string. The design MUST strictly enforce the `pragma Pure` constraint to mathematically guarantee to the SPARK prover that the root holds no dynamic state or side effects.

**Subsystems (Delegated Namespaces):**

* `MakeOps.Sys.*` (`ARC-001`): Encapsulates the operating system abstraction layer, isolating the pure core from volatile POSIX hardware and OS interactions.
* `MakeOps.Core.*` (`ARC-002`): Encapsulates the platform-independent core business logic, the domain types, and the generic processing pipelines.
* `MakeOps.App.*` (`ARC-003`): Encapsulates the global application state, the Command Line Interface (CLI) resolution, and the developer experience (observability/logging) mechanics.
* `MakeOps.Tests.*` (`ARC-004`): Encapsulates the empirical testing infrastructure and AUnit test suites, operating outside of SPARK verification constraints.