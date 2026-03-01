<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# PLAT-007 Execution Context Model

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `PLAT-007` |
| **Status** | `APPROVED` |
| **Date** | 2026-02-24 |
| **Category** | Platform Model |
| **Tags** | POSIX, CWD, Path Resolution, Working Directory, execvp, CLI |

## 1. Definition & Context
The Execution Context Model defines how the MakeOps orchestrator determines its Current Working Directory (CWD) and how it safely resolves relative file paths defined in the configuration. 

In the context of the **MakeOps** project, limiting the tool strictly to the terminal's current directory is inflexible and prevents the use of shared, out-of-tree DevOps toolchains. To solve this, the architecture introduces a strict separation between the **Execution Context** (where the processes run) and the **Configuration Anchor** (where the resources are located). This guarantees deterministic behavior, adheres to the Principle of Least Astonishment, and natively integrates with Linux POSIX APIs.

## 2. Theoretical Basis
The model relies on OS-level directory navigation (`chdir`) and a deterministic path translation heuristic evaluated prior to process invocation.

### 2.1. The Static Working Directory (Execution Context)
The Current Working Directory of the MakeOps orchestrator is determined exactly once during the application startup and remains static throughout the execution. 
* By default, the application inherits the CWD from the terminal environment.
* If the user provides the `-w <path>` (or `--workdir`) CLI argument, MakeOps immediately invokes the POSIX `chdir(path)` system call before performing any configuration parsing or graph resolution. 
Because child processes created via `fork()` natively inherit the parent's CWD, any spawned operation (e.g., a Bash script or a compiler) will naturally execute within this defined project directory.

### 2.2. The Configuration Anchor (Resource Context)
When MakeOps discovers and loads a project configuration file (either the default `makeops.toml` or one specified via the `-p` flag), it records the absolute path of the directory containing that file. This absolute directory path becomes the "Configuration Anchor." 

This establishes the architectural paradigm of the **Bundled DevOps System**. The `makeops.toml` file is not considered a standalone entity; it is inextricably linked with its adjacent helper scripts (e.g., a `devops/scripts/` directory living next to the config). Consequently, all relative paths to scripts and executable binaries defined within the configuration file are evaluated relative to this Configuration Anchor, not relative to the execution CWD.

### 2.3. POSIX Path Translation Heuristic
Because the underlying POSIX `execvp` function natively resolves relative paths against the CWD, MakeOps must proactively translate the `cmd` paths before spawning a process. The execution engine applies the following rigid heuristic:
1. **Absolute Paths:** If the `cmd` string starts with `/` (e.g., `/usr/bin/python3`), it is left unmodified.
2. **System Commands:** If the `cmd` string contains no `/` characters at all (e.g., `gcc`, `make`, `docker`), it is left unmodified. The OS will automatically resolve it using the `$PATH` environment variable.
3. **Relative Paths:** If the `cmd` string contains a `/` but does not start with it (e.g., `scripts/build.sh` or `./deploy.sh`), MakeOps prepends the Configuration Anchor path to it (e.g., resulting in `/opt/shared-ci/scripts/build.sh`).

## 3. Engineering Impact

* **Constraints:**
    * **Initialization Phase:** The `chdir` system call MUST be invoked exclusively in the CLI initialization phase (`main.adb`), prior to loading any TOML files, to ensure that relative `-p` flags are evaluated correctly against the new CWD.
    * **Translation Ordering:** The execution engine (`MakeOps.Core`) MUST implement the Path Translation Heuristic before passing the command to the `MakeOps.Sys.Processes` OS bindings. Crucially, to establish a deterministic execution pipeline, the Path Translation Heuristic MUST be applied strictly *after* the Lazy Variable Substitution (`ALG-002`) has fully evaluated the command strings.
    * **Pre-flight Limit Check (Memory Safety):** Before concatenating the Configuration Anchor with a relative command path, the engine MUST mathematically verify that their combined length (in bytes) is less than or equal to the statically defined `Max_Command_Length` (from `PLAT-006`). If the limit would be exceeded, the system MUST NOT perform the concatenation and MUST immediately return a controlled domain error (e.g., `Path_Too_Long`) to prevent an unhandled `Constraint_Error`.
    * **Pre-flight Executability Check:** Following translation, if the resulting command path indicates a specific file (contains a `/`), the engine MUST utilize the FS Adapter (`PLAT-004`) to perform a Pre-flight Executability Check, returning a domain error immediately if the file lacks the required `+x` permissions.
* **Performance Risks:** None. String concatenation for path translation adds zero measurable overhead to process spawning.
* **Opportunities:** This architectural separation lays the groundwork for advanced enterprise patterns, such as configuration inheritance (`include` directives). A shared, central `makeops.toml` repository can be referenced by multiple independent projects; its internal relative script paths will safely resolve to its own central directory, while the scripts themselves will execute against the target project's working directory.

## 4. References

**Internal Documentation:**
* [1] [PLAT-001: Pure Execution and OS Bindings](./PLAT-001-pure-execution-posix.md)
* [2] [REQ-002: Operation Orchestration & Execution](../design/REQ-002-operation-orchestration.md)
* [3] [REQ-004: Global Tool Preferences](../design/REQ-004-global-preferences.md)