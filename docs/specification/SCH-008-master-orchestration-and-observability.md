<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# SCH-008 Master Orchestration and Observability Schedule

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `SCH-008` |
| **Status** | `DRAFT` |
| **Date** | 2026-05-08 |
| **Target Stage** | Stage 8 |

## 1. Stage Context & Milestone

* **Objective & Rationale:** This final stage of realization implements the master control loop and the observability framework for the MakeOps engine. It realizes the 5-step master algorithm (Load, Cascade, Resolve, Execute, Teardown) within the `Orchestrator` and establishes a high-performance, Zero-Allocation logging and diagnostic infrastructure. This stage is the final integration point where the binary's entry point (`Main`) is assembled, ensuring that the tool adheres to the specified observability taxonomy and exit code standards.
* **Defining Milestone:** The master orchestration and observability layers are fully operational. The milestone is reached when the `mko` executable can successfully perform a full "End-to-End" run—from reading a configuration file and CLI flags to executing a DAG of processes and emitting color-coded, context-aware logs—all while maintaining the mathematical proof of zero heap allocations during the execution phase.

## 2. Stage Prerequisites

* **Entry Gating:**
  * `SCH-000` through `SCH-007` MUST be `COMPLETED`, ensuring all core, sys, and frontend sub-systems are fully verified.
  * `ARC-003` (MakeOps.App Namespace Architecture) MUST be `APPROVED`.
  * `MOD-016` (Observability Taxonomy and Style) MUST be `APPROVED`.
  * `MOD-017` (Zero-Allocation Diagnostics) MUST be `APPROVED`.
  * `REQ-003` (Execution Observability) MUST be `APPROVED`.

## 3. Scope of Work (Execution Batches)

### Batch 1: Observability & Diagnostics
Implements the static-memory logging infrastructure and the diagnostic event emission system.

* `MakeOps.App.Logger` (Ref: `ARC-003`) -> Target `DES-043`
* `MakeOps.App.Diagnostics` (Ref: `ARC-003`) -> Target `DES-044`

### Batch 2: Master Lifecycle & Entry Point
Implements the top-level orchestrator that manages sub-system hand-offs and the final binary assembly.

* `MakeOps.App.Orchestrator` (Ref: `ARC-003`) -> Target `DES-045`
* `MakeOps.App.Main` (Ref: `ARC-003`) -> Target `DES-046` - *Depends on Batch 1*

## 4. Logistical & Integration Notes

* **Integration Strategy:**
  * The `Main` procedure MUST be kept minimal, acting only as a thin wrapper that invokes the `Orchestrator` and handles any unhandled global exceptions at the OS boundary to prevent core dumps.
  * `MakeOps.App.Logger` MUST integrate with `MakeOps.Sys.Terminal` to ensure that output stream selection (stdout vs. stderr) and color escaping are handled through the verified OS abstraction layer.
* **Verification Notes:**
  * Final End-to-End (E2E) integration tests MUST be conducted using the `make test` facade, verifying the tool's behavior against a suite of "Golden Master" `makeops.toml` files and expected CLI outputs.
  * Verification of Zero-Allocation constraints MUST be performed via static analysis of the binary and GNATprove Flow Analysis on the `Orchestrator`'s execution path.