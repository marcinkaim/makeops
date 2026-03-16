<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# DES-017 MakeOps.Core.TOML.Lexer Package Design

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `DES-017` |
| **Status** | `APPROVED` |
| **Date** | 2026-03-12 |
| **Target Package** | `MakeOps.Core.TOML.Lexer` |

## 1. Scope & Responsibility

* **Goal:** Serves as the stateless, zero-allocation, event-driven lexical analyzer for the MakeOps TOML Dialect.
* **Responsibility:**
    * Acts as a Macro-FSM dispatcher routing raw strings (`TOML_Line`) to appropriate private child packages (`Standard_Mode`, `Array_Mode`) for character-by-character token extraction.
    * Maintains the internal deterministic state machine (`State`), tracking contextual modes (e.g., standard parsing vs. multi-line array parsing).
    * Retains spatial coordinates (`Line`, `Column`) of multi-line structures to guarantee pinpoint error reporting across line boundaries.
    * Validates End-Of-File (EOF) constraints (e.g., unclosed arrays) and dispatches the `On_End_Of_File` event.
* **Out of Scope:** Character-by-character token extraction is delegated to child packages. This package strictly excludes file system operations, I/O streaming, memory allocation, and semantic validation.

## 2. Traceability & Dependencies

* **Implements Requirements:**
    * `REQ-001` (Project Configuration Handling: Format interpretation).
    * `REQ-004` (Global Tool Preferences: Format interpretation).
* **Applies Concepts:**
    * `ALG-004` (Event-Driven TOML Lexer: The core state machine and line-by-line algorithm).
    * `PLAT-011` (Text Encoding Model: Safely processing raw UTF-8 byte buckets).
    * `PLAT-013` (MakeOps TOML Dialect: Rejecting complex data types).
* **Internal Package Dependencies:**
    * `MakeOps.Core.TOML` (for `TOML_Line`, `TOML_Lexeme`, `Lexical_Result`, and the `Lexer_Listener` interface).

## 3. Interface Semantics (.ads Contract)

* **Core Types & State:**
    * `State`: A `private` record holding the runtime memory of the parsing process. It encapsulates flags such as `In_Array_Mode` and tracks the `Current_Array_Key` safely between line iterations.
* **Main Subprograms:**
    * `Initial_State`: A parameterless function returning a clean, reset `State` record. Allows the orchestrator to reuse the lexer for multiple files sequentially.
    * `Process_Line`: A procedure representing the core push-based execution unit. It accepts the current `State` (in/out), a raw `TOML_Line`, the current `Line_Number`, and a reference to an object implementing the `Lexer_Listener` interface. It mutates the state, invokes callbacks on the listener, and returns a `Lexical_Result` out-parameter (indicating success or a specific syntax error with coordinates).
    * `Finish`: A procedure invoked by the orchestrator upon reaching the End-Of-File (EOF). It accepts the current `State` (in/out) and a reference to the `Lexer_Listener`. It validates that the state machine is not left in an invalid state (e.g., indicating an unclosed array), returning a `Lexical_Result` and triggering the `On_End_Of_File` event if successful.
* **Invariants & Contracts (Conceptual):**
    * The package MUST guarantee Absence of Runtime Errors (AoRE). Specifically, all string slicing operations `Line(Start_Idx .. End_Idx)` must be mathematically proven to never exceed the bounds of `Line'First` and `Line'Last`.
    * The `Process_Line` procedure MUST NOT perform any dynamic memory allocation or unbounded string concatenation.

## 4. Implementation Guidelines (.adb details)

* **SPARK / Memory Constraints:** The package body MUST be verified with `pragma SPARK_Mode (On)`. It MUST use pure integer arithmetic for index tracking (`Cursor`, `Start_Idx`). 
* **OS / POSIX Interactions:** None. The lexer is completely decoupled from `MakeOps.Sys.File_Stream`.
* **Algorithmic Flow (Dispatcher):**
    * `Process_Line` acts as a pure dispatcher. It evaluates `Lexer_State.In_Array_Mode` and delegates the actual string processing to `Standard_Mode.Process_Line` or `Array_Mode.Process_Line`.
    * `Finish` evaluates the residual state. If `In_Array_Mode` is still true at EOF, it emits an `Unclosed_Array` error using the precise spatial coordinates saved in the `Lexer_State`.
* **SPARK Ghost Functions:**
    * To allow advanced Functional Correctness proofs (Tier 3 SPARK) without violating state encapsulation, coordinates and mode flags are exposed to the prover via `Ghost` functions (`Is_In_Array_Mode`, `Get_Array_Start_Line`, etc.).

## 5. Verification Strategy

* **Static Proof (GNATprove):**
    * The package MUST achieve **Tier 3 SPARK (Functional Correctness)**.
    * Strict `Pre` and `Post` contracts must prove that memory boundaries are respected (Absence of Runtime Errors), variables are safely initialized, and state transitions (e.g., preserving array coordinates) follow the exact business logic rules.
    * Data flow contracts (`Depends`, `Global => null`) must guarantee a completely side-effect-free architecture.
* **AUnit Test Scenarios (`MakeOps.Tests.Core_TOML_Lexer`):**
    * **Happy Paths & Edge Cases:** Broad verification of correct event dispatching using a Mock Listener, covering standard definitions, multi-line arrays, comment stripping, and immediate EOF generation.
    * **Error Paths:** Verification that dialect violations (unclosed arrays, unquoted strings, nested arrays) gracefully return a `Lexical_Result` with `Success => False` and precise coordinates, without triggering Ada exceptions.