<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# PLAT-001 Pure Execution and OS Bindings

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `PLAT-001` |
| **Status** | `APPROVED` |
| **Date** | 2026-02-23 |
| **Category** | Platform Model |
| **Tags** | POSIX, Linux, glibc, execvp, fork, binfmt_script, Shebang, Thin Bindings |

## 1. Definition & Context
Pure Execution is the architectural constraint dictating that the MakeOps system must invoke external operations directly via operating system APIs, strictly avoiding the use of intermediate shell environments (like `/bin/sh -c`). 

In the context of the **MakeOps** project, this approach eliminates the risk of shell injection vulnerabilities, guarantees deterministic argument passing without unintended shell expansion (word splitting), and provides absolute control over the execution environment. To achieve this in Ada 2022 without sacrificing performance or control, the system relies on native POSIX bindings to the Linux `glibc` library.

## 2. Theoretical Basis
The platform integration relies on three foundational Linux kernel mechanisms and the C Application Binary Interface (ABI).

### 2.1. POSIX Process Lifecycle (`fork`-`exec`-`wait`)
Direct process execution in Unix-like systems requires a tripartite sequence of system calls:
1. **`fork()`:** Duplicates the current `mko` process, creating a child process with an identical memory space.
2. **`execvp(file, args)`:** Executed exclusively within the child process. It replaces the child's memory space with the new program specified by `file`. The `p` variant instructs the OS to automatically search the directories listed in the `$PATH` environment variable. The `args` array is passed directly to the kernel, completely bypassing shell parsing.
3. **`waitpid()`:** Executed in the parent process to suspend execution until the child process changes state (terminates), allowing the parent to securely harvest the exact exit code.

### 2.2. The Shebang (`#!`) and `binfmt_script`
A common misconception is that a shell is required to execute scripts (e.g., Python or Bash files). In Linux, the kernel module `binfmt_script` natively handles this. When `execvp` attempts to execute a file, the kernel inspects the first two bytes (the "magic numbers"). If it encounters `#!` (hexadecimal `0x23 0x21`), the kernel parses the rest of the first line to identify the interpreter (e.g., `/usr/bin/env python3`), and transparently executes the interpreter while passing the original script as the first argument. This guarantees that MakeOps can execute scripts natively while maintaining "Pure Execution".

### 2.3. Ada to C ABI Integration (Thin Bindings)
To interact with `glibc` without the overhead of heavy abstractions (like `GNAT.OS_Lib`), Ada 2022 utilizes Thin Bindings. By employing the `Interfaces.C` package and compiler directives such as `pragma Import (C, Execvp, "execvp");`, the Ada compiler generates direct calls to the C Application Binary Interface (ABI). This provides zero-overhead interoperability, allowing the system to harness raw POSIX power while wrapping the unsafe C calls in a strongly-typed, SPARK-verifiable Ada API.

## 3. Engineering Impact

* **Constraints:** The system MUST NOT use high-level abstractions like `GNAT.OS_Lib.Spawn` if they obscure standard stream (`stdout`/`stderr`) manipulation or process ID tracking. Instead, all POSIX interactions MUST be encapsulated within a dedicated `MakeOps.Sys.Processes` child package, hiding the raw C bindings behind a safe Ada contract.
* **Performance Risks:** Minimal. Direct `execvp` invocations are the most performant method of spawning processes in Linux, completely bypassing the latency of loading and initializing a `/bin/sh` interpreter.
* **Opportunities:** Thin bindings give us absolute control over file descriptors. This is critical for meeting execution observability requirements, as it allows the parent process to directly pipe and multiplex the child's `stdout` and `stderr` streams for real-time output. Any OS-level failures during `fork` or `exec` will explicitly raise a mapped `System_Error`.

## 4. References

**Internal Documentation:**
* [1] [REQ-002: Operation Orchestration & Execution](../design/REQ-002-operation-orchestration.md)
* [2] [REQ-003: Execution Observability](../design/REQ-003-execution-observability.md)

**External Literature:**
* [3] Kerrisk, M. (2010). *The Linux Programming Interface*. No Starch Press. (Chapter 24: Process Creation, Chapter 27: Program Execution).