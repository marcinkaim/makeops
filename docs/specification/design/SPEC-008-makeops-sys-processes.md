<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# SPEC-008 MakeOps.Sys.Processes Package Specification

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `SPEC-008` |
| **Status** | `APPROVED` |
| **Date** | 2026-03-03 |
| **Target Package** | `MakeOps.Sys.Processes` |

## 1. Scope & Responsibility

* **Goal:** Serves as the authoritative, pure-execution, safe adapter for spawning, monitoring, and reaping operating system processes.
* **Responsibility:**
    * Acts as a "Thick Wrapper" around the unsafe `MakeOps.Sys.Processes.OS_Bindings` private child package.
    * Provides strongly-typed, SPARK-safe abstractions for OS concepts like Pipes, Process IDs, and exit statuses.
    * Translates raw POSIX return codes and bitmasks (from `waitpid`, `poll`) into deterministic Ada records.
* **Out of Scope:** This package strictly manages OS-level primitives. It MUST NOT contain the business logic for the execution event loop (`ALG-008`), process timeouts, logging, or variable substitution.

## 2. Traceability & Dependencies

* **Implements Requirements:**
    * `REQ-002` (Operation Orchestration: Pure Execution API).
    * `REQ-003` (Execution Observability: Exposing I/O streams and Exit Codes).
* **Applies Concepts:**
    * `PLAT-001` (Pure Execution: Translating arguments to `execvp` boundaries).
    * `PLAT-002` (Real-Time Log Streaming: Safely exposing `pipe` and `poll`).
    * `PLAT-003` (System Signal Routing: Decoding `waitpid` statuses).
    * `PLAT-009` (IPC Lifecycle: Deterministic FD closure and SIGKILL bindings).
* **Internal Package Dependencies:**
    * `MakeOps.Sys.FS` (to use the `Path_String` type for the executable command).

## 3. Interface Semantics (.ads Contract)

* **Core Types & State:**
    * `Max_Arg_Length`: A static constant (1024) defining the maximum byte length of a single evaluated argument (from `PLAT-006`).
    * `Max_Args_Per_Command`: A static constant (32) defining the maximum number of arguments per execution (from `PLAT-006`).
    * `Arg_String`: A bounded string type (capacity `Max_Arg_Length`) for storing command arguments.
    * `Process_ID`: A strongly typed integer representing the OS process identifier (PID).
    * `File_Descriptor`: A strongly typed integer representing an open OS file descriptor.
    * `Invalid_FD`: A static constant representing an unassigned or closed pipe (e.g., `-1`).
    * `Process_State`: An enumeration (`Running`, `Exited_Normally`, `Killed_By_Signal`, `OS_Error`).
    * `Process_Result`: A discriminated variant record parameterized by `Process_State`. It securely holds the `Exit_Code` if terminated normally, or the `Signal_Number` if killed.
    * `Stream_Result`: A discriminated variant record containing the read status (`Data_Available`, `End_Of_File`, `Empty`) and the bounded string chunk if data was read.
* **Main Subprograms:**
    * `Create_Pipe`: A procedure returning a reading and writing `File_Descriptor` pair (read-end implicitly set to `O_NONBLOCK`).
    * `Close_FD`: A procedure ensuring the safe closure of a file descriptor.
    * `Spawn`: A function executing `fork` and `execvp`, rewiring streams to the provided FDs, and returning the `Process_ID`.
    * `Probe_State`: A function wrapping `waitpid` with `WNOHANG`. It accepts a `Process_ID` and returns a `Process_Result` representing the instantaneous state of the child without blocking.
    * `Poll_Streams`: A function wrapping `poll`. It accepts a list/array of `File_Descriptor`s and a timeout, returning an array of booleans indicating which FDs are ready for reading.
    * `Read_Stream_Chunk`: A procedure wrapping non-blocking `read`. It fetches available data from a `File_Descriptor` into a `Stream_Result`.
    * `Send_Signal`: A procedure wrapping `kill` to send a specific signal (e.g., `SIGKILL`) to a `Process_ID`.
* **Invariants & Contracts (Conceptual):**
    * The package specification (`.ads`) MUST be marked with `pragma SPARK_Mode (On)`. It must safely encapsulate all C-types so the rest of the application remains unaware of the `Interfaces.C` dependencies.

## 4. Implementation Guidelines (.adb details)

* **Implementation Scope:** The package body (`.adb`) MUST be marked with `pragma SPARK_Mode (Off)`.
* **OS / Standard Library Interactions:**
    * This body acts as the sole consumer of the `MakeOps.Sys.Processes.OS_Bindings` private package.
    * Translate Ada bounded strings to C-style null-terminated `char_array` arrays just before passing them to the bindings for `Spawn`.
    * **Important (C ABI Compatibility):** When preparing the arguments array for `execvp`, you MUST construct an array of pointers (`Interfaces.C.Strings.chars_ptr_array`) and explicitly append a `Null_Ptr` as the final element to satisfy the POSIX standard termination requirement.
* **Exception Trapping:**
    * If `pipe` or `fork` returns `-1` (e.g., system out of resources), the package MUST raise `MakeOps.Sys.System_Error` as this constitutes a catastrophic failure.

## 5. Verification Strategy

* **Static Proof (GNATprove):** The public interface MUST be verified to ensure memory safety bounds are respected before parameters cross the internal C ABI boundary.
* **AUnit Test Scenarios:**
    * **Happy Path:** `Spawn` a simple `/bin/sh -c "echo test"` process, `Poll_Streams` to detect output, `Read_Stream_Chunk` to verify the text, and use `Probe_State` to assert it transitions to `Exited_Normally` with code `0`.
    * **Signal Path:** `Spawn` a sleeping process (e.g., `sleep 10`), call `Send_Signal` to kill it, and verify `Probe_State` returns `Killed_By_Signal`.