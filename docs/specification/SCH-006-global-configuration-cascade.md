<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# SCH-006 Global Configuration Cascade Schedule

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `SCH-006` |
| **Status** | `APPROVED` |
| **Date** | 2026-05-08 |
| **Target Stage** | Stage 6 |

## 1. Stage Context & Milestone

* **Objective & Rationale:** This stage focuses on realizing the global application settings mechanism, strictly adhering to the Bottom-Up override hierarchy. It synthesizes inputs from system-wide files (`/etc/makeops/`), user-specific directories (`~/.config/makeops/`), environment variables, and immediate CLI flags into a single, cohesive `App_Config` state. This stage is positioned here because it requires the fully functional OS, Env, and CLI frontends (developed in Stages 1, 3, and 4) to harvest the necessary data securely.
* **Defining Milestone:** The global configuration cascade is implemented and verified. The milestone is reached when the application can successfully parse multiple conflicting configuration sources and mathematically prove (via AUnit tests) that higher-priority sources (e.g., CLI flags) correctly override lower-priority sources (e.g., global TOML files) without dynamic memory allocation or side effects.

## 2. Stage Prerequisites

* **Entry Gating:**
  * `SCH-000` through `SCH-005` MUST be `COMPLETED` to ensure that all foundational parsing pipelines, OS abstractions, and semantic engines are fully operational.
  * `ARC-009` (MakeOps.App.Config Namespace Architecture) MUST be `APPROVED`.
  * `REQ-004` (Global Preferences) MUST be `APPROVED`.
  * `MOD-003` (Hierarchical Configuration Cascade) MUST be `APPROVED`.
  * `MOD-019` (Global Preferences Schema) MUST be `APPROVED`.

## 3. Scope of Work (Execution Batches)

### Batch 1: Application State & Loader
Implements the static definition of the application configuration record and the logic required to query the OS for standard configuration paths.

* `MakeOps.App.Config` (Ref: `ARC-009`) -> Target `DES-036`
* `MakeOps.App.Config.Loader` (Ref: `ARC-009`) -> Target `DES-037`

### Batch 2: Cascade Application Engine
Implements the deterministic merging logic that applies the gathered configuration layers onto the base `App_Config` record.

* `MakeOps.App.Config.Applier` (Ref: `ARC-009`) -> Target `DES-038` - *Depends on Batch 1*

## 4. Logistical & Integration Notes

* **Integration Strategy:**
  * The `Loader` MUST use the verified `MakeOps.Sys.FS` and `MakeOps.Sys.Identity` boundaries to dynamically, yet securely, construct paths for `$HOME/.config/` and `/etc/`.
  * The merging logic inside the `Applier` MUST be `pragma Pure` or strictly side-effect free, relying only on passed-in IR events and returning a modified record.
* **Verification Notes:**
  * The AUnit testing environment MUST isolate the OS filesystem to prevent the host machine's actual `~/.config/makeops/` files from interfering with the cascade test results. Mocked configuration files must be generated in a temporary workspace before test execution.