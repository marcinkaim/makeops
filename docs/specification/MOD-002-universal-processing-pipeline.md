<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# MOD-002 Universal 5-Phase Processing Pipeline

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `MOD-002` |
| **Status** | `APPROVED` |
| **Date** | 2026-04-06 |
| **Tags** | Data-Oriented Design, DOD, Pipeline, Compiler Architecture, Zero-AST, IR |

## 1. Definition & Context
The Universal 5-Phase Processing Pipeline is the foundational data-processing architecture for the MakeOps configuration and input orchestration engine. It establishes a strictly mechanical, predictable flow for all incoming data.

Inspired by modern compiler architectures (such as LLVM), this model unifies the ingestion of configuration data from wildly different physical sources (TOML files, Command Line Arguments, Environment Variables) into a single, predictable flow. In the context of the MakeOps architecture, it acts as the universal adapter that decouples the act of reading text from the act of understanding it, ensuring absolute compatibility with the strict memory ownership rules of SPARK.

## 2. Theoretical Basis
The pipeline is built upon the principles of Data-Oriented Design (DOD) and compiler translation theory, explicitly rejecting object-oriented state polymorphism.

### 2.1. The Frontend / Backend Split (Compiler Architecture)
In traditional compiler design, writing an $M \times N$ matrix of parsers and code generators is highly inefficient. The solution is an Intermediate Representation (IR). 
* **Frontends** are solely responsible for understanding a specific source format (e.g., C++, Rust, or in our case: TOML, CLI) and translating it into a common IR.
* **Backends** are solely responsible for taking that IR and turning it into a target outcome (e.g., x86 assembly, or in our case: `Project_Config` records).
By strictly separating the extraction of data (Frontend) from the semantic application of that data (Backend) using a flat Intermediate Representation (IR), we reduce the architectural complexity from $M \times N$ to $M + N$.

### 2.2. The Zero-AST Paradigm
Standard parsing algorithms dynamically allocate an Abstract Syntax Tree (AST) in heap memory to represent the hierarchical structure of a file. Because MakeOps operates under the strict Static Memory Model, dynamic pointers and heap allocations are forbidden to guarantee the Absence of Runtime Errors (AoRE). The pipeline bypasses the intermediate AST entirely. Instead of building a tree, it streams data linearly, translating tokens directly into flat IR events and immediately applying them to the final target structures.

## 3. Conceptual Model
The model enforces that any input processed by the system must flow through a linear, 5-stage pipeline instantiated via Ada Generics. 

### 3.1. The Intermediate Representation (IR)
The universal language of the pipeline is a flat, strictly bounded data structure known as the `Pipeline_Event`. It contains context-free data (e.g., a `Namespace`, `Key`, and `Value`) alongside spatial coordinates (`Line_Number`, `Column_Number`) for diagnostic routing.

### 3.2. The Frontend (Data Extraction & Normalization)
The Frontend encompasses the first four phases of the pipeline, focusing on transforming raw OS data into the IR:
* **Phase 1: Reader (I/O Boundary)** - The only stateful phase. It safely interfaces with the OS to fetch raw bytes or strings line-by-line (e.g., reading a file stream or `argv`).
* **Phase 2: Lexer (Scanner)** - A purely mathematical, $O(1)$ memory state machine that groups raw characters into spatial Tokens without understanding their domain meaning.
* **Phase 3: Parser (Grammar FSM)** - Validates the arrangement of Tokens against a format-specific grammar (e.g., ensuring TOML brackets are closed). It emits format-specific structural events.
* **Phase 4: Normalizer (IR Generator)** - Tracks localized micro-states (like the current TOML table) and flattens the hierarchical structural events into the universal, context-free `Pipeline_Event` (IR).

### 3.3. The Backend (Semantic Application)
The Backend represents the MakeOps domain logic and operates entirely agnostic to the source format:
* **Phase 5: Applier** - Receives the normalized `Pipeline_Event`s. It verifies the semantics against the domain rules (e.g., ensuring a log level is a known enumeration value) and safely mutates the target static data structure (like `App_Config` or `Project_Config`). Any domain violation triggers an immediate Fail-Fast halt.

## 4. Engineering Impact

* **Constraints:** All inter-phase communication must occur via statically sized, flat records. No phase is permitted to allocate dynamic trees or maps to represent the configuration hierarchy. The pipeline mechanism MUST be implemented as an Ada `generic` package to ensure compile-time monomorphization, eliminating polymorphic dispatch (`access all ...'Class`).
* **Performance/Memory Risks:** By eliminating dynamic dispatch and heap memory, the pipeline guarantees cache-friendly, $O(1)$ memory complexity operations. Processing large configuration files is bounded solely by OS I/O speed.
* **Opportunities:** The absolute decoupling of Frontends and Backends yields orthogonal scalability. The Loaders defined in the Master Orchestration Lifecycle simply instantiate this generic pipeline, selecting the appropriate Frontend (e.g., `MakeOps.Core.TOML`) and routing it to the appropriate Backend (e.g., `MakeOps.App.Config.Applier`).

## 5. References

**Internal Documentation:**
* [1] [MOD-001: Master Orchestration Lifecycle](./MOD-001-master-orchestration-lifecycle.md)
* [2] [MOD-009: Formal Verification & Static Memory Foundations](./MOD-009-formal-verification-static-memory.md)
* [3] [MOD-013: MakeOps TOML Dialect Model](./MOD-013-toml-dialect-model.md)

**External Literature:**
* [4] Aho, A. V., Lam, M. S., Sethi, R., & Ullman, J. D. (2006). *Compilers: Principles, Techniques, and Tools* (2nd ed.). Pearson. (The "Dragon Book" - Front-end/Back-end split and Intermediate Representations).
* [5] Fabian, R. (2018). *Data-Oriented Design*. (Data flow, cache coherency, and rejection of object-oriented state).