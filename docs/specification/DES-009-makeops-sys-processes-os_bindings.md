<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# DES-009 MakeOps.Sys.Processes.OS_Bindings Package Design

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `DES-009` |
| **Status** | `APPROVED` |
| **Date** | 2026-03-03 |
| **Target Package** | `MakeOps.Sys.Processes.OS_Bindings` |

## 1. Scope & Responsibility

* **Goal:** Serves as the raw, unsafe Thin Binding layer to the Linux kernel and `glibc` strictly for process and IPC lifecycle management.
* **Responsibility:**
    * Maps POSIX C data types (e.g., `int`, `char**`, `struct pollfd`) to Ada equivalents using `Interfaces.C`.
    * Imports native C functions via `pragma Import` (e.g., `fork`, `execvp`, `pipe`, `poll`, `waitpid`).
* **Out of Scope:** This package strictly excludes any business logic, error handling, or exception translation. It is completely unaware of the MakeOps domain. File system bindings (like `access`) are excluded and belong to `MakeOps.Sys.FS.OS_Bindings` (if created).

## 2. Traceability & Dependencies

* **Implements Requirements:**
    * `REQ-002` (Operation Orchestration & Execution):
        * `NFR-002-001`: Provides the Pure Execution OS bindings necessary to execute binaries directly via native POSIX `execvp` and `fork` system calls.
* **Applies Concepts:**
    * `MOD-005` (Asynchronous Execution and Multiplexing): Supplies the POSIX `poll` and `read` system call definitions required for real-time I/O multiplexing.
    * `MOD-006` (POSIX IPC and Stream Routing): Provides the `pipe`, `dup2`, and `fcntl` definitions used to establish and rewire non-blocking anonymous pipes.
    * `MOD-007` (Pure Execution OS Boundaries): Defines the requirement for unsafe thin bindings mapping directly to the Linux C ABI.
    * `MOD-008` (System Signal Routing): Provides `waitpid` and `kill` bindings for asynchronous process state monitoring and forced termination.
* **Internal Package Dependencies:**
    * None. This package serves as a foundational OS adapter relying exclusively on standard Ada C-interoperability libraries (`Interfaces.C`, `Interfaces.C.Strings`, `System`).

## 3. Interface Semantics (.ads Contract)

* **Core Types & State:**
    * `ssize_t` / `pid_t`: Native POSIX integer types mapped via `Interfaces.C`.
    * `Pipe_Descriptors`: A mapped array type (`array (0 .. 1) of aliased Interfaces.C.int`) strictly adhering to the C convention, used to securely retrieve the read and write file descriptors from the `pipe` system call.
    * `struct_pollfd`: A native memory-mapped Ada record utilizing `pragma Convention (C)`, matching the exact memory layout of the POSIX `pollfd` structure to enable direct array passing to the `poll` kernel function.
* **Main Subprograms:**
    * `c_pipe`: A thin binding to the POSIX `pipe` function. Returns `0` on success or `-1` on error, populating the `Pipe_Descriptors` out-parameter.
    * `c_fork`: A thin binding to the POSIX `fork` function. Returns the child's PID to the parent, `0` to the child, or `-1` on error.
    * `c_execvp`: A thin binding to the POSIX `execvp` function. Accepts a `chars_ptr` for the file and a raw `System.Address` for the `argv` pointer array to satisfy C-ABI memory boundaries.
    * `c_dup2`, `c_fcntl`: Thin bindings for file descriptor manipulation and rewiring.
    * `c_poll`, `c_read`: Thin bindings for non-blocking stream I/O multiplexing.
    * `c_waitpid`, `c_kill`: Thin bindings for querying and altering child process states.
    * `c_close`: A thin binding to safely release kernel file descriptors.
* **Formal Contracts & Invariants (SPARK):**
    * The package specification MUST be marked with the `pragma SPARK_Mode (Off)` constraint. As a thin binding layer directly exposing the Linux C ABI, its side effects and memory semantics are fundamentally unprovable by GNATprove.
    * The package MUST be declared as a `private package` (i.e., `private package MakeOps.Sys.Processes.OS_Bindings`). This strict boundary isolation mathematically prevents any higher-level domain code from accidentally invoking unsafe C functions, restricting its consumption exclusively to its parent thick wrapper.

## 4. Implementation Guidelines (.adb details)

* **Algorithmic Flow & Models:** Not Applicable. This package acts as a purely declarative thin binding layer utilizing `pragma Import (C, ...)` to link external kernel functions. It must not contain an implementation body (`.adb`).
* **Memory & SPARK Constraints:** Not Applicable for an implementation body. Regarding the specification, it natively passes raw C pointers (`chars_ptr`), explicit memory addresses (`System.Address`), and relies on `pragma Convention (C)` for complex types. The strict lifecycle management and memory safety of these elements (especially the null-termination of the `argv` array) are completely delegated to the parent wrapper.
* **Boundary & Exception Handling:** Not Applicable for an implementation body. This package does not trap exceptions or translate error codes. Native POSIX errors (signaled via `-1` integer returns or similar mechanisms) must be caught, evaluated, and deterministically degraded by the parent thick wrapper (`MakeOps.Sys.Processes`).