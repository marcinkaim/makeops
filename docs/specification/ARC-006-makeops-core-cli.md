<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# ARC-006 MakeOps.Core.CLI Namespace Architecture

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `ARC-006` |
| **Status** | `APPROVED` |
| **Date** | 2026-05-03 |
| **Target Namespace** | `MakeOps.Core.CLI` |

## 1. Domain Definition & Purpose

* **Goal:** This domain serves as the dedicated Data-Oriented Design (DOD) Frontend for processing operating system command-line arguments (`argv`). It bridges the gap between raw OS strings and actionable domain structures, enabling the orchestrator to dynamically resolve user intents, target operations, and global configuration overrides in a secure, mathematically predictable manner.
* **Core Responsibility:** Manages Phases 1 through 4 of the Universal Processing Pipeline specifically for the Command Line Interface. It retrieves the argument array, lexically decomposes composite flags, parses them using strict POSIX conventions, and executes a Dual-Branch Normalization to split the data stream into Configuration overrides and Operational intents.

## 2. Boundaries & Constraints

* **Domain In-Scope:** POSIX-compliant `argv` array extraction, lexical decomposition of CLI flags (e.g., separating `--key=val`), Finite State Machine (FSM) grammar classification (distinguishing options from positional targets), and dual-branch IR event normalization.
* **Domain Out-of-Scope (Strict Bounds):** This namespace MUST NOT build Abstract Syntax Trees (AST) or rely on dynamic heap allocation for argument arrays. It MUST NOT apply the parsed configuration to the global state or execute any operational targets directly; its sole output is a stream of flat `Pipeline_Event` records passed back to the `MakeOps.App` orchestrators. It MUST NOT attempt complex shell expansions (e.g., globbing), as these are handled by the user's shell prior to application launch.

## 3. Traceability & Foundation

* **Implements Requirements:**
    * `REQ-003` (Execution Observability):
        * `F-003-001`: Fulfills the capability to accept operational targets and configuration flags directly from the `mko` command invocation.
        * `F-003-002`: Normalizes specific flags allowing users to control logging verbosity levels dynamically.
* **Applies Concepts:**
    * `MOD-002` (Universal 5-Phase Processing Pipeline): Implements the generic processing mechanism (Phases 1-4) without object-oriented state polymorphism, keeping memory $O(1)$.
    * `MOD-015` (CLI Interface and Argument Normalization): Dictates the FSM parsing rules, strict POSIX option conventions, and the distinct separation of tokens into the Config Branch and Command Branch (Intent Queue).
    * `MOD-009` (Formal Verification & Static Memory Foundations): Enforces strict byte-length checks on user-provided arguments against the `Max_Arg_Length` limit to eliminate buffer overflow vulnerabilities.

## 4. Architectural Topology

**Components (Package Blueprints):**

* `MakeOps.Core.CLI` (`DES-[XXX]`): The declarative root for the Command Line Interface domain. It defines CLI-specific tokens and `CLI_Syntax_Event` structures used to distinguish execution flags from positional target names. The design MUST be strictly declarative (`pragma Pure`) and contain no algorithmic state or subprograms.
* `MakeOps.Core.CLI.Reader` (`DES-[XXX]`): The Phase 1 (I/O) adapter responsible for system initialization. It safely retrieves the raw array of command-line arguments (`argv`) provided by the operating system upon execution. The design MUST safely map unprovable C-ABI argument pointers into bounded Ada strings while enforcing Absence of Runtime Errors (AoRE).
* `MakeOps.Core.CLI.Lexer` (`DES-[XXX]`): The Phase 2 scanner for initial argument processing. It splits combined or composite argument strings (e.g., correctly separating `--log-level=debug` into distinct key and value components). The design MUST operate as an $O(1)$ memory state machine without dynamically allocating new string buffers.
* `MakeOps.Core.CLI.Parser` (`DES-[XXX]`): The Phase 3 validator implementing POSIX rules. It classifies the tokens and recognizes the overarching input structure to differentiate options from targets, emitting `CLI_Syntax_Event`s. The design MUST be implemented as a non-recursive FSM that systematically flags domain violations (e.g., unrecognized syntax).
* `MakeOps.Core.CLI.Config_Normalizer` (`DES-[XXX]`): The Phase 4 (Configuration Branch) normalizer. It intercepts configuration-related flags (e.g., `--workdir`, `--log-level`) and normalizes them into property-based `Pipeline_Event`s. The design MUST rigorously bounds-check all extracted strings against global memory limits before emitting the Intermediate Representation (IR).
* `MakeOps.Core.CLI.Command_Normalizer` (`DES-[XXX]`): The Phase 4 (Operational Branch) normalizer. It intercepts positional arguments (e.g., `build`, `test`) and translates them into operation-targeting IR events. The design MUST correctly identify halting system intents (like `--help`) versus unresolved execution targets to ensure safe Orchestrator routing.

**Subsystems (Delegated Namespaces):**

* `None` (`N/A`): This namespace operates as a flat collection of pipeline components handling a specific data source, containing no delegated sub-branches.