<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# MOD-011 Isolated OS Boundaries and Exception Handling

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `MOD-011` |
| **Status** | `APPROVED` |
| **Date** | 2026-04-23 |
| **Tags** | Linux, Facade, Exception Isolation, SPARK, Graceful Degradation, I/O |

## 1. Definition & Context
The Isolated OS Boundaries and Exception Handling model constitutes the protective abstraction layer between the pure, mathematically verified business logic of MakeOps and the unpredictable underlying operating system.

In the context of the MakeOps architecture, directly invoking standard Ada I/O libraries (such as `Ada.Environment_Variables`, `Ada.Directories`, or `Ada.Text_IO`) within the core algorithmic orchestrators is an anti-pattern. These standard libraries aggressively raise hard native exceptions (e.g., `Constraint_Error` for missing variables, `Name_Error` for missing files, `Device_Error` for broken terminal pipes) which violate the SPARK Absence of Runtime Errors (AoRE) constraints. This document defines how the system uses dedicated OS Adapters (Facades) to encapsulate these interactions, enforce OS standards (like XDG), and provide safe, deterministic, and exception-free interfaces to the core engine.

## 2. Theoretical Basis
This model relies on the principles of software boundary management, the Facade design pattern, and standard Linux directory specifications.

### 2.1. Native Exceptions vs. Formal Verification
In standard Ada programming, exceptions are the primary mechanism for handling unexpected states (e.g., trying to read a file that does not exist). However, in formal verification (SPARK), unhandled exceptions represent a failure of the mathematical proof. A formally verified program must theoretically account for all possible states without resorting to dynamic runtime crashing and stack unwinding.

### 2.2. The Facade Pattern and Graceful Degradation
Instead of scattering `try-catch` (or `exception` in Ada) blocks throughout the business logic, the architecture centralizes all OS interactions behind strict adapter packages. By returning Monadic `Result` types (e.g., a variant record `File_Result` with states like `Success` or `Not_Found`), the core engine never deals with exceptions. This enables **Graceful Degradation**—for example, if a global configuration file is missing, the OS boundary gracefully returns `Not_Found` instead of crashing, allowing the core engine to safely fall back to default mathematical states.

### 2.3. The XDG Base Directory Specification
In modern Linux environments, user-specific configuration files must not clutter the user's home directory. The XDG Base Directory Specification defines standard paths for these files. Conforming to this standard requires evaluating environment variables first (`$XDG_CONFIG_HOME`) and falling back to default paths (`$HOME/.config/`) if the variable is unset.

## 3. Conceptual Model
MakeOps abstracts all OS interactions into the `MakeOps.Sys` namespace, employing a strict structural pattern to trap exceptions and return deterministic states.

### 3.1. The Boundary Isolation Pattern
To comply with formal verification constraints while still using native Ada libraries under the hood, MakeOps splits the boundary into two physically distinct compilation units:
* **The Specification (`.ads`):** Marked with `pragma SPARK_Mode (On)`. It defines deterministic outcome records (e.g., variant records indicating `Success`, `Not_Found`, or `Permission_Denied`). It guarantees to the core engine that calling these functions will never raise an exception.
* **The Body (`.adb`):** Marked with `pragma SPARK_Mode (Off)`. It performs the actual volatile OS calls. It wraps these calls in `exception when others` blocks, trapping the native Ada runtime exceptions and translating them into the deterministic variant records defined in the specification.

### 3.2. Domain-Specific Isolation Strategies
The platform encapsulates three highly volatile OS domains:
1. **File System (FS) Isolation:** When reading optional files (like `/etc/makeops/config.toml`), the adapter traps `Name_Error` and `Use_Error`, returning a deterministic `Not_Found` state rather than crashing. It also encapsulates the XDG fallback logic so the core pipeline only asks for a "User Config Stream" without worrying about path resolution.
2. **Environment Isolation:** When querying the host OS for variables, the adapter traps `Constraint_Error` (raised by Ada if a variable doesn't exist), returning a safe variant record representing absence. This is crucial for the Lazy Variable Substitution algorithm.
3. **Terminal I/O Isolation:** When logging or rendering contextual errors, the engine uses a Terminal facade. This adapter traps `Device_Error` (e.g., when output is piped to a closed reader like `head` or `grep -q`), degrading silently to prevent secondary crashes during error reporting.

### 3.3. Dependency Inversion for Testability
By routing all OS environment queries through controlled interfaces (e.g., `MakeOps.Sys.Env.Get`), the architecture adheres to the Dependency Inversion Principle. The core algorithmic engine (`MakeOps.Core`) depends purely on the adapter's interface, not the OS. This allows the OS to be easily mocked during unit testing, ensuring that complex orchestration loops can be tested in isolation without relying on the actual Linux environment.

## 4. Engineering Impact

* **Constraints:**
    * The core algorithms (`MakeOps.Core`, `MakeOps.App`) MUST NOT directly `with` or use `Ada.Environment_Variables`, `Ada.Directories`, or `Ada.Text_IO`. 
    * All environment, file system, and terminal output queries MUST be routed strictly through the `MakeOps.Sys` boundary packages.
    * The dual SPARK pragma rule (On for `.ads`, Off for `.adb`) MUST be rigorously maintained for all boundary packages.
* **Performance/Memory Risks:** Negligible. The overhead of intercepting an exception and returning a domain-specific result (like a `Partial_Config` with `Not_Set` fields) is practically zero compared to the latency of the underlying OS I/O operations.
* **Opportunities:** This strict boundary perfectly sets the stage for achieving AoRE. By keeping the impure, unpredictable OS interactions strictly confined, the rest of the application remains completely deterministic and mathematically provable.

## 5. References

**Internal Documentation:**
* [1] [MOD-003: Hierarchical Configuration Cascade](./MOD-003-hierarchical-configuration-cascade.md)
* [2] [MOD-009: SPARK Verification & Static Memory Model](./MOD-009-formal-verification-static-memory.md)

**External Literature:**
* [3] Gamma, E., Helm, R., Johnson, R., & Vlissides, J. (1994). *Design Patterns: Elements of Reusable Object-Oriented Software*. Addison-Wesley. (Facade Pattern).
* [4] [XDG Base Directory Specification - freedesktop.org](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)