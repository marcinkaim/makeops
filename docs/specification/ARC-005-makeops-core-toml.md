<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# ARC-005 MakeOps.Core.TOML Namespace Architecture

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `ARC-005` |
| **Status** | `APPROVED` |
| **Date** | 2026-05-03 |
| **Target Namespace** | `MakeOps.Core.TOML` |

## 1. Domain Definition & Purpose

* **Goal:** This domain serves as the dedicated Data-Oriented Design (DOD) Frontend for ingesting TOML configuration files. It acts as the mechanical translator that reads raw text streams from the host operating system and converts them into the universal, flat Intermediate Representation (IR) understood by the core orchestrator.
* **Core Responsibility:** Manages the first four phases of the Universal Processing Pipeline specifically for the TOML format. It safely reads file chunks, lexes raw strings into tokens, validates the token stream against the strict MakeOps TOML dialect, and flattens hierarchical tables into agnostic `Pipeline_Event` records.

## 2. Boundaries & Constraints

* **Domain In-Scope:** Lexical scanning of UTF-8 byte buckets, MakeOps TOML Dialect grammar validation (String-Only rules), spatial coordinate tracking (lines and columns), and IR event normalization.
* **Domain Out-of-Scope (Strict Bounds):** This namespace MUST NOT construct dynamic Abstract Syntax Trees (AST) or allocate heap memory for parsed data. It MUST NOT evaluate the semantic meaning of the configuration (e.g., verifying if an operation exists), which is delegated to Backends. It MUST NOT perform direct OS file I/O operations without using the `MakeOps.Sys.File_Stream` facade.

## 3. Traceability & Foundation

* **Implements Requirements:**
    * `REQ-001` (Project Configuration Handling):
        * `F-001-002`: Fulfills the requirement to parse discrete operations and environments from structured text sections.
        * `NFR-001-001`: Enforces strict parsing according to the highly restricted MakeOps TOML Dialect, explicitly rejecting complex data types.
* **Applies Concepts:**
    * `MOD-002`: Universal 5-Phase Processing Pipeline - Implements Phases 1 through 4 (Reader, Lexer, Parser, Normalizer) of the Zero-AST architecture.
    * `MOD-013`: MakeOps TOML Dialect Model - Constrains the Parser to a strict, String-Only finite state machine (FSM) to maintain $O(1)$ memory complexity.
    * `MOD-017`: Zero-Allocation Diagnostic Pattern - Requires the Lexer and Parser to attach accurate spatial coordinates (`Line_Number`, `Column_Number`) to every event for contextual error rendering.

## 4. Architectural Topology

**Components (Package Blueprints):**

* `MakeOps.Core.TOML` (`DES-[XXX]`): The declarative root for the TOML parsing domain. It defines internal transfer structures such as lexical `Token` enumerations and `TOML_Syntax_Event` records passed between internal parsing phases. The design MUST be strictly declarative and state-free to serve as a pure communication baseline for the child packages.
* `MakeOps.Core.TOML.Reader` (`DES-[XXX]`): The Phase 1 (I/O) extraction adapter. It safely interfaces with the `MakeOps.Sys.File_Stream` adapter to pull configuration files line-by-line without throwing native Ada exceptions. The design MUST manage bounded string buffers and accurately track the current line number to feed the subsequent Lexer phase.
* `MakeOps.Core.TOML.Lexer` (`DES-[XXX]`): The Phase 2 scanner responsible for initial text segmentation. It operates as a mathematically pure, $O(1)$ memory state machine that splits raw string buffers into semantic Tokens (e.g., identifying brackets, equals signs, and string literals). The design MUST strictly extract spatial coordinates for every token while treating the text payloads as opaque byte buckets to maintain UTF-8 safety.
* `MakeOps.Core.TOML.Parser` (`DES-[XXX]`): The Phase 3 validator enforcing dialect rules. It validates the incoming Token stream against the strictly restricted MakeOps TOML grammar, immediately emitting safe `TOML_Syntax_Event` records. The design MUST be implemented as a non-recursive FSM that rejects integers, booleans, and nested tables to fulfill the Fail-Fast and AoRE constraints.
* `MakeOps.Core.TOML.Normalizer` (`DES-[XXX]`): The Phase 4 Intermediate Representation (IR) generator. It tracks localized micro-states (like the current `[operations.name]` table context) and flattens the hierarchical parser events into universal, context-free `Pipeline_Event`s. The design MUST rigorously bounds-check all extracted string lengths against system limits before emitting the final IR to prevent downstream buffer overflows.

**Subsystems (Delegated Namespaces):**

* `None` (`N/A`): This namespace operates as a flat collection of pipeline components and contains no further delegated sub-branches.