<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# MOD-006 POSIX IPC and Stream Routing

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `MOD-006` |
| **Status** | `APPROVED` |
| **Date** | 2026-04-06 |
| **Tags** | POSIX, IPC, Pipes, SIGPIPE, File Descriptors, Deadlock, Streams |

## 1. Definition & Context
POSIX IPC and Stream Routing defines the low-level operating system mechanics required to safely execute and monitor child processes within the MakeOps architecture.

While the Asynchronous Execution and Multiplexing model (`MOD-005`) defines the logical event loop and control flow, this document establishes the physical "laws of physics" governing Inter-Process Communication (IPC) under Linux. It formalizes how MakeOps manages anonymous pipes, avoids deadlocks caused by orphaned background processes, and ensures non-blocking, real-time log streaming without violating memory constraints.

## 2. Theoretical Basis
This model is built upon strict POSIX standard behaviors regarding file descriptors, non-blocking I/O, and kernel-level signal generation.

### 2.1. File Descriptor Inheritance and Anonymous Pipes
When a process invokes `fork()`, the operating system duplicates all open File Descriptors (FDs). By creating unidirectional anonymous pipes (`pipe()`) before forking, and using `dup2()` within the child process to redirect its Standard Output (FD 1) and Standard Error (FD 2) into the write-ends of those pipes, MakeOps establishes a direct communication channel. Crucially, any grandchildren spawned by the child will also inherently inherit these write-ends.

### 2.2. Non-Blocking I/O and EAGAIN
By default, reading from a pipe is a blocking operation. If MakeOps attempts to read from an empty pipe, the kernel suspends the thread. To enable event-driven multiplexing, the read-ends of the pipes MUST be flagged with `O_NONBLOCK` via the `fcntl()` system call. When a read is attempted on an empty non-blocking pipe, the kernel immediately returns an `EAGAIN` error, allowing the orchestrator's event loop to continue executing.

### 2.3. The SIGPIPE Kernel Signal
If a process attempts to write to a pipe where all read-ends have been closed by the reading process, the POSIX kernel immediately sends a `SIGPIPE` signal to the writing process. By default, this signal terminates the process.

### 2.4. Block Buffering vs. Line Buffering
Because MakeOps uses standard anonymous pipes rather than Pseudo-Terminals (PTYs), the internal C library (`libc`) of the child process will typically default to Block Buffering instead of Line Buffering. MakeOps accepts this behavior as a necessary compromise to maintain strict physical separation between `stdout` and `stderr` streams, guaranteeing that data is multiplexed exactly when `libc` flushes the block.

## 3. Conceptual Model
MakeOps enforces a strict resource lifecycle and coupling strategy to manage IPC safely and efficiently.

### 3.1. Conditional Pipe Routing (I/O Optimization)
To optimize resource usage and prevent unnecessary kernel context switches, pipe creation is conditionally based on the active `Log_Level`:
* **Normal/Debug Mode:** MakeOps creates two pipes (for both `stdout` and `stderr`).
* **Error Mode (Quiet):** MakeOps creates a pipe exclusively for `stderr`. For `stdout`, it opens `/dev/null` and redirects the child's FD 1 directly to this bit bucket. The parent process never creates or polls a `stdout` pipe, physically eliminating unnecessary I/O for suppressed logs.

### 3.2. Strict Child Coupling and Deadlock Prevention
If MakeOps relied solely on the End-Of-File (EOF) state from `poll()` to determine when a task is finished, a background daemon spawned by the task (a grandchild) holding the pipe open would cause MakeOps to deadlock indefinitely.
To prevent this, the architecture mandates Strict Child Coupling:
1. MakeOps anchors its execution loop strictly to the direct child's state using asynchronous probes (`waitpid` with `WNOHANG`).
2. Once `waitpid` confirms the direct child has terminated, MakeOps performs one final non-blocking flush of the pipes.
3. MakeOps explicitly and immediately closes its read-ends of the pipes (`close(fd)`).

### 3.3. The Detachment Contract
Because MakeOps deliberately closes the read-ends of its pipes upon the direct child's termination, any surviving background processes (grandchildren) that subsequently attempt to write to `stdout` or `stderr` will instantly receive a `SIGPIPE` from the kernel and die. 
This establishes the **Detachment Contract**: If a user intends to launch a background daemon (e.g., a web server or database) that outlives the MakeOps orchestration, their scripts MUST explicitly redirect the daemon's standard streams (e.g., `command > /dev/null 2>&1 &`).

## 4. Engineering Impact

* **Constraints:** The `MakeOps.Sys.Processes.OS_Bindings` package MUST provide Thin Bindings to `pipe`, `dup2`, `fcntl`, and `close`. The execution engine MUST strictly adhere to the Strict Child Coupling sequence (Wait $\to$ Flush $\to$ Close). The Detachment Contract MUST be clearly documented in the user-facing manual.
* **Performance Risks:** Minimal. By suppressing the `stdout` pipe entirely during Error-level logging, the system actively saves CPU cycles and avoids filling internal buffers with discarded data.
* **Opportunities:** The Detachment Contract acts as a strict enforcement of POSIX Environment Hygiene. It prevents CI/CD pipelines from hanging due to poorly written user scripts that accidentally leak noisy background processes.

## 5. References

**Internal Documentation:**
* [1] [MOD-005: Asynchronous Execution and Multiplexing](./MOD-005-asynchronous-execution.md)
* [2] [MOD-009: Formal Verification & Static Memory Foundations](./MOD-009-formal-verification-static-memory.md)

**External Literature:**
* [3] [Linux Programmer's Manual: `pipe(7)` - overview of pipes and FIFOs](https://man7.org/linux/man-pages/man7/pipe.7.html)
* [4] [Linux Programmer's Manual: `fcntl(2)` - manipulate file descriptor (O_NONBLOCK)](https://man7.org/linux/man-pages/man2/fcntl.2.html)