<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# SCH-000 Foundations and Identity Schedule

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `SCH-000` |
| **Status** | `COMPLETED` |
| **Date** | 2026-05-08 |
| **Target Stage** | Stage 0 |

## 1. Stage Context & Milestone

* **Objective & Rationale:** This stage establishes the absolute foundational namespaces and structural layout for the MakeOps orchestration engine. Before any complex parsing or system bindings can be developed, the project requires a mathematically pure root identity, common status enumerations, and a strictly isolated empirical testing infrastructure. By defining these core packages upfront, we establish the global constraints (`pragma Pure`, standard POSIX exit codes, and `Log_Level` mappings) that all subsequent stages will inherit and rely upon to guarantee the Absence of Runtime Errors (AoRE).
* **Defining Milestone:** The repository successfully compiles the global base packages using GPRbuild. The SPARK prover (GNATprove) mathematically guarantees zero state or side-effects for all `pragma Pure` root components. Furthermore, the standalone `test_runner` executable is successfully built and executes a baseline sanity test suite using the AUnit framework, proving the physical isolation of the testing environment from the production binary.

## 2. Stage Prerequisites

* **Entry Gating:**
  * Macro-Phase I (Analysis) MUST be `APPROVED`. All foundational `REQ` (Requirements), `MOD` (Conceptual Models), and `ARC` (Architecture) documents defining the global system constraints and root namespaces MUST be in the `APPROVED` state to ensure a stable theoretical baseline before any physical realization begins.

## 3. Scope of Work (Execution Batches)

### Batch 1: Root Identity & Domain Types
This batch focuses on purely declarative packages that establish the project's baseline constants and mathematical types without requiring any complex implementation bodies.

* `MakeOps` (Ref: `ARC-000`) -> Target `DES-000`
* `MakeOps.Core` (Ref: `ARC-002`) -> Target `DES-002`
* `MakeOps.Sys` (Ref: `ARC-001`) -> Target `DES-003`
* `MakeOps.App` (Ref: `ARC-003`) -> Target `DES-001`

### Batch 2: Empirical Verification Infrastructure
This batch focuses on setting up the AUnit testing framework, which operates outside the strict SPARK constraints but is necessary for the subsequent empirical validation of unprovable OS boundaries.

* `MakeOps.Tests` (Ref: `ARC-004`) -> Target `DES-004` - *Depends on Batch 1 Components*

## 4. Logistical & Integration Notes

* **Integration Strategy:**
  * The GPRbuild project files (`makeops.gpr`, `makeops_app.gpr`, and `makeops_tests.gpr`) must be properly configured to isolate the compilation of the `test_runner` from the main `mko` executable.
  * Packages in Batch 1 must be strictly limited to specification files (`.ads`). Do not generate implementation bodies (`.adb`) for these packages, as they merely expose static types and constants.
* **Verification Notes:**
  * SPARK verification for Batch 1 components is trivial but mandatory. Ensure the prover is configured to run at the Silver Level to validate the `pragma Pure` and `pragma Preelaborate` constraints before closing the milestone.
  * The empirical verification (`VER-004`) for the test suite is an integration sanity check ensuring the AUnit runner returns a standard `0` exit code.