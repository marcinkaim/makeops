<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# DES-016 MakeOps.Core.TOML Package Design

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `DES-016` |
| **Status** | `APPROVED` |
| **Date** | 2026-03-12 |
| **Target Package** | `MakeOps.Core.TOML` |

## 1. Scope & Responsibility

* **Goal:** Serves as the base namespace, domain dictionary, and contract definition for the MakeOps TOML Dialect.
* **Responsibility:**
    * Defines universal spatial coordinates (`Line_Number`, `Column_Number`).
    * Defines the semantic subtypes for text slices (`TOML_Lexeme`, `TOML_Line`) to enforce the Zero-Allocation / Raw Byte Bucket paradigm.
    * Defines the `Lexer_Listener` interface required for the Event-Driven (SAX-like) parsing architecture.
    * Defines the enumeration of all possible syntactical and lexical errors specific to the dialect.
* **Out of Scope:** This package strictly contains data type declarations and abstract interfaces. It MUST NOT contain any parsing logic, state machines, file system I/O, or semantic graph construction logic.

## 2. Traceability & Dependencies

* **Implements Requirements:**
    * `REQ-001` (Project Configuration format definition).
    * `REQ-004` (Global Preferences parsing base).
* **Applies Concepts:**
    * `PLAT-013` (MakeOps TOML Dialect: Enforces the string-only grammar subset).
    * `PLAT-011` (Text Encoding Model: Employs standard Ada `String` subtypes for UTF-8 byte buckets).
    * `ALG-004` (Event-Driven TOML Lexer: Formalizes the callback interface).
* **Internal Package Dependencies:**
    * `MakeOps.Core` (for base integer types if necessary, though mostly self-contained).

## 3. Interface Semantics (.ads Contract)

* **Core Types & State:**
    * `Coordinate_Type`: A strongly-typed positive integer (e.g., `new Positive`) used to track spatial positions within the file.
    * `Line_Number` & `Column_Number`: Subtypes or aliases of `Coordinate_Type` for descriptive clarity.
    * `TOML_Line`: `subtype TOML_Line is String;` Represents a full raw line of text injected into the parser.
    * `TOML_Lexeme`: `subtype TOML_Lexeme is String;` Represents a zero-allocation slice of text (e.g., a specific key or value) extracted from the `TOML_Line`.
    * `Syntax_Error_Type`: An enumeration detailing dialect violations. Must include at least: `None`, `Malformed_Section_Header`, `Unsupported_Value_Type`, `Unrecognized_Statement`, `Unclosed_Array`.
    * `Lexical_Result`: A deterministic variant record returning either `Success` or an `Error` paired with its exact `Line_Number` and `Column_Number`.

* **Event Listener Interface:**
    * `Lexer_Listener`: An abstract interface type representing a subscriber to lexical events.
    * This interface acts as the contract between the stateless Lexer and domain-aware analyzers (like `ALG-005` or `ALG-006`).

* **Main Subprograms (Abstract Primitives of Lexer_Listener):**
    * `On_Section_Found`: An abstract procedure accepting the listener instance, the section name (`TOML_Lexeme`), and spatial coordinates (`Line_Number`, `Column_Number`). Invoked when a valid `[section]` header is parsed.
    * `On_String_Value_Found`: An abstract procedure accepting the listener instance, the key (`TOML_Lexeme`), the string value (`TOML_Lexeme`), and spatial coordinates. Invoked when a standard key-value pair is parsed.
    * `On_Array_Start`: An abstract procedure accepting the listener instance, the key (`TOML_Lexeme`) for the array, and spatial coordinates. Invoked when the opening bracket of an array is encountered.
    * `On_Array_Item`: An abstract procedure accepting the listener instance, the string value (`TOML_Lexeme`) of the array element, and spatial coordinates. Invoked for each valid string element within an array.
    * `On_Array_End`: An abstract procedure accepting the listener instance and spatial coordinates. Invoked when the closing bracket of an array is encountered.
    * `On_End_Of_File`: An abstract procedure accepting the listener instance. Invoked when the stream concludes successfully.

* **Invariants & Contracts (Conceptual):**
    * The `TOML_Lexeme` outputs MUST represent direct slices of the input `TOML_Line` to guarantee $O(1)$ memory complexity (Zero-Allocation) at the Lexer boundary.
    * Event parameters MUST NOT contain surrounding structural characters (e.g., brackets `[` `]` or quotes `"` must be stripped).

## 4. Implementation Guidelines (.adb details)

* **SPARK / Memory Constraints:** This is a purely declarative specification package. It utilizes standard `String` subtypes rather than `Ada.Strings.Bounded` to prevent any memory copying prior to the semantic analysis phase.
* **OS / POSIX Interactions:** None. This package is completely oblivious to the operating system or file streams.
* **Algorithmic Flow:**
    * The streaming adaptation of the array events (`On_Array_Start`, `On_Array_Item`, `On_Array_End`) modifies the original `ALG-004` buffering approach. This change ensures that multi-line arrays can be parsed line-by-line without requiring the Lexer to internally cache `Bounded_String` values across line iterations.

## 5. Verification Strategy

* **Static Proof (GNATprove):** The package MUST be marked with `pragma Preelaborate;` and `pragma SPARK_Mode (On);`. The compiler will automatically prove this package as it contains no state mutators or complex logic, achieving Absence of Runtime Errors (AoRE).
* **AUnit Test Scenarios:**
    * **Direct Testing:** As a declarative interface package, it does not require an independent suite of behavioral unit tests. Its constructs are indirectly and exhaustively validated by the test suites of its consumers (`MakeOps.Tests.Core_TOML_Lexer`).