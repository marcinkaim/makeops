<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# PLAT-002 Real-Time Log Streaming and I/O Multiplexing

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `PLAT-002` |
| **Status** | `APPROVED` |
| **Date** | 2026-02-23 |
| **Category** | Platform Model |
| **Tags** | Observability, POSIX, I/O Multiplexing, Non-Blocking, Pipes, stdout, stderr |

## 1. Definition & Context
Process Observability is a critical requirement dictating that the MakeOps system must stream the standard output (`stdout`) and standard error (`stderr`) of spawned child processes in real-time to the user's terminal. 

In the context of the **MakeOps** project, capturing these streams cannot be done using simple, blocking `read()` calls, as doing so introduces the risk of process deadlocks (e.g., the parent blocks waiting for `stdout` while the child is blocked trying to write a critical error to a full `stderr` buffer). To ensure safe, real-time observability without hanging, the platform architecture mandates the use of non-blocking I/O and event-driven multiplexing.

## 2. Theoretical Basis
The real-time streaming architecture is built upon four native POSIX Inter-Process Communication (IPC) mechanisms.

### 2.1. Anonymous Pipes and Stream Redirection (`pipe` & `dup2`)
Before invoking `fork()`, MakeOps prepares unidirectional data channels using the `pipe()` system call. To optimize I/O and prevent resource waste (as required by the Error log level), the creation of these pipes is conditional:
* **Normal/Debug Mode:** MakeOps creates two pipes (for `stdout` and `stderr`). Inside the spawned child process (prior to calling `execvp`), the `dup2()` system call redirects the child's FD 1 (stdout) and FD 2 (stderr) into the writing ends of these pipes.
* **Error Mode (Quiet):** MakeOps creates a pipe exclusively for `stderr`. For `stdout`, it opens `/dev/null` and uses `dup2()` to redirect the child's FD 1 directly to this bit bucket. The parent process never creates or polls a `stdout` pipe, completely eliminating unnecessary I/O reads for suppressed logs.

### 2.2. Non-Blocking I/O (`fcntl` with `O_NONBLOCK`)
By default, reading from a pipe is a blocking operation. If MakeOps attempts to read from a child's `stdout` pipe and the pipe is empty, the kernel will put the MakeOps thread to sleep. To prevent this, MakeOps uses the `fcntl()` (file control) function to set the `O_NONBLOCK` flag on the reading ends of both pipes. If a read is attempted on an empty non-blocking pipe, the kernel immediately returns an `EAGAIN` error rather than suspending the process.

### 2.3. I/O Multiplexing (`poll` / `select`)
To efficiently monitor both streams without multi-threading or busy-waiting (spinning), MakeOps employs the POSIX `poll()` (or `select()`) system call. `poll()` allows the MakeOps process to instruct the kernel: *"Suspend my execution until there is data available to read on either the `stdout` pipe OR the `stderr` pipe, or until a specified timeout expires."* While `poll` efficiently monitors the pipes, it cannot definitively detect child termination if orphaned grandchildren keep the pipes open. Therefore, it is paired with asynchronous `waitpid` probing (detailed in `PLAT-009`). This event-driven approach guarantees minimal CPU waste while waiting.

### 2.4. The Buffering Compromise
Because MakeOps uses standard pipes rather than Pseudo-Terminals (PTYs), the child process's internal C library (`libc`) may default to Block Buffering instead of Line Buffering. MakeOps accepts this behavior as a standard POSIX tradeoff to maintain strict, physical separation between the `stdout` and `stderr` streams (PTYs merge them). MakeOps guarantees that it will instantly multiplex and display any data block the moment the child's `libc` flushes it to the pipe.

## 3. Engineering Impact

* **Constraints:** The `MakeOps.Sys.Processes` package MUST encapsulate the `pipe`, `dup2`, `fcntl`, `poll`, and `read` C functions via Thin Bindings. The main execution loop MUST use `poll` to multiplex the file descriptors; it MUST NOT use blocking reads.
* **Performance Risks:** None. `poll` is a highly optimized kernel-level event listener. 
* **Opportunities:** Because MakeOps intercepts the streams programmatically, it gains the opportunity to inject metadata before printing to the user's terminal (e.g., prepending `[build-dev]` to every line). Additionally, `stderr` lines can be automatically color-coded red to instantly alert the user of failures, greatly enhancing Developer Experience (DX).

## 4. References

**Internal Documentation:**
* [1] [REQ-003: Execution Observability](../design/REQ-003-execution-observability.md)
* [2] [PLAT-001: Pure Execution and OS Bindings](./PLAT-001-pure-execution-posix.md)
* [3] [PLAT-009: IPC Lifecycle and Process Management](./PLAT-009-ipc-lifecycle-management.md)
* [4] [ALG-008: Real-Time I/O Multiplexing Loop](./ALG-008-io-multiplexing-loop.md)