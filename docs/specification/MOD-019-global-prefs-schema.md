<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# MOD-019 Global Preferences Schema Model

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `MOD-019` |
| **Status** | `APPROVED` |
| **Date** | 2026-04-24 |
| **Tags** | TOML, Schema, Preferences, Security, Separation of Concerns |

## 1. Definition & Context
The Global Preferences Schema Model defines the normative structure for user-level or system-wide configuration files (e.g., `~/.config/makeops/config.toml` or `/etc/makeops/config.toml`).

Unlike the Project Configuration (`MOD-018`), which defines the "What" (the operational graph), the Global Preferences file defines the "How" from the perspective of the environment and user experience. This model ensures that environmental overrides do not interfere with the deterministic logic of a project, enforcing a strict boundary between execution logic and environmental setup.

## 2. Theoretical Basis
This model is built on two fundamental principles of systems engineering:

### 2.1. Separation of Concerns (SoC)
As defined in `REQ-004`, logic and preference must be decoupled. A project should behave identically regardless of who runs it, unless explicitly directed by environmental preferences that do not change the DAG structure. By restricting the global schema to non-logic keys, we prevent "invisible" modifications to the build process that could lead to non-reproducible environments.

### 2.2. Principle of Least Privilege & Security
Global configuration files often reside in sensitive areas of the filesystem. Allowing them to define execution commands (`cmd`) or dependencies (`deps`) would create a vector for privilege escalation or malicious code injection. Therefore, the schema is designed to be "passive"—it only contains parameters for the MakeOps binary itself, never instructions for the shell.

## 3. Conceptual Model
The schema for Global Preferences is significantly more restrictive than the project-level dialect. It consists of a single structural block.

### 3.1. The `[preferences]` Table
All global settings must be contained within the `[preferences]` table.

* **`log_level` (Optional):**
    * **Purpose:** Controls the verbosity of the internal diagnostics engine.
    * **Allowed Values:** Must be one of exactly three string literals: `"error"`, `"info"`, or `"debug"`.
    * **Validation Rule:** Any other value must result in a deserialization error before the Orchestrator starts.
* **`project_config` (Optional):**
    * **Purpose:** Allows the user to specify a default filename for the project configuration (overriding the default `makeops.toml`).
    * **Value:** A string representing a relative or absolute path.

### 3.2. Domain Rules (Invariants)
* **Prohibition of Execution Logic:** Any presence of `[operations]` or `[environment]` sections in a global preferences file must be treated as a critical security violation, and the loader must immediately halt execution.
* **Security Hardening (The `allow_root` Block):** As a safety measure, the parameter `allow_root` (even if it were to be implemented in the future) is explicitly forbidden from being defined in a TOML file. This parameter must only be accepted as a CLI flag to ensure intentional, per-invocation bypass of safety checks.
* **String-Only Values:** Consistent with `MOD-013`, all values must be UTF-8 strings. Numbers (e.g., `1`) or Booleans (e.g., `true`) are not permitted.

## 4. Engineering Impact
The implementation of the Global Loader (`MakeOps.App.Config.Loader`) is constrained by this model.

* **Constraints:**
    * The parser must use a "Whitelisting" approach. Only keys defined in this document are allowed.
    * **Validation Phase:** The loader must perform an explicit check for forbidden sections (`[operations]`) before merging preferences with the project state.
* **Performance/Memory Risks:**
    * Since global preferences are loaded before the project CWD (Current Working Directory) is finalized, path resolution for `project_config` must be handled with care to avoid OS-level directory traversal vulnerabilities.
* **Opportunities:**
    * By strictly limiting the `log_level` to three specific strings, we can map these directly to an Ada enumerated type (`Log_Severity`) using a zero-allocation lookup table, satisfying our AoRE requirements.

## 5. References

**Internal Documentation:**
* [1] [REQ-004: Global Preferences](./REQ-004-global-preferences.md)
* [2] [MOD-012 Execution Context & Security Model](./MOD-012-execution-context-security-model.md)
* [3] [MOD-013: MakeOps TOML Dialect Model](./MOD-013-toml-dialect-model.md)
* [4] [MOD-018: Project Configuration Schema Model](./MOD-018-project-config-schema.md)

**External Literature:**
* [5] Saltzer, J. H., & Schroeder, M. D. (1975). *The Protection of Information in Computer Systems*. Proceedings of the IEEE. (Principle of Least Privilege).