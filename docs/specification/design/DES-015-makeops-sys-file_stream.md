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
    * `REQ-001` (Project Configuration Handling: streaming the `makeops.toml` file).
    * `REQ-004` (Global Tool Preferences: streaming `/etc/` and `~/.config/` configurations).
* **Applies Concepts:**
    * `PLAT-004` (Isolated OS Boundaries: Exception Isolation and Graceful Degradation).
    * `PLAT-006` (Static Memory Model: Bounded strings for file lines).
    * `PLAT-011` (Text Encoding Model: Processing files as Raw Byte Buckets).
    * `ALG-004` (Event-Driven TOML Lexer: Line-by-Line Stream Processing).
    * `ALG-010` (Contextual Error Rendering: Re-reading the file to extract a specific line).
* **Internal Package Dependencies:**
    * `MakeOps.Sys` (for baseline operational types).
    * `MakeOps.Sys.FS` (for `Path_String` usage when opening files).

## 3. Interface Semantics (.ads Contract)

* **Core Types & State:**
    * `File_Handle`: A limited private type safely encapsulating the internal `Ada.Text_IO.File_Type`. Hiding this prevents the core logic from interacting directly with native I/O streams.
    * `Max_Line_Length`: A static constant (e.g., `8192`) defining the maximum byte length of a single line parsed from configuration files.
    * `Line_String`: A bounded string type (capacity `Max_Line_Length`) representing a raw, UTF-8 line buffer.
    * `Stream_Status`: An enumeration (`Success`, `End_Of_File`, `I_O_Error`) representing the deterministic outcome of I/O operations.
    * `Read_Result`: A discriminated variant record parameterized by `Stream_Status`. If `Success`, it contains the `Line_String`. If `End_Of_File` or `I_O_Error`, it contains no string data.
* **Main Subprograms:**
    * `Open_File`: A procedure accepting a path and an out-parameter for the `File_Handle`. Returns a `Stream_Status` indicating if the file was successfully opened.
    * `Get_Next_Line`: A function accepting a `File_Handle` and returning a `Read_Result`. It reads the stream until a newline character is encountered.
    * `Close_File`: A procedure accepting a `File_Handle` that safely closes the file.
* **Invariants & Contracts (Conceptual):**
    * The package specification (`.ads`) MUST be marked with `pragma SPARK_Mode (On)`.
    * The subprograms MUST guarantee Absence of Runtime Errors (AoRE). They must never propagate native exceptions.
    * The caller must guarantee that `Close_File` is always invoked if `Open_File` returned `Success`, even in abort scenarios (e.g., inside `ALG-010`).

## 4. Implementation Guidelines (.adb details)

* **SPARK / Memory Constraints:** The package must avoid unbounded strings entirely. Use `Ada.Strings.Bounded` to construct the `Line_String`. If `Ada.Text_IO.Get_Line` encounters a line exceeding `Max_Line_Length`, the function must truncate the reading or flush the remainder of the line to prevent buffer overflows, safely returning the truncated data or raising a controlled `I_O_Error`.
* **OS / POSIX Interactions:** The package body (`.adb`) MUST be marked with `pragma SPARK_Mode (Off)`. It is the sole component utilizing `Ada.Text_IO` for file reads.
* **Algorithmic Flow:** All calls to `Ada.Text_IO.Open`, `Get_Line`, and `Close` must be wrapped in `begin ... exception when others => ... end` blocks. Specifically, `End_Error` must map cleanly to `End_Of_File`, while `Name_Error` and `Use_Error` map to `I_O_Error`.

## 5. Verification Strategy

* **Static Proof (GNATprove):** The public interface MUST be verified to ensure it introduces no native Ada exceptions into the calling core parsers, guaranteeing safe, deterministic data flow records (`Read_Result`).
* **AUnit Test Scenarios:**
    * **Happy Path:** `Open_File` an existing temporary test file, successfully invoke `Get_Next_Line` to retrieve the contents, and verify `Close_File` executes without issues.
    * **Edge Cases:** Calling `Get_Next_Line` on an empty file immediately returns a `Read_Result` with `End_Of_File` status instead of throwing an exception.
    * **Error Paths:** Calling `Open_File` on a non-existent path gracefully returns `I_O_Error`.