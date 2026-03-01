<!--
  MakeOps
  Copyright (C) 2026 Marcin Kaim
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# ALG-004 Event-Driven TOML Lexer

| Attribute | Value |
| :--- | :--- |
| **Document ID** | `ALG-004` |
| **Status** | `APPROVED` |
| **Date** | 2026-02-22 |
| **Category** | Algorithm |
| **Tags** | TOML, Lexer, Parser, SAX, Event-Driven, Stream Processing |

## 1. Definition & Context
The Event-Driven TOML Lexer represents the Level 1 (Syntactical) tier of the internal configuration parsing engine. Instead of loading an entire configuration file into a generic, memory-heavy Document Object Model (DOM), this lexer reads the configuration as a continuous text stream. 

In the context of the **MakeOps** project, this zero-dependency algorithm ensures fast, strict, and memory-efficient interpretation of a specific TOML subset (the MakeOps TOML Dialect, as formalized in `PLAT-013`). By leveraging the mathematical properties of UTF-8 (`PLAT-011`), it safely processes raw byte streams without decoding overhead. Because the dialect strictly limits values to strings and arrays of strings, the lexer intentionally treats booleans, integers, and inline tables as syntax errors. It separates the pure syntax validation from the domain-specific business logic by triggering semantic events (callbacks) whenever a valid structure is encountered.

## 2. Theoretical Basis
The parsing strategy is built upon a Line-by-Line Processing model paired with an Event-Driven Architecture (analogous to the SAX parsing pattern). 

### 2.1. Line-by-Line Stream Processing
To satisfy the $O(1)$ memory constraint regarding file size, the algorithm maintains only the currently evaluated line in memory. It strips out human-readable noise (trailing comments, leading/trailing whitespaces) sequentially. A miniature state machine (a boolean flag) is employed strictly to handle multi-line arrays, aggregating them line-by-line without buffering the entire file.

### 2.2. Event-Driven Decoupling
The lexer possesses no semantic knowledge of the MakeOps domain (e.g., it does not know what an "operation" or a "dependency" is). Its sole responsibility is pattern matching. When a pattern is successfully matched, it fires one of three distinct events:
* `On_Section_Found`
* `On_String_Value_Found`
* `On_Array_Value_Found`

When the end of file is reached, after successfully processing its content, the `On_End_Of_File` event is fired.

This decoupling allows the exact same Level 1 Lexer to be reused for both the project operations graph (`makeops.toml`) and the hierarchical global preferences (`config.toml`).

### 2.3. Structured Algorithmic Description
The following is a structured definition of the Level 1 Lexical and Syntactic Parser (Event-Driven).

**Inputs:**
* `File_Stream`: An open text stream of the configuration file.

**Outputs:**
* Triggers event `On_Section_Found(Section_Name)`.
* Triggers event `On_String_Value_Found(Key, String_Value)`.
* Triggers event `On_Array_Value_Found(Key, Array_Of_Strings, Line_Number, Column_Number)`.
* Domain errors represented as a variant record containing the exact error type and its spatial coordinates (`Line_Number`, `Column_Number`): `Malformed_Section_Header`, `Unsupported_Value_Type`, `Unrecognized_Statement`.

**Procedure `Extract_Strings_To_List(Text, Target_List)`:**
1. Loop while `Text` contains `"`:
   * Set `Extracted_String := Extract_Between_Quotes(Text)`
   * Call `Target_List.Append(Extracted_String)`
   * Call `Remove_Processed_Part(Text)`

**Main Execution Flow:**
1. Set `Line_Number := 0`
2. Set `In_Array_Mode := False`
3. Set `Current_Array_Key := Empty_String`
4. Set `Current_Array_Elements := Empty_List`
5. Set `Current_Array_Column := 0`
6. Loop while `File_Stream` has next line:
   * Set `Raw_Line := File_Stream.Get_Next_Line()`
   * Set `Line_Number := Line_Number + 1`
   * Set `Line := Strip_Trailing_Comments(Raw_Line)`
   * Set `Line := Strip_Whitespace(Line)`
   * If `Line` is empty:
     * Proceed to next iteration.
   * Check `In_Array_Mode`:
     * **If `True`:**
       * Call `Extract_Strings_To_List(Line, Current_Array_Elements)`
       * If `Line` contains `]`:
         * Call `On_Array_Value_Found(Current_Array_Key, Current_Array_Elements, Line_Number, Current_Array_Column)`
         * Set `In_Array_Mode := False`
     * **If `False`:**
       * If `Line` starts with `[`:
         * If `Line` ends with `]`:
           * Set `Section_Name := Extract_Text_Between(Line, "[", "]")`
           * Set `Column_Number := Find_Index(Raw_Line, "[")`
           * Call `On_Section_Found(Section_Name, Line_Number, Column_Number)`
         * Else:
           * Set `Column_Number := Find_Index(Raw_Line, "[")`
           * Return Error: `Malformed_Section_Header` (Line => Line_Number, Column => Column_Number)
       * Else if `Line` contains `=`:
         * Set `Key := Get_Left_Side(Line, "=")`
         * Set `Column_Number := Find_Index(Raw_Line, Key)`
         * Set `Value_Part := Get_Right_Side(Line, "=")`
         * If `Value_Part` starts with `"`:
           * Set `String_Val := Extract_Between_Quotes(Value_Part)`
           * Call `On_String_Value_Found(Key, String_Val, Line_Number, Column_Number)`
         * Else if `Value_Part` starts with `[`:
           * Set `Current_Array_Key := Key`
           * Set `Current_Array_Column := Column_Number`
           * Call `Current_Array_Elements.Clear()`
           * Call `Extract_Strings_To_List(Value_Part, Current_Array_Elements)`
           * If `Value_Part` contains `]`:
             * Call `On_Array_Value_Found(Current_Array_Key, Current_Array_Elements, Line_Number, Column_Number)`
           * Else:
             * Set `In_Array_Mode := True`
         * Else:
           * Set `Column_Number := Find_Index(Raw_Line, "=") + 1`
           * Return Error: `Unsupported_Value_Type` (Line => Line_Number, Column => Column_Number)
       * Else:
         * Set `Column_Number := Find_Index(Raw_Line, Line[1])`
         * Return Error: `Unrecognized_Statement` (Line => Line_Number, Column => Column_Number)
7. Call `On_End_Of_File`

## 3. Engineering Impact

* **Constraints:** The implementation MUST strictly rely on native Ada Text I/O streams. The lexer MUST NOT dynamically allocate heap memory for generic abstract syntax trees. 
* **Performance Risks:** None. The line-by-line approach ensures optimal CPU cache utilization and predictable, bounded memory consumption regardless of the configuration file's length.
* **Opportunities (Observability):** Because the lexer natively tracks the current `Line_Number` during its physical file iteration, any syntax violation (e.g., a missing quotation mark) results in an immediate `Invalid_Syntax` domain error tagged with the exact line number. This significantly enhances Developer Experience (DX) by providing pinpoint accuracy for troubleshooting.

## 4. References

**Internal Documentation:**
* [1] [REQ-001: Project Configuration Handling](../design/REQ-001-project-configuration.md)
* [2] [REQ-004: Global Tool Preferences](../design/REQ-004-global-preferences.md)
* [3] [PLAT-011: Text Encoding and Memory Safety](./PLAT-011-text-encoding-model.md)
* [4] [PLAT-013: MakeOps TOML Dialect and Grammar Constraints](./PLAT-013-makeops-toml-dialect.md)
