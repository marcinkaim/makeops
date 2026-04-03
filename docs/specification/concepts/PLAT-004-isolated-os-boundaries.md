<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# PLAT-004 OS Boundary Facades and Exception Isolation

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `PLAT-004` |
| **Status** | `APPROVED` |
| **Date** | 2026-02-23 |
| **Category** | Platform Model |
| **Tags** | Linux, Facade, Exception Isolation, File System, Environment Variables, Terminal I/O |

## 1. Definition & Context
The OS Boundary Facades constitute a protective abstraction layer between the pure, mathematically verified business logic of MakeOps and the unpredictable underlying operating system.

In the context of the **MakeOps** project, directly invoking standard Ada I/O libraries (such as `Ada.Environment_Variables`, `Ada.Directories`, or `Ada.Text_IO`) within the core algorithmic orchestrators is an anti-pattern. These standard libraries aggressively raise hard native exceptions (e.g., `Constraint_Error` for missing variables, `Name_Error` for missing files, `Device_Error` for broken terminal pipes) which violate the SPARK Absence of Runtime Errors (AoRE) constraints and can unexpectedly crash the tool. The system requires dedicated OS Adapters that encapsulate these interactions, providing safe, deterministic, and exception-free interfaces.

## 2. Theoretical Basis
The platform model relies on the Facade design pattern  to implement the XDG standard and guarantee Graceful Degradation.

### 2.1. The XDG Base Directory Specification
In modern Linux environments, user-specific configuration files must not clutter the user's home directory. The system must strictly adhere to the XDG Base Directory Specification. When resolving the path for the user-level global configuration, the adapter evaluates the following logic:
1. It queries the OS for the `$XDG_CONFIG_HOME` environment variable.
2. If the variable exists and is not empty, the target path is `$XDG_CONFIG_HOME/makeops/config.toml`.
3. If the variable is missing, it falls back to the default path: `$HOME/.config/makeops/config.toml`.

### 2.2. Exception Isolation and Graceful Degradation
The platform encapsulates three highly volatile OS domains to guarantee Graceful Degradation:

1. **File System (FS) Isolation:** When reading optional files (like `/etc/makeops/config.toml`), the adapter traps `Name_Error` and `Use_Error`, returning a deterministic `Not_Found` state rather than crashing, allowing the Configuration Cascade (`ALG-003`) to safely fallback. It also uses Thin Bindings (`access`) for safe "Pre-flight Executability Checks", avoiding heavy `fork` failures.
2. **Environment Isolation:** When querying the host OS for variables, the adapter traps `Constraint_Error`, returning a safe variant record representing absence, crucial for Lazy Variable Substitution (`ALG-002`).
3. **Terminal I/O Isolation:** When the diagnostic engine (`MODEL-002`) or Logging layer needs to print contextual errors to standard streams, it must use the Terminal facade. This adapter traps formatting and `Device_Error` exceptions (e.g., when output is piped to a closed reader like `head`), degrading silently to prevent secondary crashes during error reporting.

### 2.3. Dependency Inversion for Testability
By routing all OS environment queries through a controlled interface (e.g., `MakeOps.Sys.Env.Get`), the architecture adheres to the Dependency Inversion Principle. The core algorithmic engine (`MakeOps.Core`) depends purely on the adapter's interface. This allows the OS to be easily mocked during Phase 4 (Implementation and Unit Testing), ensuring that complex variable substitution loops (`ALG-002`) can be mathematically verified and tested in isolation without relying on the actual Linux environment.

## 3. Engineering Impact

* **Constraints:**
    * **Dependency Isolation:** The core algorithms and rendering engines MUST NOT directly `with` or use `Ada.Environment_Variables`, `Ada.Directories`, or `Ada.Text_IO`. All environment, file system, and terminal output queries MUST be routed through the `MakeOps.Sys` boundary packages (`MakeOps.Sys.Env`, `MakeOps.Sys.FS`, and `MakeOps.Sys.Terminal`).
    * **Exception Isolation (SPARK Boundary):** To comply with formal verification constraints (`PLAT-005`), the specifications (`.ads`) of the `MakeOps.Sys` adapters MUST be mathematically verifiable (`pragma SPARK_Mode (On)`) and MUST return deterministic outcome records (e.g., variant records indicating `Success`, `Not_Found`, or `Permission_Denied`). The package bodies (`.adb`) MUST explicitly opt-out of verification (`pragma SPARK_Mode (Off)`) to safely trap native Ada runtime exceptions (like `Ada.Text_IO.Name_Error`) and translate them into these deterministic return types, guaranteeing that exceptions never propagate into the core engine.
* **Performance Risks:** Negligible. The overhead of intercepting an exception and returning a domain-specific result (like a `Partial_Config` with `Not_Set` fields) is practically zero.
* **Opportunities:** This strict boundary perfectly sets the stage for formal verification (SPARK). By keeping the impure, unpredictable OS interactions strictly confined to the `Sys` package boundaries, the rest of the application can remain completely deterministic and mathematically provable.

## 4. References

**Internal Documentation:**
* [1] [REQ-004: Global Tool Preferences](../design/REQ-004-global-preferences.md)
* [2] [ALG-002: Lazy Variable Substitution](./ALG-002-lazy-variable-substitution.md)
* [3] [ALG-003: Hierarchical Configuration Cascade](./ALG-003-configuration-cascade.md)