<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# SCH-007 User Interaction Intent Gateway Schedule

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `SCH-007` |
| **Status** | `DRAFT` |
| **Date** | 2026-05-08 |
| **Target Stage** | Stage 7 |

## 1. Stage Context & Milestone

* **Objective & Rationale:** This stage implements the final classification layer of the user interface, situated in the `MakeOps.App.CLI` namespace. While Stage 4 handled the raw normalization of strings, Stage 7 transforms those normalized "Intent Branches" into concrete application actions. It separates "Halting Commands" (e.g., `--help`, `--version`, `--list-targets`) that exit immediately after execution from "Operational Targets" that require the full activation of the Semantic Backend developed in Stage 5.
* **Defining Milestone:** The User Interaction Gateway is fully implemented and integrated with the global application state. The milestone is reached when the `mko` binary can successfully distinguish between built-in system commands and project-specific operations. Success is verified when a call to a built-in command (e.g., `mko --version`) executes its logic and terminates with a success code without loading the project DAG, whereas a call to a project target correctly triggers the semantic backend hand-off.

## 2. Stage Prerequisites

* **Entry Gating:**
  * `SCH-000` through `SCH-006` MUST be `COMPLETED`, ensuring the existence of the configuration cascade and the project semantic backend.
  * `ARC-010` (MakeOps.App.CLI Namespace Architecture) MUST be `APPROVED`.
  * `MOD-001` (Master Orchestration Lifecycle) MUST be `APPROVED` to define the hand-off points between CLI and the Orchestrator.
  * `MOD-015` (CLI Interface and Argument Normalization) MUST be `APPROVED`.

## 3. Scope of Work (Execution Batches)

### Batch 1: Intent Loading & Classification
Implements the high-level logic that queries the CLI normalized events and maps them to the internal `Command_Type` enumeration.

* `MakeOps.App.CLI` (Ref: `ARC-010`) -> Target `DES-039`
* `MakeOps.App.CLI.Loader` (Ref: `ARC-010`) -> Target `DES-040`

### Batch 2: Built-in Command Execution
Implements the specialized executors for system-level intents that do not involve the project DAG.

* `MakeOps.App.CLI.Command` (Ref: `ARC-010`) -> Target `DES-041`
* `MakeOps.App.CLI.Command.Executor` (Ref: `ARC-010`) -> Target `DES-042` - *Depends on Batch 1*

## 4. Logistical & Integration Notes

* **Integration Strategy:**
  * The `Loader` MUST consult the `App_Config` record created in Stage 6 to determine if global flags (like `--dry-run` or `--force`) should modify the behavior of the identified commands.
  * Built-in commands like `--version` MUST be implemented to retrieve their metadata from the foundational `MakeOps` root package established in Stage 0.
* **Verification Notes:**
  * AUnit tests MUST verify the "Command Precedence" logic, ensuring that if both a built-in halting command (e.g., `--help`) and a project target are present, the halting command takes priority and prevents the project execution.