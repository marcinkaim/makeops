<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# SCH-003 Configuration Frontend Pipelines Schedule

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `SCH-003` |
| **Status** | `APPROVED` |
| **Date** | 2026-05-08 |
| **Target Stage** | Stage 3 |

## 1. Stage Context & Milestone

* **Objective & Rationale:** This stage focuses on implementing the format-specific Frontends for configuration ingestion. We will realize the processing logic for both the host OS Environment variables and the specialized MakeOps TOML dialect. This stage is critical because it bridges the gap between raw system data and the universal Intermediate Representation (IR), enabling the subsequent semantic analysis of user project configurations.
* **Defining Milestone:** The TOML and OS Environment frontend packages are implemented and successfully instantiated via the generic Pipeline Runner. The milestone is reached when the system can lexically and syntactically validate a provided `makeops.toml` stream and extract host environment variables, correctly generating a sequence of context-free `Pipeline_Event` records verified by AUnit scenarios.

## 2. Stage Prerequisites

* **Entry Gating:**
  * `SCH-000` (Foundations and Identity) MUST be `COMPLETED`.
  * `SCH-001` (OS Abstraction Layer Facade) MUST be `COMPLETED`.
  * `SCH-002` (Universal Processing Pipeline) MUST be `COMPLETED`, providing the generic `Runner` and `Pipeline_Event` structures.
  * `ARC-005` (MakeOps.Core.TOML Namespace Architecture) MUST be `APPROVED`.
  * `ARC-007` (MakeOps.Core.Env Namespace Architecture) MUST be `APPROVED`.
  * `MOD-013` (MakeOps TOML Dialect Model) MUST be `APPROVED`.
  * `MOD-014` (Environment Variables & Shadowing Model) MUST be `APPROVED`.

## 3. Scope of Work (Execution Batches)

### Batch 1: OS Environment Frontend
Implements the streamlined pipeline for harvesting raw host environment variables without complex lexical parsing.

* `MakeOps.Core.Env` (Ref: `ARC-007`) -> Target `DES-018`
* `MakeOps.Core.Env.Reader` (Ref: `ARC-007`) -> Target `DES-019`
* `MakeOps.Core.Env.Normalizer` (Ref: `ARC-007`) -> Target `DES-020`

### Batch 2: TOML Configuration Frontend
Implements the full 4-phase frontend for lexical and syntactic validation of project configuration files.

* `MakeOps.Core.TOML` (Ref: `ARC-005`) -> Target `DES-021`
* `MakeOps.Core.TOML.Reader` & `MakeOps.Core.TOML.Lexer` (Ref: `ARC-005`) -> Target `DES-022`
* `MakeOps.Core.TOML.Parser` & `MakeOps.Core.TOML.Normalizer` (Ref: `ARC-005`) -> Target `DES-023` - *Depends on Lexer*

## 4. Logistical & Integration Notes

* **Integration Strategy:**
  * The TOML Lexer MUST strictly implement the $O(1)$ memory Finite State Machine (FSM) to satisfy the Deep Tech and AoRE principles.
  * The Environment Normalizer MUST enforce the Terminal-Value security policy, ensuring that OS variables are treated as raw byte buckets without recursive interpolation.
* **Verification Notes:**
  * Empirical AUnit tests for the TOML Parser MUST include edge-case scenarios for invalid TOML syntax and explicitly rejected native non-string types (e.g., booleans, integers) to verify dialect enforcement.
  * All Frontends MUST be verified to attach accurate `Line_Number` and `Column_Number` metadata to events to support the Zero-Allocation Diagnostic pattern.