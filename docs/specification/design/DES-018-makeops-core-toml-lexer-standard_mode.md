<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# DES-018 MakeOps.Core.TOML.Lexer.Standard_Mode Design

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `DES-018` |
| **Status** | `APPROVED` |
| **Date** | 2026-03-16 |
| **Target Package** | `MakeOps.Core.TOML.Lexer.Standard_Mode` |

## 1. Scope & Responsibility

* **Goal:** Encapsulates the line-parsing logic for standard TOML lines (outside of array blocks) using a flat character-by-character Micro-FSM.
* **Responsibility:**
    * Processes standard lines to identify `[sections]` and `key = "value"` assignments.
    * Implements a detailed Finite State Machine (`Parse_Phase`) to track syntax correctness on a character level.
    * Extracts zero-allocation text slices and dispatches them immediately to the `Lexer_Listener`.
    * Detects the start of inline and multi-line arrays (e.g., encountering `[` as a value) and transitions the global `Lexer_State` into array mode.
    * Calculates and reports precise spatial coordinates (column numbers) upon encountering syntax errors.
* **Out of Scope:** This package does not handle the continuation of multi-line array parsing (which is strictly delegated to the `Array_Mode` child package). It also excludes file I/O, dynamic memory allocation, and semantic validation of the parsed tokens.

## 2. Traceability & Dependencies

* **Implements Requirements:**
    * `REQ-001` (Project Configuration Handling: Format interpretation).
    * `REQ-004` (Global Tool Preferences: Format interpretation).
* **Applies Concepts:**
    * `ALG-004` (Zero-Allocation Lexical Scanning).
    * `PLAT-011` (Text Encoding Model: UTF-8 byte buckets via `String`).
    * `PLAT-013` (MakeOps TOML Dialect constraints: string-only subset).
* **Internal Package Dependencies:**
    * `MakeOps.Core.TOML` (Domain dictionary, spatial coordinates, listener interface).
    * `MakeOps.Core.TOML.Lexer` (Parent package, defines the `State` record and `Ghost` functions for proofs).

## 3. Interface Semantics (.ads Contract)

* **Core Types & State:**
    * This package operates strictly on the private `State` record inherited from its parent `MakeOps.Core.TOML.Lexer`. It does not declare its own state types, maintaining the stateless nature of the parsing cycle.
* **Main Subprograms:**
    * `Process_Line`: The sole execution primitive. It evaluates a single `TOML_Line` and either fires event callbacks on the `Listener` or halts early by setting a failing `Lexical_Result`. It mutates `Lexer_State` if an array is opened.
* **Invariants & Contracts (Conceptual):**
    * **Preconditions:** The lexer MUST NOT be in array mode (`not Lexer_State.In_Array_Mode`) prior to execution, and the line must not be completely empty or oversized.
    * **Postconditions:** Guarantees that if a parsing error occurs, the result will precisely point to the current `Line_Num`. If an array is opened during the line processing, it mathematically guarantees that the array's starting line coordinates are correctly recorded in the state.
    * **Data Flow:** `Depends` contracts strictly guarantee that `Lexer_State` and `Result` depend only on the line contents and current state, preventing hidden side-effects.

## 4. Implementation Guidelines (.adb details)

* **SPARK / Memory Constraints:** Must operate completely within bounded stack limits. Substrings (e.g., `Line (Key_Start .. Key_End)`) must be proven via loop invariants to never exceed the bounds of the underlying `String` array.
* **OS / POSIX Interactions:** None. Pure computational and string-slicing logic.
* **Algorithmic Flow:**
    * Driven by a strictly defined `Parse_Phase` enumeration (e.g., `Idle`, `Parsing_Key`, `Expecting_Eq`, `Parsing_String_Value`, `In_Array_Expecting_Item`).
    * Utilizes a single `while` loop that iterates over `Cursor` bounds.
    * Relies heavily on `pragma Loop_Invariant` to suppress SPARK loop amnesia, continuously proving the safety of array indices (`Token_Start`, `Key_Start`, `Value_Start`, `Key_End`) and the retention of `Lexer_State` spatial coordinates.

## 5. Verification Strategy

* **Static Proof (GNATprove):**
    * The package MUST achieve **Tier 3 SPARK (Functional Correctness)**.
    * Loop invariants must mathematically demonstrate that no slice bounds can ever trigger a `Constraint_Error` or `Range_Check` failure.
    * The prover must verify the State Transition Contracts, specifically that `Array_Start_Line` is mutated if and only if a valid `[` character transitions the `Parse_Phase` into an array-expecting state.
* **AUnit Test Scenarios:**
    * **Indirect Testing:** As a private child package, it is not tested in isolation. Its functional correctness is exhaustively verified through the parent orchestrator test suite (`MakeOps.Tests.Core_TOML_Lexer`).
    * **Happy Path (via Parent):** Valid sections and key-value pairs are successfully mapped to `On_Section_Found` and `On_String_Value_Found` events.
    * **Error Paths (via Parent):** Missing quotes, stray characters, or missing `=` signs immediately halt the `while` loop, returning `Success => False` with pinpoint column coordinates without raising native exceptions.