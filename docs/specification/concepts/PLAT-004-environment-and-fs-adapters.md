<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# PLAT-004 Linux Environment and FS Adapters

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `PLAT-004` |
| **Status** | `APPROVED` |
| **Date** | 2026-02-23 |
| **Category** | Platform Model |
| **Tags** | Linux, XDG, File System, Environment Variables, Facade, Graceful Degradation |

## 1. Definition & Context
The Linux Environment and File System Adapters constitute a protective abstraction layer (Facade) between the pure business logic of MakeOps and the underlying Debian 13 operating system. 

In the context of the **MakeOps** project, directly invoking standard Ada libraries (such as `Ada.Environment_Variables` or `Ada.Text_IO`) within the core algorithmic orchestrators is an anti-pattern. These standard libraries aggressively raise hard exceptions (e.g., `Constraint_Error` for missing variables, `Name_Error` for missing files) which can unexpectedly crash the tool. To fulfill the requirements of resilient configuration cascading and lazy variable evaluation, the system requires a dedicated OS Adapter that handles the XDG Base Directory specification and provides safe, exception-free query interfaces.

## 2. Theoretical Basis
The platform model relies on the Facade design pattern  to implement the XDG standard and guarantee Graceful Degradation.

### 2.1. The XDG Base Directory Specification
In modern Linux environments, user-specific configuration files must not clutter the user's home directory. The system must strictly adhere to the XDG Base Directory Specification. When resolving the path for the user-level global configuration, the adapter evaluates the following logic:
1. It queries the OS for the `$XDG_CONFIG_HOME` environment variable.
2. If the variable exists and is not empty, the target path is `$XDG_CONFIG_HOME/makeops/config.toml`.
3. If the variable is missing, it falls back to the default path: `$HOME/.config/makeops/config.toml`.

### 2.2. Exception Isolation and Graceful Degradation
To support the Hierarchical Configuration Cascade (`ALG-003`), the File System (FS) adapter implements a "fail-safe" reading mechanism. When attempting to read an optional file (like `/etc/makeops/config.toml`), the adapter traps native Ada exceptions such as `Name_Error` (file not found) and `Use_Error` (permission denied). Instead of crashing, it returns a distinct "Not_Found" state or yields a formatted warning string that the cascade algorithm can buffer and potentially suppress (if the `--log-level error` flag is eventually resolved).

**Pre-flight Executability Checks:**
The FS Adapter also encapsulates the POSIX `access(path, X_OK)` C function (via Thin Bindings). Providing a safe `Is_Executable(Path)` query allows the core orchestrator to perform "Pre-flight Checks" on resolved binaries before delegating them to the execution engine. This gracefully translates cryptic kernel `EACCES` errors into explicit, domain-aware diagnostic messages (e.g., informing the user that a script lacks the `+x` permission flag) without invoking the heavy machinery of process forking.

### 2.3. Dependency Inversion for Testability
By routing all OS environment queries through a controlled interface (e.g., `MakeOps.Sys.Env.Get`), the architecture adheres to the Dependency Inversion Principle. The core algorithmic engine (`MakeOps.Core`) depends purely on the adapter's interface. This allows the OS to be easily mocked during Phase 4 (Implementation and Unit Testing), ensuring that complex variable substitution loops (`ALG-002`) can be mathematically verified and tested in isolation without relying on the actual Linux environment.

## 3. Engineering Impact

* **Constraints:**
    * **Dependency Isolation:** The core algorithms (`ALG-001` through `ALG-006`) MUST NOT directly `with` or use `Ada.Environment_Variables` or `Ada.Directories`. All environment and file system queries MUST be routed through the `MakeOps.Sys` child packages (e.g., `MakeOps.Sys.Env` and `MakeOps.Sys.FS`).
    * **Exception Isolation (SPARK Boundary):** To comply with formal verification constraints (`PLAT-005`), the specifications (`.ads`) of the `MakeOps.Sys` adapters MUST be mathematically verifiable (`pragma SPARK_Mode (On)`) and MUST return deterministic outcome records (e.g., variant records indicating `Success`, `Not_Found`, or `Permission_Denied`). The package bodies (`.adb`) MUST explicitly opt-out of verification (`pragma SPARK_Mode (Off)`) to safely trap native Ada runtime exceptions (like `Ada.Text_IO.Name_Error`) and translate them into these deterministic return types, guaranteeing that exceptions never propagate into the core engine.
* **Performance Risks:** Negligible. The overhead of intercepting an exception and returning a domain-specific result (like a `Partial_Config` with `Not_Set` fields) is practically zero.
* **Opportunities:** This strict boundary perfectly sets the stage for formal verification (SPARK). By keeping the impure, unpredictable OS interactions strictly confined to the `Sys` package boundaries, the rest of the application can remain completely deterministic and mathematically provable.

## 4. References

**Internal Documentation:**
* [1] [REQ-004: Global Tool Preferences](../design/REQ-004-global-preferences.md)
* [2] [ALG-002: Lazy Variable Substitution](./ALG-002-lazy-variable-substitution.md)
* [3] [ALG-003: Hierarchical Configuration Cascade](./ALG-003-configuration-cascade.md)