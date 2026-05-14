<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# DES-011 MakeOps.Sys.Signals Package Design

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `DES-011` |
| **Status** | `APPROVED` |
| **Date** | 2026-03-04 |
| **Target Package** | `MakeOps.Sys.Signals` |

## 1. Scope & Responsibility

* **Goal:** Serves as the safe, thread-aware OS adapter for intercepting and routing hardware interrupts and OS signals (e.g., `SIGINT`).
* **Responsibility:**
    * Safely catches termination signals, specifically `SIGINT` (Ctrl+C) and `SIGTERM`, sent to the process group.
    * Provides an atomic, thread-safe mechanism for the core execution loop to check if an operational abort has been requested.
* **Out of Scope:** This package strictly listens for incoming signals. It MUST NOT send signals to other processes (delegated to `MakeOps.Sys.Processes.Send_Signal`). It does not contain the logic for timing out or reaping child processes (`MOD-005`, `MOD-008`).

## 2. Traceability & Dependencies

* **Implements Requirements:**
    * `REQ-002` (Operation Orchestration & Execution):
        * Provides the asynchronous signaling mechanism necessary to halt the execution sequence gracefully upon user interrupt (e.g., via Ctrl+C).
* **Applies Concepts:**
    * `MOD-008` (System Signal Routing): Explains the use of `Ada.Interrupts` and protected objects to safely catch `SIGINT` and `SIGTERM` signals without deadlocking the main execution loop.
    * `MOD-009` (Formal Verification & Static Memory Foundations): Requires deterministic polling of a boolean flag instead of allowing asynchronous hardware mutations to leak into the verified core logic.
* **Internal Package Dependencies:**
    * None. This is a foundational subsystem component relying exclusively on standard Ada libraries (`Ada.Interrupts.Names`).

## 3. Interface Semantics (.ads Contract)

* **Core Types & State:**
    * None. The internal state (the abort flag) is strictly hidden from the public interface to guarantee complete encapsulation.
* **Main Subprograms:**
    * `Abort_Requested`: Returns a boolean indicating whether a termination signal (`SIGINT` or `SIGTERM`) has been caught since the application started. It guarantees an atomic, thread-safe read.
* **Formal Contracts & Invariants (SPARK):**
    * The package specification MUST be marked with the `pragma SPARK_Mode (On)` constraint.
    * The specification MUST include `pragma Unreserve_All_Interrupts` at the library level to grant the application exclusive control over hardware signal handling.
    * The domain invariant mathematically guarantees that checking for aborts is a pure, race-condition-free read operation that does not expose the underlying concurrency primitives (protected objects) to the calling domain.

## 4. Implementation Guidelines (.adb details)

* **Algorithmic Flow & Models:** The implementation encapsulates an internal protected object (e.g., `Signal_Handler`) that intercepts hardware interrupts (`SIGINT`, `SIGTERM`) and asynchronously mutates a private, atomic boolean abort flag.
    * `Abort_Requested`: Must serve as a deterministic, non-blocking getter. It delegates the read operation to the internal protected object, guaranteeing a thread-safe evaluation of the abort flag without exposing the underlying Ada concurrency primitives to the pure orchestration loop.
* **Memory & SPARK Constraints:** The package enforces the Static Memory Model, requiring zero dynamic memory allocation (Zero-Allocation). The single boolean state flag is statically allocated within the protected object.
* **Boundary & Exception Handling:** The package body MUST be marked with `pragma SPARK_Mode (Off)`. Hardware interrupts and native concurrency pragmas inherently break the strict deterministic mathematical models required by GNATprove. This boundary ensures that the unprovable, asynchronous delivery of signals never corrupts the mathematically verified data flow of the orchestrator.