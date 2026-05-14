<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# DES-008 MakeOps.Sys.Processes Package Design

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `DES-008` |
| **Status** | `APPROVED` |
| **Date** | 2026-03-03 |
| **Target Package** | `MakeOps.Sys.Processes` |

## 1. Scope & Responsibility

* **Goal:** Serves as the authoritative, pure-execution, safe adapter for spawning, monitoring, and reaping operating system processes.
* **Responsibility:**
    * Acts as a "Thick Wrapper" around the unsafe `MakeOps.Sys.Processes.OS_Bindings` private child package.
    * Provides strongly-typed, SPARK-safe abstractions for OS concepts like Pipes, Process IDs, and exit statuses.
    * Translates raw POSIX return codes and bitmasks (from `waitpid`, `poll`) into deterministic Ada records.
* **Out of Scope:** This package strictly manages OS-level primitives. It MUST NOT contain the business logic for the execution event loop (`MOD-005`), process timeouts, logging, or variable substitution.

## 2. Traceability & Dependencies

* **Implements Requirements:**
    * `REQ-002` (Operation Orchestration & Execution):
        * `NFR-002-001` / `NFR-002-002`: Implements the "Pure Execution" API by safely translating and passing strict argument arrays to the underlying POSIX system.
    * `REQ-003` (Execution Observability):
        * `NFR-003-001`: Provides the non-blocking stream interfaces required to expose stdout and stderr in real-time.
        * `F-003-004`: Decodes native OS bitmasks into standardized execution status codes.
* **Applies Concepts:**
    * `MOD-005` (Asynchronous Execution and Multiplexing): Implements the `poll` mechanics and non-blocking process state probing (`WNOHANG`).
    * `MOD-006` (POSIX IPC and Stream Routing): Governs the creation of anonymous pipes and the enforcement of the `O_NONBLOCK` file descriptor flags.
    * `MOD-007` (Pure Execution OS Boundaries): Dictates the strict `fork` and `execvp` sequence, handling C-ABI translations and null-terminated argument arrays.
    * `MOD-008` (System Signal Routing): Explains the bitwise decoding of the `waitpid` integer status into signals and exit codes.
    * `MOD-009` (Formal Verification & Static Memory Foundations): Requires the mapping of unpredictable POSIX errors to deterministic variant records and strictly bounded string arrays.
* **Internal Package Dependencies:**
    * `MakeOps.Sys.FS`: Utilized for the `Path_String` type representation of the executable command.
    * `MakeOps.Sys.Processes.OS_Bindings`: The unsafe C ABI layer providing native POSIX primitives.

## 3. Interface Semantics (.ads Contract)

* **Core Types & State:**
    * `Max_Arg_Length` / `Max_Args_Per_Command`: Static constants enforcing physical limits on process arguments.
    * `Arg_List`: A constrained array of bounded strings containing the exact arguments for execution.
    * `Max_Stream_Chunk_Length`: A static constant (4096) defining the bounded capacity for a single stream read buffer.
    * `Process_ID` / `File_Descriptor`: Strongly typed integers representing OS handles.
    * `Invalid_FD`: A static constant (`-1`) representing an unassigned or closed pipe.
    * `Process_Result`: A discriminated variant record (parameterized by `Process_State`) securely holding the `Exit_Code` if terminated normally, or the `Signal_Number` if killed.
    * `Stream_Result`: A discriminated variant record indicating the read outcome (`Data_Available`, `End_Of_File`, `Empty`) alongside the payload chunk.
* **Main Subprograms:**
    * `Create_Pipe`: Creates a unidirectional anonymous pipe, implicitly configuring the read-end for non-blocking I/O.
    * `Close_FD`: Ensures the safe, deterministic closure of a file descriptor.
    * `Spawn`: Forks the process, rewires the standard streams to the provided FDs, executes the target binary, and returns the tracking PID.
    * `Probe_State`: Non-blockingly evaluates the instantaneous execution state of the child process.
    * `Poll_Streams`: Accepts an array of file descriptors and evaluates which streams are ready for reading based on a timeout constraint.
    * `Read_Stream_Chunk`: Fetches available data from a non-blocking file descriptor into a safe variant record.
    * `Send_Signal`: Transmits a specific OS signal (e.g., `SIGKILL`) to a tracked process.
* **Formal Contracts & Invariants (SPARK):**
    * The package specification MUST be marked with the `pragma SPARK_Mode (On)` constraint.
    * It acts as a strict mathematical barrier. The domain invariant guarantees that executing subprograms will yield fully deterministic states (e.g., specific `Process_State` or `Stream_Status` variants) without leaking native C pointers, raw bitmasks, or unhandled exceptions into the core orchestrator.

## 4. Implementation Guidelines (.adb details)

* **Algorithmic Flow & Models:** The implementation acts as a robust Thick Wrapper, enforcing strict resource lifecycles across the C ABI boundary, managing memory allocation natively, and mechanically translating complex POSIX bitmasks into deterministic Ada records.
    * `Create_Pipe`: Must sequentially invoke `c_pipe` and `c_fcntl` to establish an anonymous pipe and explicitly apply the `O_NONBLOCK` mask to the read-end. Any failure during this kernel initialization sequence must trigger an immediate Fail-Fast hardware panic (`MakeOps.Sys.System_Error`).
    * `Close_FD`: Must safely invoke `c_close` and explicitly ignore the return code. This provides idempotent closure and guarantees that attempting to close an already invalid descriptor will not propagate native exceptions.
    * `Spawn`: Must actively manage memory allocation across the ABI boundary (`New_String`) to construct a null-terminated C-array (`chars_ptr_array`) for the arguments. Following `c_fork`, the parent path must immediately free the allocated C-strings and return the PID. The child path must rewire its standard file descriptors using `c_dup2` (or explicitly route to `/dev/null` if the target is `Invalid_FD`) before invoking `c_execvp`. If `c_execvp` fails and returns, the child must immediately halt using the POSIX `_exit(1)` call to prevent a catastrophic dual-process execution flow.
    * `Probe_State`: Must invoke `c_waitpid` using the `WNOHANG` flag for non-blocking status checks. It must deterministically map the resulting integer: `0` translates to `Running`, and `<0` translates to `OS_Error`. For `>0`, it must perform bitwise arithmetic to decode the packed POSIX status bitmask (differentiating `WIFEXITED` from `WIFSIGNALED`) to return either an `Exited_Normally` or `Killed_By_Signal` variant.
    * `Send_Signal`: Must invoke `c_kill` to send the requested signal and explicitly ignore the return code, seamlessly handling scenarios where the target process has already been reaped.
    * `Poll_Streams`: Must dynamically map the incoming Ada `FD_Array` into a C-compatible array of `struct_pollfd` records. After invoking `c_poll` with the specified timeout, it must evaluate the `revents` bitmask of each structure (checking for `POLLIN`, `POLLERR`, or `POLLHUP`) to construct and return a deterministic boolean array of ready descriptors.
    * `Read_Stream_Chunk`: Must utilize a pre-allocated, fixed-size string array as a raw byte bucket to adhere to Zero-Allocation rules. It invokes `c_read` and maps the `ssize_t` result: `>0` triggers string bounding and returns `Data_Available`, `0` maps directly to `End_Of_File`, and `<0` (which implies `EAGAIN` on a non-blocking pipe) gracefully degrades to an `Empty` status to preserve the exception-free contract.
* **Memory & SPARK Constraints:** The implementation relies on strict manual memory management across the ABI boundary. `Spawn` MUST dynamically allocate C strings (`chars_ptr`) for the argument array and append a `Null_Ptr` at the end to satisfy `execvp` requirements. The parent process MUST meticulously free all allocated C strings immediately after the `fork` to prevent memory leaks. Stream reading (`Read_Stream_Chunk`) MUST use a pre-allocated static stack array as the raw byte bucket to adhere to Zero-Allocation rules (`MOD-009`).
* **Boundary & Exception Handling:** The package body MUST be marked with `pragma SPARK_Mode (Off)`. It actively traps catastrophic kernel failures: if `pipe`, `fcntl`, or `fork` returns `-1`, the implementation MUST explicitly raise `MakeOps.Sys.System_Error`. Conversely, non-fatal or unrecoverable native errors are degraded gracefully: `c_close` and `c_kill` errors are silently ignored, and an `EAGAIN` response (negative bytes read) during a stream read is safely mapped to the `Empty` stream status variant.