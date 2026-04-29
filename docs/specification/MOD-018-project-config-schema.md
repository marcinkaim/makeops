<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# MOD-018 Project Configuration Schema Model

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `MOD-018` |
| **Status** | `APPROVED` |
| **Date** | 2026-04-24 |
| **Tags** | TOML, Schema, Operations, DAG, Environment, Config |

## 1. Definition & Context
The Project Configuration Schema Model defines the absolute, normative structure of the project-level `makeops.toml` file. 

In the context of the MakeOps architecture, while `MOD-013` (MakeOps TOML Dialect) defines *how* the text is parsed (the syntax constraints), this document defines *what* is allowed to be parsed (the semantic schema). It establishes the exact rules for defining global environment constants and constructing the nodes of the operational Directed Acyclic Graph (DAG), ensuring that the configuration safely maps to the system's static memory boundaries.

## 2. Theoretical Basis
This schema bridges data definition theory with the mathematical representation of dependency graphs.

### 2.1. Domain-Specific Languages (DSL) vs. Strict Schemas
A configuration file acts as a Domain-Specific Language. To ensure mathematical determinism, the schema must enforce strict validation rules. Any data provided by the user that falls outside the recognized schema (e.g., misspelled keys, unsupported fields) must be explicitly rejected. Permissive schemas (which silently ignore unknown fields) lead to unpredictable behavior and violate the "Fail-Fast" engineering principle.

### 2.2. Graph Representation via Data Structures
In graph theory, a Directed Acyclic Graph (DAG) is composed of Vertices (Nodes) and Edges (Dependencies). In a text-based schema, this is represented via an Adjacency List. Each operation block defines a Vertex, and its corresponding `deps` array explicitly lists the directed Edges pointing to prerequisite Vertices.

## 3. Conceptual Model
The schema defines exactly two primary structural components: the static Environment Dictionary and the Operations Graph. 

### 3.1. The `[environment]` Dictionary
This single, optional section acts as the project's static variable repository.
* **Purpose:** Defines immutable constants used for Lazy Variable Substitution.
* **Schema Constraints:**
    * It must be a top-level table named exactly `[environment]`.
    * **Keys:** Act as the variable identifiers (e.g., `PROJECT_ROOT`, `VERSION`).
    * **Values:** Must be exclusively standard UTF-8 string literals (e.g., `"1.0.0"`). Arrays or nested tables are strictly prohibited in this section.

### 3.2. The `[operations.<name>]` Nodes
These sections define the executable tasks. Each discrete `<name>` identifies a unique Vertex in the DAG.
* **Purpose:** Instructs the POSIX execution engine on what binary to run and defines temporal dependencies.
* **Schema Constraints:**
    * **`cmd` (Required):** A single string representing the binary to execute (e.g., `"gprbuild"` or `"./scripts/build.sh"`).
    * **`args` (Required):** An array of strings representing the exact arguments passed to the `cmd`. To enforce pure execution, this cannot be a single concatenated string. If no arguments are needed, an empty array `[]` must be provided.
    * **`deps` (Optional):** An array of strings representing the names of other operations that must complete before this operation begins (the edges of the DAG).
    * **`description` (Optional):** A string providing a human-readable explanation of the task, used for CLI help output.
    * **Unknown Keys:** Any key other than `cmd`, `args`, `deps`, or `description` within an operations block is considered a domain violation.

### 3.3. Schema Invariants & Domain Rules
* **String-Only Paradigm:** Inheriting from `MOD-013`, no native TOML numbers or booleans are allowed as values anywhere in the schema.
* **Uniqueness:** Operation names (the `<name>` in `[operations.<name>]`) must be unique across the entire file. Redefining an operation must trigger an immediate schema violation.
* **Self-Referential Isolation:** Variables defined in the `[environment]` section can reference OS variables or other `[environment]` variables via `${VAR}`, but they cannot reference properties of operations.

## 4. Engineering Impact
This schema directly constrains the implementation of Phase 5 (The Applier) for the project domain.

* **Constraints:**
    * **`MakeOps.Core.Project.Config.Applier`:** This package MUST implement strict semantic validation. Upon receiving `Pipeline_Event`s from the Normalizer, it MUST reject any unknown keys inside operation tables.
    * It MUST verify that `cmd` events carry string values and `args`/`deps` events carry string-array values.
* **Performance/Memory Risks:**
    * To maintain AoRE and comply with `MOD-009` (Static Memory Model), the Applier MUST enforce physical limits during schema validation: the total number of operations cannot exceed `Max_Operations`, and the length of any `cmd` string cannot exceed `Max_Command_Length`. Exceeding these limits must result in a controlled domain error, not an Ada exception.
* **Opportunities:** Because the schema is flat and explicitly denies nested tables inside operations, the memory structures mapping to this schema (`Project_Config` record) can be constructed using straightforward, static arrays and indices, making SPARK verification trivial.

## 5. References

**Internal Documentation:**
* [1] [REQ-001: Project Configuration Handling](./REQ-001-project-configuration.md)
* [2] [MOD-004: Execution Plan Resolution](./MOD-004-execution-plan-resolution.md)
* [3] [MOD-009: SPARK Verification & Static Memory Model](./MOD-009-formal-verification-static-memory.md)
* [4] [MOD-013: MakeOps TOML Dialect Model](./MOD-013-toml-dialect-model.md)

**External Literature:**
* [6] Diestel, R. (2017). *Graph Theory* (5th ed.). Springer. (Mathematical foundations of Adjacency Lists and Directed Acyclic Graphs).
* [7] Hoare, C. A. R. (1969). *An Axiomatic Basis for Computer Programming*. Communications of the ACM. (Mathematical validation of states and constraints).