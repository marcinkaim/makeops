<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# MOD-012 Execution Context & Security Model

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `MOD-012` |
| **Status** | `APPROVED` |
| **Date** | 2026-04-25 |
| **Tags** | POSIX, Security, Root, UID, Privilege Dropping, Workspace Pollution, chdir |

## 1. Definition & Context
The Execution Context & Security Model defines how the MakeOps orchestrator determines its physical location in the file system and how it reacts when executed with superuser (root) permissions.

In the context of the MakeOps project, executing arbitrary, user-defined operations via `execvp` requires strict environmental boundaries. Limiting the tool to the terminal's current directory is inflexible, while running it unconditionally as root poses severe security and usability risks. This document establishes the architectural separation between the resource location (Configuration Anchor) and the process execution directory (Execution Context), and introduces an "Opt-In Root" safety mechanism to prevent accidental workspace pollution.

## 2. Theoretical Basis
This model relies on POSIX directory navigation, User Identifier (UID) inheritance, and the explicit rejection of dynamic privilege dropping.

### 2.1. POSIX Working Directories and Inheritance
In Unix-like systems, every process has a Current Working Directory (CWD). When a process creates a child via `fork()`, the child natively inherits the parent's CWD. Following the **Principle of Least Astonishment**, navigating the parent process using the `chdir()` system call guarantees that all subsequent child processes will execute from the intended location without requiring explicit path prefixes for every command.

### 2.2. Security Philosophy: Privilege Dropping vs. External Responsibility
MakeOps explicitly rejects the "Privilege Dropping" pattern (where a root process attempts to switch to a lower-privileged user). This mechanism is notoriously complex and inconsistent across different Linux distributions and container runtimes. Instead, MakeOps adheres to the **Principle of External Responsibility**: the environment (shell, CI/CD runner, or Container Engine like Podman/Docker) is responsible for setting the correct security context. MakeOps only validates this context and enforces safety rails.

### 2.3. UID Inheritance and Workspace Pollution
Similar to the CWD, a child process inherits the User ID (UID) and Group ID (GID) of its parent. If MakeOps is launched as root (UID 0) via `sudo`, every operation in the dependency graph will also execute as root. Any build artifacts, logs, or cache files created during this run will belong to the root user. When the developer later tries to clean or modify the project as a standard user, they will encounter "Permission Denied" errors. This phenomenon is known as Workspace Pollution.

### 2.4. Rejection of Dynamic Privilege Dropping
Some tools attempt to fix root execution dynamically by detecting variables like `SUDO_UID` and invoking `setuid()` to drop privileges back to the standard user. MakeOps explicitly rejects this pattern. System calls that dynamically mutate fundamental security states introduce severe complexities into formal mathematical verification (SPARK). Furthermore, managing user namespaces is strictly the responsibility of the host environment (e.g., Docker, Podman, or the shell), adhering to the Separation of Concerns.

## 3. Conceptual Model
MakeOps enforces strict heuristics to decouple resource locations from execution directories and acts as a strict gatekeeper against root privileges.

### 3.1. The Configuration Anchor vs. Execution Context
To support shared, out-of-tree DevOps toolchains (the Bundled DevOps System), MakeOps establishes two distinct locations:
* **Execution Context:** The directory where processes run. By default, it is the terminal's CWD. It can be overridden globally using the `-w <path>` CLI flag, which immediately invokes `chdir(path)`.
* **Configuration Anchor:** The directory where the `makeops.toml` file is located.

When a relative script path is defined in `makeops.toml` (e.g., `cmd = "scripts/build.sh"`), it is assumed to be adjacent to the configuration file, not the CWD. 

### 3.2. Path Translation Heuristic
Before spawning a process, the engine applies a rigid translation heuristic to the `cmd` string:
1. **Absolute Paths:** If it starts with `/` (e.g., `/usr/bin/python3`), it is unchanged.
2. **System Commands:** If it contains no `/` (e.g., `gcc`, `make`), it is unchanged (resolved via `$PATH`).
3. **Relative Paths:** If it contains a `/` but does not start with it, MakeOps prepends the Configuration Anchor path.

### 3.3. The "Opt-In Root" Safety Mechanism & Workspace Pollution
To prevent unintentional root execution and the resulting **Workspace Pollution** (where build artifacts and logs become owned by `root`, leading to "Permission Denied" errors for developers), MakeOps implements a hard-stop barrier. If the system detects a UID of `0` (root), it will refuse to execute the DAG unless the user provides an explicit "Opt-In" via the `--allow-root` CLI flag or the `MKO_ALLOW_ROOT=1` environment variable.

### 3.4. Pre-flight Executability Check
Prior to invoking any command, the engine MUST verify that the resolved binary path is actually executable. This check is performed using the FS Adapter to verify the `+x` bit in the file's permission mask. This prevents the orchestrator from entering a partial execution state where some dependencies succeed but the main command fails due to trivial permission issues.

## 4. Engineering Impact

* **Constraints:**
    * The `chdir` system call MUST be invoked exclusively in the CLI initialization phase.
    * **Security Boundary:** The `MakeOps.Sys` package MUST provide a thin binding to the POSIX `getuid()` function to enable UID validation during the startup phase.
    * **Executability Check:** The engine MUST utilize the FS Adapter to perform a Pre-flight Executability Check (`+x`) before each process invocation.
    * **Memory Safety Check:** Before concatenating the Configuration Anchor with a relative path, the engine MUST verify that the combined byte length is $\le$ `Max_Command_Length` (defined in `MOD-009`).
* **Performance/Memory Risks:** None. `getuid()` is an extremely lightweight kernel call, and string concatenation adds zero measurable overhead.
* **Opportunities:** This architectural separation lays the groundwork for configuration inheritance (where multiple projects reference a central, read-only MakeOps file). The Opt-In Root mechanism prevents junior developers from accidentally breaking their local permissions while maintaining full compatibility with automated DevOps pipelines.

## 5. References

**Internal Documentation:**
* [1] [MOD-003: Hierarchical Configuration Cascade](./MOD-003-hierarchical-configuration-cascade.md)
* [2] [MOD-007: Pure Execution OS Boundaries](./MOD-007-pure-execution-os-boundaries.md)
* [3] [MOD-009: SPARK Verification & Static Memory Model](./MOD-009-formal-verification-static-memory.md)
* [4] [MOD-011: Isolated OS Boundaries and Exception Handling](./MOD-011-isolated-os-boundaries.md)

**External Literature:**
* [5] [Linux Programmer's Manual: `credentials(7)` - Process identifiers (UID, GID)](https://man7.org/linux/man-pages/man7/credentials.7.html)