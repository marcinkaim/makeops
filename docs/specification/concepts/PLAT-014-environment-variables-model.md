<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# PLAT-014 Environment Variables Model

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `PLAT-014` |
| **Status** | `APPROVED` |
| **Date** | 2026-02-27 |
| **Category** | Platform Model |
| **Tags** | Environment Variables, Namespaces, Shadowing, Security, OS_Env, Interpolation |

## 1. Definition & Context
The Environment Variables Model defines how the MakeOps orchestrator categorizes, prioritizes, and securely processes external environment variables provided by the host operating system. 

In the context of the **MakeOps** project, the system must interact with environment variables in two distinct operational domains: configuring the tool's global behavior and resolving dynamic parameters within a specific project. This document establishes the strict boundaries between these namespaces, defines an immutable priority hierarchy (Shadowing), and enforces security constraints to prevent interpolation injection attacks.

## 2. Theoretical Basis
The model relies on explicit namespace separation and a deterministic, fail-safe evaluation order that prioritizes the project's explicit configuration over the host environment.

### 2.1. Definition of Variable Namespaces
To prevent collisions between the orchestrator's internal settings and the user's project parameters, MakeOps partitions environment variables into two distinct namespaces:
* **Global Configuration Namespace:** Variables in this space are strictly reserved for configuring the `mko` tool itself. They MUST be prefixed with `MKO_`. The system currently recognizes only the following variables:
  * `MKO_LOG_LEVEL`
  * `MKO_PROJECT_CONFIG`
  * `MKO_ALLOW_ROOT`
  
  These variables are processed exclusively by the Hierarchical Configuration Cascade (`ALG-003`) during the application's startup phase and are not accessible within the project's operation graph.
* **Project Execution Namespace:** Variables without the `MKO_` prefix are treated as project-specific parameters. They are utilized by the Lazy Variable Substitution algorithm (`ALG-002`) to resolve placeholders (e.g., `${DB_HOST}`) defined in the `makeops.toml` operations graph.

### 2.2. Hierarchy of Project Variable Priorities (Shadowing)
Unlike standard DevOps tools (where the OS environment usually overrides project files), MakeOps enforces a strict, deterministic lock-in strategy for project variables. The resolution priority operates from lowest to highest authority as follows:
1. **System OS Environment (`OS_Env`):** The baseline source.
2. **Project Configuration (`makeops.toml`):** The ultimate authority.

**The Shadowing Rule:** If a variable is present in the host's operating system environment, MakeOps will read it. However, if the exact same variable key is explicitly defined within the `[environment]` section of the project's `makeops.toml` file, the project's definition strictly overwrites (shadows) the OS value. This guarantees that critical project variables cannot be accidentally or maliciously altered by external CI/CD pipeline environments.

### 2.3. Security Constraints (Raw Terminal Values)
To protect the system from Interpolation Injection (where an attacker crafts an OS environment variable containing nested MakeOps `${...}` syntax to exfiltrate secrets or execute secondary commands), the system enforces a strict terminal-value policy based on the variable's source:
* **Project Configuration (`makeops.toml`):** Variables defined here are fully trusted. They undergo standard Lazy Variable Substitution (`ALG-002`) and can recursively reference other variables.
* **System OS Environment (`OS_Env`):** Variables ingested from the operating system are treated as strictly terminal (Raw Byte Buckets). MakeOps will NOT parse, expand, or evaluate any `${...}` syntax found within an OS environment variable. They are substituted exactly as they are provided by the kernel.

## 3. Engineering Impact
* **Constraints:** The `ALG-002` variable substitution algorithm MUST implement the shadowing hierarchy by querying the `OS_Env` first, and subsequently overwriting that value if the key is found in the parsed `makeops.toml` environment dictionary. Furthermore, the substitution loop MUST bypass recursive evaluation for values originating from `OS_Env`.
* **Performance Risks:** Minimal. Fetching from the OS environment and overriding from an in-memory dictionary operates in amortized $O(1)$ time. Bypassing evaluation for OS variables actively saves CPU cycles.
* **Opportunities:** This model provides mathematical predictability. Developers can write their `makeops.toml` files knowing that their explicit variable declarations represent an immutable source of truth, immune to unexpected host environment pollution.

## 4. References

**Internal Documentation:**
* [1] [ALG-002: Lazy Variable Substitution](./ALG-002-lazy-variable-substitution.md)
* [2] [ALG-003: Hierarchical Configuration Cascade](./ALG-003-configuration-cascade.md)
* [3] [PLAT-011: Text Encoding and Memory Safety](./PLAT-011-text-encoding-model.md)