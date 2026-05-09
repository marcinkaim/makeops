<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# SCH-002 Universal Processing Pipeline Schedule

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `SCH-002` |
| **Status** | `DRAFT` |
| **Date** | 2026-05-08 |
| **Target Stage** | Stage 2 |

## 1. Stage Context & Milestone

* **Objective & Rationale:** This stage focuses on realizing the mathematical Data-Oriented Design (DOD) backbone of the MakeOps orchestration engine. By implementing the `Pipeline_Event` Intermediate Representation (IR) and the generic `Runner`, we establish the universal mechanism for the 5-Phase Processing Pipeline. This stage is prioritized because all subsequent data ingestion modules (TOML, CLI, OS Environment) must instantiate this generic pipeline to guarantee the Zero-AST memory constraints and Fail-Fast control flow.
* **Defining Milestone:** The `MakeOps.Core.Pipeline` and `MakeOps.Core.Pipeline.Runner` packages are fully designed and implemented. The milestone is reached when the generic Runner compiles successfully and an empirical AUnit test utilizing a mocked, dummy 5-phase instantiation proves that state transitions occur sequentially without dynamic heap allocations.

## 2. Stage Prerequisites

* **Entry Gating:**
  * `SCH-000` (Foundations and Identity) MUST be `COMPLETED`, ensuring the existence of core namespaces and the testing infrastructure.
  * `SCH-001` (OS Abstraction Layer Facade) MUST be `COMPLETED`, providing the verified system adapters required for safe file streaming and terminal interaction.
  * `ARC-002` (MakeOps.Core Namespace Architecture) MUST be `APPROVED`, establishing the normative structural layout for the data processing domain.
  * `MOD-002` (Universal 5-Phase Processing Pipeline) MUST be `APPROVED`, defining the theoretical requirements for the Zero-AST event-streaming architecture.

## 3. Scope of Work (Execution Batches)

### Batch 1: Intermediate Representation (IR)
Focuses on the purely declarative definitions of the universal pipeline events and spatial tracking coordinates.

* `MakeOps.Core.Pipeline` (Ref: `ARC-002`) -> Target `DES-016`

### Batch 2: Generic Pipeline Execution Engine
Focuses on the state-machine orchestration that pushes data from Phase 1 through Phase 5.

* `MakeOps.Core.Pipeline.Runner` (Ref: `ARC-002`) -> Target `DES-017` - *Depends on MakeOps.Core.Pipeline*

## 4. Logistical & Integration Notes

* **Integration Strategy:**
  * The `MakeOps.Core.Pipeline.Runner` MUST be implemented as an Ada `generic` package. This ensures compile-time monomorphization and eliminates dynamic dispatch (`access all ...'Class`), strictly adhering to the AoRE and memory models.
  * For testing purposes, the developers must create a set of local `Mock_Frontend` and `Mock_Backend` components within the AUnit test suite to instantiate the generic runner.
* **Verification Notes:**
  * `MakeOps.Core.Pipeline` MUST be mathematically proven as `pragma Pure` by GNATprove.
  * The empirical tests (`VER-017`) for the Runner must explicitly assert that a fatal domain error emitted by the mocked Phase 3 (Parser) immediately halts the pipeline without invoking Phase 4 or 5, verifying the Fail-Fast behavior.