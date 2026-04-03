<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# MODEL-001 5-Phase Orchestration Pipeline

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `MODEL-001` |
| **Status** | `APPROVED` |
| **Date** | 2026-04-02 |
| **Category** | Model |
| **Tags** | Data-Oriented Design, Pipeline, Frontend, Backend, Compiler Architecture, Zero-AST |

## 1. Definition & Context
The 5-Phase Orchestration Pipeline is the foundational data-processing architecture for the MakeOps configuration and input orchestration engine. It uses a strict Data-Oriented Design (DOD) approach, encompassing both configuration property updates and operational command execution.

Inspired by modern compiler architectures (such as LLVM), this model unifies the ingestion of configuration data from wildly different physical sources (TOML files, Command Line Arguments, Environment Variables) into a single, predictable flow. It strictly separates the extraction of data (Frontend) from the semantic application of that data (Backend) using a flat Intermediate Representation (IR), ensuring 100% compatibility with SPARK memory ownership rules and the Zero-AST paradigm.

## 2. Theoretical Basis
The model dictates that any input processed by the system must flow through a linear, 5-stage pipeline instantiated via Ada Generics. This eliminates polymorphic dispatch (`access all ...'Class`) and heap allocation, moving all interface resolution to compile-time monomorphization.

### 2.1. The Intermediate Representation (IR)
The linchpin of the pipeline is the use of flat, strictly bounded records as the universal language between Phase 4 and Phase 5. Depending on the intent, the pipeline emits:
* **`Property_Event`**: For configuration. Whether read from a TOML file or a CLI flag, it is normalized into a record containing a `Namespace`, `Key`, and `Value`.
* **`Operation_Event`**: For commands. It captures operational intent (e.g., `mko build`) and packages it for the execution engine.

### 2.2. The Frontend (Data Extraction & Normalization)
The Frontend is responsible for reading source material and translating it into the IR. It consists of the first four phases:
* **Phase 1: Reader (I/O Boundary)** - The only stateful phase. It interacts with the OS to fetch raw bytes or strings (e.g., reading a file stream, fetching `argv`, querying POSIX environment variables).
* **Phase 2: Lexer (Scanner)** - A purely mathematical state machine that groups raw characters into spatial Tokens (e.g., identifying strings, equals signs, or brackets). 
* **Phase 3: Parser (Grammar FSM)** - Validates the arrangement of Tokens against a format-specific grammar (e.g., TOML Dialect). It emits format-specific structural events.
* **Phase 4: Normalizer (IR Generator)** - Tracks localized micro-states (like the current TOML table/namespace) and flattens the structural events into a specific target IR. Instead of a single monolithic router, the architecture employs specialized Normalizers dedicated to distinct event types. For instance, the CLI frontend utilizes a dedicated `Config_Normalizer` to process syntax flags into `Property_Event`s, and a completely separate `Command_Normalizer` to translate positional arguments into `Operation_Event`s.

*Note: Depending on the complexity of the source, Phases 2 and 3 can be virtualized or bypassed (e.g., Environment Variables map almost directly from Phase 1 to Phase 4).*

### 2.3. The Backend (Semantic Application)
The Backend represents the domain logic. It is completely agnostic to the origin of the data.
* **Phase 5: Applier / Target** - Receives the normalized events and validates them against domain rules.
    * For **`Property_Event`**: The Applier verifies the data and writes it into the final, static destination record (e.g., `App_Config`).
    * For **`Operation_Event`**: The event is routed to the **Execution Engine**, which orchestrates the requested tasks.
    Any semantic violation triggers an immediate Fail-Fast halt of the entire pipeline.

## 3. Engineering Impact
This compilation-inspired model profoundly shapes the MakeOps codebase:

* **Constraints:** All inter-phase communication must occur via statically sized, flat records. No phase is permitted to allocate dynamic trees or maps to represent the configuration hierarchy. 
* **Performance Risks:** None. By eliminating dynamic dispatch and heap memory (`new`), the pipeline guarantees cache-friendly, O(1) memory complexity operations. Monomorphization via Ada Generics allows the compiler to heavily inline the pipeline loop.
* **Opportunities:** The absolute decoupling of Frontends and Backends yields orthogonal scalability. Adding a new configuration target (a new Backend) instantly supports TOML, CLI, and Env inputs for free. Similarly, adding a new data source format requires writing only a Frontend, which instantly becomes compatible with all existing MakeOps configurations. Furthermore, the absence of pointers restores the ability to mark the core processing Finite State Machines with `pragma Pure`, satisfying the strictest SPARK verification tiers.

## 4. References

**Internal Documentation:**
* [1] [MODEL-002: Zero-Allocation Diagnostic Pattern](./MODEL-002-zero-allocation-diagnostics.md)
* [2] [PLAT-013: MakeOps TOML Dialect and Grammar Constraints](./PLAT-013-makeops-toml-dialect.md)