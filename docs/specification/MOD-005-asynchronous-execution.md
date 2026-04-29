<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# MOD-005 Asynchronous Execution and Multiplexing

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `MOD-005` |
| **Status** | `APPROVED` |
| **Date** | 2026-04-06 |
| **Tags** | POSIX, Executor, Multiplexing, IPC, Event Loop, Sub-Orchestrator |

## 1. Definition & Context
Asynchronous Execution and Multiplexing defines the physical interaction boundary between the MakeOps orchestration engine and the host operating system. It represents the domain of the Executive Sub-Orchestrator (`MakeOps.Core.Project.Operation.Executor`).

In the context of the MakeOps architecture, this model dictates how the statically validated, mathematical `Execution_Queue` (produced by the Resolver in `MOD-004`) is translated into actual running processes. It establishes the rules for spawning POSIX child processes, safely managing Inter-Process Communication (IPC) via anonymous pipes, and streaming their output to the user in real-time without violating memory constraints or risking deadlocks.

## 2. Theoretical Basis
This execution model relies heavily on native POSIX system calls and the mechanics of real-time I/O multiplexing, deliberately avoiding heavy runtime abstractions.

### 2.1. POSIX Process and IPC Lifecycle
Under Linux/POSIX, executing a new program is a two-step mathematical operation:
1. `fork()`: Duplicates the current process, creating a Child.
2. `execvp()`: Replaces the Child's memory space with the target executable.
Before `execvp` is called, the parent must establish Inter-Process Communication (IPC) by creating anonymous pipes (`pipe()`) and binding them to the Child's standard file descriptors (`stdout`, `stderr`) using `dup2()`. 

### 2.2. Real-Time I/O Multiplexing
If a Parent process attempts a blocking read on a Child's `stdout` pipe, and the Child unexpectedly writes only to `stderr`, the Parent will block indefinitely, causing a deadlock. To prevent this, the architecture relies on I/O Multiplexing (specifically the POSIX `poll()` system call). `poll()` allows the Parent to monitor multiple file descriptors simultaneously, unblocking and notifying the Parent exactly when and where data is ready to be read.

## 3. Conceptual Model
The Executor operates as a stateful event loop that processes the linear execution queue one operation at a time, enforcing strict environmental context and managing OS resources.

### 3.1. The Execution Context Heuristic
Before an operation is spawned, the Executor must resolve its physical working directory. Because users can invoke MakeOps from any directory, the Executor applies the Configuration Anchor heuristic:
* The `Project_Config` defines a physical Anchor (the absolute path to the directory containing the `makeops.toml` file).
* The Executor strictly calls `chdir()` to shift the process environment to this Anchor (or a defined relative path from it) immediately prior to invoking `execvp()`, ensuring deterministic execution regardless of where the user typed the `mko` command.

### 3.2. The Event Loop 
For each operation in the `Execution_Queue`, the Executor runs an isolated Event Loop:
1. **Bootstrap:** Create IPC pipes and `fork` the process. The Child executes the command.
2. **Multiplexing Phase:** The Parent enters a loop calling `poll()` on the Child's `stdout` and `stderr` pipes.
3. **Stream Handling:** When `poll()` reports `POLLIN` (data available), the Parent reads the raw bytes into a fixed-size, statically allocated buffer and immediately flushes them to `MakeOps.App.Logger` for formatted terminal rendering.
4. **Status Polling:** In the same loop, the Parent calls `waitpid()` with the `WNOHANG` flag to non-blockingly check if the Child has terminated.
5. **Teardown:** Once the Child terminates and all pipes report `POLLHUP` (hang up), the loop exits, yielding the final POSIX exit code.

### 3.3. Strict Child Coupling (Orphan Prevention)
A common deadlock vector occurs when a Child process spawns a Grandchild process that inherits the `stdout` pipe, but the Child dies while the Grandchild keeps the pipe open. The `poll()` call will never receive a `POLLHUP`. 
To solve this, the Executor enforces Strict Child Coupling. If `waitpid()` confirms the direct Child has died, the Executor immediately ceases reading from the pipes and initiates a teardown, sending a `SIGKILL` to the process group if necessary. This guarantees MakeOps will never hang waiting for a daemonized Grandchild.

## 4. Engineering Impact

* **Constraints:** The implementation MUST use Thin Bindings to the C standard library for `fork`, `execvp`, `pipe`, `poll`, and `waitpid`. It MUST NOT use native Ada Tasking (concurrency) to monitor processes, as OS-level multiplexing guarantees superior determinism and memory safety.
* **Performance/Memory Risks:** To adhere to the Static Memory Model, all pipe reads MUST use bounded, pre-allocated stack arrays (e.g., a 4KB byte bucket). Dynamic string concatenation during stream reading is strictly forbidden to prevent buffer overflows if a misbehaving child process emits infinite data without newlines.
* **Opportunities:** The real-time multiplexing approach ensures that the Developer Experience (DX) feels instantaneous. Logs are streamed to the terminal exactly as they are generated by the underlying operations, allowing developers to see build progress or test results fluidly, rather than waiting for the entire process to finish before seeing output.

## 5. References

**Internal Documentation:**
* [1] [MOD-001: Master Orchestration Lifecycle](./MOD-001-master-orchestration-lifecycle.md)
* [2] [MOD-004: Execution Plan Resolution](./MOD-004-execution-plan-resolution.md)
* [3] [MOD-009: Formal Verification & Static Memory Foundations](./MOD-009-formal-verification-static-memory.md)
* [4] [MOD-016: Observability and Visual Taxonomy Model](./MOD-016-observability-taxonomy.md)

**External Literature:**
* [5] [Linux Programmer's Manual: `poll(2)` - wait for some event on a file descriptor](https://man7.org/linux/man-pages/man2/poll.2.html)
* [6] [Linux Programmer's Manual: `fork(2)` and `execve(2)`](https://man7.org/linux/man-pages/man2/execve.2.html)