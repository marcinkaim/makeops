<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# SCH-001 OS Abstraction Layer Facade Schedule

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `SCH-001` |
| **Status** | `COMPLETED` |
| **Date** | 2026-05-08 |
| **Target Stage** | Stage 1 |

## 1. Stage Context & Milestone

* **Objective & Rationale:** This stage focuses on building the protective boundary between the deterministic Ada/SPARK core and the unpredictable Linux/POSIX environment. By implementing safe, exception-free "Thick Wrappers" around volatile system calls, we eliminate native Ada exceptions (like `Name_Error` or `Device_Error`) and replace them with SPARK-verified variant records. This foundational work is critical for all subsequent orchestration and I/O tasks, ensuring that OS-level failures result in graceful degradation rather than application crashes.
* **Defining Milestone:** All OS Facade packages are fully realized and verified. The mathematical Absence of Runtime Errors (AoRE) is proven for all public specifications via GNATprove. The empirical validation suite in AUnit demonstrates successful interaction with the host filesystem, environment variables, and process lifecycle management, providing a stable platform for the 5-Phase Processing Pipeline.

## 2. Stage Prerequisites

* **Entry Gating:**
  * `SCH-000` (Foundations and Identity) MUST be `COMPLETED`, ensuring that the root namespaces and testing infrastructure are physically present and verified.
  * `ARC-001` (MakeOps.Sys Namespace Architecture) MUST be `APPROVED`, providing the normative structural map for the OS Facade layer.

## 3. Scope of Work (Execution Batches)

### Batch 1: Core System Services
This batch implements the non-process-related OS adapters required for configuration loading and system identity verification.

* `MakeOps.Sys.Env` (Ref: `ARC-001`) -> Target `DES-005`
* `MakeOps.Sys.FS` (Ref: `ARC-001`) -> Target `DES-006`
* `MakeOps.Sys.FS.OS_Bindings` (Ref: `ARC-001`) -> Target `DES-007`
* `MakeOps.Sys.Terminal` (Ref: `ARC-001`) -> Target `DES-010`
* `MakeOps.Sys.Identity` (Ref: `ARC-001`) -> Target `DES-012`
* `MakeOps.Sys.Identity.OS_Bindings` (Ref: `ARC-001`) -> Target `DES-013`
* `MakeOps.Sys.Time` (Ref: `ARC-001`) -> Target `DES-014`

### Batch 2: Process & Stream Management
This batch implements advanced POSIX interactions for process spawning and line-by-line file streaming.

* `MakeOps.Sys.Processes` (Ref: `ARC-001`) -> Target `DES-008`
* `MakeOps.Sys.Processes.OS_Bindings` (Ref: `ARC-001`) -> Target `DES-009`
* `MakeOps.Sys.Signals` (Ref: `ARC-001`) -> Target `DES-011`
* `MakeOps.Sys.File_Stream` (Ref: `ARC-001`) -> Target `DES-015`

## 4. Logistical & Integration Notes

* **Integration Strategy:**
  * Bodies (`.adb`) of all OS Facades MUST use `pragma SPARK_Mode (Off)` to encapsulate unprovable C-ABI bindings and native Ada exceptions.
  * All public interfaces (`.ads`) MUST remain `pragma SPARK_Mode (On)` to provide verified contracts to the core engine.
* **Verification Notes:**
  * Dynamic tests for `MakeOps.Sys.Processes` require careful handling of child process termination and stream cleanup in the AUnit environment to prevent orphaned processes during test runs.