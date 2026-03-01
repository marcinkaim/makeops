<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# ALG-008 Real-Time I/O Multiplexing Loop

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `ALG-008` |
| **Status** | `APPROVED` |
| **Date** | 2026-02-25 |
| **Category** | Algorithm |
| **Tags** | Event Loop, Multiplexing, poll, waitpid, I/O, IPC |

## 1. Definition & Context
The Real-Time I/O Multiplexing Loop is the core operational algorithm used during the execution of a single task. It bridges the gap between the process lifecycle management and real-time observability.

In the context of the **MakeOps** project, once a child process is spawned via `fork`/`execvp`, the parent MakeOps process must actively monitor the child's standard streams (`stdout`/`stderr`) and its execution state simultaneously. This algorithm defines the deterministic state machine that multiplexes these streams without blocking and gracefully handles child termination.

## 2. Theoretical Basis
The algorithm relies on an event-driven loop that prioritizes I/O polling, combined with non-blocking stream reads and asynchronous child state probes.

### 2.1. The Event Loop Lifecycle and Timeout
The loop operates continuously until the direct child process explicitly terminates. Inside the loop, the algorithm instructs the OS to put the thread to sleep until an event occurs on the file descriptors (using `poll`). Crucially, the `poll` call MUST include a timeout (`Polling_Timeout`). If the child process is performing a long, silent computation, the timeout ensures the loop wakes up periodically to verify if the child has terminated, preventing the orchestrator from blocking indefinitely.

### 2.2. The Final Flush Mechanism
When `waitpid` indicates that the child has died, the kernel might still hold unread data in the pipe buffers. The algorithm mandates a "Final Flush"—a forced, non-blocking read of both pipes until they return empty (`EAGAIN`)—before returning control to the caller. This guarantees that the final lines of output (e.g., a critical error message emitted right before the crash) are not lost.

### 2.3. Structured Algorithmic Description
The following is a structured definition of the execution and multiplexing loop.

**Inputs:**
* `Child_PID`: The Process ID of the spawned target operation.
* `FD_Out`: The optional file descriptor for the child's `stdout` pipe (configured as `O_NONBLOCK`). Can be `Not_Set` if stdout is redirected to `/dev/null`.
* `FD_Err`: The file descriptor for the child's `stderr` pipe (configured as `O_NONBLOCK`).
* `Grace_Period_MS`: The allowed time in milliseconds for the child to voluntarily terminate after an abort is requested.

**Outputs:**
* `Final_Exit_Code`: The decoded POSIX exit code of the child process (or a designated error code if OS monitoring fails).
* Outputs text directly to the MakeOps `stdout` and `stderr` streams.

**Procedure `Read_Stream_Non_Blocking(FD, Target_Stream)`:**
1. Loop:
   * Set `Buffer := Read_From_FD(FD)`
   * Check Result:
     * **If Data Read:** Call `Print(Target_Stream, Buffer)` *(Note: Print internally evaluates Log_Level and suppresses stdout if configured to Error)*
     * **If EOF or EAGAIN (Empty):** Return

**Main Execution Flow:**
1. Set `Process_Running := True`
2. Set `Final_Exit_Code := 0`
3. Set `Kill_Deadline_Set := False`
4. Set `Kill_Deadline := 0`
5. Set `Active_FDs := Create_List(FD_Err)`
6. If `FD_Out` is not `Not_Set`:
    * Call `Active_FDs.Append(FD_Out)`
7. Loop while `Process_Running == True`:
    * Call `OS.poll(Active_FDs, Polling_Timeout)`
    * *Phase 1: Process Output Streams*
        * If `FD_Out` is not `Not_Set` and `FD_Out` has data to read:
            * Call `Read_Stream_Non_Blocking(FD_Out, stdout)`
        * If `FD_Err` has data to read:
            * Call `Read_Stream_Non_Blocking(FD_Err, stderr)` 
    * *Phase 2: Probe Process State*
        * Set `Status := OS.waitpid(Child_PID, WNOHANG)`
        * Check `Status`:
            * **If 0:**
                * If `Abort_Requested` is `True`:
                    * If `Kill_Deadline_Set` is `False`:
                        * Set `Kill_Deadline := Current_Time + Grace_Period_MS`
                        * Set `Kill_Deadline_Set := True`
                    * If `Current_Time > Kill_Deadline`:
                        * Call `OS.kill(Child_PID, SIGKILL)`
            * **If > 0 (Child Terminated):**
                * Set `Process_Running := False`
                * Set `Final_Exit_Code := Decode_Exit_Status(Status)`
            * **If < 0 (OS Error):**
                * Set `Process_Running := False`
                * Set `Final_Exit_Code := System_Failure_Code`

8. *Phase 3: Final Flush (Ensure no logs are left behind)*
   * If `FD_Out` is not `Not_Set`:
       * Call `Read_Stream_Non_Blocking(FD_Out, stdout)`
   * Call `Read_Stream_Non_Blocking(FD_Err, stderr)`

9. Return `Final_Exit_Code`

## 3. Engineering Impact

* **Constraints:**
    * The `Read_Stream_Non_Blocking` procedure MUST properly handle partial reads and string buffering if the data chunk does not end with a newline character, ensuring that output lines are not prematurely broken.
    * **Output Filtering:** The multiplexing loop dynamically adapts to the provided file descriptors. If the `Log_Level` is set to `Error`, the orchestrator simply does not pass an `FD_Out` pipe to this algorithm (redirecting it to `/dev/null` at the OS level instead). This completely eliminates unnecessary buffering and polling overhead, while still guaranteeing that the loop drains whatever pipes it is actually given to prevent OS-level deadlocks.
    * **Resource Ownership:** The algorithm operates exclusively on borrowed File Descriptors. It MUST NOT close the pipes. Closing the file descriptors remains the strict responsibility of the calling procedure (as required by the Detachment Contract in `PLAT-009`).
* **Performance Risks:** None. The use of `poll` ensures that MakeOps consumes virtually $0\%$ CPU while waiting for the child process to generate output.
* **Opportunities:** Centralizing this logic into a single algorithm cleanly separates the pure orchestration loop from the messy POSIX resource management setup (like calling `pipe` and `fork`).

## 4. References

**Internal Documentation:**
* [1] [PLAT-002: Real-Time Log Streaming and I/O Multiplexing](./PLAT-002-realtime-log-streaming.md)
* [2] [PLAT-003: System Signal Routing and Exit Codes](./PLAT-003-signal-routing-and-exit-codes.md)
* [3] [PLAT-009: IPC Lifecycle and Process Management](./PLAT-009-ipc-lifecycle-management.md)