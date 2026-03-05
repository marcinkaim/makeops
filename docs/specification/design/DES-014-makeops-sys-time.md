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
    * `REQ-003` (Execution Observability: Reporting operation duration).
* **Applies Concepts:**
    * `PLAT-012` (Logging and DX Model: Emitting operation completion times).
    * `ALG-008` (Real-Time I/O Multiplexing Loop: Evaluating the Grace Period deadline).
    * `PLAT-005` (SPARK Formal Verification: Abstracting non-deterministic volatile state).
* **Internal Package Dependencies:** None. This is a foundational subsystem component.

## 3. Interface Semantics (.ads Contract)

* **Core Types & State:**
    * `Timestamp`: A private type representing an absolute point in monotonic time. Hiding the implementation details prevents domain logic from performing unsafe arithmetic directly on the time objects.
    * `Duration_MS`: A strongly typed integer representing a time interval in milliseconds.
* **Main Subprograms:**
    * `Clock`: A parameterless function returning the current `Timestamp`.
    * `Elapsed_Time`: A function accepting a `Start_Time` and an `End_Time` (both `Timestamp`), returning the difference as `Duration_MS`.
    * `Add_Milliseconds`: A function accepting a `Base_Time` (`Timestamp`) and an `Offset` (`Duration_MS`), returning a new `Timestamp`. Used to calculate future deadlines.
    * `Is_Past`: A function accepting a `Deadline` (`Timestamp`) returning `True` if the current clock has surpassed it.
* **Invariants & Contracts (Conceptual):**
    * The package specification (`.ads`) MUST be marked with `pragma SPARK_Mode (On)`.
    * Time calculation functions MUST guarantee Absence of Runtime Errors (AoRE), protecting against integer overflows when dealing with extremely large durations.

## 4. Implementation Guidelines (.adb details)

* **SPARK / Memory Constraints:** No dynamic memory allocation is required.
* **OS / POSIX Interactions:** The package body (`.adb`) MUST be marked with `pragma SPARK_Mode (Off)`. It MUST utilize `Ada.Real_Time` (not `Ada.Calendar`), as `Ada.Real_Time` guarantees monotonic behavior on POSIX systems.
* **Algorithmic Flow:**
    * `Timestamp` is internally aliased to `Ada.Real_Time.Time`.
    * `Elapsed_Time` performs subtraction (`End_Time - Start_Time`) resulting in an `Ada.Real_Time.Time_Span`, which is then converted into integer milliseconds (`Duration_MS`).

## 5. Verification Strategy

* **Static Proof (GNATprove):** The public interface MUST be proven to hide the volatile nature of the real-time clock from the deterministic core logic.
* **AUnit Test Scenarios:**
    * **Happy Path:** Capture `T1 := Clock`, execute a minor busy-loop, capture `T2 := Clock`, and assert that `Elapsed_Time (T1, T2) >= 0`.
    * **Deadline Math:** Assert that `Is_Past (Add_Milliseconds (Clock, 10_000))` returns `False` immediately after invocation.