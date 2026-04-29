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
    * `REQ-003` (Execution Observability): Outputting streams to the user.
* **Applies Concepts:**
    * `MOD-005` (Asynchronous Execution and Multiplexing): Stream Handling.
    * `MOD-009` (Formal Verification & Static Memory Foundations): Translating native exceptions.
    * `MOD-010` (Text Encoding and Raw Byte Bucket Model): The Raw Byte Bucket Paradigm.
    * `MOD-011` (Isolated OS Boundaries and Exception Handling): Exception Isolation.
    * `MOD-016` (Observability and Visual Taxonomy Model): Emitting raw streams.
* **Internal Package Dependencies:** None. This is a foundational subsystem component relying only on the standard Ada library.

## 3. Interface Semantics (.ads Contract)

* **Core Types & State:**
    * `Stream_Target`: An enumeration (`Standard_Output`, `Standard_Error`) defining the destination stream for the output.
* **Main Subprograms:**
    * `Print`: A procedure accepting a standard `String` and a `Stream_Target`. Writes the text without appending a newline character.
    * `Print_Line`: A procedure accepting a standard `String` and a `Stream_Target`. Writes the text and appends a newline character.
* **Invariants & Contracts (Conceptual):**
    * The package specification (`.ads`) MUST be marked with `pragma SPARK_Mode (On)`.
    * The subprograms MUST guarantee Absence of Runtime Errors (AoRE). They must never propagate exceptions, even if the underlying OS terminal is detached or the output pipe is closed (`SIGPIPE` context).

## 4. Implementation Guidelines (.adb details)

* **SPARK / Memory Constraints:** The interface accepts standard unconstrained Ada `String` types (Raw Byte Buckets). No dynamic allocation is needed to pass these strings to `Ada.Text_IO`.
* **OS / POSIX Interactions:** The package body (`.adb`) MUST be marked with `pragma SPARK_Mode (Off)`. It must use `Ada.Text_IO` (or `Ada.Streams`) to perform the actual writing.
* **Automatic Flushing:** To guarantee the real-time stream observability required by `MOD-005` and `MOD-016`, every invocation of `Print` and `Print_Line` MUST implicitly call `Ada.Text_IO.Flush` on the target stream immediately after writing the text. This prevents output from hanging in Ada's internal buffers when a child process emits text without a newline.
* **Exception Trapping:** All calls to `Ada.Text_IO.Put`, `Ada.Text_IO.Put_Line`, and `Ada.Text_IO.Flush` MUST be wrapped in an `exception when others => null;` block (or specifically trap `Ada.Text_IO.Device_Error` and `Ada.Text_IO.Use_Error`). If writing to the terminal fails at the OS level, the application cannot reliably report it anyway, so silent degradation is the mathematically safe fallback.

## 5. Verification Strategy

* **Static Proof (GNATprove):** The public interface MUST be verified to ensure it introduces no state violations or exceptions into the calling components.
* **AUnit Test Scenarios:**
    * **Happy Path:** Calling `Print_Line` with `Standard_Output` and `Standard_Error` executes successfully without crashing the test runner.
    * *Note:* Due to the nature of terminal output, AUnit tests for this package are primarily sanity checks for exception suppression rather than content validation.