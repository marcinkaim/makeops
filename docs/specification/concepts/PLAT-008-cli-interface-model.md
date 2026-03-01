<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# PLAT-008 Command Line Interface Model

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `PLAT-008` |
| **Status** | `APPROVED` |
| **Date** | 2026-02-24 |
| **Category** | Platform Model |
| **Tags** | CLI, Arguments, POSIX, User Experience, DX, Options |

## 1. Definition & Context
The Command Line Interface (CLI) Model defines the formal specification of the arguments, flags, and operational targets accepted by the `mko` executable. 

In the context of the **MakeOps** project, a predictable and modern Developer Experience (DX) is critical. By normalizing the command-line arguments into strict key-value pairs and clearly separating them from positional arguments (target operations), the system not only provides a highly intuitive interface for users but also drastically simplifies the underlying parsing algorithms, making formal verification (SPARK) mathematically trivial.

## 2. Theoretical Basis
The model enforces a standard POSIX-compliant signature structure while heavily minimizing the complexity of mixing binary state flags with parameterized flags.

### 2.1. The Command Signature
The fundamental execution signature of the tool is structured as follows:
`mko [OPTIONS] [OPERATIONS...]`

### 2.2. Key-Value Argument Normalization (Options)
To maintain consistency and simplify the internal Finite State Machine (FSM) parser, all operational modifiers are structured as key-value pairs supporting both short (single dash) and long (double dash) UNIX conventions.
* **Working Directory:** `-w <path>`, `--workdir <path>`
  Sets the static Execution Context (invokes `chdir`) before resolving the configuration.
* **Project Configuration:** `-p <path>`, `--project-config <path>`
  Explicitly defines the location of the project's `makeops.toml` file, overriding the default discovery mechanism. The term `project-config` clearly distinguishes this local operational file from global user preferences.
* **Log Level:** `-l <level>`, `--log-level <level>`
  Controls the diagnostic output granularity. Allowed values are strictly mapped to standard DevOps logging conventions corresponding to the internal `Log_Level` domain: `error` (quiet), `info` (normal default), and `debug` (verbose).

### 2.3. Binary Flags
While most operational modifiers are strictly key-value pairs, the system supports specific binary flags for application metadata and explicit security overrides:
* **Auxiliary (Halting):**
  * `-h`, `--help`: Prints the usage manual and immediately halts further execution.
  * `--version`: Prints the software version, build information, and license details and immediately halts further execution.
* **Security Context:**
  * `--allow-root`: Explicitly bypasses the Fail-Fast safety catch when the tool is executed by the root user (UID 0), permitting execution.

### 2.4. Positional Arguments (Operations)
Any space-separated string provided in the arguments array that is not preceded by an Option flag is classified as a Positional Argument. These represent the target operations (e.g., `build`, `test`, `deploy`) defined within the directed acyclic graph of the `makeops.toml` file.

**Default Behavior (Empty Target):** If the user invokes the `mko` command without specifying any positional arguments (operations), the system MUST NOT silently succeed. The default behavior in this scenario is to emit a diagnostic error indicating that no target operation was provided, and subsequently print the usage manual (identical to the halting behavior of the `-h` or `--help` flag).

## 3. Engineering Impact
* **Constraints:** The CLI parser MUST map the parsed Options into the highest-priority `Partial_Config` record to feed the Hierarchical Configuration Cascade (`ALG-003`). The Positional Arguments MUST be queued and passed to the Operation Orchestration engine (`REQ-002`).
* **Performance Risks:** None. Iterating over the operating system's argument array operates in $O(N)$ time, where $N$ is practically bounded by the user's shell limits.
* **Opportunities:** Because the interface avoids mutually exclusive boolean flags (like `--quiet` vs `--verbose`) in favor of a single `--log-level` key-value pair, the parser can be implemented as a simple, highly deterministic state machine. Even with the introduction of the isolated `--allow-root` binary flag, this practically eliminates complex branching logic and perfectly aligns with the Absence of Runtime Errors (AoRE) verification goals.

## 4. References

**Internal Documentation:**
* [1] [REQ-003: Execution Observability](../design/REQ-003-execution-observability.md)
* [2] [REQ-004: Global Tool Preferences](../design/REQ-004-global-preferences.md)
* [3] [ALG-003: Hierarchical Configuration Cascade](./ALG-003-configuration-cascade.md)
* [4] [PLAT-007: Execution Context Model](./PLAT-007-execution-context-model.md)
* [5] [PLAT-010: Security Context and Root Privileges](./PLAT-010-security-context-and-privileges.md)