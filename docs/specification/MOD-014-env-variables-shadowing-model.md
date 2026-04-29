<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# MOD-014 Environment Variables & Shadowing Model

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `MOD-014` |
| **Status** | `APPROVED` |
| **Date** | 2026-04-25 |
| **Tags** | Environment Variables, Namespaces, Shadowing, Security, OS_Env, Interpolation, Injection |

## 1. Definition & Context
The Environment Variables and Shadowing Model defines how the MakeOps orchestrator categorizes, prioritizes, and securely processes external environment variables provided by the host operating system.

In the context of the MakeOps project, environment variables are utilized in two distinct operational domains: configuring the tool's global behavior and resolving dynamic parameters within a specific project. This model establishes strict boundaries between these namespaces, defines an immutable priority hierarchy (Shadowing), and enforces security constraints to prevent interpolation injection attacks, ensuring mathematical predictability and AoRE.

## 2. Theoretical Basis
This model relies on explicit namespace separation and a deterministic, fail-safe evaluation order that prioritizes the project's explicit configuration over the volatile host environment.

### 2.1. Namespace Separation
To prevent collisions between orchestrator settings and user project parameters, variables are partitioned into distinct namespaces. Prefix-based filtering (e.g., `MKO_`) allows the system to distinguish between instructions intended for the tool itself and data intended for the tasks it orchestrates.

### 2.2. Shadowing and Precedence
In configuration management, shadowing is the rule where a definition at a higher authority level eclipses a definition at a lower level. While many tools allow the host environment to override local files, a "Lock-in" strategy treats the project configuration as the ultimate authority, ensuring that external environments cannot maliciously or accidentally alter verified project logic.

### 2.3. Interpolation Injection Security
A security risk exists when an attacker crafts an environment variable containing nested variable syntax (e.g., `${SECRET_VAR}`). If the orchestrator recursively evaluates these values, it could lead to unauthorized data exposure or command execution. The principle of "Terminal Values" dictates that data from untrusted sources (the OS) should be treated as raw bytes and never recursively parsed.

## 3. Conceptual Model
The model enforces a rigid hierarchy and security policies for variable ingestion and substitution.

### 3.1. Namespace Partitioning (Domain Rules)
* **Global Configuration Namespace:** Variables prefixed with `MKO_` (e.g., `MKO_LOG_LEVEL`, `MKO_ALLOW_ROOT`). These are processed exclusively by the Hierarchical Configuration Cascade and are never available for project-level interpolation.
* **Project Execution Namespace:** All other variables. These are used by the Resolver during Execution Plan Resolution.

### 3.2. Precedence Hierarchy (Shadowing)
MakeOps applies a "Bottom-Up" authority model for project variables:
1. **Host OS Environment (`OS_Env`):** The baseline source (Lowest priority).
2. **Project Configuration (`makeops.toml`):** The ultimate authority (Highest priority).

**The Shadowing Rule:** If a key exists in both `OS_Env` and the project TOML's `[environment]` section, the TOML definition strictly overwrites the value.

### 3.3. Terminal-Value Policy (Security)
The system distinguishes between "Trusted" and "Untrusted" sources for the purpose of recursion:
* **Trusted (`makeops.toml`):** Values undergo full Lazy Variable Substitution and can recursively reference other variables.
* **Untrusted (`OS_Env`):** Values are treated as "Raw Byte Buckets". MakeOps will substitute the exact bytes provided by the kernel but will NEVER parse or evaluate `${...}` markers within them.

## 4. Engineering Impact
This model constrains the implementation of both the Configuration Loader and the Variable Substitution engine.

* **Constraints:**
    * **`MakeOps.App.Config.Loader`:** MUST filter for `MKO_` prefixes and route them to the internal `App_Config` record.
    * **`MakeOps.Core.Project.Config.Variable_Substitution`:** MUST implement the shadowing hierarchy by querying the OS environment first and then overriding with the internal project dictionary.
    * **Substitution Loop:** MUST be implemented with a "no-recursion" flag when processing values originating from `OS_Env` to prevent injection.
* **Performance/Memory Risks:** Amortized $O(1)$ lookups for variables in memory. Bypassing evaluation for OS variables reduces CPU cycles and prevents complex recursion stack overflows.
* **Opportunities:** This model provides absolute mathematical predictability for developers. A `makeops.toml` file becomes an immutable source of truth, immune to unexpected pollution from different CI/CD host environments.

## 5. References

**Internal Documentation:**
* [1] [MOD-003: Hierarchical Configuration Cascade](./MOD-003-hierarchical-configuration-cascade.md)
* [2] [MOD-004: Execution Plan Resolution](./MOD-004-execution-plan-resolution.md)
* [3] [MOD-009: SPARK Verification & Static Memory Model](./MOD-009-formal-verification-static-memory.md)
* [4] [MOD-010: Text Encoding and Raw Byte Bucket Model](./MOD-010-text-encoding-byte-bucket.md)
* [5] [MOD-011: Isolated OS Boundaries and Exception Handling](./MOD-011-isolated-os-boundaries.md)

**External Literature:**
* [6] [MITRE CWE-78: Improper Neutralization of Special Elements used in an OS Command ('OS Command Injection')](https://cwe.mitre.org/data/definitions/78.html)
* [7] [POSIX.1-2017 - IEEE Std 1003.1: exec environment propagation](https://pubs.opengroup.org/onlinepubs/9699919799/functions/exec.html)