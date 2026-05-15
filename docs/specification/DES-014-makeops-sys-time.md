<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# DES-014 MakeOps.Sys.Time Package Design

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `DES-014` |
| **Status** | `APPROVED` |
| **Date** | 2026-03-04 |
| **Target Package** | `MakeOps.Sys.Time` |

## 1. Scope & Responsibility

* **Goal:** Serves as the safe, SPARK-friendly OS adapter for monotonic time and duration measurements.
* **Responsibility:**
    * Provides access to a strictly monotonic clock, immune to system time adjustments (e.g., NTP syncs).
    * Calculates elapsed execution time (durations) in deterministic integer units (e.g., milliseconds) for observability and loop timeouts.
* **Out of Scope:** This package strictly measures monotonic time intervals. It MUST NOT format dates into human-readable strings (e.g., "YYYY-MM-DD HH:MM:SS"), it MUST NOT provide thread-blocking/sleeping capabilities (like `delay`), and it MUST NOT use the calendar clock.

## 2. Traceability & Dependencies

* **Implements Requirements:**
    * `REQ-003` (Execution Observability):
        * `F-003-003`: Provides the mechanism to measure the exact execution duration of operations for reporting and performance metrics.
    * `REQ-002` (Operation Orchestration & Execution):
        * `F-002-007`: Provides the foundational monotonic timing primitives required to mathematically calculate deadlines and implement timeout-driven, non-blocking polling loops.
* **Applies Concepts:**
    * `MOD-005` (Asynchronous Execution and Multiplexing): Supplies the monotonic clock and duration calculations necessary for timeout-driven multiplexing.
    * `MOD-009` (Formal Verification & Static Memory Foundations): Enforces the use of strongly typed 64-bit integers (`Duration_MS`) and private opaque records to replace unsafe floating-point time calculations.
    * `MOD-011` (Isolated OS Boundaries and Exception Handling): Identifies the hardware clock as a volatile system input that must be isolated from the pure mathematical logic of the core.
* **Intra-Project Dependencies:**
    * `None`: This foundational OS Facade for monotonic time operations operates independently and does not depend on any other packages within the project's namespace.
* **Standard Library Dependencies:**
    * `Ada.Real_Time`: Utilized privately in the specification and exclusively within the body to query the host's monotonic hardware clock (`Clock`) and calculate precise time spans. The private import ensures that the broader MakeOps domain remains strictly agnostic to the underlying OS time representation, preserving architectural purity.

## 3. Interface Semantics (.ads Contract)

* **Core Types & State:**
    * `Duration_MS`: A strongly typed 64-bit integer (`Long_Long_Integer`) representing a time interval in milliseconds, designed to prevent overflow during long uptimes.
    * `Timestamp`: A private, opaque record type representing an absolute point in monotonic time. By hiding its internal structure, the package prevents domain logic from performing direct, unverified arithmetic on time objects.
* **Main Subprograms:**
    * `Clock`: Returns the current point in monotonic time. This clock is strictly immune to NTP adjustments or system time jumps.
    * `Elapsed_Time`: Calculates the duration between two `Timestamp` objects, returning a deterministic integer value in milliseconds.
    * `Add_Milliseconds`: Calculates a future or past `Timestamp` by adding a `Duration_MS` offset to a base point.
    * `Is_Past`: A boolean predicate that evaluates whether the system's monotonic clock has surpassed a specific deadline.
* **Formal Contracts & Invariants (SPARK):**
    * The package specification MUST be marked with the global `pragma SPARK_Mode (On)` constraint.
    * It mathematically guarantees to the core orchestrator that all time-related operations (elapsed calculations and deadline checks) are side-effect-free and yield deterministic results. The private nature of the `Timestamp` ensures that time-domain invariants cannot be violated by external packages.

## 4. Implementation Guidelines (.adb details)

* **Algorithmic Flow & Models:** The implementation acts as a safe translation layer over the native `Ada.Real_Time` package. It strictly converts complex native span types and fixed-point durations into deterministic 64-bit integer milliseconds, eliminating the risk of floating-point inaccuracies and arithmetic overflows in the higher-level orchestration logic.
    * `Clock`: Must invoke `Ada.Real_Time.Clock` and securely wrap the result inside the opaque `Timestamp` record.
    * `Elapsed_Time`: Must calculate the difference between two timestamps using native `Time_Span` arithmetic. It then safely converts the result to a standard `Duration` (seconds) and scales it up to a 64-bit integer (`Duration_MS`) representing exact milliseconds.
    * `Add_Milliseconds`: Must convert the 64-bit integer offset back into a standard `Duration` (by dividing by 1_000.0) before transforming it into a `Time_Span` for safe addition. This specific sequence prevents arithmetic overflow when manipulating extremely large bounds.
    * `Is_Past`: Must perform a direct, instantaneous relational comparison (`>`) between the current `Ada.Real_Time.Clock` and the internal time of the provided deadline.
* **Memory & SPARK Constraints:** The package strictly enforces the Static Memory Model (Zero-Allocation). All time objects and duration scalars are managed on the stack, and no dynamic memory allocation is permitted during clock interrogation or duration arithmetic.
* **Boundary & Exception Handling:** The package body MUST be marked with `pragma SPARK_Mode (Off)`. This is necessary because `Ada.Real_Time.Clock` reads from the volatile hardware state of the operating system, which is inherently non-deterministic from the perspective of GNATprove. By isolating this volatility within the body, the package provides a stable, verifiable interface for the rest of the system.