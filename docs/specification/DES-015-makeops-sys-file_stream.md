<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# DES-015 MakeOps.Sys.File_Stream Package Design

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `DES-015` |
| **Status** | `APPROVED` |
| **Date** | 2026-03-05 |
| **Target Package** | `MakeOps.Sys.File_Stream` |

## 1. Scope & Responsibility

* **Goal:** Serves as the safe, exception-free OS adapter for reading text files line-by-line.
* **Responsibility:**
    * Provides a deterministic mechanism to open, read, and safely close file streams.
    * Reads raw bytes line-by-line into strictly bounded string buffers.
    * Traps and translates underlying `Ada.Text_IO` exceptions (such as `End_Error` or `Name_Error`) into safe variant records.
* **Out of Scope:** This package strictly handles sequential file I/O operations. It MUST NOT parse TOML syntax or evaluate the semantics of the text (delegated to `MakeOps.Core.Lexer`). It also MUST NOT perform filesystem metadata checks like executing permissions (delegated to `MakeOps.Sys.FS`).

## 2. Traceability & Dependencies

* **Implements Requirements:**
    * `REQ-001` (Project Configuration):
        * `NFR-001-002`: Requires the safe, sequential ingestion of configuration files (`makeops.toml`) without loading the entire file into dynamically allocated memory.
* **Applies Concepts:**
    * `MOD-009` (Formal Verification & Static Memory Foundations): Dictates the use of strongly bounded buffers (8192 bytes) and variant records to ensure reading from files never triggers a heap allocation or buffer overflow.
    * `MOD-010` (Text Encoding and Raw Byte Bucket Model): Treats the incoming file data as raw, unconstrained byte buckets rather than semantic wide characters.
    * `MOD-011` (Isolated OS Boundaries and Exception Handling): Establishes the exception isolation pattern, translating unpredictable POSIX I/O errors into deterministic `Stream_Status` enumerations.
* **Internal Package Dependencies:**
    * `MakeOps.Sys.FS`: Utilized conceptually for the `Path_String` type required to locate the file to be opened.

## 3. Interface Semantics (.ads Contract)

* **Core Types & State:**
    * `Max_Line_Length`: A static constant (8192 bytes) establishing the absolute maximum memory bound for a single configuration line.
    * `Line_String`: A bounded string explicitly adhering to the `Max_Line_Length` limit.
    * `Stream_Status`: An enumeration (`Success`, `End_Of_File`, `I_O_Error`) representing the deterministic outcome of the file operation.
    * `Read_Result`: A discriminated variant record. It safely encapsulates the `Line_String` only when the status is `Success`, mathematically guaranteeing that consumers cannot access uninitialized memory on EOF or IO errors.
    * `File_Handle`: A limited private type. It entirely hides the underlying `Ada.Text_IO.File_Type` to prevent the formally verified domain logic from interacting with the unprovable native OS state.
* **Main Subprograms:**
    * `Open_File`: Attempts to open the physical file for reading, returning a deterministic status rather than an exception.
    * `Get_Next_Line`: Reads sequential text from the open handle up to the bounded limit.
    * `Close_File`: Safely releases the OS file descriptor.
* **Formal Contracts & Invariants (SPARK):**
    * The package specification MUST be marked with the global `pragma SPARK_Mode (On)` constraint.
    * It guarantees the absolute Absence of Runtime Errors (AoRE) to its callers. By hiding the `File_Type` in a limited private record, it mathematically enforces that file handles cannot be copied or maliciously mutated outside of this package's control.

## 4. Implementation Guidelines (.adb details)

* **Algorithmic Flow & Models:** The implementation serves as a memory-bounded, exception-free facade over standard Ada file I/O. It rigorously tracks internal state to prevent resource leaks and translates all native exceptions into deterministic variant records to uphold the Absence of Runtime Errors (AoRE) boundary.
    * `Open_File`: Must implement a Fail-Fast check to immediately return an `I_O_Error` if the provided handle is already marked as open, preventing descriptor leaks. It invokes `Ada.Text_IO.Open` and must trap all native exceptions (`Name_Error`, `Use_Error`), degrading gracefully to an error status without halting execution.
    * `Get_Next_Line`: Must fail-fast if the handle is closed or if `Ada.Text_IO.End_Of_File` is true. It reads data into a statically bounded string buffer using `Ada.Text_IO.Get_Line`. Critically, if the read data exactly fills the maximum buffer length, it must proactively invoke `Ada.Text_IO.Skip_Line` (if not at EOF) to flush any unread remainder of the truncated line, preventing byte-offset misalignment during subsequent read operations.
    * `Close_File`: Must perform an idempotent closure. It attempts to invoke `Ada.Text_IO.Close` only if the internal flag indicates the file is open. Regardless of whether the native OS operation succeeds or raises an exception (which must be trapped), it must deterministically reset the internal state flag to `False` to prevent reuse of the stale handle.
* **Memory & SPARK Constraints:** The package enforces the Static Memory Model (`MOD-009`). All string reads are pulled directly into fixed-size stack arrays without utilizing the `new` keyword or unbounded standard libraries.
* **Boundary & Exception Handling:** The package body MUST be marked with `pragma SPARK_Mode (Off)`. It wraps every `Ada.Text_IO` operation in a defensive block. `Name_Error` and `Use_Error` during opening are translated to `I_O_Error`. Unpredictable `End_Error` exceptions during reading are smoothly caught and degraded into the `End_Of_File` status variant, completely isolating the core parsing engine from Ada's native exception propagation.