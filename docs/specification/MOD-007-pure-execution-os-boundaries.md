<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# MOD-007 Pure Execution OS Boundaries

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `MOD-007` |
| **Status** | `APPROVED` |
| **Date** | 2026-04-06 |
| **Tags** | POSIX, Linux, glibc, execvp, fork, Shebang, Thin Bindings, C ABI |

## 1. Definition & Context
Pure Execution OS Boundaries define the architectural interface between the MakeOps orchestration engine (written in Ada/SPARK) and the underlying Linux operating system kernel.

In the context of the **MakeOps** project, invoking external operations must be completely deterministic and secure. The system strictly forbids the use of intermediate shell environments (e.g., `/bin/sh -c "command"`). Bypassing the shell eliminates the risk of shell injection vulnerabilities, prevents unpredictable word-splitting on arguments, and grants the orchestrator absolute control over the process lifecycle. This document models how MakeOps achieves this "Pure Execution" by binding directly to the C Application Binary Interface (ABI).

## 2. Theoretical Basis
The execution model relies on native POSIX system calls, kernel-level script interpretation, and cross-language ABI compatibility.

### 2.1. POSIX Process Lifecycle (`fork` and `execvp`)
Direct process execution in Unix-like systems is not a single atomic action; it requires a tripartite sequence:
1. **`fork()`:** Duplicates the current process, creating a Child with an identical memory space.
2. **`execvp(file, args)`:** Executed exclusively within the Child process. It halts the current program and replaces the Child's memory space with the new binary specified by `file`. The `p` variant instructs the OS to automatically resolve the binary's location using the directories listed in the `$PATH` environment variable. The `args` array is passed directly to the kernel, circumventing shell parsers entirely.
3. **`waitpid()`:** Suspends the Parent process (or is polled asynchronously) until the Child terminates, allowing the OS to release the process table entry and return the exit status.

### 2.2. The Shebang (`#!`) and `binfmt_script`
A common misconception is that a shell wrapper is required to execute scripts (e.g., Python or Bash files). In Linux, the kernel module `binfmt_script` handles this natively. When `execvp` attempts to execute a text file, the kernel inspects the first two bytes (the "magic numbers"). If it reads `#!` (hexadecimal `0x23 0x21`), it parses the rest of the first line to identify the interpreter (e.g., `/usr/bin/env python3`). The kernel then transparently executes that interpreter, passing the original script as its first argument.

### 2.3. The C Application Binary Interface (ABI)
Operating system APIs in Linux are exposed via the C standard library (`glibc`). Interacting with them from Ada requires memory layout compatibility. Ada provides standard mechanisms (like `Interfaces.C`) to define types that mathematically match the memory footprint of C types (e.g., matching a C `int` or a `char*`), enabling zero-overhead cross-language function calls.

## 3. Conceptual Model
To safely integrate unsafe POSIX calls into a SPARK-verified environment, MakeOps utilizes a dual-layer abstraction pattern: The Thin Binding and the Thick Wrapper.

### 3.1. The Thin Binding Layer (Private & Unsafe)
The lowest layer (`MakeOps.Sys.Processes.OS_Bindings`) is a private package mapping directly to the C ABI.
* **Mechanism:** It uses `pragma Import (C, ...)` to instruct the linker to bind Ada subprogram declarations directly to the `glibc` symbols (e.g., importing `execvp`).
* **Constraint:** Because C functions cannot be mathematically proven by GNATprove to be free of side-effects or memory violations, this entire layer is explicitly marked with `pragma SPARK_Mode (Off)`. It acts strictly as a "dumb pipe" to the OS.

### 3.2. The Thick Wrapper Layer (Public & Safe)
The public-facing layer (`MakeOps.Sys.Processes`) acts as the SPARK-compliant facade.
* **Mechanism:** It defines subprograms using strict Ada types (e.g., bounded strings and strong `ID_Type` integers). It validates all inputs before translating them into C-compatible types and calling the Thin Binding.
* **C-Array Null Termination Rule:** When preparing the `args` array for `execvp`, the Thick Wrapper is responsible for converting Ada strings into an array of C pointers (`chars_ptr_array`). To satisfy the POSIX standard, the wrapper MUST explicitly append a `Null_Ptr` as the final element of this array to prevent the kernel from reading out of bounds.

### 3.3. Shell Rejection Heuristic
Because Pure Execution explicitly bypasses `/bin/sh`, shell-specific operators (like `|` for pipes, `>` for redirection, or `&&` for chaining) embedded in a configuration's `cmd` or `args` will NOT be evaluated by the OS; they will be passed as literal text arguments to the binary. 
If a user requires complex shell routing, they MUST encapsulate that logic within a standalone `.sh` script file and instruct MakeOps to execute that file, thereby delegating the shell logic to the `binfmt_script` kernel interpreter.

## 4. Engineering Impact

* **Constraints:**
    * The system MUST NOT use high-level, opaque abstractions (like `GNAT.OS_Lib.Spawn`) if they obscure standard stream manipulation or Process ID (PID) tracking. 
    * All raw POSIX interactions MUST be isolated within the `MakeOps.Sys` subsystem. The core orchestration loop (`MOD-001`) MUST remain entirely unaware of C types or ABI translations.
* **Performance Risks:** Minimal. Direct `execvp` invocations are the most performant method of spawning processes in Linux, completely bypassing the latency of loading and initializing a shell interpreter for every spawned task.
* **Opportunities:** Maintaining absolute control over the `fork` and `exec` sequence allows MakeOps to seamlessly integrate the anonymous pipes defined in the POSIX IPC model (`MOD-006`). By holding the raw file descriptors between the `fork` and `exec` stages, MakeOps can precisely wire the child's streams without relying on external wrappers.

## 5. References

**Internal Documentation:**
* [1] [MOD-005: Asynchronous Execution and Multiplexing](./MOD-005-asynchronous-execution.md)
* [2] [MOD-006: POSIX IPC and Stream Routing](./MOD-006-posix-ipc-stream-routing.md)
* [3] [MOD-008: System Signal Routing and Termination](./MOD-008-system-signal-routing.md)
* [4] [MOD-009: Formal Verification & Static Memory Foundations](./MOD-009-formal-verification-static-memory.md)

**External Literature:**
* [5] [System V Application Binary Interface (C ABI) - AMD64 Architecture Processor Supplement](https://gitlab.com/x86-psABIs/x86-64-ABI)
* [6] [Linux kernel documentation: `binfmt_script` (Shebang execution)](https://docs.kernel.org/admin-guide/binfmt-misc.html)