<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# DES-012 MakeOps.Sys.Identity Package Design

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `DES-012` |
| **Status** | `APPROVED` |
| **Date** | 2026-03-04 |
| **Target Package** | `MakeOps.Sys.Identity` |

## 1. Scope & Responsibility

* **Goal:** Serves as the safe, SPARK-verifiable OS adapter for querying the operating system user identity and security context.
* **Responsibility:**
    * Provides a deterministic mechanism to check if the current process is executing with superuser (root) privileges.
    * Acts as a "Thick Wrapper" around the unsafe `MakeOps.Sys.Identity.OS_Bindings` private child package.
* **Out of Scope:** This package strictly queries the OS state. It MUST NOT contain the business logic for interpreting the `--allow-root` CLI flag, nor should it autonomously abort the application. Halting the execution pipeline is the responsibility of the Master Orchestration Lifecycle (`MOD-001`).

## 2. Traceability & Dependencies

* **Implements Requirements:**
    * `REQ-000` (System Constraints):
        * `F-000-003`: Provides the native OS bindings necessary to query the operating system user identity (`getuid`), fulfilling the foundational security checks.
* **Applies Concepts:**
    * `MOD-007` (Pure Execution OS Boundaries): Implements the "Thick Wrapper" side of the Dual-Layer abstraction pattern, safely encapsulating the raw C ABI binding.
    * `MOD-012` (Execution Context & Security Model): Provides the concrete mechanism to query the OS User ID to detect root execution and prevent Workspace Pollution.
* **Internal Package Dependencies:**
    * `MakeOps.Sys.Identity.OS_Bindings`: Consumed as the private, unsafe thin binding layer to access the native POSIX `getuid` function.

## 3. Interface Semantics (.ads Contract)

* **Core Types & State:**
    * None. This package exposes no internal state or data structures.
* **Main Subprograms:**
    * `Is_Root_User`: Evaluates whether the current process holds superuser (root) privileges. It deterministically returns a boolean flag, guaranteeing the Absence of Runtime Errors (AoRE).
* **Formal Contracts & Invariants (SPARK):**
    * The package specification MUST be marked with the global `pragma SPARK_Mode (On)` constraint.
    * The domain invariant mathematically guarantees that querying the OS user identity resolves to a completely deterministic, side-effect-free boolean state without exposing raw POSIX integer types (such as `uid_t`) to the formally verified orchestration core.

## 4. Implementation Guidelines (.adb details)

* **Algorithmic Flow & Models:** The implementation performs a primitive, deterministic boolean evaluation to establish the security context of the executing process without exposing raw OS types.
    * `Is_Root_User`: Must invoke the native C function `c_getuid` exposed via the `OS_Bindings` child package. It evaluates the returned POSIX User ID (UID); if the value is exactly `0` (which mathematically represents the superuser in POSIX systems), it must return `True`, otherwise it returns `False`.
* **Memory & SPARK Constraints:** The package strictly enforces the Static Memory Model. It requires zero dynamic memory allocation (Zero-Allocation) and relies exclusively on immediate scalar evaluations.
* **Boundary & Exception Handling:** The package body MUST be marked with `pragma SPARK_Mode (Off)`. This isolation boundary safely encapsulates the unprovable, external C ABI call, ensuring that the volatile state of the host operating system cannot invalidate the data flow proofs of the higher-level domain logic.