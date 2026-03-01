<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# ALG-005 Event-Driven Semantic Analyzer

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `ALG-005` |
| **Status** | `APPROVED` |
| **Date** | 2026-02-22 |
| **Category** | Algorithm |
| **Tags** | Semantic Analysis, State Machine, Parser, DAG, Configuration |

## 1. Definition & Context
The Event-Driven Semantic Analyzer represents the Level 2 tier of the MakeOps parsing engine. While the Level 1 Lexer (`ALG-004`) is strictly responsible for interpreting raw TOML syntax into agnostic events, the Level 2 Analyzer is fully aware of the MakeOps domain. 

In the context of the **MakeOps** project, this algorithm acts as an event subscriber that interprets syntactic callbacks to construct the internal business logic structures: the Environment Dictionary and the Operations Dependency Graph. It serves as the bridge between raw text parsing and the mathematical orchestration engine, guaranteeing that the user's configuration strictly adheres to the project specification.

## 2. Theoretical Basis
The analyzer is designed around two core theoretical concepts: a Context-Aware Finite State Machine (FSM) and Direct Graph Construction (Zero-AST).

### 2.1. Context-Aware Finite State Machine
The algorithm operates as a state machine where the current "State" is defined by the configuration context (e.g., parsing the `[environment]` block versus parsing a specific `[operations.build]` block). When the Level 1 Lexer emits an event (such as a key-value pair being found), the analyzer evaluates this event strictly through the lens of its current state. This context-awareness allows the algorithm to instantly reject logically invalid structures (e.g., declaring arrays inside the environment section) with precise semantic error messages.

### 2.2. Direct Graph Construction (Zero-AST)
Traditional parsing architectures often build a massive, intermediate Abstract Syntax Tree (AST) representing the entire file, which is later mapped to business objects. To maximize performance and adhere to strict memory constraints, this algorithm bypasses the intermediate AST entirely. Instead, event handlers directly instantiate and mutate the final `Graph_Node` objects required by the Topological Sorting algorithm (`ALG-001`).

### 2.3. Structured Algorithmic Description
The following is a structured definition of the Level 2 Semantic Analyzer (Event-Driven State Machine) for the `makeops.toml` configuration.

**Inputs:**
* A stream of events emitted by the Level 1 Lexer (`On_Section_Found`, `On_String_Value_Found`, `On_Array_Value_Found` with context `Line_Number` and `Column_Number`).
* An `On_End_Of_File` event triggered when the stream concludes.

**Outputs:**
* `Environment_Map`: A dictionary mapping environment variables.
* `Operations_Graph`: A dictionary mapping `ID_Type` to `Graph_Node` structures (as required by ALG-001).
* Domain errors: `Unsupported_Section`, `Redefinition_Error`, `Unsupported_Key`, `Out_Of_Context_Declaration`, `Unexpected_Array`, `Missing_Mandatory_Field`, `Dangling_Dependency`.

**Internal State:**
* `Current_Context`: The active configuration block. Valid states: `None`, `In_Environment`, `In_Operation` (initially `None`).
* `Current_Operation_ID`: The ID of the operation currently being parsed.

**Event Handler `On_Section_Found(Section_Name, Line_Number, Column_Number)`:**
1. Check `Section_Name`:
   * **If `"environment"`:**
     * Set `Current_Context := In_Environment`
   * **If starts with `"operations."`:**
     * Set `Current_Context := In_Operation`
     * Set `Current_Operation_ID := Get_Right_Side(Section_Name, ".")`
     * If `Operations_Graph` does not contain `Current_Operation_ID`:
       * Call `Operations_Graph.Add(Current_Operation_ID, Empty_Node)`
     * Else:
       * Return Error: `Redefinition_Error` (`Line_Number`, `Column_Number`)
   * **If other:**
     * Return Error: `Unsupported_Section` (`Line_Number`, `Column_Number`)

**Event Handler `On_String_Value_Found(Key, String_Value, Line_Number, Column_Number)`:**
1. Check `Current_Context`:
   * **If `In_Environment`:**
     * Set `Environment_Map[Key] := String_Value`
   * **If `In_Operation`:**
     * Set `Node := Operations_Graph[Current_Operation_ID]`
     * Check `Key`:
       * **If `"description"`:** Set `Node.Description := String_Value`
       * **If `"cmd"`:** Set `Node.Cmd := String_Value`
       * **If other:** Return Error: `Unsupported_Key` (`Line_Number`, `Column_Number`)
     * Update `Node` in `Operations_Graph`
   * **If `None`:**
     * Return Error: `Out_Of_Context_Declaration` (`Line_Number`, `Column_Number`)

**Event Handler `On_Array_Value_Found(Key, Array_Of_Strings, Line_Number, Column_Number)`:**
1. Check `Current_Context`:
   * **If `In_Operation`:**
     * Set `Node := Operations_Graph[Current_Operation_ID]`
     * Check `Key`:
       * **If `"deps"`:** Set `Node.Deps := Array_Of_Strings`
       * **If `"args"`:** Set `Node.Args := Array_Of_Strings`
       * **If other:** Return Error: `Unsupported_Key` (`Line_Number`, `Column_Number`)
     * Update `Node` in `Operations_Graph`
   * **If other:**
     * Return Error: `Unexpected_Array` (`Line_Number`, `Column_Number`)

**Event Handler `On_End_Of_File()`:**
1. For each `Node` in `Operations_Graph` loop:
   * If `Node.Cmd` is empty:
     * Return Error: `Missing_Mandatory_Field`
   * For each `Dependency_ID` in `Node.Deps` loop:
     * If `Operations_Graph` does not contain `Dependency_ID`:
       * Return Error: `Dangling_Dependency`

## 3. Engineering Impact

* **Constraints:** The implementation MUST adhere to the Open-Closed Principle (OCP). Adding support for new configuration keys in the future (e.g., an operation `timeout` parameter) MUST only require adding a single case statement within the existing semantic event handler, without requiring any modifications to the Level 1 Lexer. The analyzer MUST also enforce mandatory fields (e.g., ensuring every operation has a `cmd` defined) upon receiving the End-Of-File (EOF) signal.
* **Performance Risks:** Negligible. Dictionary lookups and graph insertions operate in amortized $O(1)$ time. 
* **Opportunities:** By strictly separating Level 1 (Syntax) and Level 2 (Semantics), the exact same Level 1 Lexer can be reused to feed events into a completely different, much simpler Level 2 Analyzer designed specifically for reading the global `config.toml` preferences (`REQ-004`).

## 4. References

**Internal Documentation:**
* [1] [REQ-001: Project Configuration Handling](../design/REQ-001-project-configuration.md)
* [2] [ALG-001: Topological Sorting and Cycle Detection](./ALG-001-topological-sort.md)
* [3] [ALG-004: Event-Driven TOML Lexer](./ALG-004-event-driven-toml-lexer.md)