<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# SCH-004 CLI Frontend and Normalization Schedule

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `SCH-004` |
| **Status** | `APPROVED` |
| **Date** | 2026-05-08 |
| **Target Stage** | Stage 4 |

## 1. Stage Context & Milestone

* **Objective & Rationale:** This stage focuses on realizing the Command Line Interface (CLI) as a primary data source for the orchestration engine. By instantiating the 5-Phase Processing Pipeline for the `mko` executable's arguments, we ensure that raw OS `argv` strings are securely normalized into actionable domain intents and configuration overrides. This stage is essential for establishing the tool's interaction gateway, separating "Halting" system commands from "Execution" project targets while strictly enforcing POSIX utility conventions.
* **Defining Milestone:** The CLI frontend components are fully implemented and integrated with the generic Pipeline Runner. The milestone is reached when the system successfully parses complex command-line inputs (e.g., `--log-level=debug --workdir=./dev build test`) and produces a validated stream of `Pipeline_Event` records, categorized into the Config Branch and the Intent Branch, as verified by comprehensive AUnit scenarios.

## 2. Stage Prerequisites

* **Entry Gating:**
  * `SCH-000` (Foundations and Identity) MUST be `COMPLETED`.
  * `SCH-001` (OS Abstraction Layer Facade) MUST be `COMPLETED`.
  * `SCH-002` (Universal Processing Pipeline) MUST be `COMPLETED`, providing the generic `Runner` and IR infrastructure.
  * `ARC-006` (MakeOps.Core.CLI Namespace Architecture) MUST be `APPROVED`.
  * `MOD-015` (CLI Interface and Argument Normalization) MUST be `APPROVED`.
  * `MOD-009` (Formal Verification & Static Memory Foundations) MUST be `APPROVED` to guide argument length validation.

## 3. Scope of Work (Execution Batches)

### Batch 1: CLI Data Acquisition & Scanning
Implements the retrieval of the OS `argv` array and the lexical decomposition of composite flags.

* `MakeOps.Core.CLI` (Ref: `ARC-006`) -> Target `DES-024`
* `MakeOps.Core.CLI.Reader` (Ref: `ARC-006`) -> Target `DES-025`
* `MakeOps.Core.CLI.Lexer` (Ref: `ARC-006`) -> Target `DES-026`

### Batch 2: Grammar Enforcement & Normalization
Implements the POSIX-compliant FSM parser and the dual-branch IR generators for configuration and intents.

* `MakeOps.Core.CLI.Parser` (Ref: `ARC-006`) -> Target `DES-027`
* `MakeOps.Core.CLI.Config_Normalizer` (Ref: `ARC-006`) -> Target `DES-028`
* `MakeOps.Core.CLI.Command_Normalizer` (Ref: `ARC-006`) -> Target `DES-029`

## 4. Logistical & Integration Notes

* **Integration Strategy:**
  * The CLI Reader MUST safely interface with the OS boundary to retrieve `argv` without assumptions about array length, mapping C-style pointers to bounded Ada strings.
  * The Normalizers MUST perform immediate byte-length validation against the `Max_Arg_Length` limit (1024 bytes) to prevent buffer overflow vulnerabilities.
* **Verification Notes:**
  * Empirical AUnit tests MUST verify the "Empty Target Heuristic," ensuring that invoking `mko` without arguments correctly triggers a help-intent.
  * Tests MUST explicitly validate the decomposition of composite flags (e.g., `--key=val`) into discrete IR events.