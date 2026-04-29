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
    * `REQ-000` (System constraints and security).
* **Applies Concepts:**
    * `MOD-007` (Pure Execution OS Boundaries: Thin to Thick wrapper translation).
    * `MOD-012` (Execution Context & Security Model: Preventing Workspace Pollution).
* **Internal Package Dependencies:**
    * `MakeOps.Sys.Identity.OS_Bindings` (private child package containing the C bindings).

## 3. Interface Semantics (.ads Contract)

* **Core Types & State:**
    * None.
* **Main Subprograms:**
    * `Is_Root_User`: A parameterless function returning a `Boolean`. Returns `True` if the OS User ID (UID) is `0`, and `False` otherwise.
* **Invariants & Contracts (Conceptual):**
    * The package specification (`.ads`) MUST be marked with `pragma SPARK_Mode (On)`.
    * The function strictly guarantees Absence of Runtime Errors (AoRE) and must be deterministic from the perspective of the SPARK boundary, treating the external C call as an abstract state input.

## 4. Implementation Guidelines (.adb details)

* **SPARK / Memory Constraints:** The implementation does not require any dynamic memory allocation or string manipulation.
* **OS / POSIX Interactions:** The package body (`.adb`) MUST be marked with `pragma SPARK_Mode (Off)` to safely consume the unprovable C bindings. It must invoke `MakeOps.Sys.Identity.OS_Bindings.c_getuid`.
* **Algorithmic Flow:** The implementation is a trivial boolean evaluation: `return c_getuid = 0;`.

## 5. Verification Strategy

* **Static Proof (GNATprove):** The public interface MUST be fully proven to ensure no unsafe C types or potential runtime exceptions leak into the calling orchestration logic.
* **AUnit Test Scenarios:**
    * **Happy Path:** Calling `Is_Root_User` executes successfully without raising any exceptions. 
    * *Note:* Since the test runner could technically be executed by a standard user or the root user in a CI environment, the exact boolean result (`True` or `False`) cannot be rigidly asserted in a generic test. The test serves as a crash-prevention sanity check for the C ABI boundary.