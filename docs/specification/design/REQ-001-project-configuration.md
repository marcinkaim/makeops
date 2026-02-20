<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# REQ-001 Project Configuration Handling

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `REQ-001` |
| **Status** | `APPROVED` |
| **Date** | 2026-02-20 |
| **Capability Type** | User-Facing |
| **References** | `REQ-000` |

## 1. Capability Description (The "What" & "Why")
* **Definition:** The ability for users to define the operational environment, tasks, and execution dependencies using a structured, human-readable configuration file.
* **User Value / Rationale:** Provides a centralized, deterministic, and easily maintainable blueprint for the project's DevOps lifecycle. It separates configuration from execution logic, allowing users to orchestrate complex tasks without embedding shell scripts.
* **Dependencies:** Inherits constraints from `REQ-000`.

## 2. Functional Requirements (Behavior)
* **F-001-001:** The system SHALL allow users to define immutable global constants within an `[environment]` section.
* **F-001-002:** The system SHALL allow users to define discrete operations in isolated sections (e.g., `[operations.<name>]`).
* **F-001-003:** The system SHALL allow users to declare dependencies between operations to establish a specific execution order.
* **F-001-004:** The system SHALL allow users to construct an execution payload by specifying a single executable command (`cmd`) and an ordered list of arguments (`args`) for each operation.
* **F-001-005:** The system SHALL, by default, load the configuration from a file named `makeops.toml` located in the current working directory.
* **F-001-006:** The system SHALL provide a mechanism (e.g., via a CLI argument) for the user to specify an alternative path to the configuration file.

## 3. System Constraints & Quality Attributes (NFRs)
* **NFR-001-001 (Format Compatibility):** The underlying parsing mechanism MUST strictly interpret the configuration file as a predefined subset of the TOML format.
* **NFR-001-002 (Dependency Integrity):** The system MUST strictly enforce acyclic relationships; it MUST reject the configuration if cyclical dependencies are defined by the user.
* **NFR-001-003 (Stream Processing):** The core parsing logic MUST operate on an abstracted text stream rather than hardcoded file paths, allowing the application layer to manage file I/O operations.

## 4. Input / Output Data Model
* **Inputs:**
    * The user-provided configuration file (`makeops.toml` or a custom-provided path).
    * Optional CLI flags altering the file path.
* **Outputs:**
    * An internal abstract syntax tree (AST) or domain model representing the parsed environment constants, operations, and the resolved dependency graph.

## 5. Acceptance Criteria (Definition of Done)
* **AC-001-001:** The system successfully discovers, loads, and interprets a valid `makeops.toml` file from the current directory without requiring explicit path arguments.
* **AC-001-002:** The system successfully loads and interprets a valid configuration file from a custom location when the user specifies an alternative path.
* **AC-001-003:** The system gracefully aborts and provides a clear error message when the user attempts to load a file with invalid syntax or missing mandatory fields (`cmd` and `args` in an operation).
* **AC-001-004:** The system correctly establishes the order of operations based on the user-defined `deps` arrays.