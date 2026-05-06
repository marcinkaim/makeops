<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# ARC-007 MakeOps.Core.Env Namespace Architecture

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `ARC-007` |
| **Status** | `APPROVED` |
| **Date** | 2026-05-03 |
| **Target Namespace** | `MakeOps.Core.Env` |

## 1. Domain Definition & Purpose

* **Goal:** This domain serves as the dedicated Data-Oriented Design (DOD) Frontend for extracting and processing operating system environment variables. It ensures that dynamic configuration data provided by the host OS (such as CI/CD runner environments) is securely ingested, filtered, and structurally aligned with the universal Intermediate Representation (IR) without exposing the core engine to unpredictable native OS exceptions.
* **Core Responsibility:** Manages a streamlined variant of the Universal Processing Pipeline specifically optimized for environment variables. Since OS variables inherently possess a flat, key-value structure, this subsystem safely bypasses classical lexical parsing (Phases 2 and 3), focusing purely on Phase 1 (Data Extraction) and Phase 4 (IR Normalization and namespace routing).

## 2. Boundaries & Constraints

* **Domain In-Scope:** OS environment variable extraction via safe OS Facades, static buffer boundary checks, namespace prefix filtering (e.g., distinguishing `MKO_` global properties from project variables), and IR event generation.
* **Domain Out-of-Scope (Strict Bounds):** This namespace MUST NOT perform dynamic variable substitution (Lazy Interpolation); it only harvests the raw definitions. It MUST NOT evaluate or recursively parse `${...}` syntax within OS variables, strictly adhering to the Terminal-Value security policy. It MUST NOT invoke native Ada environment libraries (`Ada.Environment_Variables`) directly; all I/O MUST route through `MakeOps.Sys.Env`.

## 3. Traceability & Foundation

* **Implements Requirements:**
    * `REQ-004` (Global Tool Preferences):
        * `F-004-005`: Fulfills the requirement to support overriding configuration parameters via specific environment variables (e.g., `MKO_LOG_LEVEL`).
* **Applies Concepts:**
    * `MOD-002`: Universal 5-Phase Processing Pipeline - Implements Phase 1 (Reader) and Phase 4 (Normalizer), demonstrating the pipeline's architectural flexibility by safely omitting the Lexer and Parser phases for natively structured data.
    * `MOD-014`: Environment Variables & Shadowing Model - Dictates the strict namespace separation between global orchestrator settings and project-level parameters, as well as the anti-injection Terminal-Value rules.
    * `MOD-009`: Formal Verification & Static Memory Foundations - Enforces rigid bounds-checking against the `Max_Env_Var_Value_Length` limit prior to converting OS bytes into universal pipeline events.

## 4. Architectural Topology

**Components (Package Blueprints):**

* `MakeOps.Core.Env` (`DES-[XXX]`): The declarative root for the environment variable data source domain. It defines the specific internal state enumerations and lightweight transfer structures used during environment variable extraction. The design MUST be strictly declarative (`pragma Pure`) and contain no algorithmic state, ensuring a mathematical foundation for its child packages.
* `MakeOps.Core.Env.Reader` (`DES-[XXX]`): The Phase 1 (I/O) extraction adapter for the host environment. It utilizes the `MakeOps.Sys.Env` OS adapter to safely iterate over and extract variables from the operating system without triggering native Ada constraints. The design MUST implement strict Fallback/Fail-Fast loops to handle OS-level string truncations gracefully before passing raw data forward.
* `MakeOps.Core.Env.Normalizer` (`DES-[XXX]`): The Phase 4 Intermediate Representation (IR) generator. It directly filters relevant variables (e.g., segregating keys with the `MKO_` prefix) and instantly translates them into context-free `Pipeline_Event`s (IR). The design MUST perform rigorous byte-length validation against static limits before emitting the IR to prevent out-of-bounds memory corruptions in the subsequent Applier backends.

**Subsystems (Delegated Namespaces):**

* `None` (`N/A`): This namespace operates as a flat, specialized pipeline frontend and contains no delegated sub-branches.