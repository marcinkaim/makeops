<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# DES-010 MakeOps.Sys.Terminal Package Design

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `DES-010` |
| **Status** | `APPROVED` |
| **Date** | 2026-03-04 |
| **Target Package** | `MakeOps.Sys.Terminal` |

## 1. Scope & Responsibility

* **Goal:** Serves as the safe, exception-free OS adapter for terminal standard streams (`stdout` and `stderr`).
* **Responsibility:**
    * Provides a deterministic mechanism to print text to the console.
    * Traps and safely suppresses underlying OS and `Ada.Text_IO` exceptions (such as `Device_Error` when a pipe is broken).
* **Out of Scope:** This package strictly handles raw text output. It MUST NOT contain logic for contextual error rendering (`MOD-017`), nor should it manage ANSI colors, emojis, or log levels (`MOD-016`). Those responsibilities belong to `MakeOps.App.Logging` which will consume this package.

## 2. Traceability & Dependencies

* **Implements Requirements:**
    * `REQ-003` (Execution Observability):
        * `NFR-003-001`: Enforces real-time transparency by flushing standard output and standard error streams directly to the terminal, preventing artificial buffering.
* **Applies Concepts:**
    * `MOD-005` (Asynchronous Execution and Multiplexing): Provides the underlying synchronous stream facades required to emit multiplexed process data.
    * `MOD-010` (Text Encoding and Raw Byte Bucket Model): Accepts standard unconstrained Ada `String` arguments, treating them as raw UTF-8 byte buckets rather than semantic wide characters.
    * `MOD-011` (Isolated OS Boundaries and Exception Handling): Implements the exception isolation pattern by trapping unpredictable `Ada.Text_IO` errors (e.g., broken pipes) to preserve system stability.
    * `MOD-016` (Observability and Visual Taxonomy Model): Exposes the foundational stream routing (`stdout` vs `stderr`) consumed by the higher-level logging and taxonomy engine.
* **Internal Package Dependencies:**
    * None. This is a foundational subsystem component relying exclusively on the standard Ada library (`Ada.Text_IO`).

## 3. Interface Semantics (.ads Contract)

* **Core Types & State:**
    * `Stream_Target`: An enumeration (`Standard_Output`, `Standard_Error`) defining the physical destination stream for the raw text output.
* **Main Subprograms:**
    * `Print`: Writes the provided text to the specified stream without appending a newline character.
    * `Print_Line`: Writes the provided text to the specified stream and appends a newline character.
* **Formal Contracts & Invariants (SPARK):**
    * The package specification MUST be marked with the global `pragma SPARK_Mode (On)` constraint.
    * It mathematically guarantees to the orchestration core the absolute Absence of Runtime Errors (AoRE). The interface strictly acts as a pure consumer of byte buckets and will never leak native I/O exceptions back to the caller, regardless of the physical terminal state.

## 4. Implementation Guidelines (.adb details)

* **Algorithmic Flow & Models:** The implementation acts as an exception-proof router for terminal output, ensuring that all text is immediately visible and that native I/O failures (like closed pipes) degrade silently without halting the orchestrator.
    * `Print`: Must evaluate the `Target` enumeration to route the unappended text via `Ada.Text_IO.Put` to either `Current_Output` or `Current_Error`. To satisfy real-time observability constraints, it must explicitly invoke `Ada.Text_IO.Flush` on the respective stream immediately after writing. The entire operation must be wrapped in a global exception trap (`when others`) that silently ignores any native failures (e.g., `Device_Error`) to preserve the AoRE boundary.
    * `Print_Line`: Must evaluate the `Target` enumeration to route the newline-appended text via `Ada.Text_IO.Put_Line` to the corresponding standard stream. It shares the exact same requirement to immediately invoke `Ada.Text_IO.Flush` and must be equally encapsulated within a silent catch-all exception block.
* **Memory & SPARK Constraints:** The package enforces the Static Memory Model (`MOD-010`). It operates directly on standard unconstrained `String` inputs (Raw Byte Buckets) and guarantees zero dynamic memory allocation (Zero-Allocation) when flushing byte streams to the terminal.
* **Boundary & Exception Handling:** The package body MUST be marked with `pragma SPARK_Mode (Off)`. It MUST wrap all `Ada.Text_IO` interactions in a global exception trap (`when others => null;`). This ensures that if the OS pipe is broken (e.g., `SIGPIPE` context) or the terminal is detached, the resulting `Device_Error` or `Use_Error` is silently degraded, preserving the exception-free boundary contract established in `MOD-011`.