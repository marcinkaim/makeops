<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# MOD-003 Hierarchical Configuration Cascade

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `MOD-003` |
| **Status** | `APPROVED` |
| **Date** | 2026-04-06 |
| **Tags** | Configuration, Cascade, Bottom-Up, CLI, Pipeline, Shadowing, Observability |

## 1. Definition & Context
The Hierarchical Configuration Cascade defines the deterministic strategy used by the `MakeOps.App.Config.Loader` and `MakeOps.App.CLI.Loader` to resolve the final runtime preferences of the MakeOps tool.

In the context of the MakeOps architecture, the tool must balance strict determinism for project execution with flexible quality-of-life overrides for the user (e.g., globally enforcing a quiet log level in a CI/CD environment without modifying the project repository). This model establishes how disparate data sources—ranging from static TOML files to dynamic OS argument arrays—are safely ingested via the Universal 5-Phase Pipeline (`MOD-002`) and mathematically fused into a single, cohesive `App_Config` record.

## 2. Theoretical Basis
The cascade relies on the mathematical concept of Monoid-like partial structures and orthogonal data stream normalization.

### 2.1. Partial Structures and Overlays (Shadowing)
When aggregating configurations from multiple tiers, the system cannot assume that every tier provides a complete set of instructions. Most layers (like environment variables or CLI flags) only provide a sparse subset of overrides. Mathematically, these sparse layers are represented as Partial Structures, where each field can explicitly hold a `Not_Set` (or `None`) state. Shadowing is the strict hierarchical rule dictating that a defined value at a higher priority level completely eclipses any value defined at a lower level.

### 2.2. Pipeline-Based CLI Ingestion
Instead of using a monolithic ad-hoc loop to process Command Line Arguments (`argv`), the operating system's argument array is treated purely as another raw data stream. By applying the Data-Oriented Design (DOD) principles of the 5-Phase Pipeline, the raw argument strings are lexically split, syntactically grouped, and normalized into the universal Intermediate Representation (IR) before any domain logic evaluates them.

## 3. Conceptual Model
This model defines the merging heuristic, the handling of side-effects (observability), and the specific 5-Phase Pipeline implementation for CLI arguments.

### 3.1. The 5-Level Cascade (Data Flow)
The cascade aggregates partial configurations across a strict 5-level precedence hierarchy (from lowest to highest authority):
1. **Hardcoded Defaults:** The baseline layer. Implicitly defines complete fallbacks (e.g., `Log_Level := Info`, `Project_Config := "makeops.toml"`, `Allow_Root := False`).
2. **System-wide Configuration:** Fetched from `/etc/makeops/config.toml` (via TOML Pipeline).
3. **User-specific Configuration:** Fetched from `$XDG_CONFIG_HOME/makeops/config.toml` (via TOML Pipeline).
4. **Environment Variables:** Queried from the OS (e.g., `MKO_LOG_LEVEL`) (via Env Pipeline).
5. **CLI Flags:** Extracted directly from the execution command (e.g., `--log-level debug`) (via CLI Pipeline).

### 3.2. Bottom-Up Merging Heuristic
The `App.Config.Loader` employs a Bottom-Up mutation strategy. It initializes a complete base record using Level 1. It then sequentially iterates through Levels 2 to 5. For each field in the current overlaying layer, an overwrite operation occurs *if and only if* the overlaying field is not explicitly `Not_Set`. This guarantees that the final configuration record is mathematically complete and free of missing data.

### 3.3. Deferred Observability (Domain Rule)
A critical feature of the cascade is its bifurcation in error handling:
* **Fail-Fast (Structural):** If a TOML file contains malformed syntax, or an invalid CLI flag is passed, the pipeline immediately aborts.
* **Deferred Observability (Environmental):** If optional files (Levels 2 or 3) are simply missing from the file system, the system MUST NOT crash. However, because the final `Log_Level` is unknown until Level 5 is merged, the Loader buffers any non-critical I/O warnings into an internal list. This buffer is only flushed to standard error (`stderr`) at the very end of the cascade sequence, and only if the finalized `Log_Level` permits warnings to be displayed.

### 3.4. The CLI 5-Phase Ingestion Pipeline
The `App.CLI.Loader` instantiates the Universal Pipeline (`MOD-002`) to process the `argv` array safely, bridging the gap between OS strings and actionable domain structures:
* **Phase 1 (Reader):** Retrieves the `argv` array from the OS boundary.
* **Phase 2 (Lexer):** Splits composite argument strings (e.g., separating `--log-level=debug` into `--log-level` and `debug` tokens).
* **Phase 3 (Parser):** A minimal grammatical state machine that associates flags with their subsequent values, differentiating them from positional arguments. It emits `CLI_Syntax_Event`s (e.g., `Flag_With_Value`, `Positional_Argument`, `Standalone_Flag`).
* **Phase 4 (Normalizers):** The stream branches into two specialized IR generators:
    * `Config_Normalizer`: Converts configuration flags (`--workdir`, `--log-level`) into universal `Property_Event`s.
    * `Command_Normalizer`: Converts positional arguments and halting flags (`--help`, `--version`) into universal `Operation_Event`s.
* **Phase 5 (Appliers / Backends):**
    * `MakeOps.App.Config.Applier`: Consumes `Property_Event`s to populate the Level 5 CLI overlay for the cascade.
    * `CLI_Intent_Applier` (Internal to the Loader): Consumes `Operation_Event`s to populate the final `Target_Operations` list and determine the overriding `System_Action`.

## 4. Engineering Impact

* **Constraints:** The implementation MUST utilize Ada's variant records or explicit enumerations to safely represent the `Not_Set` state in partial configuration structures. The CLI parsing MUST strictly adhere to the 5-phase boundaries, decoupling string manipulation from list building.
* **Performance/Memory Risks:** Evaluating a maximum of two lightweight TOML files and passing the `argv` array through the static 5-phase pipeline introduces negligible, $O(N)$ memory overhead bounded strictly by OS limits.
* **Opportunities:** By forcing CLI argument parsing through the same generic pipeline as TOML files, the architecture becomes highly uniform. The core cascade merging logic (`Bottom-Up Merging`) remains completely blind to where the partial configurations came from, allowing for exhaustive, deterministic unit testing of the precedence rules purely in memory.

## 5. References

**Internal Documentation:**
* [1] [MOD-001: Master Orchestration Lifecycle](./MOD-001-master-orchestration-lifecycle.md)
* [2] [MOD-002: Universal 5-Phase Processing Pipeline](./MOD-002-universal-processing-pipeline.md)
* [3] [REQ-004: Global Tool Preferences](./REQ-004-global-preferences.md)

**External Literature:**
* [4] [The Twelve-Factor App (Section III: Config - Store config in the environment)](https://12factor.net/config)
* [5] [POSIX.1-2017 - IEEE Std 1003.1: Base Definitions (Chapter 8: Environment Variables)](https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap08.html)