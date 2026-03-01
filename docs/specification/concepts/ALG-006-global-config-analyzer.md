<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# ALG-006 Global Config Semantic Analyzer

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `ALG-006` |
| **Status** | `APPROVED` |
| **Date** | 2026-02-22 |
| **Category** | Algorithm |
| **Tags** | Configuration, Semantic Analysis, State Machine, Fail-Fast, TOML |

## 1. Definition & Context
The Global Config Semantic Analyzer is a specialized Level 2 event subscriber designed exclusively to interpret system-wide and user-specific preference files (e.g., `/etc/makeops/config.toml`). 

In the context of the **MakeOps** project, while it relies on the same Level 1 Lexer (`ALG-004`) as the main project configuration parser, its semantic domain is strictly limited. It listens for lexical events to populate a `Partial_Config` record, which is subsequently fed into the Hierarchical Configuration Cascade (`ALG-003`). It acts as a rigid gatekeeper, ensuring that external global files cannot inject malformed data or unsupported structures into the application runtime.

## 2. Theoretical Basis
This analyzer utilizes a highly constrained subset of the Event-Driven State Machine pattern, emphasizing early data validation over complex graph construction.

### 2.1. Minimalist State Machine
Because the global configuration specification dictates a flat, single-section hierarchy (the `[preferences]` block), the internal Finite State Machine (FSM) is minimalist. It strictly enforces that no key-value pairs are declared outside of this explicit section. Any structural deviation immediately invalidates the parsing process.

### 2.2. Strict Domain Validation (Fail-Fast)
To protect the integrity of the configuration cascade (`ALG-003`), this analyzer performs rigid semantic validation at the earliest possible stage. It mathematically limits the allowed configuration keys and their respective value domains (e.g., ensuring `log_level` is exclusively "error", "info", or "debug"). Furthermore, since global preferences do not utilize lists, the analyzer unconditionally rejects all array-based lexical events.

### 2.3. Structured Algorithmic Description
The following is a structured definition of the Level 2 Semantic Analyzer (Event-Driven State Machine) for the `config.toml` global preferences.

**Inputs:**
* A stream of events emitted by the Level 1 Lexer (`On_Section_Found`, `On_String_Value_Found`, `On_Array_Value_Found` with context `Line_Number` and `Column_Number`).
* An `On_End_Of_File` event triggered when the stream concludes.

**Outputs:**
* `Config_Record`: A `Partial_Config` structure containing `Log_Level` and `Project_Config` fields (initially set to `Not_Set`).
* Domain errors: `Unsupported_Section`, `Unsupported_Key`, `Unsupported_Value`, `Out_Of_Context_Declaration`, `Unexpected_Array`.

**Internal State:**
* `Current_Context`: The active configuration block. Valid states: `None`, `In_Preferences` (initially `None`).

**Event Handler `On_Section_Found(Section_Name, Line_Number, Column_Number)`:**
1. Check `Section_Name`:
   * **If `"preferences"`:**
     * Set `Current_Context := In_Preferences`
   * **If other:**
     * Return Error: `Unsupported_Section` (`Line_Number`, `Column_Number`)

**Event Handler `On_String_Value_Found(Key, String_Value, Line_Number, Column_Number)`:**
1. Check `Current_Context`:
   * **If `In_Preferences`:**
     * Check `Key`:
       * **If `"log_level"`:**
         * Check `String_Value`:
           * **If `"error"` or `"info"` or `"debug"`:** * Set `Config_Record.Log_Level := String_Value`
           * **If other:** * Return Error: `Unsupported_Value` (`Line_Number`, `Column_Number`)
       * **If `"project_config"`:**
         * Set `Config_Record.Project_Config := String_Value`
       * **If other:**
         * Return Error: `Unsupported_Key` (`Line_Number`, `Column_Number`)
   * **If `None`:**
     * Return Error: `Out_Of_Context_Declaration` (`Line_Number`, `Column_Number`)

**Event Handler `On_Array_Value_Found(Key, Array_Of_Strings, Line_Number, Column_Number)`:**
1. Return Error: `Unexpected_Array` (`Line_Number`, `Column_Number`)

**Event Handler `On_End_Of_File()`:**
1. Return `Config_Record`

## 3. Engineering Impact

* **Constraints:** The implementation MUST safely ignore arrays and unsupported TOML sections by returning an `Invalid_Semantics` error. It MUST output a `Partial_Config` record mapping missing fields to a distinct `Not_Set` state to satisfy the requirements of the Bottom-Up merging algorithm.
* **Performance Risks:** None. The file structures parsed by this analyzer are inherently tiny, guaranteeing microsecond-level execution times.
* **Opportunities:** This algorithm perfectly validates the separation of concerns (SoC) within the parsing architecture. It proves that the "MakeOps TOML" Level 1 Lexer is completely decoupled from the business logic and can be reused to parse entirely different domain models with minimal effort.

## 4. References

**Internal Documentation:**
* [1] [REQ-004: Global Tool Preferences](../design/REQ-004-global-preferences.md)
* [2] [ALG-003: Hierarchical Configuration Cascade](./ALG-003-configuration-cascade.md)
* [3] [ALG-004: Event-Driven TOML Lexer](./ALG-004-event-driven-toml-lexer.md)