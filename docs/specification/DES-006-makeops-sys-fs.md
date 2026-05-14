<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# DES-006 MakeOps.Sys.FS Package Design

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `DES-006` |
| **Status** | `APPROVED` |
| **Date** | 2026-03-03 |
| **Target Package** | `MakeOps.Sys.FS` |

## 1. Scope & Responsibility

* **Goal:** Serves as the safe, exception-free OS adapter for file system interactions and path resolution.
* **Responsibility:**
    * Provides mechanism to query file existence and accessibility without raising native Ada exceptions.
    * Resolves standard Linux user configuration paths adhering to the XDG Base Directory Specification.
    * Exposes a "Pre-flight Executability Check" to mathematically verify if a resolved binary path has POSIX execution (`+x`) permissions.
    * Safely changes the current working directory of the process to support the `--workdir` CLI flag.
    * Retrieves the current working directory (CWD).
    * Resolves the absolute directory path of a given file to establish the Configuration Anchor.
* **Out of Scope:** This package strictly queries metadata, resolves paths, and manages the working directory context. It MUST NOT parse file contents (delegated to Lexers) nor execute the files (delegated to `MakeOps.Sys.Processes`).

## 2. Traceability & Dependencies

* **Implements Requirements:**
    * `REQ-002` (Operation Orchestration & Execution):
        * `F-002-006`: Requires pre-flight executability checks to ensure target binaries possess adequate permissions before attempting process spawning.
    * `REQ-004` (Global Tool Preferences):
        * `F-004-007`: Demands safe, non-crashing existence checks for optional preference files during the Configuration Cascade.
* **Applies Concepts:**
    * `MOD-011` (Isolated OS Boundaries and Exception Handling): Dictates the translation of unpredictable POSIX/Ada filesystem errors into deterministic variant types to support Graceful Degradation.
    * `MOD-012` (Execution Context & Security Model): Establishes the requirement for managing the Current Working Directory (CWD) and resolving the Configuration Anchor via absolute paths.
    * `MOD-009` (Formal Verification & Static Memory Foundations): Requires that all path data passed through the OS boundary adheres strictly to the statically bounded `Path_String` constraints.
* **Internal Package Dependencies:**
    * `MakeOps.Sys.FS.OS_Bindings`: Provides the unsafe C ABI thin bindings to POSIX filesystem functions (`access`, `chdir`, `getcwd`, `realpath`).
    * `Ada.Directories`: Utilized exclusively for pure string manipulation (extracting containing directories) without invoking native I/O exceptions.

## 3. Interface Semantics (.ads Contract)

* **Core Types & State:**
    * `FS_Status`: An enumeration (`Success`, `Not_Found`, `Permission_Denied`) representing the deterministic outcome of file system existence and accessibility queries.
* **Main Subprograms:**
    * `Check_File_Access`: Safely probes a path for physical existence and read permissions, supporting the fallback mechanism for optional configuration files.
    * `Is_Executable`: Performs a mathematical pre-flight check to verify if a resolved binary path possesses POSIX execution (`+x`) permissions.
    * `Change_Directory`: Safely shifts the process's working directory to establish the Execution Context.
    * `Get_Current_Directory`: Retrieves the absolute path of the environment's current working directory.
    * `Get_Absolute_Directory_Path`: Resolves symlinks and translates a given file path into its absolute containing directory, establishing the Configuration Anchor.
* **Formal Contracts & Invariants (SPARK):**
    * The package specification MUST be marked with the global `pragma SPARK_Mode (On)` constraint.
    * It mathematically guarantees to the orchestration core that interacting with the volatile host filesystem will never raise a native Ada exception. Unpredictable environmental states are fully encapsulated within the deterministic `FS_Status` and boolean return types.

## 4. Implementation Guidelines (.adb details)

* **Algorithmic Flow & Models:** The implementation relies on underlying POSIX thin bindings rather than native Ada I/O libraries to guarantee precise Linux permission resolution. It must actively manage memory allocation and deallocation (`New_String`, `Free`) across the C ABI boundary for every operation.
    * `Check_File_Access`: Must sequentially invoke the POSIX `c_access` binding. It first uses the `F_OK` mask to strictly verify physical existence (returning `Not_Found` if missing), followed by the `R_OK` mask to verify read permissions (returning `Success` or `Permission_Denied`).
    * `Is_Executable`: Must invoke the POSIX `c_access` binding strictly using the `X_OK` mask, mapping the integer result directly to a deterministic boolean value (degrading to `False` on any failure).
    * `Change_Directory`: Must invoke the POSIX `c_chdir` binding to shift the process environment, mapping a successful execution to `Success` and safely degrading any other OS error to a generic `Not_Found` status.
    * `Get_Current_Directory`: Must pre-allocate a fixed-size C-string buffer (bounded by `Max_Command_Length`) before invoking `c_getcwd`. It must safely evaluate the returned pointer, converting valid data back into an Ada bounded string and yielding an empty bounded string if the OS returns a null pointer.
    * `Get_Absolute_Directory_Path`: Must invoke `c_realpath` to natively resolve symlinks into a pre-allocated C-string buffer. Once the absolute file path is securely retrieved from the OS, it must utilize `Ada.Directories.Containing_Directory` solely for its safe string-manipulation capabilities to extract and return the parent directory path.
* **Memory & SPARK Constraints:** The package enforces the Static Memory Model (`MOD-009`) by returning only bounded `Path_String` structures. When interacting with the C ABI, the implementation MUST actively manage memory boundaries by allocating `chars_ptr` objects (`New_String`), passing them to the OS, and explicitly invoking `Free` immediately after use to mathematically prevent memory leaks at the Ada-to-C boundary.
* **Boundary & Exception Handling:** The package body MUST be marked with `pragma SPARK_Mode (Off)`. To enforce the Absence of Runtime Errors (AoRE) defined in `MOD-011`, all subprograms MUST wrap their native string translations and C-ABI calls in global exception traps (`when others`). Any failure during path resolution or OS querying must degrade gracefully into deterministic fallback states (e.g., returning `Not_Found`, `False`, or an empty `Null_Bounded_String`).