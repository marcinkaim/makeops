<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# DES-019 MakeOps.Core.TOML.Lexer.Array_Mode Design

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `DES-019` |
| **Status** | `APPROVED` |
| **Date** | 2026-03-16 |
| **Target Package** | `MakeOps.Core.TOML.Lexer.Array_Mode` |

## 1. Scope & Responsibility

* **Goal:** Encapsulates the line-parsing logic for TOML lines specifically when the lexer is currently inside a multi-line array block.
* **Responsibility:**
    * Implements a flat, character-by-character Finite State Machine (Micro-FSM) tailored for array contents.
    * Extracts array elements (specifically string values) and dispatches them via the `On_Array_Item` event.
    * Handles array syntactical constructs such as commas and whitespaces/comments between items.
    * Detects the closing bracket `]` and transitions the global `Lexer_State` back to the standard mode (setting `In_Array_Mode` to `False`), emitting the `On_Array_End` event.
* **Out of Scope:** This package strictly excludes the parsing of standard TOML key-value pairs or section headers. It also excludes file I/O, dynamic memory allocation, and semantic validation of the array's internal data.

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
    * This package operates strictly on the private `State` record inherited from its parent `MakeOps.Core.TOML.Lexer`. It does not maintain independent states between calls.
* **Main Subprograms:**
    * `Process_Line`: The primary execution primitive. It evaluates the string, extracts items, triggers callbacks on the `Lexer_Listener`, and manages the exit from array mode if `]` is reached.
* **Invariants & Contracts (Conceptual):**
    * **Preconditions:** The lexer MUST currently be in array mode (`Lexer_State.In_Array_Mode`) before execution. The `Line` must not be empty and must fit within `Integer` limits.
    * **Postconditions:** Guarantees that if a parsing error occurs, the spatial result points exactly to `Line_Num`. Mathematically guarantees that if the lexer does *not* exit array mode, the original `Array_Start_Line` and `Array_Start_Column` coordinates in the `Lexer_State` remain completely untouched (`Lexer_State'Old`).
    * **Data Flow:** The `Depends` contract strictly specifies that the resulting `Lexer_State` depends only on its previous state and the current `Line` contents (ignoring the `Line_Num` for state mutations, as it only mutates `In_Array_Mode`).

## 4. Implementation Guidelines (.adb details)

* **SPARK / Memory Constraints:** Completely bounds-checked and stack-based. The zero-allocation slice `Line (Value_Start .. Cursor - 1)` must be proven to fit safely within the allocated `String` memory.
* **OS / POSIX Interactions:** None.
* **Algorithmic Flow:**
    * Governed by the `Parse_Phase` enumeration (e.g., `Expecting_Item`, `Parsing_String`, `Expecting_Comma_Or_End`, `Trailing_Garbage`).
    * Uses a single `while` loop over the line's characters. 
    * If a string remains unclosed at the end of the line (e.g., `Parsing_String` state), it correctly flags an error, as strings cannot span multiple lines in this specific TOML dialect.
    * Comments (`#`) correctly cause the lexer to ignore the remainder of the line without raising errors.

## 5. Verification Strategy

* **Static Proof (GNATprove):**
    * The package MUST achieve **Tier 3 SPARK (Functional Correctness)**.
    * Loop invariants must mathematically demonstrate that `Value_Start` and `Cursor` cannot violate array bounds, ensuring memory safety.
    * The prover must verify the State Transition Contracts, specifically ensuring that array start coordinates are strictly preserved across loop iterations and procedure calls as long as the array remains open.
* **AUnit Test Scenarios:**
    * **Indirect Testing:** Tested through the parent orchestrator test suite (`MakeOps.Tests.Core_TOML_Lexer`).
    * **Happy Path (via Parent):** Valid elements separated by commas, potentially spread across multiple lines, properly fire `On_Array_Item` events followed by an `On_Array_End` event.
    * **Error Paths (via Parent):** Missing commas between elements, unquoted items (e.g., booleans or integers), or garbage characters after the closing bracket `]` result in an immediate `Success => False` with precise coordinate reporting, without raising exceptions.