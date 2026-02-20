<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# REQ-002 Operation Orchestration & Execution

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `REQ-002` |
| **Status** | `APPROVED` |
| **Date** | 2026-02-20 |
| **Capability Type** | User-Facing |
| **References** | `REQ-000`, `REQ-001` |

## 1. Capability Description (The "What" & "Why")
* **Definition:** The ability for users to trigger a specific target operation, relying on the system to automatically determine the correct execution order of prerequisites and securely invoke the underlying system processes.
* **User Value / Rationale:** Eliminates the manual tracking and execution of complex build or deployment steps. It ensures deterministic, repeatable, and secure execution by enforcing pure binary invocations without relying on unpredictable or vulnerable embedded shell scripts.
* **Dependencies:** Inherits constraints from `REQ-000`. Relies on the parsed project configuration and data model provided by `REQ-001`.

## 2. Functional Requirements (Behavior)
* **F-002-001:** The system SHALL accept a target operation name from the user as a trigger for execution.
* **F-002-002:** The system SHALL automatically resolve and execute all prerequisite operations defined in the `deps` arrays prior to executing the target operation.
* **F-002-003:** The system SHALL ensure that any given operation within the dependency chain is executed exactly once per run, even if multiple operations depend on it.
* **F-002-004:** The system SHALL dynamically substitute declared environment variables (e.g., `${VAR_NAME}`) within the operation's `args` definitions immediately prior to execution.
* **F-002-005:** The system SHALL immediately halt the execution sequence if any invoked operation returns a non-zero exit code.

## 3. System Constraints & Quality Attributes (NFRs)
* **NFR-002-001 (Pure Execution):** The system MUST execute the defined `cmd` binary directly via operating system process bindings (POSIX). It MUST NOT invoke an intermediate shell (e.g., `/bin/sh -c`) to parse the command.
* **NFR-002-002 (Strict Argument Passing):** The system MUST pass the evaluated `args` array strictly as discrete arguments to the spawned process, preventing arbitrary command injection.
* **NFR-002-003 (Mathematical Ordering):** The internal engine MUST utilize Directed Acyclic Graph (DAG)  traversal algorithms to guarantee the mathematical correctness of the operation sequence.

## 4. Input / Output Data Model
* **Inputs:**
    * Target operation identifier passed via the `mko` CLI command (string).
    * Internal domain model containing the resolved operation nodes and environment dictionary (from `REQ-001`).
* **Outputs:**
    * Operating system process invocations.
    * Process exit status codes (success/failure metrics).

## 5. Acceptance Criteria (Definition of Done)
* **AC-002-001:** Invoking a target operation via the CLI with multiple layers of dependencies (e.g., `mko dist` depending on `build-release`, `test`, and `prove`) results in all required commands executing in the correct topological order.
* **AC-002-002:** If a prerequisite operation fails and returns a non-zero exit code, the system terminates immediately and does not attempt to execute subsequent operations.
* **AC-002-003:** Variables mapped in the configuration (e.g., `${GPR_MAIN}`) are successfully substituted with their actual values (e.g., `makeops.gpr`) in the argument list before the process is spawned.
* **AC-002-004:** System-level verification confirms that the specified executable is spawned directly, without any shell wrappers or implicit argument expansion by the OS.