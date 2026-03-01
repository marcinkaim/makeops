<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# PLAT-009 IPC Lifecycle and Process Management

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `PLAT-009` |
| **Status** | `APPROVED` |
| **Date** | 2026-02-25 |
| **Category** | Platform Model |
| **Tags** | IPC, Deadlock, POSIX, waitpid, poll, pipes, orphans, SIGPIPE |

## 1. Definition & Context
The IPC Lifecycle and Process Management model defines the precise sequence of operations required to safely manage anonymous pipes connecting the MakeOps orchestrator to its spawned child processes. 

In the context of the **MakeOps** project, a naive implementation of standard output/error streaming (relying solely on waiting for the End-Of-File [EOF] signal from a pipe) introduces a severe risk of infinite deadlocks. If a spawned operation (e.g., a Bash script) spawns its own background tasks (grandchildren of MakeOps) and terminates, those background tasks inherit the open pipe descriptors. This document establishes the "Strict Child Coupling" strategy to prevent the orchestrator from hanging indefinitely while waiting for these orphaned processes.

## 2. Theoretical Basis
The model is built upon three foundational POSIX principles regarding file descriptor inheritance, non-blocking process state observation, and kernel-level signal generation.

### 2.1. File Descriptor Inheritance and IPC Deadlocks
When a process invokes `fork()`, the operating system duplicates all open File Descriptors (FDs). If MakeOps creates a pipe and `forks` a child, the child inherits the write-end of that pipe. If that child subsequently forks its own background process (a grandchild), the grandchild also inherits this write-end. 
The POSIX `poll()` system call monitoring the read-end of the pipe within MakeOps will only return an EOF state when **all** write-ends across **all** processes are closed. If a grandchild is designed to run indefinitely (e.g., a web server started via `npm run start &`), the pipe remains open, and the MakeOps `poll()` loop deadlocks, despite the primary target operation having successfully completed.

### 2.2. Asynchronous State Polling (`waitpid` with `WNOHANG`)
To decouple the orchestrator from the unpredictable behavior of grandchild processes, the execution loop must anchor its termination condition to the lifecycle of the *direct* child process, not the state of the pipe. 
Alongside multiplexing the pipes with `poll()`, the MakeOps execution loop invokes `waitpid(Child_PID, &status, WNOHANG)`. The `WNOHANG` flag instructs the kernel to return immediately (asynchronously). 
* If it returns `0`, the direct child is still running.
* If it returns the `Child_PID`, the direct child has terminated.

### 2.3. Deliberate Pipe Closure and `SIGPIPE`
Once `waitpid` confirms the direct child has terminated, MakeOps performs one final non-blocking read to flush any remaining data from the pipes. Immediately after, MakeOps explicitly closes its read-ends of the pipes (`close(fd)`). 
According to POSIX standards, if an orphaned grandchild subsequently attempts to write to a pipe where the read-end has been closed, the kernel will immediately send a `SIGPIPE` signal to the grandchild, which by default terminates it. This ensures MakeOps does not artificially keep background processes alive if they are actively trying to stream logs to a closed session.

### 2.4. The Detachment Contract and Background Daemons
Because MakeOps intentionally closes the read-ends of its pipes upon the direct child's termination, any background processes (grandchildren) that attempt to write to `stdout` or `stderr` will receive a `SIGPIPE` and be terminated by the OS. 
This is not a flaw, but a strict architectural enforcement of POSIX Environment Hygiene. If a user intends for a background process to outlive the MakeOps orchestration (e.g., launching a detached database or web server), the user's operational scripts MUST explicitly redirect the background process's standard streams (e.g., `command > /dev/null 2>&1 &`). By enforcing this, MakeOps ensures that out-of-band processes do not silently corrupt the terminal state or block IPC resources.

## 3. Engineering Impact

* **Constraints:**
    * The main execution loop in `MakeOps.Sys.Processes` MUST NOT rely on EOF from `poll()` as the sole exit condition. The loop MUST incorporate `waitpid` with the `WNOHANG` flag to actively probe the direct child's status. Upon child termination, the system MUST perform a final buffer flush before explicitly closing the file descriptors.
    * The documentation (e.g., User Manual) MUST clearly state that background tasks spawned by MakeOps operations will be killed by `SIGPIPE` if they log to standard output without being explicitly redirected to a file or `/dev/null`.
* **Performance Risks:** Minimal. Invoking `waitpid(WNOHANG)` inside a `poll()`-driven event loop introduces a microscopic overhead (a fast non-blocking kernel trap) that is completely negligible in the context of process orchestration.
* **Opportunities:** This "Strict Child Coupling" strategy makes MakeOps highly resilient. It guarantees deterministic execution times and prevents CI/CD pipeline stalls caused by poorly written user scripts that accidentally leak background processes.

## 4. References

**Internal Documentation:**
* [1] [PLAT-002: Real-Time Log Streaming and I/O Multiplexing](./PLAT-002-realtime-log-streaming.md)
* [2] [PLAT-003: System Signal Routing and Exit Codes](./PLAT-003-signal-routing-and-exit-codes.md)

**External Literature:**
* [3] Kerrisk, M. (2010). *The Linux Programming Interface*. No Starch Press. (Chapter 26: Monitoring Child Processes; Chapter 44: Pipes and FIFOs).