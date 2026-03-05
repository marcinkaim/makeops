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
* **Out of Scope:** This package strictly listens for incoming signals. It MUST NOT send signals to other processes (delegated to `MakeOps.Sys.Processes.Send_Signal`). It does not contain the logic for timing out or reaping child processes (`ALG-008`).

## 2. Traceability & Dependencies

* **Implements Requirements:**
    * `REQ-002` (Operation Orchestration & Execution: Graceful termination upon user interrupt).
* **Applies Concepts:**
    * `PLAT-003` (System Signal Routing and Exit Codes: Using `Ada.Interrupts` and protected objects).
    * `PLAT-005` (SPARK Formal Verification: Thread-safe data access).
* **Internal Package Dependencies:** None. This is a foundational subsystem component.

## 3. Interface Semantics (.ads Contract)

* **Core Types & State:**
    * None. The internal state (the abort flag) is strictly hidden from the public interface to guarantee encapsulation.
* **Main Subprograms:**
    * `Abort_Requested`: A parameterless function returning a `Boolean`. Returns `True` if a termination signal (such as `SIGINT` or `SIGTERM`) has been caught since the application started, and `False` otherwise.
* **Invariants & Contracts (Conceptual):**
    * The package specification (`.ads`) MUST be marked with `pragma SPARK_Mode (On)`.
    * The `Abort_Requested` function MUST be mathematically proven to be free of race conditions and must provide atomic reads.

## 4. Implementation Guidelines (.adb details)

* **Implementation Scope:** The package body (`.adb`) is required and MUST manage the actual Ada concurrency primitives. It may be marked with `pragma SPARK_Mode (Off)` if the specific `Ada.Interrupts.Names` mappings cause verification issues with GNATprove.
* **Protected Object Architecture:**
    * The body MUST declare a `protected` object (e.g., `Signal_Handler`) to encapsulate a boolean variable (e.g., `Is_Aborted` initialized to `False`).
    * The protected object MUST contain procedure(s) to handle the interrupts (e.g., `Handle_Signal`), attached to the respective POSIX signals using multiple directives: `pragma Attach_Handler (Handle_Signal, Ada.Interrupts.Names.SIGINT)` and `pragma Attach_Handler (Handle_Signal, Ada.Interrupts.Names.SIGTERM)`.
    * When the handler is triggered by the OS, it simply sets `Is_Aborted := True`.
* **Flow Control:** The public `Abort_Requested` function merely calls a protected function inside the `Signal_Handler` to safely read the `Is_Aborted` value, ensuring zero locks or deadlocks during the hot execution loop.

## 5. Verification Strategy

* **Static Proof (GNATprove):** The public interface MUST be verified to ensure that calling `Abort_Requested` has no side effects and safely abstracts the underlying protected object.
* **AUnit Test Scenarios:**
    * **Direct Testing Limitations:** Hardware interrupts are notoriously difficult to test deterministically in standard unit test runners like AUnit without mocking the interrupt controller.
    * **Validation:** Verification of this package is generally deferred to integration testing. However, a dummy routine can be exposed (e.g., `Simulate_Interrupt` available only in the test profile) to trigger the protected object and verify that `Abort_Requested` correctly flips from `False` to `True`.