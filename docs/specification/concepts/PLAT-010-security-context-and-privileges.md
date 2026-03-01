<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# PLAT-010 Security Context and Root Privileges

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `PLAT-010` |
| **Status** | `APPROVED` |
| **Date** | 2026-02-25 |
| **Category** | Platform Model |
| **Tags** | Security, Root, UID, sudo, Docker, Containers, Privilege Drop, SPARK |

## 1. Definition & Context
The Security Context and Root Privileges model defines how the MakeOps orchestrator reacts when executed with superuser (root) permissions. 

In the context of the **MakeOps** project, running the tool as root poses significant security and operational risks. Because MakeOps invokes arbitrary user-defined binaries and scripts via `execvp`, an accidental `sudo mko` invocation can execute destructive commands with full system privileges. Furthermore, generated build artifacts and logs will be owned by the root user, leading to "Permission Denied" errors for developers (Workspace Pollution). This document establishes an "Opt-In Root" safety mechanism to prevent these scenarios while remaining compatible with modern containerized environments.

## 2. Theoretical Basis
The security model relies on POSIX User Identifiers (UID), process inheritance, and the explicit rejection of dynamic privilege dropping.

### 2.1. UID Inheritance and Workspace Pollution
When a process invokes `fork()`, the child process inherits the User ID (UID) and Group ID (GID) of its parent. Consequently, if MakeOps is launched as root (UID 0), every operation spawned in the dependency graph will also execute as root. Any files created by compilers, linters, or deployment scripts during this run will belong to the root user, effectively polluting the local workspace and locking out the standard developer account.

### 2.2. The Opt-In Root Strategy (Safety Catch)
To protect the system and the workspace, MakeOps employs a Fail-Fast heuristic upon startup. The application immediately queries the POSIX `getuid()` function. 
* If the UID is strictly greater than `0`, execution proceeds normally.
* If the UID equals `0`, the system aborts execution immediately with a fatal error.
To execute MakeOps as root intentionally (e.g., in a CI/CD pipeline configuring system packages), the user MUST explicitly bypass this safety catch by providing the `--allow-root` CLI flag or by setting the `MKO_ALLOW_ROOT=1` environment variable.

### 2.3. Rejection of Dynamic Privilege Dropping (`setuid`)
An alternative approach to handling root execution is "Privilege Dropping" (e.g., detecting `SUDO_UID` and calling `setuid()` to revert to the original user). MakeOps explicitly rejects this architectural pattern for two reasons:
1. **SPARK Verification Restrictions:** System calls that dynamically mutate the fundamental security state and memory access rights of a running process introduce severe complexities into formal mathematical verification. Bypassing them helps guarantee the Absence of Runtime Errors (AoRE).
2. **Separation of Concerns:** Managing user namespaces is the responsibility of the environment (e.g., the shell or the Container Engine). Modern tools like Podman or Docker provide native user mapping (e.g., `--userns=keep-id` or `-u 1000:1000`). MakeOps relies on DevOps engineers to configure their containers correctly rather than attempting to magically fix broken security contexts from within the application.

## 3. Engineering Impact

* **Constraints:** The `MakeOps.Sys` package MUST provide a thin binding to the POSIX `getuid()` C function. The system initialization phase (`MakeOps.App` / `main.adb`) MUST evaluate this UID prior to executing the DAG traversal. The hierarchical configuration cascade (`ALG-003` / `ALG-007`) MUST be expanded to parse the `--allow-root` flag and the `MKO_ALLOW_ROOT` environment variable.
* **Performance Risks:** None. `getuid()` is an extremely lightweight, heavily optimized kernel system call.
* **Opportunities:** This architectural decision forces strict "Environment Hygiene." It prevents accidental system destruction by junior developers while providing a standardized, explicit escape hatch for automated DevOps environments.

## 4. References

**Internal Documentation:**
* [1] [PLAT-001: Pure Execution and OS Bindings](./PLAT-001-pure-execution-posix.md)
* [2] [PLAT-005: SPARK Formal Verification and Ada 2022 Constraints](./PLAT-005-spark-formal-verification.md)
* [3] [ALG-003: Hierarchical Configuration Cascade](./ALG-003-configuration-cascade.md)
* [4] [ALG-007: CLI Finite State Machine Parser](./ALG-007-cli-fsm-parser.md)