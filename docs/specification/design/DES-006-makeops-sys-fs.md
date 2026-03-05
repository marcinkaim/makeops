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
    * `REQ-004` (Global Tool Preferences: reading `/etc/` and `~/.config/`).
    * `REQ-002` (Operation Orchestration: pre-flight checks before process spawning).
* **Applies Concepts:**
    * `PLAT-004` (Linux Environment and FS Adapters: XDG standard and Graceful Degradation).
    * `PLAT-005` (SPARK Formal Verification: Translating native exceptions to status enums).
    * `PLAT-007` (Execution Context Model: Path Translation Heuristic and Configuration Anchor).
* **Internal Package Dependencies:**
    * `MakeOps.Sys.Env` (to query `$XDG_CONFIG_HOME` and `$HOME` internally for path resolution).

## 3. Interface Semantics (.ads Contract)

* **Core Types & State:**
    * `Max_Command_Length`: A static constant (256) defining the maximum byte length of a file path or executable command (from `PLAT-006`).
    * `Path_String`: A bounded string type (capacity `Max_Command_Length`) for storing file system paths and commands.
    * `FS_Status`: An enumeration (`Success`, `Not_Found`, `Permission_Denied`) representing the deterministic outcome of file system queries.
* **Main Subprograms:**
    * `Check_File_Access`: A function accepting a path (bounded string) and returning `FS_Status`. Used by the Configuration Cascade to safely probe optional preference files.
    * `Is_Executable`: A function accepting a path and returning a `Boolean`. Used by the Master Orchestration Pipeline as a pre-flight check before calling `execvp`.
    * `Resolve_User_Config_Path`: A function returning the absolute path to the user's global `config.toml` by evaluating XDG variables.
    * `Change_Directory`: A function accepting a path (bounded string) and returning `FS_Status`. Used during CLI initialization to set the execution context.
    * `Get_Current_Directory`: A function returning the absolute path (`Path_String`) of the current working directory.
    * `Get_Absolute_Directory_Path`: A function accepting a file path and returning the absolute path (`Path_String`) to its parent directory. Used to establish the Configuration Anchor.
* **Invariants & Contracts (Conceptual):**
    * The package specification (`.ads`) MUST be marked with `pragma SPARK_Mode (On)`. All subprograms must guarantee Absence of Runtime Errors (AoRE) and return deterministic status values.

## 4. Implementation Guidelines (.adb details)

* **Implementation Scope:** The package body (`.adb`) MUST be marked with `pragma SPARK_Mode (Off)`.
* **OS / Standard Library Interactions:**
    * Use `Ada.Directories` to implement `Check_File_Access`. Wrap calls in exception blocks trapping `Name_Error` and `Use_Error`.
    * To implement `Is_Executable`, Ada's standard library may lack direct POSIX execution permission checks. It is acceptable and recommended to use a Thin Binding to the POSIX C function `access(path, X_OK)` to guarantee accurate permission resolution under Linux.
    * To implement `Change_Directory`, use the Thin Binding to the POSIX C function `chdir(path)`. Map the integer return code to `FS_Status`.
    * To implement `Get_Current_Directory` and `Get_Absolute_Directory_Path`, use the Thin Bindings to the POSIX C functions `getcwd` and `realpath` respectively.
* **XDG Resolution Logic:** Query `MakeOps.Sys.Env.Get("XDG_CONFIG_HOME")`. If `Not_Found` or empty, query `HOME` and append `/.config/makeops/config.toml`.

## 5. Verification Strategy

* **Static Proof (GNATprove):** The interface must be fully proven to allow safe consumption by `MakeOps.Core.Pipeline` and `MakeOps.Core.Config.Cascade`.
* **AUnit Test Scenarios:**
    * **Happy Path:** `Resolve_User_Config_Path` correctly builds a path using the injected XDG environment. `Check_File_Access` returns `Success` for a known existing file (e.g., the test executable itself).
    * **Edge Cases:** `Check_File_Access` gracefully returns `Not_Found` for a non-existent file without raising an exception.
    * **Error Paths:** Create a temporary file, remove its execute permissions via OS tools, and assert `Is_Executable` returns `False`.